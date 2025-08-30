import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
import '../models/crop_model.dart';
import '../models/consumer_order_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Replace with your actual Stripe secret key
  static const String _stripeSecretKey = 'sk_test_51R0iJpQOtXlNP6ZKKR2gH9QsWrVvGUqqRuutdeGwpGTpkCtR9NaMvPEB4O5dpfuHZJImfe1m6lgTerLGjD5ZJvIQ008IyrwdlM';
  static const String _stripePublishableKey = 'pk_test_51R0iJpQOtXlNP6ZKo0NwWCEkwW2SAq51llmdIRsAX095DZPWnaWcuTZUK0EFcMGo2eU7WrWy081Skjav8SlzvE9c00G7vYBNQN';
  
  // Collection references
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _consumerOrdersCollection => _firestore.collection('consumer_orders');

  // Create a payment intent for an order
  Future<Map<String, dynamic>> createPaymentIntent(OrderModel order) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (order.finalPrice * 100).round().toString(), // Convert to cents
          'currency': 'inr',
          'metadata[order_id]': order.id,
          'metadata[crop_id]': order.cropId,
          'metadata[distributor_id]': order.distributorId,
          'metadata[farmer_id]': order.farmerId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'paymentIntentId': data['id'],
          'clientSecret': data['client_secret'],
        };
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment intent creation failed: $e');
    }
  }

  // Update payment status based on payment intent status
  Future<bool> updatePaymentStatus(String orderId, String paymentIntentId) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents/$paymentIntentId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        
        String paymentStatus;
        DateTime? paymentCompletedAt;
        
        switch (status) {
          case 'succeeded':
            paymentStatus = 'completed';
            paymentCompletedAt = DateTime.now();
            break;
          case 'processing':
            paymentStatus = 'processing';
            break;
          case 'requires_payment_method':
          case 'requires_confirmation':
          case 'requires_action':
            paymentStatus = 'pending';
            break;
          case 'canceled':
            paymentStatus = 'failed';
            break;
          default:
            paymentStatus = 'pending';
        }

        // Update order in Firestore
        await _ordersCollection.doc(orderId).update({
          'paymentStatus': paymentStatus,
          'paymentCompletedAt': paymentCompletedAt != null ? Timestamp.fromDate(paymentCompletedAt) : null,
          'lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
          // If payment is completed, also update order status to trigger delivery order creation
          if (paymentStatus == 'completed') 'orderStatus': 'completed',
          if (paymentStatus == 'completed') 'completedAt': Timestamp.fromDate(DateTime.now()),
        });

        return status == 'succeeded';
      } else {
        throw Exception('Failed to get payment intent status: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment status update failed: $e');
    }
  }

  // Check payment status for an order
  Future<String> checkPaymentStatus(String orderId) async {
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final paymentIntentId = orderData['stripePaymentIntentId'];
        final lastActivity = orderData['lastPaymentActivity'];
        
        if (paymentIntentId != null) {
          // Check if there's been recent activity (within last 5 minutes)
          if (lastActivity != null) {
            final lastActivityTime = (lastActivity as Timestamp).toDate();
            final timeSinceLastActivity = DateTime.now().difference(lastActivityTime);
            
            // If no recent activity, check with Stripe
            if (timeSinceLastActivity.inMinutes > 5) {
              await updatePaymentStatus(orderId, paymentIntentId);
            }
          }
          
          return orderData['paymentStatus'] ?? 'pending';
        }
      }
      return 'pending';
    } catch (e) {
      throw Exception('Failed to check payment status: $e');
    }
  }

  // Get Stripe publishable key
  String get publishableKey => _stripePublishableKey;

  // Create order with payment intent
  Future<OrderModel> createOrderWithPayment(OrderModel order) async {
    try {
      // Create payment intent
      final paymentResult = await createPaymentIntent(order);
      
      if (paymentResult['success']) {
        // Create order with payment intent details
        final orderWithPayment = order.copyWith(
          stripePaymentIntentId: paymentResult['paymentIntentId'],
          stripeClientSecret: paymentResult['clientSecret'],
          lastPaymentActivity: DateTime.now(),
        );

        // Save order to Firestore
        await _ordersCollection.doc(order.id).set(orderWithPayment.toMap());
        
        return orderWithPayment;
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      throw Exception('Order creation with payment failed: $e');
    }
  }

  // Confirm payment completion
  Future<bool> confirmPaymentCompletion(String orderId) async {
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final paymentIntentId = orderData['stripePaymentIntentId'];
      
      if (paymentIntentId == null) {
        throw Exception('No payment intent found for order');
      }

      // Update payment status
      final isCompleted = await updatePaymentStatus(orderId, paymentIntentId);
      
      if (isCompleted) {
        // Update order status to completed (this will trigger delivery order creation)
        await _ordersCollection.doc(orderId).update({
          'orderStatus': 'completed',
          'completedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
      
      return isCompleted;
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  // Get payment form data for tracking
  Future<Map<String, dynamic>> getPaymentFormData(String orderId) async {
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      return {
        'paymentIntentId': orderData['stripePaymentIntentId'],
        'clientSecret': orderData['stripeClientSecret'],
        'amount': orderData['finalPrice'],
        'currency': 'inr',
        'lastActivity': orderData['lastPaymentActivity'],
        'paymentStatus': orderData['paymentStatus'],
      };
    } catch (e) {
      throw Exception('Failed to get payment form data: $e');
    }
  }

  // Update last payment activity
  Future<void> updateLastPaymentActivity(String orderId) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to update payment activity: $e');
    }
  }

  // Create a payment intent for a consumer order
  Future<Map<String, dynamic>> createPaymentIntentForConsumerOrder(ConsumerOrderModel order) async {
    try {
      final url = Uri.parse('https://api.stripe.com/v1/payment_intents');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': (order.totalAmount * 100).round().toString(), // Convert to cents
          'currency': 'inr',
          'metadata[order_id]': order.id,
          'metadata[consumer_id]': order.consumerId,
          'metadata[order_type]': 'consumer_order',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'paymentIntentId': data['id'],
          'clientSecret': data['client_secret'],
        };
      } else {
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment intent creation failed: $e');
    }
  }

  // Process simple payment for consumer order
  Future<bool> processSimplePaymentForConsumerOrder(ConsumerOrderModel order, {String? consumerLocation}) async {
    try {
      // Create payment intent
      final paymentResult = await createPaymentIntentForConsumerOrder(order);
      
      if (paymentResult['success']) {
        // Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Update order status with payment confirmation
        await _consumerOrdersCollection.doc(order.id).update({
          'paymentStatus': 'completed',
          'paymentCompletedAt': Timestamp.fromDate(DateTime.now()),
          'orderStatus': 'confirmed',
          'confirmedAt': Timestamp.fromDate(DateTime.now()),
          'stripePaymentIntentId': paymentResult['paymentIntentId'],
          'stripeClientSecret': paymentResult['clientSecret'],
          'lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
          if (consumerLocation != null) 'consumerLocation': consumerLocation,
        });
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  // Confirm payment with Stripe
  Future<bool> confirmPayment({
    required String paymentMethodId,
    required int amount,
    required String currency,
    required String orderId,
  }) async {
    try {
      // Get the payment intent from the order
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      final clientSecret = orderData['stripeClientSecret'];
      
      if (clientSecret == null) {
        throw Exception('No payment intent found for order');
      }

      // For now, simulate payment confirmation
      // In production, you would use the actual Stripe API
      await Future.delayed(const Duration(seconds: 2));
      
      // Update payment status in Firestore
      await updatePaymentStatus(orderId, orderData['stripePaymentIntentId']);

      return true;
    } catch (e) {
      throw Exception('Payment confirmation failed: $e');
    }
  }

  // Simple payment processing without Stripe SDK
  Future<bool> processSimplePayment(OrderModel order, {String? distributorLocation}) async {
    try {
      // Create payment intent
      final paymentResult = await createPaymentIntent(order);
      
      if (paymentResult['success']) {
        // Simulate payment processing
        await Future.delayed(const Duration(seconds: 2));
        
        // Update order status with payment confirmation
        await _ordersCollection.doc(order.id).update({
          'paymentStatus': 'completed',
          'paymentCompletedAt': Timestamp.fromDate(DateTime.now()),
          'orderStatus': 'confirmed',
          'confirmedAt': Timestamp.fromDate(DateTime.now()),
          'stripePaymentIntentId': paymentResult['paymentIntentId'],
          'stripeClientSecret': paymentResult['clientSecret'],
          'lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
          if (distributorLocation != null) 'distributorLocation': distributorLocation,
        });
        
        // Update the embedded order in the crop collection
        await _updateCropOrderStatus(order.cropId, order.id, distributorLocation);
        
        return true;
      } else {
        return false;
      }
    } catch (e) {
      throw Exception('Payment processing failed: $e');
    }
  }

  // Update payment status to completed
  Future<void> updatePaymentStatusToCompleted(String orderId) async {
    try {
      // First, get the order to find the cropId
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final cropId = orderData['cropId'];
      
      if (cropId == null) {
        throw Exception('Crop ID not found in order');
      }
      
      // Update the order collection
      await _ordersCollection.doc(orderId).update({
        'paymentStatus': 'completed',
        'paymentCompletedAt': Timestamp.fromDate(DateTime.now()),
        'orderStatus': 'completed',
        'completedAt': Timestamp.fromDate(DateTime.now()),
        'lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
      });
      
      // Update the embedded order in the crop collection
      await _updateCropOrderStatus(cropId, orderId);
      
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Update the embedded order status in crop collection
  Future<void> _updateCropOrderStatus(String cropId, String orderId, [String? distributorLocation]) async {
    try {
      final cropDoc = await _firestore.collection('crops').doc(cropId).get();
      if (!cropDoc.exists) {
        throw Exception('Crop not found');
      }
      
      final cropData = cropDoc.data() as Map<String, dynamic>;
      final order = cropData['order'] as Map<String, dynamic>?;
      
      if (order != null && order['id'] == orderId) {
        // Update the embedded order with completed status
        final updateData = {
          'order.paymentStatus': 'completed',
          'order.paymentCompletedAt': Timestamp.fromDate(DateTime.now()),
          'order.orderStatus': 'completed',
          'order.completedAt': Timestamp.fromDate(DateTime.now()),
          'order.lastPaymentActivity': Timestamp.fromDate(DateTime.now()),
        };
        
        // Add distributor location if provided
        if (distributorLocation != null) {
          updateData['order.distributorLocation'] = distributorLocation;
        }
        
        await _firestore.collection('crops').doc(cropId).update(updateData);
      }
    } catch (e) {
      throw Exception('Failed to update crop order status: $e');
    }
  }

  // Get current payment status
  Future<String> getPaymentStatus(String orderId) async {
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        return orderData['paymentStatus'] ?? 'pending';
      }
      return 'pending';
    } catch (e) {
      throw Exception('Failed to get payment status: $e');
    }
  }

  // Sync payment status between order collection and crop collection
  Future<void> syncPaymentStatus(String orderId) async {
    try {
      final orderDoc = await _ordersCollection.doc(orderId).get();
      if (!orderDoc.exists) {
        throw Exception('Order not found');
      }
      
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final cropId = orderData['cropId'];
      final paymentStatus = orderData['paymentStatus'];
      final orderStatus = orderData['orderStatus'];
      
      if (cropId != null) {
        // Update the embedded order in crop collection to match order collection
        await _firestore.collection('crops').doc(cropId).update({
          'order.paymentStatus': paymentStatus,
          'order.orderStatus': orderStatus,
          'order.paymentCompletedAt': orderData['paymentCompletedAt'],
          'order.confirmedAt': orderData['confirmedAt'],
          'order.lastPaymentActivity': orderData['lastPaymentActivity'],
        });
      }
    } catch (e) {
      throw Exception('Failed to sync payment status: $e');
    }
  }
}
