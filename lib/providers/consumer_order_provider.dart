import 'package:flutter/material.dart';
import '../models/consumer_order_model.dart';
import '../services/consumer_order_service.dart';

class ConsumerOrderProvider extends ChangeNotifier {
  final ConsumerOrderService _orderService = ConsumerOrderService();
  
  List<ConsumerOrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;

  List<ConsumerOrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get orders by status
  List<ConsumerOrderModel> getPendingOrders() {
    return _orders.where((order) => 
      order.orderStatus == 'pending' || 
      order.orderStatus == 'confirmed' || 
      order.orderStatus == 'shipped'
    ).toList();
  }

  List<ConsumerOrderModel> getCompletedOrders() {
    return _orders.where((order) => 
      order.orderStatus == 'delivered'
    ).toList();
  }

  List<ConsumerOrderModel> getReviewedOrders() {
    return _orders.where((order) => 
      order.orderStatus == 'delivered' && 
      order.paymentStatus == 'completed'
    ).toList();
  }

  // Load consumer orders
  void loadConsumerOrders(String consumerId) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _orderService.getConsumerOrders(consumerId).listen(
      (orders) {
        _orders = orders;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // Get order statistics
  Map<String, int> getOrderStatistics() {
    return {
      'total': _orders.length,
      'pending': getPendingOrders().length,
      'completed': getCompletedOrders().length,
      'reviewed': getReviewedOrders().length,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
