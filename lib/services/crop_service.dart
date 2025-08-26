import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_model.dart';
import 'storage_service.dart';

class CropService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StorageService _storageService = StorageService();

  // Collection references
  CollectionReference get _cropsCollection => _firestore.collection('crops');

  // Add a new crop listing
  Future<String> addCrop(CropModel crop) async {
    try {
      DocumentReference docRef = await _cropsCollection.add(crop.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add crop: $e');
    }
  }

  // Get all crops for a specific farmer
  Stream<List<CropModel>> getFarmerCrops(String farmerId) {
    return _cropsCollection
        .where('farmerId', isEqualTo: farmerId)
        // Temporarily removed orderBy to avoid composite index requirement
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
      // Sort in memory instead of in Firestore
      crops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return crops;
    });
  }

  // Get all active crops (for distributors to view)
  Stream<List<CropModel>> getActiveCrops() {
    return _cropsCollection
        .where('status', isEqualTo: 'active')
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
    });
  }

  // Get a specific crop by ID
  Future<CropModel?> getCropById(String cropId) async {
    try {
      DocumentSnapshot doc = await _cropsCollection.doc(cropId).get();
      if (doc.exists) {
        return CropModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get crop: $e');
    }
  }

  // Add a bid to a crop
  Future<void> addBid(String cropId, BidModel bid) async {
    try {
      DocumentReference cropRef = _cropsCollection.doc(cropId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot cropDoc = await transaction.get(cropRef);
        
        if (!cropDoc.exists) {
          throw Exception('Crop not found');
        }
        
        CropModel crop = CropModel.fromFirestore(cropDoc);
        
        if (crop.isExpired) {
          throw Exception('Bidding has ended for this crop');
        }
        
        if (bid.amount <= crop.minBidPrice) {
          throw Exception('Bid must be higher than minimum bid price');
        }
        
        List<BidModel> updatedBids = List.from(crop.bids);
        updatedBids.add(bid);
        
        transaction.update(cropRef, {'bids': updatedBids.map((b) => b.toMap()).toList()});
      });
    } catch (e) {
      throw Exception('Failed to add bid: $e');
    }
  }

  // Update crop status
  Future<void> updateCropStatus(String cropId, String status) async {
    try {
      await _cropsCollection.doc(cropId).update({'status': status});
    } catch (e) {
      throw Exception('Failed to update crop status: $e');
    }
  }

  // Delete a crop
  Future<void> deleteCrop(String cropId) async {
    try {
      // First get the crop to access its image URL
      final cropDoc = await _cropsCollection.doc(cropId).get();
      if (cropDoc.exists) {
        final cropData = cropDoc.data() as Map<String, dynamic>;
        final imageUrl = cropData['imageUrl'] as String? ?? '';
        
        // Delete the image from storage if it exists
        if (imageUrl.isNotEmpty && !imageUrl.contains('placeholder')) {
          await _storageService.deleteCropImage(imageUrl);
        }
      }
      
      // Delete the crop document
      await _cropsCollection.doc(cropId).delete();
    } catch (e) {
      throw Exception('Failed to delete crop: $e');
    }
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;
}
