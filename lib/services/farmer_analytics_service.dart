import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';
import '../models/delivery_order_model.dart';

class FarmerAnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _cropsCollection => _firestore.collection('crops');
  CollectionReference get _ordersCollection => _firestore.collection('orders');
  CollectionReference get _deliveryOrdersCollection => _firestore.collection('delivery_orders');

  // Get comprehensive farmer analytics
  Future<FarmerAnalytics> getFarmerAnalytics(String farmerId) async {
    try {
      // Get all crops for the farmer
      final cropsSnapshot = await _cropsCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      // Get all orders for the farmer
      final ordersSnapshot = await _ordersCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      // Get all delivery orders for the farmer
      final deliveryOrdersSnapshot = await _deliveryOrdersCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();


      return _calculateAnalytics(
        cropsSnapshot.docs,
        ordersSnapshot.docs,
        deliveryOrdersSnapshot.docs,
      );
    } catch (e) {
      throw Exception('Failed to get farmer analytics: $e');
    }
  }

  // Get monthly earnings breakdown
  Future<List<MonthlyEarnings>> getMonthlyEarnings(String farmerId, {int months = 12}) async {
    try {
      final ordersSnapshot = await _ordersCollection
          .where('farmerId', isEqualTo: farmerId)
          .where('paymentStatus', isEqualTo: 'completed')
          .get();

      final Map<String, MonthlyEarnings> monthlyData = {};
      final now = DateTime.now();

      // Initialize last 12 months
      for (int i = 0; i < months; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyData[key] = MonthlyEarnings(
          month: date,
          earnings: 0.0,
          orders: 0,
          quantity: 0.0,
        );
      }

      // Process orders
      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        final createdAt = (orderData['createdAt'] as Timestamp).toDate();
        final key = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';

        if (monthlyData.containsKey(key)) {
          final monthly = monthlyData[key]!;
          monthlyData[key] = MonthlyEarnings(
            month: monthly.month,
            earnings: monthly.earnings + (orderData['finalPrice'] ?? 0).toDouble(),
            orders: monthly.orders + 1,
            quantity: monthly.quantity + (orderData['quantity'] ?? 0).toDouble(),
          );
        }
      }

      return monthlyData.values.toList()
        ..sort((a, b) => b.month.compareTo(a.month));
    } catch (e) {
      throw Exception('Failed to get monthly earnings: $e');
    }
  }

  // Get crop performance analytics
  Future<List<CropPerformance>> getCropPerformance(String farmerId) async {
    try {
      final cropsSnapshot = await _cropsCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      final Map<String, CropPerformance> cropData = {};

      for (var doc in cropsSnapshot.docs) {
        final cropData = doc.data() as Map<String, dynamic>;
        final cropName = cropData['cropName'] ?? 'Unknown';
        final status = cropData['status'] ?? 'pending';
        final quantity = (cropData['quantity'] ?? 0).toDouble();
        final minBidPrice = (cropData['minBidPrice'] ?? 0).toDouble();
        final order = cropData['order'];
        final bids = cropData['bids'] as List<dynamic>? ?? [];

        if (!cropData.containsKey(cropName)) {
          cropData[cropName] = CropPerformance(
            cropName: cropName,
            totalListed: 0,
            totalSold: 0,
            totalQuantity: 0.0,
            totalEarnings: 0.0,
            averageBids: 0.0,
            successRate: 0.0,
          );
        }

        final performance = cropData[cropName]!;
        cropData[cropName] = CropPerformance(
          cropName: cropName,
          totalListed: performance.totalListed + 1,
          totalSold: performance.totalSold + (status == 'sold' ? 1 : 0),
          totalQuantity: performance.totalQuantity + quantity,
          totalEarnings: performance.totalEarnings + (order != null ? (order['finalPrice'] ?? 0).toDouble() : 0),
          averageBids: performance.averageBids + bids.length,
          successRate: 0.0, // Will be calculated later
        );
      }

      // Calculate success rates
      final results = <CropPerformance>[];
      for (var performance in cropData.values) {
        final successRate = performance.totalListed > 0 
            ? (performance.totalSold / performance.totalListed) * 100 
            : 0.0;
        final avgBids = performance.totalListed > 0 
            ? performance.averageBids / performance.totalListed 
            : 0.0;

        results.add(CropPerformance(
          cropName: performance.cropName,
          totalListed: performance.totalListed,
          totalSold: performance.totalSold,
          totalQuantity: performance.totalQuantity,
          totalEarnings: performance.totalEarnings,
          averageBids: avgBids,
          successRate: successRate,
        ));
      }

      return results..sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));
    } catch (e) {
      throw Exception('Failed to get crop performance: $e');
    }
  }

  // Get recent activity
  Future<List<RecentActivity>> getRecentActivity(String farmerId, {int limit = 10}) async {
    try {
      final activities = <RecentActivity>[];

      // Get recent crops
      final cropsSnapshot = await _cropsCollection
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      for (var doc in cropsSnapshot.docs) {
        final cropData = doc.data() as Map<String, dynamic>;
        activities.add(RecentActivity(
          id: doc.id,
          type: ActivityType.cropListed,
          title: 'Crop Listed: ${cropData['cropName']}',
          description: '${cropData['quantity']} kg listed for ₹${cropData['minBidPrice']}',
          timestamp: (cropData['createdAt'] as Timestamp).toDate(),
          amount: (cropData['minBidPrice'] ?? 0).toDouble(),
        ));
      }

      // Get recent orders
      final ordersSnapshot = await _ordersCollection
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      for (var doc in ordersSnapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        activities.add(RecentActivity(
          id: doc.id,
          type: ActivityType.orderReceived,
          title: 'Order Received: ${orderData['cropName']}',
          description: 'Order from ${orderData['distributorName']}',
          timestamp: (orderData['createdAt'] as Timestamp).toDate(),
          amount: (orderData['finalPrice'] ?? 0).toDouble(),
        ));
      }

      // Sort by timestamp and limit
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return activities.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent activity: $e');
    }
  }

  // Calculate analytics from raw data
  FarmerAnalytics _calculateAnalytics(
    List<QueryDocumentSnapshot> cropsDocs,
    List<QueryDocumentSnapshot> ordersDocs,
    List<QueryDocumentSnapshot> deliveryOrdersDocs,
  ) {
    // Crop statistics
    int totalCrops = cropsDocs.length;
    int activeCrops = 0;
    int soldCrops = 0;
    int expiredCrops = 0;
    int pendingCrops = 0;
    double totalQuantity = 0.0;

    for (var doc in cropsDocs) {
      final cropData = doc.data() as Map<String, dynamic>;
      final status = cropData['status'] ?? 'pending';
      final quantity = (cropData['quantity'] ?? 0).toDouble();

      totalQuantity += quantity;

      switch (status) {
        case 'active':
          activeCrops++;
          break;
        case 'sold':
          soldCrops++;
          break;
        case 'expired':
          expiredCrops++;
          break;
        case 'pending':
          pendingCrops++;
          break;
      }
    }

    // Order statistics
    int totalOrders = ordersDocs.length;
    int completedOrders = 0;
    double totalEarnings = 0.0; // Only completed earnings
    double completedEarnings = 0.0;

    for (var doc in ordersDocs) {
      final orderData = doc.data() as Map<String, dynamic>;
      final paymentStatus = orderData['paymentStatus'] ?? 'pending';
      final orderStatus = orderData['orderStatus'] ?? 'pending';
      final amount = (orderData['finalPrice'] ?? 0).toDouble();

      // Only count as completed if both order and payment are completed
      if (paymentStatus == 'completed' && (orderStatus == 'confirmed' || orderStatus == 'completed')) {
        completedOrders++;
        completedEarnings += amount;
        totalEarnings += amount; // Total earnings should only include completed orders
      }
    }

    // Use pending crops count instead of pending orders count
    int pendingOrders = pendingCrops;

    // Delivery statistics
    int totalDeliveries = deliveryOrdersDocs.length;
    int deliveredCount = 0;
    int inTransitCount = 0;
    int pendingDeliveries = 0;

    for (var doc in deliveryOrdersDocs) {
      final deliveryData = doc.data() as Map<String, dynamic>;
      final status = deliveryData['status'] ?? 'pending';

      switch (status) {
        case 'delivered':
          deliveredCount++;
          break;
        case 'in_transit':
          inTransitCount++;
          break;
        case 'pending':
        case 'accepted':
          pendingDeliveries++;
          break;
      }
    }

    // Calculate success rate (based on crops that have been processed - expired or sold)
    int processedCrops = soldCrops + expiredCrops;
    double successRate = processedCrops > 0 ? (soldCrops / processedCrops) * 100 : 0.0;

    // Calculate average order value (only for completed orders)
    double averageOrderValue = completedOrders > 0 ? completedEarnings / completedOrders : 0.0;


    return FarmerAnalytics(
      totalCrops: totalCrops,
      activeCrops: activeCrops,
      soldCrops: soldCrops,
      expiredCrops: expiredCrops,
      totalQuantity: totalQuantity,
      totalOrders: totalOrders,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      totalEarnings: totalEarnings,
      completedEarnings: completedEarnings,
      totalDeliveries: totalDeliveries,
      deliveredCount: deliveredCount,
      inTransitCount: inTransitCount,
      pendingDeliveries: pendingDeliveries,
      successRate: successRate,
      averageOrderValue: averageOrderValue,
    );
  }
}

// Analytics data models
class FarmerAnalytics {
  final int totalCrops;
  final int activeCrops;
  final int soldCrops;
  final int expiredCrops;
  final double totalQuantity;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final double totalEarnings;
  final double completedEarnings;
  final int totalDeliveries;
  final int deliveredCount;
  final int inTransitCount;
  final int pendingDeliveries;
  final double successRate;
  final double averageOrderValue;

  FarmerAnalytics({
    required this.totalCrops,
    required this.activeCrops,
    required this.soldCrops,
    required this.expiredCrops,
    required this.totalQuantity,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.totalEarnings,
    required this.completedEarnings,
    required this.totalDeliveries,
    required this.deliveredCount,
    required this.inTransitCount,
    required this.pendingDeliveries,
    required this.successRate,
    required this.averageOrderValue,
  });
}

class MonthlyEarnings {
  final DateTime month;
  final double earnings;
  final int orders;
  final double quantity;

  MonthlyEarnings({
    required this.month,
    required this.earnings,
    required this.orders,
    required this.quantity,
  });
}

class CropPerformance {
  final String cropName;
  final int totalListed;
  final int totalSold;
  final double totalQuantity;
  final double totalEarnings;
  final double averageBids;
  final double successRate;

  CropPerformance({
    required this.cropName,
    required this.totalListed,
    required this.totalSold,
    required this.totalQuantity,
    required this.totalEarnings,
    required this.averageBids,
    required this.successRate,
  });
}

class RecentActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final double amount;

  RecentActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.amount,
  });
}

enum ActivityType {
  cropListed,
  orderReceived,
  paymentReceived,
  deliveryCompleted,
}
