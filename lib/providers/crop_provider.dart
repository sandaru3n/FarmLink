import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../services/crop_service.dart';

class CropProvider extends ChangeNotifier {
  final CropService _cropService = CropService();
  
  List<CropModel> _farmerCrops = [];
  List<CropModel> _allActiveCrops = [];
  List<CropModel> _pendingCrops = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<CropModel> get farmerCrops => _farmerCrops;
  List<CropModel> get allActiveCrops => _allActiveCrops;
  List<CropModel> get pendingCrops => _pendingCrops;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get active crops for current farmer
  List<CropModel> get activeFarmerCrops => 
      _farmerCrops.where((crop) => crop.isActive).toList();

  // Get expired crops for current farmer
  List<CropModel> get expiredFarmerCrops => 
      _farmerCrops.where((crop) => crop.isExpired).toList();

  // Get pending crops for current farmer
  List<CropModel> get pendingFarmerCrops => 
      _farmerCrops.where((crop) => crop.isPending).toList();

  // Load farmer's crops
  void loadFarmerCrops(String farmerId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cropService.getFarmerCrops(farmerId).listen(
      (crops) {
        _farmerCrops = crops;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load pending crops for a farmer
  void loadPendingCrops(String farmerId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cropService.getPendingCrops(farmerId).listen(
      (crops) {
        _pendingCrops = crops;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load all active crops (for distributors)
  void loadAllActiveCrops() {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cropService.getActiveCrops().listen(
      (crops) {
        _allActiveCrops = crops;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Load crops for distributors (active + expired crops they've won)
  void loadDistributorCrops(String distributorId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _cropService.getDistributorCrops(distributorId).listen(
      (crops) {
        _allActiveCrops = crops;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // Add new crop
  Future<bool> addCrop(CropModel crop) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.addCrop(crop);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update crop details (for pending crops)
  Future<bool> updateCrop(String cropId, CropModel updatedCrop) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.updateCrop(cropId, updatedCrop);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add bid to crop
  Future<bool> addBid(String cropId, BidModel bid) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.addBid(cropId, bid);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing bid
  Future<bool> updateBid(String cropId, String distributorId, double newAmount) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.updateBid(cropId, distributorId, newAmount);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Place order for highest bidder
    Future<OrderModel?> placeOrder(String cropId, String distributorId, String distributorLocation) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final order = await _cropService.placeOrder(cropId, distributorId, distributorLocation);

      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update crop status
  Future<bool> updateCropStatus(String cropId, String status) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.updateCropStatus(cropId, status);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update crop status based on time
  Future<bool> updateCropStatusBasedOnTime(String cropId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.updateCropStatusBasedOnTime(cropId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete crop
  Future<bool> deleteCrop(String cropId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _cropService.deleteCrop(cropId);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Batch update crop statuses
  Future<void> batchUpdateCropStatuses() async {
    try {
      await _cropService.batchUpdateCropStatuses();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _cropService.getCurrentUserId();
  }

  // Clean up orphaned orders
  Future<void> cleanupOrphanedOrders() async {
    try {
      await _cropService.cleanupOrphanedOrders();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
}
