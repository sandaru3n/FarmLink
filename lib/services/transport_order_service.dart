import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transport_order_model.dart';
import '../models/delivery_order_model.dart';

class TransportOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _transportOrdersCollection => _firestore.collection('transport_orders');
  CollectionReference get _deliveryOrdersCollection => _firestore.collection('delivery_orders');

  // Create transport order when transporter accepts delivery order
  Future<void> createTransportOrderFromAcceptedDelivery(
    DeliveryOrderModel deliveryOrder,
    String transporterId,
    String transporterName,
  ) async {
    try {
      print('Creating transport order for delivery: ${deliveryOrder.id}');
      
      // Check if transport order already exists
      final existingTransportOrder = await _transportOrdersCollection
          .where('deliveryOrderId', isEqualTo: deliveryOrder.id)
          .get();
      
      if (existingTransportOrder.docs.isNotEmpty) {
        print('Transport order already exists for delivery: ${deliveryOrder.id}');
        throw Exception('Transport order already exists for this delivery');
      }

      // Create transport order ID
      final transportOrderId = 'transport_${deliveryOrder.id}';

      // Create transport order model
      final transportOrder = TransportOrderModel(
        id: transportOrderId,
        deliveryOrderId: deliveryOrder.id,
        orderId: deliveryOrder.orderId,
        cropImageUrl: deliveryOrder.cropImageUrl,
        cropName: deliveryOrder.cropName,
        quantity: deliveryOrder.quantity,
        farmerName: deliveryOrder.farmerName,
        pickupLocation: deliveryOrder.pickupLocation,
        distributorName: deliveryOrder.distributorName,
        distributorLocation: deliveryOrder.distributorLocation,
        price: deliveryOrder.price,
        transporterId: transporterId,
        transporterName: transporterName,
        status: 'accepted',
        createdAt: DateTime.now(),
        acceptedAt: DateTime.now(),
        deliveryFee: deliveryOrder.price * 0.1, // 10% delivery fee
        estimatedDeliveryTime: '2-3 hours',
      );

      // Save to Firestore
      await _transportOrdersCollection.doc(transportOrderId).set(transportOrder.toMap());
      print('Successfully created transport order: $transportOrderId');
    } catch (e) {
      print('Error creating transport order: $e');
      throw Exception('Failed to create transport order: $e');
    }
  }

  // Get all transport orders for a specific transporter
  Stream<List<TransportOrderModel>> getTransporterTransportOrders(String transporterId) {
    print('Fetching transport orders for transporter: $transporterId');
    return _transportOrdersCollection
        .where('transporterId', isEqualTo: transporterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('Found ${snapshot.docs.length} transport orders for transporter: $transporterId');
      final transportOrders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Transport order data: $data');
        return TransportOrderModel.fromMap(data);
      }).toList();
      print('Parsed ${transportOrders.length} transport orders');
      return transportOrders;
    });
  }

  // Get transport orders by status for a transporter
  Stream<List<TransportOrderModel>> getTransporterTransportOrdersByStatus(String transporterId, String status) {
    return _transportOrdersCollection
        .where('transporterId', isEqualTo: transporterId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransportOrderModel.fromMap(doc.data() as Map<String, dynamic>)).toList();
    });
  }

  // Mark transport order as in transit
  Future<void> markTransportInTransit(String transportOrderId) async {
    try {
      await _transportOrdersCollection.doc(transportOrderId).update({
        'status': 'in_transit',
        'inTransitAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to mark transport as in transit: $e');
    }
  }

  // Mark transport order as delivered
  Future<void> markTransportDelivered(String transportOrderId) async {
    try {
      await _transportOrdersCollection.doc(transportOrderId).update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
        'actualDeliveryTime': DateTime.now().toString(),
      });
    } catch (e) {
      throw Exception('Failed to mark transport as delivered: $e');
    }
  }

  // Cancel transport order
  Future<void> cancelTransportOrder(String transportOrderId, String cancellationReason) async {
    try {
      await _transportOrdersCollection.doc(transportOrderId).update({
        'status': 'cancelled',
        'cancelledAt': Timestamp.fromDate(DateTime.now()),
        'cancellationReason': cancellationReason,
      });
    } catch (e) {
      throw Exception('Failed to cancel transport order: $e');
    }
  }

  // Get transport order by ID
  Future<TransportOrderModel?> getTransportOrderById(String transportOrderId) async {
    try {
      final doc = await _transportOrdersCollection.doc(transportOrderId).get();
      if (doc.exists) {
        return TransportOrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transport order: $e');
    }
  }

  // Get transport statistics for a transporter
  Future<Map<String, dynamic>> getTransporterTransportStatistics(String transporterId) async {
    try {
      final transportOrdersSnapshot = await _transportOrdersCollection
          .where('transporterId', isEqualTo: transporterId)
          .get();

      int totalTransports = 0;
      int acceptedTransports = 0;
      int inTransitTransports = 0;
      int deliveredTransports = 0;
      int cancelledTransports = 0;
      double totalEarnings = 0;
      double totalDeliveryFees = 0;

      for (var doc in transportOrdersSnapshot.docs) {
        final transportData = doc.data() as Map<String, dynamic>;
        final status = transportData['status'] ?? 'accepted';
        final deliveryFee = (transportData['deliveryFee'] ?? 0).toDouble();

        totalTransports++;
        totalDeliveryFees += deliveryFee;

        switch (status) {
          case 'accepted':
            acceptedTransports++;
            break;
          case 'in_transit':
            inTransitTransports++;
            break;
          case 'delivered':
            deliveredTransports++;
            totalEarnings += deliveryFee;
            break;
          case 'cancelled':
            cancelledTransports++;
            break;
        }
      }

      return {
        'totalTransports': totalTransports,
        'acceptedTransports': acceptedTransports,
        'inTransitTransports': inTransitTransports,
        'deliveredTransports': deliveredTransports,
        'cancelledTransports': cancelledTransports,
        'totalEarnings': totalEarnings,
        'totalDeliveryFees': totalDeliveryFees,
      };
    } catch (e) {
      throw Exception('Failed to get transport statistics: $e');
    }
  }

  // Listen for transport order updates
  Stream<TransportOrderModel?> listenToTransportOrder(String transportOrderId) {
    return _transportOrdersCollection
        .doc(transportOrderId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return TransportOrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // Update transport order notes
  Future<void> updateTransportNotes(String transportOrderId, String notes) async {
    try {
      await _transportOrdersCollection.doc(transportOrderId).update({
        'notes': notes,
      });
    } catch (e) {
      throw Exception('Failed to update transport notes: $e');
    }
  }

  // Update estimated delivery time
  Future<void> updateEstimatedDeliveryTime(String transportOrderId, String estimatedTime) async {
    try {
      await _transportOrdersCollection.doc(transportOrderId).update({
        'estimatedDeliveryTime': estimatedTime,
      });
    } catch (e) {
      throw Exception('Failed to update estimated delivery time: $e');
    }
  }
} 