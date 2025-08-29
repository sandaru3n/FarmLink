import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/delivery_order_model.dart';
import '../models/crop_model.dart';

class DeliveryOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _deliveryOrdersCollection => _firestore.collection('delivery_orders');
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Create delivery order when payment is completed
  Future<void> createDeliveryOrderFromCompletedOrder(OrderModel order) async {
    try {
      print('Creating delivery order for order: ${order.id}');
      
      // Check if delivery order already exists
      final existingDeliveryOrder = await _deliveryOrdersCollection
          .where('orderId', isEqualTo: order.id)
          .get();
      
      if (existingDeliveryOrder.docs.isNotEmpty) {
        print('Delivery order already exists for order: ${order.id}');
        throw Exception('Delivery order already exists for this order');
      }

      // Create delivery order ID
      final deliveryOrderId = 'delivery_${order.id}';

      // Create delivery order model
      final deliveryOrder = DeliveryOrderModel(
        id: deliveryOrderId,
        orderId: order.id,
        cropImageUrl: order.cropImageUrl,
        cropName: order.cropName,
        quantity: order.quantity,
        farmerName: order.farmerName,
        pickupLocation: order.pickupLocation,
        distributorName: order.distributorName,
        distributorLocation: order.distributorLocation,
        price: order.finalPrice,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _deliveryOrdersCollection.doc(deliveryOrderId).set(deliveryOrder.toMap());
      print('Successfully created delivery order: $deliveryOrderId');
    } catch (e) {
      print('Error creating delivery order: $e');
      throw Exception('Failed to create delivery order: $e');
    }
  }

  // Get all pending delivery orders from orders collection where paymentStatus is "completed"
  Stream<List<DeliveryOrderModel>> getPendingDeliveryOrders() {
    return _ordersCollection
        .where('paymentStatus', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final List<DeliveryOrderModel> availableOrders = [];
      
      for (var doc in snapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        final orderId = orderData['id'] ?? doc.id;
        
        // Check if delivery order already exists for this order
        final existingDeliveryOrder = await _deliveryOrdersCollection
            .where('orderId', isEqualTo: orderId)
            .get();
        
        // Only include orders that don't have delivery orders yet
        if (existingDeliveryOrder.docs.isEmpty) {
          // Convert OrderModel to DeliveryOrderModel for display
          final deliveryOrder = DeliveryOrderModel(
            id: orderId,
            orderId: orderId,
            cropImageUrl: orderData['cropImageUrl'] ?? '',
            cropName: orderData['cropName'] ?? '',
            quantity: (orderData['quantity'] ?? 0).toDouble(),
            farmerName: orderData['farmerName'] ?? '',
            pickupLocation: orderData['pickupLocation'] ?? '',
            distributorName: orderData['distributorName'] ?? '',
            distributorLocation: orderData['distributorLocation'] ?? '',
            price: (orderData['finalPrice'] ?? 0).toDouble(),
            status: 'pending',
            createdAt: (orderData['completedAt'] as Timestamp?)?.toDate() ?? 
                       (orderData['createdAt'] as Timestamp?)?.toDate() ?? 
                       DateTime.now(),
            // Additional fields from the order
            cropId: orderData['cropId'] ?? '',
            distributorId: orderData['distributorId'] ?? '',
            distributorEmail: orderData['distributorEmail'] ?? '',
            distributorPhone: orderData['distributorPhone'] ?? '',
            farmerId: orderData['farmerId'] ?? '',
            farmerEmail: orderData['farmerEmail'] ?? '',
            farmerPhone: orderData['farmerPhone'] ?? '',
            stripePaymentIntentId: orderData['stripePaymentIntentId'],
            stripeClientSecret: orderData['stripeClientSecret'],
            paymentCompletedAt: (orderData['paymentCompletedAt'] as Timestamp?)?.toDate(),
            confirmedAt: (orderData['confirmedAt'] as Timestamp?)?.toDate(),
            lastPaymentActivity: (orderData['lastPaymentActivity'] as Timestamp?)?.toDate(),
          );
          
          availableOrders.add(deliveryOrder);
        }
      }
      
      return availableOrders;
    });
  }

  // Get delivery orders for a specific transporter
  Stream<List<DeliveryOrderModel>> getTransporterDeliveryOrders(String transporterId) {
    return _deliveryOrdersCollection
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DeliveryOrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Get delivery orders by status for a transporter
  Stream<List<DeliveryOrderModel>> getTransporterDeliveryOrdersByStatus(String transporterId, String status) {
    return _deliveryOrdersCollection
        .where('transporterId', isEqualTo: transporterId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DeliveryOrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Accept delivery order - create delivery_order collection entry and transport_order
  Future<void> acceptDeliveryOrder(String orderId, String transporterId, String transporterName) async {
    try {
      print('Accepting delivery order for order: $orderId by transporter: $transporterName');
      
      // Get the order details from orders collection
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found: $orderId');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Create delivery order ID
      final deliveryOrderId = 'delivery_${orderId}';
      
      // Create delivery order document in delivery_orders collection
      final deliveryOrderData = {
        'id': deliveryOrderId,
        'orderId': orderId,
        'cropImageUrl': orderData['cropImageUrl'] ?? '',
        'cropName': orderData['cropName'] ?? '',
        'quantity': orderData['quantity'] ?? 0,
        'farmerName': orderData['farmerName'] ?? '',
        'pickupLocation': orderData['pickupLocation'] ?? '',
        'distributorName': orderData['distributorName'] ?? '',
        'distributorLocation': orderData['distributorLocation'] ?? '',
        'price': orderData['finalPrice'] ?? 0,
        'status': 'accepted',
        'transporterId': transporterId,
        'transporterName': transporterName,
        'createdAt': orderData['completedAt'] ?? Timestamp.fromDate(DateTime.now()),
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        // Additional fields from the order
        'cropId': orderData['cropId'] ?? '',
        'distributorId': orderData['distributorId'] ?? '',
        'distributorEmail': orderData['distributorEmail'] ?? '',
        'distributorPhone': orderData['distributorPhone'] ?? '',
        'farmerId': orderData['farmerId'] ?? '',
        'farmerEmail': orderData['farmerEmail'] ?? '',
        'farmerPhone': orderData['farmerPhone'] ?? '',
        'stripePaymentIntentId': orderData['stripePaymentIntentId'],
        'stripeClientSecret': orderData['stripeClientSecret'],
        'paymentCompletedAt': orderData['paymentCompletedAt'],
        'confirmedAt': orderData['confirmedAt'],
        'lastPaymentActivity': orderData['lastPaymentActivity'],
        // Transport-specific fields
        'deliveryFee': (orderData['finalPrice'] ?? 0) * 0.1, // 10% delivery fee
        'estimatedDeliveryTime': '2-3 hours',
      };
      
      // Save to delivery_orders collection
      await _deliveryOrdersCollection.doc(deliveryOrderId).set(deliveryOrderData);
      
      // Create transport order in transport_orders collection
      final transportOrderId = 'transport_${deliveryOrderId}';
      final transportOrderData = {
        'id': transportOrderId,
        'deliveryOrderId': deliveryOrderId,
        'orderId': orderId,
        'cropImageUrl': orderData['cropImageUrl'] ?? '',
        'cropName': orderData['cropName'] ?? '',
        'quantity': orderData['quantity'] ?? 0,
        'farmerName': orderData['farmerName'] ?? '',
        'pickupLocation': orderData['pickupLocation'] ?? '',
        'distributorName': orderData['distributorName'] ?? '',
        'distributorLocation': orderData['distributorLocation'] ?? '',
        'price': orderData['finalPrice'] ?? 0,
        'transporterId': transporterId,
        'transporterName': transporterName,
        'status': 'accepted',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'acceptedAt': Timestamp.fromDate(DateTime.now()),
        'deliveryFee': (orderData['finalPrice'] ?? 0) * 0.1, // 10% delivery fee
        'estimatedDeliveryTime': '2-3 hours',
      };
      
      // Save to transport_orders collection
      await _firestore.collection('transport_orders').doc(transportOrderId).set(transportOrderData);
      
      print('Successfully created delivery order and transport order for order: $orderId');
      print('Transport order ID: $transportOrderId');
      print('Transport order data: $transportOrderData');
    } catch (e) {
      print('Error accepting delivery order: $e');
      throw Exception('Failed to accept delivery order: $e');
    }
  }

  // Reject delivery order - create delivery_order collection entry with rejected status
  Future<void> rejectDeliveryOrder(String orderId, String rejectionReason) async {
    try {
      print('Rejecting delivery order for order: $orderId');
      
      // Get the order details from orders collection
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found: $orderId');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Create delivery order ID
      final deliveryOrderId = 'delivery_${orderId}';
      
      // Create delivery order document in delivery_orders collection with rejected status
      final deliveryOrderData = {
        'id': deliveryOrderId,
        'orderId': orderId,
        'cropImageUrl': orderData['cropImageUrl'] ?? '',
        'cropName': orderData['cropName'] ?? '',
        'quantity': orderData['quantity'] ?? 0,
        'farmerName': orderData['farmerName'] ?? '',
        'pickupLocation': orderData['pickupLocation'] ?? '',
        'distributorName': orderData['distributorName'] ?? '',
        'distributorLocation': orderData['distributorLocation'] ?? '',
        'price': orderData['finalPrice'] ?? 0,
        'status': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedAt': Timestamp.fromDate(DateTime.now()),
        'createdAt': orderData['completedAt'] ?? Timestamp.fromDate(DateTime.now()),
        // Additional fields from the order
        'cropId': orderData['cropId'] ?? '',
        'distributorId': orderData['distributorId'] ?? '',
        'distributorEmail': orderData['distributorEmail'] ?? '',
        'distributorPhone': orderData['distributorPhone'] ?? '',
        'farmerId': orderData['farmerId'] ?? '',
        'farmerEmail': orderData['farmerEmail'] ?? '',
        'farmerPhone': orderData['farmerPhone'] ?? '',
        'stripePaymentIntentId': orderData['stripePaymentIntentId'],
        'stripeClientSecret': orderData['stripeClientSecret'],
        'paymentCompletedAt': orderData['paymentCompletedAt'],
        'confirmedAt': orderData['confirmedAt'],
        'lastPaymentActivity': orderData['lastPaymentActivity'],
      };
      
      // Save to delivery_orders collection
      await _deliveryOrdersCollection.doc(deliveryOrderId).set(deliveryOrderData);
      
      print('Successfully rejected delivery order for order: $orderId');
    } catch (e) {
      print('Error rejecting delivery order: $e');
      throw Exception('Failed to reject delivery order: $e');
    }
  }

  // Mark delivery as in transit
  Future<void> markDeliveryInTransit(String deliveryOrderId) async {
    try {
      await _deliveryOrdersCollection.doc(deliveryOrderId).update({
        'status': 'in_transit',
        'inTransitAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark delivery as in transit: $e');
    }
  }

  // Mark delivery as completed
  Future<void> markDeliveryCompleted(String deliveryOrderId) async {
    try {
      await _deliveryOrdersCollection.doc(deliveryOrderId).update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark delivery as completed: $e');
    }
  }

  // Get delivery order by ID
  Future<DeliveryOrderModel?> getDeliveryOrderById(String deliveryOrderId) async {
    try {
      final doc = await _deliveryOrdersCollection.doc(deliveryOrderId).get();
      if (doc.exists) {
        return DeliveryOrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get delivery order: $e');
    }
  }

  // Get delivery statistics for a transporter
  Future<Map<String, dynamic>> getTransporterDeliveryStatistics(String transporterId) async {
    try {
      final deliveryOrdersSnapshot = await _deliveryOrdersCollection
          .where('transporterId', isEqualTo: transporterId)
          .get();

      int totalDeliveries = 0;
      int pendingDeliveries = 0;
      int acceptedDeliveries = 0;
      int inTransitDeliveries = 0;
      int completedDeliveries = 0;
      int rejectedDeliveries = 0;
      double totalEarnings = 0;

      for (var doc in deliveryOrdersSnapshot.docs) {
        final deliveryData = doc.data() as Map<String, dynamic>;
        final status = deliveryData['status'] ?? 'pending';
        final price = (deliveryData['price'] ?? 0).toDouble();

        totalDeliveries++;

        switch (status) {
          case 'pending':
            pendingDeliveries++;
            break;
          case 'accepted':
            acceptedDeliveries++;
            break;
          case 'in_transit':
            inTransitDeliveries++;
            break;
          case 'delivered':
            completedDeliveries++;
            totalEarnings += price;
            break;
          case 'rejected':
            rejectedDeliveries++;
            break;
        }
      }

      return {
        'totalDeliveries': totalDeliveries,
        'pendingDeliveries': pendingDeliveries,
        'acceptedDeliveries': acceptedDeliveries,
        'inTransitDeliveries': inTransitDeliveries,
        'completedDeliveries': completedDeliveries,
        'rejectedDeliveries': rejectedDeliveries,
        'totalEarnings': totalEarnings,
      };
    } catch (e) {
      throw Exception('Failed to get delivery statistics: $e');
    }
  }

  // Listen for new delivery orders (for real-time updates)
  Stream<DeliveryOrderModel?> listenToDeliveryOrder(String deliveryOrderId) {
    return _deliveryOrdersCollection
        .doc(deliveryOrderId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return DeliveryOrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Get real-time updates for all delivery orders for a transporter
  Stream<List<DeliveryOrderModel>> listenToTransporterDeliveryOrders(String transporterId) {
    return _deliveryOrdersCollection
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => DeliveryOrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Test method to manually create a delivery order (for testing purposes)
  Future<void> testCreateDeliveryOrder(String orderId) async {
    try {
      // Get order from Firestore
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found: $orderId');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Create a mock order model for testing
      final order = OrderModel(
        id: orderId,
        cropId: orderData['cropId'] ?? '',
        distributorId: orderData['distributorId'] ?? '',
        distributorName: orderData['distributorName'] ?? '',
        distributorEmail: orderData['distributorEmail'] ?? '',
        distributorPhone: orderData['distributorPhone'] ?? '',
        distributorLocation: orderData['distributorLocation'] ?? '',
        farmerId: orderData['farmerId'] ?? '',
        farmerName: orderData['farmerName'] ?? '',
        farmerEmail: orderData['farmerEmail'] ?? '',
        farmerPhone: orderData['farmerPhone'] ?? '',
        cropName: orderData['cropName'] ?? '',
        cropImageUrl: orderData['cropImageUrl'] ?? '',
        quantity: (orderData['quantity'] ?? 0).toDouble(),
        finalPrice: (orderData['finalPrice'] ?? 0).toDouble(),
        pickupLocation: orderData['pickupLocation'] ?? '',
        createdAt: (orderData['createdAt'] as Timestamp).toDate(),
      );

      await createDeliveryOrderFromCompletedOrder(order);
    } catch (e) {
      throw Exception('Test delivery order creation failed: $e');
    }
  }

  // Debug method to check delivery order creation status
  Future<Map<String, dynamic>> debugDeliveryOrderCreation() async {
    try {
      final result = <String, dynamic>{};
      
      // Check total orders
      final ordersSnapshot = await _firestore.collection('orders').get();
      result['totalOrders'] = ordersSnapshot.docs.length;
      
      // Check completed orders
      final completedOrdersSnapshot = await _firestore.collection('orders')
          .where('orderStatus', isEqualTo: 'completed')
          .get();
      result['completedOrders'] = completedOrdersSnapshot.docs.length;
      
      // Check total delivery orders
      final deliveryOrdersSnapshot = await _deliveryOrdersCollection.get();
      result['totalDeliveryOrders'] = deliveryOrdersSnapshot.docs.length;
      
      // Check pending delivery orders
      final pendingDeliveryOrdersSnapshot = await _deliveryOrdersCollection
          .where('status', isEqualTo: 'pending')
          .get();
      result['pendingDeliveryOrders'] = pendingDeliveryOrdersSnapshot.docs.length;
      
      // Sample delivery order data
      if (deliveryOrdersSnapshot.docs.isNotEmpty) {
        final sampleDoc = deliveryOrdersSnapshot.docs.first;
        result['sampleDeliveryOrder'] = {
          'id': sampleDoc.id,
          'data': sampleDoc.data(),
        };
      }
      
      return result;
    } catch (e) {
      throw Exception('Debug failed: $e');
    }
  }
} 