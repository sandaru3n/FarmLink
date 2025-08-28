import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/crop_model.dart';
import 'payment_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PaymentService _paymentService = PaymentService();

  // Collection references
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _cropsCollection => _firestore.collection('crops');

  // Create a new order with payment integration
  Future<OrderModel> createOrder(CropModel crop, String distributorId, String distributorLocation) async {
    try {
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
        createdAt: DateTime.now(),
      );

      // Create order with payment intent
      final orderWithPayment = await _paymentService.createOrderWithPayment(order);

      // Update crop status to sold
      await _cropsCollection.doc(crop.id).update({
        'order': orderWithPayment.toMap(),
        'status': 'sold',
      });

      return orderWithPayment;
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  // Get all orders for a distributor
  Stream<List<OrderModel>> getDistributorOrders(String distributorId) {
    return _ordersCollection
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get all orders for a farmer
  Stream<List<OrderModel>> getFarmerOrders(String farmerId) {
    return _ordersCollection
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get a specific order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      final doc = await _ordersCollection.doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'orderStatus': status,
        if (status == 'confirmed') 'confirmedAt': Timestamp.fromDate(DateTime.now()),
        if (status == 'completed') 'completedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Confirm payment and update order status
  Future<bool> confirmPayment(String orderId) async {
    try {
      final isCompleted = await _paymentService.confirmPaymentCompletion(orderId);
      return isCompleted;
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  // Check payment status for an order
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      return await _paymentService.checkPaymentStatus(orderId);
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  // Get payment form data for an order
  Future<Map<String, dynamic>> getPaymentFormData(String orderId) async {
    try {
      return await _paymentService.getPaymentFormData(orderId);
    } catch (e) {
      throw Exception('Failed to get payment form data: $e');
    }
  }

  // Update last payment activity
  Future<void> updateLastPaymentActivity(String orderId) async {
    try {
      await _paymentService.updateLastPaymentActivity(orderId);
    } catch (e) {
      throw Exception('Failed to update payment activity: $e');
    }
  }

  // Get orders by payment status
  Stream<List<OrderModel>> getOrdersByPaymentStatus(String distributorId, String paymentStatus) {
    return _ordersCollection
        .where('distributorId', isEqualTo: distributorId)
        .where('paymentStatus', isEqualTo: paymentStatus)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get orders by order status
  Stream<List<OrderModel>> getOrdersByOrderStatus(String distributorId, String orderStatus) {
    return _ordersCollection
        .where('distributorId', isEqualTo: distributorId)
        .where('orderStatus', isEqualTo: orderStatus)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get payment statistics for a distributor
  Future<Map<String, dynamic>> getPaymentStatistics(String distributorId) async {
    try {
      final ordersSnapshot = await _ordersCollection
          .where('distributorId', isEqualTo: distributorId)
          .get();

      int totalOrders = 0;
      int completedPayments = 0;
      int pendingPayments = 0;
      int failedPayments = 0;
      double totalAmount = 0;
      double completedAmount = 0;

      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        final amount = (orderData['finalPrice'] ?? 0).toDouble();
        final paymentStatus = orderData['paymentStatus'] ?? 'pending';

        totalOrders++;
        totalAmount += amount;

        switch (paymentStatus) {
          case 'completed':
            completedPayments++;
            completedAmount += amount;
            break;
          case 'pending':
          case 'processing':
            pendingPayments++;
            break;
          case 'failed':
            failedPayments++;
            break;
        }
      }

      return {
        'totalOrders': totalOrders,
        'completedPayments': completedPayments,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'totalAmount': totalAmount,
        'completedAmount': completedAmount,
      };
    } catch (e) {
      throw Exception('Failed to get payment statistics: $e');
    }
  }

  // Update order location (shipping address)
  Future<void> updateOrderLocation(String orderId, String shippingAddress) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'distributorLocation': shippingAddress,
        'lastUpdated': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update order location: $e');
    }
  }
}
