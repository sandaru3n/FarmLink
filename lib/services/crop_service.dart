import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_model.dart';
import 'storage_service.dart';
import 'order_service.dart';

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

  // Get crops for distributors (active + expired crops they've won)
  Stream<List<CropModel>> getDistributorCrops(String distributorId) {
    return _cropsCollection
        .where('status', whereIn: ['active', 'expired'])
        .snapshots()
        .map((snapshot) {
      List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
      
      // Filter expired crops to only show those where this distributor is the highest bidder
      crops = crops.where((crop) {
        if (crop.status == 'active') return true;
        if (crop.status == 'expired' && crop.isUserHighestBidder(distributorId)) return true;
        return false;
      }).toList();
      
      // Sort in memory instead of in Firestore to avoid composite index requirement
      crops.sort((a, b) => a.endDate.compareTo(b.endDate));
      return crops;
    });
  }

  // Get pending crops for a farmer
  Stream<List<CropModel>> getPendingCrops(String farmerId) {
    return _cropsCollection
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
      crops.sort((a, b) => a.startDate.compareTo(b.startDate));
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

  // Update crop status based on time
  Future<void> updateCropStatusBasedOnTime(String cropId) async {
    try {
      DocumentSnapshot cropDoc = await _cropsCollection.doc(cropId).get();
      if (!cropDoc.exists) {
        throw Exception('Crop not found');
      }

      CropModel crop = CropModel.fromFirestore(cropDoc);
      
      // Check if crop should be active
      if (crop.shouldBeActive && crop.status == 'pending') {
        await _cropsCollection.doc(cropId).update({
          'status': 'active',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      // Check if crop should be expired
      if (crop.isExpired && crop.status == 'active') {
        await _cropsCollection.doc(cropId).update({
          'status': 'expired',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      throw Exception('Failed to update crop status: $e');
    }
  }

  // Update crop details (for pending crops)
  Future<void> updateCrop(String cropId, CropModel updatedCrop) async {
    try {
      DocumentSnapshot cropDoc = await _cropsCollection.doc(cropId).get();
      if (!cropDoc.exists) {
        throw Exception('Crop not found');
      }

      CropModel existingCrop = CropModel.fromFirestore(cropDoc);
      
      // Only allow updates if crop is pending
      if (existingCrop.status != 'pending') {
        throw Exception('Only pending crops can be updated');
      }

      await _cropsCollection.doc(cropId).update(updatedCrop.toFirestore());
    } catch (e) {
      throw Exception('Failed to update crop: $e');
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
        
        // Check if crop is active
        if (crop.status != 'active') {
          throw Exception('Bidding is not active for this crop');
        }
        
        if (crop.isExpired) {
          throw Exception('Bidding has ended for this crop');
        }
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold to another distributor. Please check other available crops.');
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
        
        // Check if crop is active
        if (crop.status != 'active') {
          throw Exception('Bidding is not active for this crop');
        }
        
        if (crop.isExpired) {
          throw Exception('Bidding has ended for this crop');
        }
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold to another distributor. Please check other available crops.');
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
  Future<OrderModel> placeOrder(String cropId, String distributorId, String distributorLocation) async {
    try {
      DocumentReference cropRef = _cropsCollection.doc(cropId);
      
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot cropDoc = await transaction.get(cropRef);
        
        if (!cropDoc.exists) {
          throw Exception('Crop not found');
        }
        
        CropModel crop = CropModel.fromFirestore(cropDoc);
        
        if (!crop.isExpired) {
          throw Exception('Bidding has not ended yet');
        }
        
        if (crop.isSold) {
          throw Exception('This crop has already been sold to another distributor. Please check other available crops.');
        }
        
        if (crop.bids.isEmpty) {
          throw Exception('No bids were placed on this crop');
        }
        
        // Additional check: verify no existing order for this crop
        final existingOrderQuery = await _firestore.collection('orders')
            .where('cropId', isEqualTo: cropId)
            .where('orderStatus', whereIn: ['pending', 'confirmed', 'processing'])
            .limit(1)
            .get();
            
        if (existingOrderQuery.docs.isNotEmpty) {
          final existingOrder = existingOrderQuery.docs.first.data() as Map<String, dynamic>;
          final existingDistributorId = existingOrder['distributorId'] as String?;
          
          if (existingDistributorId == distributorId) {
            throw Exception('You have already placed an order for this crop. Please check your orders.');
          } else {
            throw Exception('This crop has already been ordered by another distributor.');
          }
        }
        
        // Check if the user is the highest bidder
        if (!crop.isUserHighestBidder(distributorId)) {
          throw Exception('Only the highest bidder can place an order');
        }
        
        // Get distributor details
        final distributorDoc = await _firestore.collection('users').doc(distributorId).get();
        if (!distributorDoc.exists) {
          throw Exception('Distributor not found');
        }
        
        final distributorData = distributorDoc.data() as Map<String, dynamic>;
        
        // Get farmer details
        final farmerDoc = await _firestore.collection('users').doc(crop.farmerId).get();
        if (!farmerDoc.exists) {
          throw Exception('Farmer not found');
        }
        
        final farmerData = farmerDoc.data() as Map<String, dynamic>;

        // Create order ID
        final orderId = DateTime.now().millisecondsSinceEpoch.toString();

        // Create order model
        final order = OrderModel(
          id: orderId,
          cropId: crop.id,
          distributorId: distributorId,
          distributorName: distributorData['displayName'] ?? 'Distributor',
          distributorEmail: distributorData['email'] ?? '',
          distributorPhone: distributorData['phone'] ?? '',
          distributorLocation: distributorLocation,
          farmerId: crop.farmerId,
          farmerName: farmerData['displayName'] ?? 'Farmer',
          farmerEmail: farmerData['email'] ?? '',
          farmerPhone: farmerData['phone'] ?? '',
          cropName: crop.cropName,
          cropImageUrl: crop.imageUrl,
          quantity: crop.quantity,
          finalPrice: crop.highestBid!.amount,
          pickupLocation: crop.pickupLocation,
          pickupLatitude: crop.pickupLatitude,
          pickupLongitude: crop.pickupLongitude,
          createdAt: DateTime.now(),
        );

        // Save order to Firestore within transaction
        transaction.set(_firestore.collection('orders').doc(orderId), order.toMap());

        // Update crop status to sold within the transaction
        transaction.update(cropRef, {
          'order': order.toMap(),
          'status': 'sold',
          'lastUpdated': Timestamp.fromDate(DateTime.now()),
        });

        return order;
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
      // First get the crop to access its image URL and check status
      final cropDoc = await _cropsCollection.doc(cropId).get();
      if (cropDoc.exists) {
        final cropData = cropDoc.data() as Map<String, dynamic>;
        final imageUrl = cropData['imageUrl'] as String? ?? '';
        final status = cropData['status'] as String? ?? 'pending';
        
        // Only allow deletion of pending crops
        if (status != 'pending') {
          throw Exception('Only pending crops can be deleted');
        }
        
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

  // Clean up orphaned orders and ensure data consistency
  Future<void> cleanupOrphanedOrders() async {
    try {
      // Get all orders
      final ordersSnapshot = await _firestore.collection('orders').get();
      
      for (var orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final cropId = orderData['cropId'] as String?;
        
        if (cropId != null) {
          // Check if crop exists and is marked as sold
          final cropDoc = await _cropsCollection.doc(cropId).get();
          
          if (!cropDoc.exists) {
            // Crop doesn't exist, delete the order
            await _firestore.collection('orders').doc(orderDoc.id).delete();
            print('Deleted orphaned order: ${orderDoc.id}');
          } else {
            final cropData = cropDoc.data() as Map<String, dynamic>;
            final cropStatus = cropData['status'] as String? ?? 'pending';
            final cropOrder = cropData['order'];
            
            // If crop is not marked as sold but has an order, update crop status
            if (cropStatus != 'sold' && cropOrder != null) {
              await _cropsCollection.doc(cropId).update({
                'status': 'sold',
                'lastUpdated': Timestamp.fromDate(DateTime.now()),
              });
              print('Updated crop status to sold: $cropId');
            }
            
            // If crop is marked as sold but has no order, check if order exists
            if (cropStatus == 'sold' && cropOrder == null) {
              // Check if order exists in orders collection
              final orderExists = await _firestore.collection('orders')
                  .where('cropId', isEqualTo: cropId)
                  .limit(1)
                  .get();
                  
              if (orderExists.docs.isNotEmpty) {
                // Update crop with order data
                final orderData = orderExists.docs.first.data();
                await _cropsCollection.doc(cropId).update({
                  'order': orderData,
                  'lastUpdated': Timestamp.fromDate(DateTime.now()),
                });
                print('Updated crop with order data: $cropId');
              } else {
                // No order exists, revert crop status
                await _cropsCollection.doc(cropId).update({
                  'status': 'active',
                  'order': null,
                  'lastUpdated': Timestamp.fromDate(DateTime.now()),
                });
                print('Reverted crop status to active: $cropId');
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error during cleanup: $e');
    }
  }

  // Batch update crop statuses based on time
  Future<void> batchUpdateCropStatuses() async {
    try {
      // Get all pending crops that should be active
      final pendingCropsQuery = await _cropsCollection
          .where('status', isEqualTo: 'pending')
          .get();
      
      final batch = _firestore.batch();
      int updatedCount = 0;
      
      for (var doc in pendingCropsQuery.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.shouldBeActive) {
          batch.update(doc.reference, {
            'status': 'active',
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
          updatedCount++;
        }
      }
      
      // Get all active crops that should be expired
      final activeCropsQuery = await _cropsCollection
          .where('status', isEqualTo: 'active')
          .get();
      
      for (var doc in activeCropsQuery.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.isExpired) {
          batch.update(doc.reference, {
            'status': 'expired',
            'lastUpdated': Timestamp.fromDate(DateTime.now()),
          });
          updatedCount++;
        }
      }
      
      if (updatedCount > 0) {
        await batch.commit();
        print('Updated $updatedCount crop statuses');
      }
    } catch (e) {
      print('Error during batch status update: $e');
    }
  }
}
