import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/consumer_order_model.dart';
import '../models/cart_item_model.dart';
import 'payment_service.dart';

class ConsumerOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  // Collection references
  CollectionReference get _consumerOrdersCollection => _firestore.collection('consumer_orders');
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Create a new consumer order from cart items
  Future<ConsumerOrderModel> createConsumerOrder({
    required String consumerId,
    required List<CartItemModel> cartItems,
    required String consumerLocation,
  }) async {
    try {
      // Get consumer details
      final consumerDoc = await _usersCollection.doc(consumerId).get();
      if (!consumerDoc.exists) {
        throw Exception('Consumer not found');
      }
      
      final consumerData = consumerDoc.data() as Map<String, dynamic>;
      
      // Create order ID
      final orderId = DateTime.now().millisecondsSinceEpoch.toString();

      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) => ConsumerOrderItem(
        productId: cartItem.productId,
        productName: cartItem.productName,
        imageUrl: cartItem.imageUrl,
        distributorId: cartItem.distributorId,
        distributorName: 'Distributor', // You might want to fetch distributor name
        pricePerKg: cartItem.pricePerKg,
        quantity: cartItem.quantity,
        totalPrice: cartItem.totalPrice,
      )).toList();

      // Calculate totals
      final subtotal = orderItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      final tax = subtotal * 0.18; // 18% GST
      final totalAmount = subtotal + tax;

      // Create order model
      final order = ConsumerOrderModel(
        id: orderId,
        consumerId: consumerId,
        consumerName: consumerData['displayName'] ?? 'Consumer',
        consumerEmail: consumerData['email'] ?? '',
        consumerPhone: consumerData['phone'] ?? '',
        consumerLocation: consumerLocation,
        items: orderItems,
        subtotal: subtotal,
        tax: tax,
        totalAmount: totalAmount,
        createdAt: DateTime.now(),
      );

      // Create order with payment intent
      final orderWithPayment = await _createOrderWithPayment(order);

      // Save order to Firestore
      await _consumerOrdersCollection.doc(orderId).set(orderWithPayment.toMap());

      return orderWithPayment;
    } catch (e) {
      throw Exception('Failed to create consumer order: $e');
    }
  }

  // Create order with payment intent
  Future<ConsumerOrderModel> _createOrderWithPayment(ConsumerOrderModel order) async {
    try {
      // Create payment intent using the existing payment service
      final paymentResult = await _paymentService.createPaymentIntentForConsumerOrder(order);
      
      if (paymentResult['success']) {
        // Create order with payment intent details
        final orderWithPayment = order.copyWith(
          stripePaymentIntentId: paymentResult['paymentIntentId'],
          stripeClientSecret: paymentResult['clientSecret'],
          lastPaymentActivity: DateTime.now(),
        );
        
        return orderWithPayment;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Payment intent creation failed: $e');
    }
  }

  // Get all orders for a consumer
  Stream<List<ConsumerOrderModel>> getConsumerOrders(String consumerId) {
    return _consumerOrdersCollection
        .where('consumerId', isEqualTo: consumerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ConsumerOrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get a specific order by ID
  Future<ConsumerOrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _consumerOrdersCollection.doc(orderId).get();
      if (doc.exists) {
        return ConsumerOrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'orderStatus': status,
      };

      switch (status) {
        case 'confirmed':
          updateData['confirmedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case 'shipped':
          updateData['shippedAt'] = Timestamp.fromDate(DateTime.now());
          break;
        case 'delivered':
          updateData['deliveredAt'] = Timestamp.fromDate(DateTime.now());
          break;
      }

      await _consumerOrdersCollection.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String orderId, String status) async {
    try {
      final updateData = <String, dynamic>{
        'paymentStatus': status,
      };

      if (status == 'completed') {
        updateData['paymentCompletedAt'] = Timestamp.fromDate(DateTime.now());
        updateData['orderStatus'] = 'confirmed';
        updateData['confirmedAt'] = Timestamp.fromDate(DateTime.now());
      }

      await _consumerOrdersCollection.doc(orderId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Process payment for consumer order
  Future<bool> processConsumerOrderPayment(ConsumerOrderModel order, {String? consumerLocation}) async {
    try {
      // Use simple payment processing
      final success = await _paymentService.processSimplePaymentForConsumerOrder(
        order,
        consumerLocation: consumerLocation,
      );
      
      if (success) {
        // Update order status
        await updatePaymentStatus(order.id, 'completed');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  // Get order statistics for consumer
  Future<Map<String, dynamic>> getConsumerOrderStats(String consumerId) async {
    try {
      final ordersSnapshot = await _consumerOrdersCollection
          .where('consumerId', isEqualTo: consumerId)
          .get();

      final orders = ordersSnapshot.docs
          .map((doc) => ConsumerOrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      int totalOrders = orders.length;
      int pendingOrders = orders.where((order) => order.orderStatus == 'pending').length;
      int completedOrders = orders.where((order) => order.orderStatus == 'delivered').length;
      double totalSpent = orders
          .where((order) => order.paymentStatus == 'completed')
          .fold(0.0, (sum, order) => sum + order.totalAmount);

      return {
        'totalOrders': totalOrders,
        'pendingOrders': pendingOrders,
        'completedOrders': completedOrders,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      throw Exception('Failed to get order statistics: $e');
    }
  }
} 