import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/donation_model.dart';
import '../models/charity_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _donationsCollection => _firestore.collection('donations');
  CollectionReference get _charitiesCollection => _firestore.collection('charities');

  // Create a new donation
  Future<String> createDonation({
    required String consumerId,
    required String consumerName,
    required String charityId,
    required String charityName,
    required String donationType,
    required List<DonationItem> items,
    double monetaryAmount = 0.0,
    String? paymentMethod,
    String? paymentStatus,
    String? notes,
    String? pickupAddress,
    String? contactPhone,
  }) async {
    try {
      final donationId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Calculate total value
      final foodValue = items.fold(0.0, (sum, item) => sum + item.totalValue);
      final totalValue = foodValue + monetaryAmount;

      final donation = DonationModel(
        id: donationId,
        consumerId: consumerId,
        consumerName: consumerName,
        charityId: charityId,
        charityName: charityName,
        donationType: donationType,
        items: items,
        monetaryAmount: monetaryAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        totalValue: totalValue,
        notes: notes,
        pickupAddress: pickupAddress,
        contactPhone: contactPhone,
        createdAt: DateTime.now(),
      );

      await _donationsCollection.doc(donationId).set(donation.toMap());
      
      // Update charity's total donations count
      await _updateCharityDonationCount(charityId);
      
      print('Donation created successfully: $donationId');
      return donationId;
    } catch (e) {
      print('Error creating donation: $e');
      throw Exception('Failed to create donation: $e');
    }
  }

  // Get all donations for a consumer
  Stream<List<DonationModel>> getConsumerDonations(String consumerId) {
    return _donationsCollection
        .where('consumerId', isEqualTo: consumerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        DonationModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get all donations for a charity
  Stream<List<DonationModel>> getCharityDonations(String charityId) {
    return _donationsCollection
        .where('charityId', isEqualTo: charityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        DonationModel.fromMap(doc.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  // Get all active charities
  Stream<List<CharityModel>> getActiveCharities() {
    return _charitiesCollection
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => 
        CharityModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        })
      ).where((charity) => charity.isActive).toList();
    });
  }

  // Get charity by ID
  Future<CharityModel?> getCharityById(String charityId) async {
    try {
      final doc = await _charitiesCollection.doc(charityId).get();
      if (doc.exists) {
        return CharityModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        });
      }
      return null;
    } catch (e) {
      print('Error getting charity: $e');
      throw Exception('Failed to get charity: $e');
    }
  }

  // Update donation status
  Future<void> updateDonationStatus(String donationId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
      };

      switch (status) {
        case 'confirmed':
          updateData['confirmedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case 'picked_up':
          updateData['pickedUpAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case 'completed':
          updateData['completedAt'] = Timestamp.fromDate(DateTime.now());
          // Generate tax receipt ID
          updateData['taxReceiptId'] = 'TR-${DateTime.now().millisecondsSinceEpoch}';
          break;
      }

      await _donationsCollection.doc(donationId).update(updateData);
      print('Donation status updated successfully: $donationId');
    } catch (e) {
      print('Error updating donation status: $e');
      throw Exception('Failed to update donation status: $e');
    }
  }

  // Cancel donation
  Future<void> cancelDonation(String donationId, String reason) async {
    try {
      await _donationsCollection.doc(donationId).update({
        'status': 'cancelled',
        'notes': reason,
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
      });
      print('Donation cancelled successfully: $donationId');
    } catch (e) {
      print('Error cancelling donation: $e');
      throw Exception('Failed to cancel donation: $e');
    }
  }

  // Get donation statistics for consumer
  Future<Map<String, dynamic>> getConsumerDonationStats(String consumerId) async {
    try {
      final donationsSnapshot = await _donationsCollection
          .where('consumerId', isEqualTo: consumerId)
          .get();

      final donations = donationsSnapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      int totalDonations = donations.length;
      int completedDonations = donations.where((d) => d.isCompleted).length;
      double totalValue = donations
          .where((d) => d.isCompleted)
          .fold(0.0, (sum, d) => sum + d.totalValue);

      return {
        'totalDonations': totalDonations,
        'completedDonations': completedDonations,
        'totalValue': totalValue,
        'charitiesSupported': donations.map((d) => d.charityId).toSet().length,
      };
    } catch (e) {
      print('Error getting donation stats: $e');
      return {
        'totalDonations': 0,
        'completedDonations': 0,
        'totalValue': 0.0,
        'charitiesSupported': 0,
      };
    }
  }

  // Update charity's donation count
  Future<void> _updateCharityDonationCount(String charityId) async {
    try {
      final donationsSnapshot = await _donationsCollection
          .where('charityId', isEqualTo: charityId)
          .where('status', isEqualTo: 'completed')
          .get();

      await _charitiesCollection.doc(charityId).update({
        'totalDonations': donationsSnapshot.docs.length,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error updating charity donation count: $e');
      // Don't throw error as this is not critical
    }
  }

  // Get donation by ID
  Future<DonationModel?> getDonationById(String donationId) async {
    try {
      final doc = await _donationsCollection.doc(donationId).get();
      if (doc.exists) {
        return DonationModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting donation: $e');
      throw Exception('Failed to get donation: $e');
    }
  }

  // Search charities by name or category
  Stream<List<CharityModel>> searchCharities(String query) {
    return _charitiesCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final charities = snapshot.docs.map((doc) => 
        CharityModel.fromMap({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        })
      ).toList();

      if (query.isEmpty) return charities;

      return charities.where((charity) {
        return charity.name.toLowerCase().contains(query.toLowerCase()) ||
               charity.description.toLowerCase().contains(query.toLowerCase()) ||
               charity.categories.any((cat) => cat.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }
}
