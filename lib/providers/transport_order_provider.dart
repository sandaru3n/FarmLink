import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/transport_order_model.dart';
import '../services/transport_order_service.dart';

class TransportOrderProvider with ChangeNotifier {
  final TransportOrderService _transportOrderService = TransportOrderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<TransportOrderModel> _transporterTransportOrders = [];
  Map<String, dynamic> _transportStatistics = {};
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription<List<TransportOrderModel>>? _transporterOrdersSubscription;

  // Getters
  List<TransportOrderModel> get transporterTransportOrders => _transporterTransportOrders;
  Map<String, dynamic> get transportStatistics => _transportStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUserId => _auth.currentUser?.uid;

  // Get accepted transport orders
  List<TransportOrderModel> get acceptedTransportOrders {
    return _transporterTransportOrders.where((order) => order.status == 'accepted').toList();
  }

  // Get in-transit transport orders
  List<TransportOrderModel> get inTransitTransportOrders {
    return _transporterTransportOrders.where((order) => order.status == 'in_transit').toList();
  }

  // Get delivered transport orders
  List<TransportOrderModel> get deliveredTransportOrders {
    return _transporterTransportOrders.where((order) => order.status == 'delivered').toList();
  }

  // Get cancelled transport orders
  List<TransportOrderModel> get cancelledTransportOrders {
    return _transporterTransportOrders.where((order) => order.status == 'cancelled').toList();
  }

  // Load transporter transport orders
  Future<void> loadTransporterTransportOrders() async {
    if (_isLoading || currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _transporterOrdersSubscription?.cancel();
      
      // Create new subscription
      _transporterOrdersSubscription = _transportOrderService
          .getTransporterTransportOrders(currentUserId!)
          .listen(
        (transportOrders) {
          print('TransportOrderProvider: Received ${transportOrders.length} transport orders');
          _transporterTransportOrders = transportOrders;
          notifyListeners();
        },
        onError: (error) {
          print('TransportOrderProvider: Error loading transport orders: $error');
          _setError(error.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load transporter transport orders by status
  Future<void> loadTransporterTransportOrdersByStatus(String status) async {
    if (_isLoading || currentUserId == null) return;

    _setLoading(true);
    _clearError();

    try {
      // Cancel existing subscription
      await _transporterOrdersSubscription?.cancel();
      
      // Create new subscription
      _transporterOrdersSubscription = _transportOrderService
          .getTransporterTransportOrdersByStatus(currentUserId!, status)
          .listen(
        (transportOrders) {
          _transporterTransportOrders = transportOrders;
          notifyListeners();
        },
        onError: (error) {
          _setError(error.toString());
        },
      );
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Mark transport as in transit
  Future<bool> markTransportInTransit(String transportOrderId) async {
    try {
      await _transportOrderService.markTransportInTransit(transportOrderId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Mark transport as delivered
  Future<bool> markTransportDelivered(String transportOrderId) async {
    try {
      await _transportOrderService.markTransportDelivered(transportOrderId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Cancel transport order
  Future<bool> cancelTransportOrder(String transportOrderId, String cancellationReason) async {
    try {
      await _transportOrderService.cancelTransportOrder(transportOrderId, cancellationReason);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update transport notes
  Future<bool> updateTransportNotes(String transportOrderId, String notes) async {
    try {
      await _transportOrderService.updateTransportNotes(transportOrderId, notes);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update estimated delivery time
  Future<bool> updateEstimatedDeliveryTime(String transportOrderId, String estimatedTime) async {
    try {
      await _transportOrderService.updateEstimatedDeliveryTime(transportOrderId, estimatedTime);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Update transport order scheduling
  Future<bool> updateTransportOrderScheduling(String transportOrderId, {
    String? scheduledDay,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? deliveryLocation,
  }) async {
    try {
      await _transportOrderService.updateTransportOrderScheduling(
        transportOrderId,
        scheduledDay: scheduledDay,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
        deliveryLocation: deliveryLocation,
      );
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }

  // Load transport statistics
  Future<void> loadTransportStatistics() async {
    if (currentUserId == null) return;

    try {
      _transportStatistics = await _transportOrderService.getTransporterTransportStatistics(currentUserId!);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Get transport order by ID
  Future<TransportOrderModel?> getTransportOrderById(String transportOrderId) async {
    try {
      return await _transportOrderService.getTransportOrderById(transportOrderId);
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

  // Dispose method to clean up stream subscriptions
  @override
  void dispose() {
    _transporterOrdersSubscription?.cancel();
    super.dispose();
  }
} 