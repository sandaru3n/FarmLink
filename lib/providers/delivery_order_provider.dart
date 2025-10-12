import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/delivery_order_model.dart';
import '../services/delivery_order_service.dart';

class DeliveryOrderProvider with ChangeNotifier {
  final DeliveryOrderService _deliveryOrderService = DeliveryOrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<DeliveryOrderModel> _pendingDeliveryOrders = [];
  List<DeliveryOrderModel> _transporterDeliveryOrders = [];
  Map<String, dynamic> _deliveryStatistics = {};
  bool _isLoading = false;
  String? _error;
  
  // Stream subscriptions
  StreamSubscription<List<DeliveryOrderModel>>? _pendingOrdersSubscription;
  StreamSubscription<List<DeliveryOrderModel>>? _transporterOrdersSubscription;

  // Getters
  List<DeliveryOrderModel> get pendingDeliveryOrders => _pendingDeliveryOrders;
  List<DeliveryOrderModel> get transporterDeliveryOrders => _transporterDeliveryOrders;
  Map<String, dynamic> get deliveryStatistics => _deliveryStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Load pending delivery orders
  Future<void> loadPendingDeliveryOrders() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _pendingOrdersSubscription?.cancel();
      
      // Create new subscription
      _pendingOrdersSubscription = _deliveryOrderService.getPendingDeliveryOrders().listen(
        (deliveryOrders) {
          _pendingDeliveryOrders = deliveryOrders;
          notifyListeners();
        },
        onError: (e) {
          _setError(e.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load transporter delivery orders
  Future<void> loadTransporterDeliveryOrders() async {
    if (_isLoading || currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _transporterOrdersSubscription?.cancel();
      
      // Create new subscription with real-time updates
      _transporterOrdersSubscription = _deliveryOrderService.listenToTransporterDeliveryOrders(currentUserId!).listen(
        (deliveryOrders) {
          _transporterDeliveryOrders = deliveryOrders;
          notifyListeners();
        },
        onError: (e) {
          _setError(e.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load transporter delivery orders by status
  Future<void> loadTransporterDeliveryOrdersByStatus(String status) async {
    if (_isLoading || currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _transporterOrdersSubscription?.cancel();
      
      // Create new subscription
      _transporterOrdersSubscription = _deliveryOrderService.getTransporterDeliveryOrdersByStatus(currentUserId!, status).listen(
        (deliveryOrders) {
          _transporterDeliveryOrders = deliveryOrders;
          notifyListeners();
        },
        onError: (e) {
          _setError(e.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Accept delivery order
  Future<bool> acceptDeliveryOrder(String orderId, String transporterName, {String? scheduledDay}) async {
    if (currentUserId == null) {
      _setError('User not authenticated');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _deliveryOrderService.acceptDeliveryOrder(orderId, currentUserId!, transporterName, scheduledDay: scheduledDay);
      
      // Refresh the lists
      await loadPendingDeliveryOrders();
      await loadTransporterDeliveryOrders();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update delivery order status without creating transport order
  Future<bool> updateDeliveryOrderStatus(String deliveryOrderId, String status) async {
    _setLoading(true);
    _clearError();

    try {
      await _deliveryOrderService.updateDeliveryOrderStatus(deliveryOrderId, status);
      
      // Refresh the lists
      await loadPendingDeliveryOrders();
      await loadTransporterDeliveryOrders();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reject delivery order
  Future<bool> rejectDeliveryOrder(String orderId, String rejectionReason) async {
    _setLoading(true);
    _clearError();

    try {
      await _deliveryOrderService.rejectDeliveryOrder(orderId, rejectionReason);
      
      // Refresh the lists
      await loadPendingDeliveryOrders();
      await loadTransporterDeliveryOrders();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark delivery as in transit
  Future<bool> markDeliveryInTransit(String deliveryOrderId) async {
    _setLoading(true);
    _clearError();

    try {
      await _deliveryOrderService.markDeliveryInTransit(deliveryOrderId);
      
      // Refresh transporter delivery orders
      await loadTransporterDeliveryOrders();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Mark delivery as completed
  Future<bool> markDeliveryCompleted(String deliveryOrderId, {double? deliveryFee}) async {
    _setLoading(true);
    _clearError();

    try {
      await _deliveryOrderService.markDeliveryCompleted(deliveryOrderId, deliveryFee: deliveryFee);
      
      // Refresh transporter delivery orders
      await loadTransporterDeliveryOrders();
      
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load delivery statistics
  Future<void> loadDeliveryStatistics() async {
    if (_isLoading || currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      final statistics = await _deliveryOrderService.getTransporterDeliveryStatistics(currentUserId!);
      _deliveryStatistics = statistics;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get delivery order by ID
  Future<DeliveryOrderModel?> getDeliveryOrderById(String deliveryOrderId) async {
    try {
      return await _deliveryOrderService.getDeliveryOrderById(deliveryOrderId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear error manually
  void clearError() {
    _clearError();
  }

  // Get delivery orders by status
  List<DeliveryOrderModel> getDeliveryOrdersByStatus(String status) {
    return _transporterDeliveryOrders.where((order) => order.status == status).toList();
  }

  // Get pending delivery orders count
  int get pendingDeliveryOrdersCount => _pendingDeliveryOrders.length;

  // Get transporter delivery orders count
  int get transporterDeliveryOrdersCount => _transporterDeliveryOrders.length;

  // Get active delivery orders (accepted or in transit)
  List<DeliveryOrderModel> get activeDeliveryOrders {
    return _transporterDeliveryOrders.where((order) => 
      order.status == 'accepted' || order.status == 'in_transit'
    ).toList();
  }

  // Get completed delivery orders
  List<DeliveryOrderModel> get completedDeliveryOrders {
    return _transporterDeliveryOrders.where((order) => order.status == 'delivered').toList();
  }

  // Dispose method to clean up stream subscriptions
  @override
  void dispose() {
    _pendingOrdersSubscription?.cancel();
    _transporterOrdersSubscription?.cancel();
    super.dispose();
  }
} 