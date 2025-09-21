import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';

class CropStatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _statusUpdateTimer;
  
  // Collection references
  CollectionReference get _cropsCollection => _firestore.collection('crops');

  // Start the status update service
  void startStatusUpdateService() {
    // Update statuses every minute
    _statusUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateCropStatuses();
    });
    
    // Also update immediately when service starts
    _updateCropStatuses();
  }

  // Stop the status update service
  void stopStatusUpdateService() {
    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;
  }

  // Update crop statuses based on time
  Future<void> _updateCropStatuses() async {
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
      print('Error during crop status update: $e');
    }
  }

  // Manual update for a specific crop
  Future<void> updateCropStatus(String cropId) async {
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

  // Get crops that need status updates
  Future<List<CropModel>> getCropsNeedingStatusUpdate() async {
    try {
      final pendingCropsQuery = await _cropsCollection
          .where('status', isEqualTo: 'pending')
          .get();
      
      final activeCropsQuery = await _cropsCollection
          .where('status', isEqualTo: 'active')
          .get();
      
      List<CropModel> cropsNeedingUpdate = [];
      
      // Check pending crops that should be active
      for (var doc in pendingCropsQuery.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.shouldBeActive) {
          cropsNeedingUpdate.add(crop);
        }
      }
      
      // Check active crops that should be expired
      for (var doc in activeCropsQuery.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.isExpired) {
          cropsNeedingUpdate.add(crop);
        }
      }
      
      return cropsNeedingUpdate;
    } catch (e) {
      print('Error getting crops needing status update: $e');
      return [];
    }
  }
}
