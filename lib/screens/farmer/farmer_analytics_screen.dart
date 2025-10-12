import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/farmer_analytics_service.dart';
import '../../utils/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade700,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        l10n.get('analytics_earnings'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.green.shade700,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    tabs: [
                      Tab(text: l10n.get('overview'), icon: const Icon(Icons.dashboard, size: 20)),
                      Tab(text: l10n.get('earnings'), icon: const Icon(Icons.trending_up, size: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context);
    
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
              child: Text(l10n.get('retry')),
            ),
          ],
        ),
      );
    }

    if (_analytics == null) {
      return Center(
        child: Text(l10n.get('no_analytics_data')),
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
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
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
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsTab() {
    return Container(
      color: Colors.grey.shade50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Breakdown
            _buildMonthlyBreakdown(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }


  Widget _buildKeyMetrics() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('key_metrics'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                l10n.get('total_earnings'),
                'LKR ${_analytics!.totalEarnings.toStringAsFixed(0)}',
                Icons.attach_money,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.get('completed_orders'),
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
                l10n.get('success_rate'),
                '${_analytics!.successRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                l10n.get('avg_order_value'),
                'LKR ${_analytics!.averageOrderValue.toStringAsFixed(0)}',
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
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('farm_statistics'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatRow(l10n.get('total_crops_listed'), '${_analytics!.totalCrops}'),
        _buildStatRow(l10n.get('crops_sold'), '${_analytics!.soldCrops}'),
        _buildStatRow(l10n.get('active_listings'), '${_analytics!.activeCrops}'),
        _buildStatRow(l10n.get('total_quantity_label'), '${_analytics!.totalQuantity.toStringAsFixed(1)} kg'),
        _buildStatRow(l10n.get('pending_orders'), '${_analytics!.pendingOrders}'),
        _buildStatRow(l10n.get('deliveries_completed'), '${_analytics!.deliveredCount}'),
        _buildStatRow(l10n.get('in_transit'), '${_analytics!.inTransitCount}'),
      ],
    );
  }

  Widget _buildRecentActivity() {
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('recent_activity'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
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

    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('monthly_breakdown'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
        const SizedBox(height: 16),
        ..._monthlyEarnings.take(6).map((monthly) => _buildMonthlyItem(monthly)),
      ],
    );
  }



  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    final MaterialColor materialColor = color is MaterialColor ? color : Colors.green;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: materialColor.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: materialColor.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  materialColor.shade400,
                  materialColor.shade600,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: materialColor.shade300,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: materialColor.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    final MaterialColor activityColor = _getActivityColor(activity.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    activityColor.shade400,
                    activityColor.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getActivityIcon(activity.type),
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    activity.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'LKR ${activity.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: activityColor.shade700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(activity.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyItem(MonthlyEarnings monthly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade400,
                    Colors.green.shade600,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    monthly.month.month.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Text(
                    'Mo',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMonthName(monthly.month.month),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${monthly.orders} orders • ${monthly.quantity.toStringAsFixed(1)} kg',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'LKR ${monthly.earnings.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }



  MaterialColor _getActivityColor(ActivityType type) {
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
    final l10n = AppLocalizations.of(context);
    final months = [
      l10n.get('month_jan'), l10n.get('month_feb'), l10n.get('month_mar'),
      l10n.get('month_apr'), l10n.get('month_may'), l10n.get('month_jun'),
      l10n.get('month_jul'), l10n.get('month_aug'), l10n.get('month_sep'),
      l10n.get('month_oct'), l10n.get('month_nov'), l10n.get('month_dec'),
    ];
    return months[month - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
