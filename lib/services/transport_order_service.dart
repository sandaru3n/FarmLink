import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../models/transport_order_model.dart';
import '../models/delivery_order_model.dart';
import 'directions_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class TransportOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DirectionsService _directionsService = DirectionsService();

  // Collection references
  CollectionReference get _transportOrdersCollection => _firestore.collection('transport_orders');
  CollectionReference get _deliveryOrdersCollection => _firestore.collection('delivery_orders');

  // Create transport order when transporter accepts delivery order
  Future<void> createTransportOrderFromAcceptedDelivery(
    DeliveryOrderModel deliveryOrder,
    String transporterId,
    String transporterName, {
    String? scheduledDay,
  }) async {
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

      // Calculate delivery fee based on distance using Directions API
      double deliveryFee = 0.0;
      String estimatedDeliveryTime = '2-3 hours';
      
      if (deliveryOrder.pickupLatitude != null && 
          deliveryOrder.pickupLongitude != null &&
          deliveryOrder.distributorLatitude != null && 
          deliveryOrder.distributorLongitude != null) {
        try {
          final directionsResult = await _directionsService.getDirections(
            origin: LatLng(deliveryOrder.pickupLatitude!, deliveryOrder.pickupLongitude!),
            destination: LatLng(deliveryOrder.distributorLatitude!, deliveryOrder.distributorLongitude!),
          );
          
          if (directionsResult != null) {
            deliveryFee = directionsResult.deliveryPrice; // LKR 100 per km
            estimatedDeliveryTime = directionsResult.duration;
          } else {
            // Fallback to minimum fee if directions API fails
            deliveryFee = 500.0; // Minimum LKR 500
          }
        } catch (e) {
          print('Error calculating delivery fee: $e');
          // Fallback to minimum fee if directions API fails
          deliveryFee = 500.0; // Minimum LKR 500
        }
      } else {
        // Fallback to minimum fee if coordinates are not available
        deliveryFee = 500.0; // Minimum LKR 500
      }

      // Create transport order model
      final transportOrder = TransportOrderModel(
        id: transportOrderId,
        deliveryOrderId: deliveryOrder.id,
        orderId: deliveryOrder.orderId,
        transportOrderKey: '${Random().nextInt(90000) + 10000}',
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
        deliveryFee: deliveryFee,
        estimatedDeliveryTime: estimatedDeliveryTime,
        scheduledDay: scheduledDay,
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
      
      // Sort by scheduled day order (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
      final dayOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      transportOrders.sort((a, b) {
        if (a.scheduledDay != null && b.scheduledDay != null) {
          final aIndex = dayOrder.indexOf(a.scheduledDay!);
          final bIndex = dayOrder.indexOf(b.scheduledDay!);
          if (aIndex != -1 && bIndex != -1) {
            return aIndex.compareTo(bIndex);
          }
        }
        // Fallback to creation time if no scheduled day
        return b.createdAt.compareTo(a.createdAt);
      });
      
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

      // Sync status to corresponding delivery order
      final transportDoc = await _transportOrdersCollection.doc(transportOrderId).get();
      if (transportDoc.exists) {
        final data = transportDoc.data() as Map<String, dynamic>;
        final String? deliveryOrderId = data['deliveryOrderId'];
        if (deliveryOrderId != null && deliveryOrderId.isNotEmpty) {
          await _deliveryOrdersCollection.doc(deliveryOrderId).update({
            'status': 'in_transit',
            'inTransitAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to mark transport as in transit: $e');
    }
  }

  // Mark transport order as delivered
  Future<void> markTransportDelivered(String transportOrderId) async {
    try {
      final DateTime now = DateTime.now();
      await _transportOrdersCollection.doc(transportOrderId).update({
        'status': 'delivered',
        'deliveredAt': Timestamp.fromDate(now),
        'actualDeliveryTime': now.toString(),
      });

      // Sync status to corresponding delivery order
      final transportDoc = await _transportOrdersCollection.doc(transportOrderId).get();
      if (transportDoc.exists) {
        final data = transportDoc.data() as Map<String, dynamic>;
        final String? deliveryOrderId = data['deliveryOrderId'];
        if (deliveryOrderId != null && deliveryOrderId.isNotEmpty) {
          await _deliveryOrdersCollection.doc(deliveryOrderId).update({
            'status': 'delivered',
            'deliveredAt': Timestamp.fromDate(now),
            'actualDeliveryTime': now.toString(),
          });
        }
      }
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

  // Update transport order scheduling details
  Future<void> updateTransportOrderScheduling(String transportOrderId, {
    String? scheduledDay,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? deliveryLocation,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (scheduledDay != null) updateData['scheduledDay'] = scheduledDay;
      if (scheduledDate != null) updateData['scheduledDate'] = Timestamp.fromDate(scheduledDate);
      if (scheduledTime != null) updateData['scheduledTime'] = scheduledTime;
      if (deliveryLocation != null) updateData['deliveryLocation'] = deliveryLocation;
      
      await _transportOrdersCollection.doc(transportOrderId).update(updateData);
      print('Successfully updated transport order scheduling: $transportOrderId');
    } catch (e) {
      print('Error updating transport order scheduling: $e');
      throw Exception('Failed to update transport order scheduling: $e');
    }
  }
} 