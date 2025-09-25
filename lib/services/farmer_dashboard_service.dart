import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_model.dart';
import '../models/delivery_order_model.dart';

class FarmerDashboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _cropsCollection => _firestore.collection('crops');
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  // Get comprehensive dashboard statistics for a farmer
  Future<FarmerDashboardStats> getFarmerDashboardStats(String farmerId) async {
    try {
      // Get all crops for the farmer
      final cropsSnapshot = await _cropsCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      // Get all orders for the farmer
      final ordersSnapshot = await _ordersCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      return _calculateDashboardStats(
        cropsSnapshot.docs,
        ordersSnapshot.docs,
      );
    } catch (e) {
      throw Exception('Failed to get farmer dashboard stats: $e');
    }
  }

  // Calculate dashboard statistics from raw data
  FarmerDashboardStats _calculateDashboardStats(
    List<QueryDocumentSnapshot> cropsDocs,
    List<QueryDocumentSnapshot> ordersDocs,
  ) {
    // Crop statistics
    int activeCrops = 0;
    int soldCrops = 0;
    int pendingCrops = 0;

    for (var doc in cropsDocs) {
      final cropData = doc.data() as Map<String, dynamic>;
      final status = cropData['status'] ?? 'pending';

      switch (status) {
        case 'active':
          activeCrops++;
          break;
        case 'sold':
          soldCrops++;
          break;
        case 'pending':
          pendingCrops++;
          break;
      }
    }

    // Calculate this month's sales from orders
    double thisMonthSales = 0.0;
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    for (var doc in ordersDocs) {
      final orderData = doc.data() as Map<String, dynamic>;
      final paymentStatus = orderData['paymentStatus'] ?? 'pending';
      final createdAt = (orderData['createdAt'] as Timestamp).toDate();
      final amount = (orderData['finalPrice'] ?? 0).toDouble();

      // Calculate this month's sales (only completed orders)
      if (paymentStatus == 'completed' && 
          createdAt.month == currentMonth && 
          createdAt.year == currentYear) {
        thisMonthSales += amount;
      }
    }

    return FarmerDashboardStats(
      activeCrops: activeCrops,
      soldCrops: soldCrops,
      pendingOrders: pendingCrops, // Use pending crops count instead of pending orders
      thisMonthSales: thisMonthSales,
    );
  }
}

// Dashboard statistics data model
class FarmerDashboardStats {
  final int activeCrops;
  final int soldCrops;
  final int pendingOrders;
  final double thisMonthSales;

  FarmerDashboardStats({
    required this.activeCrops,
    required this.soldCrops,
    required this.pendingOrders,
    required this.thisMonthSales,
  });
}
