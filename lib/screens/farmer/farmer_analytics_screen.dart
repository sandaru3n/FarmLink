import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/farmer_analytics_service.dart';

class FarmerAnalyticsScreen extends StatefulWidget {
  const FarmerAnalyticsScreen({super.key});

  @override
  State<FarmerAnalyticsScreen> createState() => _FarmerAnalyticsScreenState();
}

class _FarmerAnalyticsScreenState extends State<FarmerAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FarmerAnalyticsService _analyticsService = FarmerAnalyticsService();
  
  FarmerAnalytics? _analytics;
  List<MonthlyEarnings> _monthlyEarnings = [];
  List<RecentActivity> _recentActivity = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile?.uid == null) {
        throw Exception('User not logged in');
      }

      final farmerId = authProvider.userProfile!.uid;

      // Load all analytics data
      final results = await Future.wait([
        _analyticsService.getFarmerAnalytics(farmerId),
        _analyticsService.getMonthlyEarnings(farmerId),
        _analyticsService.getRecentActivity(farmerId),
      ]);

      setState(() {
        _analytics = results[0] as FarmerAnalytics;
        _monthlyEarnings = results[1] as List<MonthlyEarnings>;
        _recentActivity = results[2] as List<RecentActivity>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Earnings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Earnings', icon: Icon(Icons.trending_up)),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAnalytics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_analytics == null) {
      return const Center(
        child: Text('No analytics data available'),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(),
        _buildEarningsTab(),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          _buildKeyMetrics(),
          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(),
          const SizedBox(height: 24),

          // Recent Activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildEarningsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monthly Breakdown
          _buildMonthlyBreakdown(),
        ],
      ),
    );
  }


  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Total Earnings',
                '₹${_analytics!.totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Completed Orders',
                '${_analytics!.completedOrders}',
                Icons.check_circle,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Success Rate',
                '${_analytics!.successRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Avg Order Value',
                '₹${_analytics!.averageOrderValue.toStringAsFixed(0)}',
                Icons.shopping_bag,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Farm Statistics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatRow('Total Crops Listed', '${_analytics!.totalCrops}'),
        _buildStatRow('Crops Sold', '${_analytics!.soldCrops}'),
        _buildStatRow('Active Listings', '${_analytics!.activeCrops}'),
        _buildStatRow('Total Quantity', '${_analytics!.totalQuantity.toStringAsFixed(1)} kg'),
        const SizedBox(height: 16),
        _buildStatRow('Pending Orders', '${_analytics!.pendingOrders}'),
        _buildStatRow('Deliveries Completed', '${_analytics!.deliveredCount}'),
        _buildStatRow('In Transit', '${_analytics!.inTransitCount}'),
      ],
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._recentActivity.take(5).map((activity) => _buildActivityItem(activity)),
      ],
    );
  }


  Widget _buildMonthlyBreakdown() {
    if (_monthlyEarnings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Breakdown',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._monthlyEarnings.take(6).map((monthly) => _buildMonthlyItem(monthly)),
      ],
    );
  }



  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getActivityColor(activity.type),
          child: Icon(
            _getActivityIcon(activity.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(activity.title),
        subtitle: Text(activity.description),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${activity.amount.toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
              _formatDate(activity.timestamp),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyItem(MonthlyEarnings monthly) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            monthly.month.month.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(_getMonthName(monthly.month.month)),
        subtitle: Text('${monthly.orders} orders • ${monthly.quantity.toStringAsFixed(1)} kg'),
        trailing: Text(
          '₹${monthly.earnings.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.green,
          ),
        ),
      ),
    );
  }



  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.cropListed:
        return Colors.blue;
      case ActivityType.orderReceived:
        return Colors.green;
      case ActivityType.paymentReceived:
        return Colors.purple;
      case ActivityType.deliveryCompleted:
        return Colors.orange;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.cropListed:
        return Icons.agriculture;
      case ActivityType.orderReceived:
        return Icons.shopping_bag;
      case ActivityType.paymentReceived:
        return Icons.payment;
      case ActivityType.deliveryCompleted:
        return Icons.local_shipping;
    }
  }


  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
