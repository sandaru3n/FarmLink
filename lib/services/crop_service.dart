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
        .snapshots()
        .map((snapshot) {
      List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
      // Sort in memory instead of in Firestore to avoid composite index requirement
      crops.sort((a, b) => a.endDate.compareTo(b.endDate));
      return crops;
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
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold');
        }
        
        // Check if user has already bid
        if (crop.hasUserBid(bid.distributorId)) {
          throw Exception('You have already bid on this crop. Use "Update Bid" to change your bid amount.');
        }
        
        if (bid.amount < crop.minBidPrice) {
          throw Exception('Bid must be at least ₹${crop.minBidPrice}');
        }
        
        List<BidModel> updatedBids = List.from(crop.bids);
        updatedBids.add(bid);
        
        transaction.update(cropRef, {'bids': updatedBids.map((b) => b.toMap()).toList()});
      });
    } catch (e) {
      throw Exception('Failed to add bid: $e');
    }
  }

  // Update an existing bid
  Future<void> updateBid(String cropId, String distributorId, double newAmount) async {
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
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold');
        }
        
        // Check if user has bid
        BidModel? userBid = crop.getUserBid(distributorId);
        if (userBid == null) {
          throw Exception('You have not bid on this crop yet');
        }
        
        if (newAmount <= userBid.amount) {
          throw Exception('New bid amount must be higher than your current bid');
        }
        
        List<BidModel> updatedBids = List.from(crop.bids);
        int bidIndex = updatedBids.indexWhere((bid) => bid.distributorId == distributorId);
        
        if (bidIndex != -1) {
          updatedBids[bidIndex] = userBid.copyWith(
            amount: newAmount,
            createdAt: DateTime.now(),
          );
        }
        
        transaction.update(cropRef, {'bids': updatedBids.map((b) => b.toMap()).toList()});
      });
    } catch (e) {
      throw Exception('Failed to update bid: $e');
    }
  }

  // Place an order for the highest bidder
  Future<void> placeOrder(String cropId, String distributorId) async {
    try {
      DocumentReference cropRef = _cropsCollection.doc(cropId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot cropDoc = await transaction.get(cropRef);
        
        if (!cropDoc.exists) {
          throw Exception('Crop not found');
        }
        
        CropModel crop = CropModel.fromFirestore(cropDoc);
        
        if (!crop.isExpired) {
          throw Exception('Bidding has not ended yet');
        }
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold');
        }
        
        if (crop.bids.isEmpty) {
          throw Exception('No bids were placed on this crop');
        }
        
        // Check if the user is the highest bidder
        if (!crop.isUserHighestBidder(distributorId)) {
          throw Exception('Only the highest bidder can place an order');
        }
        
        BidModel highestBid = crop.highestBid!;
        
        // Create order
        OrderModel order = OrderModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          cropId: cropId,
          distributorId: distributorId,
          distributorName: highestBid.distributorName,
          farmerId: crop.farmerId,
          farmerName: 'Farmer', // You might want to get this from user service
          cropName: crop.cropName,
          quantity: crop.quantity,
          finalPrice: highestBid.amount,
          pickupLocation: crop.pickupLocation,
          status: 'pending',
          createdAt: DateTime.now(),
        );
        
        // Update crop with order and status
        transaction.update(cropRef, {
          'order': order.toMap(),
          'status': 'sold',
        });
      });
    } catch (e) {
      throw Exception('Failed to place order: $e');
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
