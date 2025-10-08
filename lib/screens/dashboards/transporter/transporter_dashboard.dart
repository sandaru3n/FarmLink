import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transport_order_provider.dart';
import '../../../providers/delivery_order_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/transport_order_model.dart';
import '../../../utils/app_localizations.dart';
import '../../settings/transporter_settings_screen.dart';
import '../../transporter/delivery_orders_screen.dart';
import '../../transporter/transport_orders_screen.dart';
import '../../transporter/earnings_details_screen.dart';

class TransporterDashboard extends StatefulWidget {
  final int initialTabIndex;
  
  const TransporterDashboard({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<TransporterDashboard> createState() => _TransporterDashboardState();
}

class _TransporterDashboardState extends State<TransporterDashboard> {
  int _currentIndex = 0;
  String _selectedDateFilter = 'All Time';

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    
    // Load data when dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
      final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
      
      transportOrderProvider.loadTransporterTransportOrders();
      deliveryOrderProvider.loadPendingDeliveryOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in'),
            ),
          );
        }

        final userProfile = authProvider.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: Text('Transporter Dashboard'),
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TransporterSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildDashboardContent(userProfile),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.purple,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home',
              ),
                             BottomNavigationBarItem(
                 icon: const Icon(Icons.local_shipping),
                 label: 'Available',
               ),
                             BottomNavigationBarItem(
                 icon: const Icon(Icons.map),
                 label: 'My Transports',
               ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.analytics),
                label: 'Analytics',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(UserModel? userProfile) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(userProfile);
             case 1:
         return _buildDeliveriesTab();
       case 2:
         return _buildTransportOrdersTab();
      case 3:
        return _buildHistoryTab();
      case 4:
        return _buildAnalyticsTab();
      default:
        return _buildHomeTab(userProfile);
    }
  }

  Widget _buildHomeTab(UserModel? userProfile) {
    return Consumer2<TransportOrderProvider, DeliveryOrderProvider>(
      builder: (context, transportOrderProvider, deliveryOrderProvider, child) {
        // Calculate real statistics
        final activeDeliveries = transportOrderProvider.acceptedTransportOrders.length + 
                                transportOrderProvider.inTransitTransportOrders.length;
        
        final completedToday = transportOrderProvider.deliveredTransportOrders
            .where((order) => order.deliveredAt?.day == DateTime.now().day)
            .length;
        
        final totalEarnings = transportOrderProvider.deliveredTransportOrders
            .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
        
        final availableDeliveries = deliveryOrderProvider.pendingDeliveryOrders.length;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: const Icon(
                              Icons.local_shipping,
                              size: 20,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${userProfile?.displayName ?? 'User'}!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userProfile?.displayName ?? userProfile?.email ?? 'Transporter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Delivering fresh produce safely!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.purple,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active Deliveries', activeDeliveries.toString(), Icons.local_shipping, Colors.purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Completed Today', completedToday.toString(), Icons.check_circle, Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Available Deliveries', availableDeliveries.toString(), Icons.local_shipping_outlined, Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('Total Earnings', '₹${totalEarnings.toStringAsFixed(0)}', Icons.trending_up, Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Earnings Summary Section
              _buildEarningsSummaryCard(transportOrderProvider.deliveredTransportOrders),
              const SizedBox(height: 16),

              // Quick Actions
              Text(
                'Quick Actions',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Show available deliveries if any
              if (availableDeliveries > 0) ...[
                _buildQuickActionCard(
                  'View Available Deliveries',
                  '$availableDeliveries new delivery opportunities',
                  Icons.local_shipping,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DeliveryOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              
              // Show active deliveries if any
              if (activeDeliveries > 0) ...[
                _buildQuickActionCard(
                  'View Active Deliveries',
                  '$activeDeliveries current delivery assignments',
                  Icons.directions_car,
                  () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DeliveryOrdersScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
              
              _buildQuickActionCard(
                'View My Transport Orders',
                'Manage your accepted transport orders',
                Icons.list_alt,
                () {
                  setState(() {
                    _currentIndex = 2; // Switch to My Transports tab
                  });
                },
              ),
              const SizedBox(height: 8),
              
              _buildQuickActionCard(
                'Delivery History',
                'View completed deliveries',
                Icons.history,
                () {
                  setState(() {
                    _currentIndex = 3; // Switch to History tab
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSummaryCard(List<TransportOrderModel> deliveredOrders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    
    // Helper function to check if two dates are the same day
    bool isSameDay(DateTime date1, DateTime date2) {
      return date1.year == date2.year && 
             date1.month == date2.month && 
             date1.day == date2.day;
    }
    
    // Calculate today's earnings
    final todayEarnings = deliveredOrders
        .where((order) {
          if (order.deliveredAt == null) return false;
          return isSameDay(order.deliveredAt!, today);
        })
        .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
    
    // Calculate this week's earnings
    final weekEarnings = deliveredOrders
        .where((order) {
          if (order.deliveredAt == null) return false;
          return order.deliveredAt!.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        })
        .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
    
    // Calculate last 7 days earnings for chart
    final last7DaysEarnings = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      return deliveredOrders
          .where((order) {
            if (order.deliveredAt == null) return false;
            return isSameDay(order.deliveredAt!, date);
          })
          .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with more details icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earnings Summary',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Navigate to detailed earnings page
                    _navigateToEarningsDetails();
                  },
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.purple,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Today's and This Week's earnings row
            Row(
              children: [
                Expanded(
                  child: _buildEarningsSubCard(
                    'Today\'s Earnings',
                    '₹${todayEarnings.toStringAsFixed(0)}',
                    Icons.today,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildEarningsSubCard(
                    'This Week\'s Earnings',
                    '₹${weekEarnings.toStringAsFixed(0)}',
                    Icons.date_range,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // 7-day earnings chart
            _buildEarningsChart(last7DaysEarnings),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsSubCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsChart(List<double> earnings) {
    final maxEarnings = earnings.isEmpty ? 1.0 : earnings.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Generate day labels for the last 7 days
    final dayLabels = List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[date.weekday - 1];
    });
    
    return Container(
      height: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 Days Earnings',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earnings.asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value;
                final height = maxEarnings > 0 ? (value / maxEarnings) : 0.0;
                final barHeight = (30 * height).clamp(2.0, 30.0);
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 16,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayLabels[index],
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEarningsDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const EarningsDetailsScreen(),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    return const DeliveryOrdersScreen();
  }

  Widget _buildTransportOrdersTab() {
    // Refresh transport orders when this tab is accessed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
      print('Refreshing transport orders for transporter dashboard');
      transportOrderProvider.loadTransporterTransportOrders();
    });
    return const TransportOrdersScreen();
  }

  Widget _buildHistoryTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        final allCompletedDeliveries = transportOrderProvider.deliveredTransportOrders;
        final filteredDeliveries = _filterDeliveriesByDate(allCompletedDeliveries);
        
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return Column(
          children: [
            // Date Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${filteredDeliveries.length} deliveries',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Time', _selectedDateFilter == 'All Time'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Today', _selectedDateFilter == 'Today'),
                        const SizedBox(width: 8),
                        _buildFilterChip('This Week', _selectedDateFilter == 'This Week'),
                        const SizedBox(width: 8),
                        _buildFilterChip('This Month', _selectedDateFilter == 'This Month'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Last 3 Months', _selectedDateFilter == 'Last 3 Months'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Deliveries List
            Expanded(
              child: filteredDeliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _selectedDateFilter == 'All Time' ? Icons.history : Icons.filter_list,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _selectedDateFilter == 'All Time' 
                                ? 'No delivery history'
                                : 'No deliveries found',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _selectedDateFilter == 'All Time'
                                ? 'Completed deliveries will appear here'
                                : 'Try selecting a different time period',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        await transportOrderProvider.loadTransporterTransportOrders();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredDeliveries.length,
                        itemBuilder: (context, index) {
                          final delivery = filteredDeliveries[index];
                          return _buildHistoryCard(delivery);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDateFilter = label;
        });
      },
      selectedColor: Colors.purple.withOpacity(0.2),
      checkmarkColor: Colors.purple,
      labelStyle: TextStyle(
        color: isSelected ? Colors.purple : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  List<TransportOrderModel> _filterDeliveriesByDate(List<TransportOrderModel> deliveries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedDateFilter) {
      case 'Today':
        return deliveries.where((delivery) {
          if (delivery.deliveredAt == null) return false;
          final deliveryDate = DateTime(
            delivery.deliveredAt!.year,
            delivery.deliveredAt!.month,
            delivery.deliveredAt!.day,
          );
          return deliveryDate.isAtSameMomentAs(today);
        }).toList();
        
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return deliveries.where((delivery) {
          if (delivery.deliveredAt == null) return false;
          return delivery.deliveredAt!.isAfter(startOfWeek.subtract(const Duration(days: 1)));
        }).toList();
        
      case 'This Month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        return deliveries.where((delivery) {
          if (delivery.deliveredAt == null) return false;
          return delivery.deliveredAt!.isAfter(startOfMonth.subtract(const Duration(days: 1)));
        }).toList();
        
      case 'Last 3 Months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
        return deliveries.where((delivery) {
          if (delivery.deliveredAt == null) return false;
          return delivery.deliveredAt!.isAfter(threeMonthsAgo.subtract(const Duration(days: 1)));
        }).toList();
        
      case 'All Time':
      default:
        return deliveries;
    }
  }

  Widget _buildHistoryCard(TransportOrderModel delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to delivery details if needed
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Completed Delivery #${delivery.id.substring(0, 8)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Delivered',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Crop information with image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      delivery.cropImageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600], size: 32),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Crop details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.cropName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${delivery.quantity} kg',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.attach_money, size: 16, color: Colors.green[600]),
                            const SizedBox(width: 4),
                            Text(
                              '₹${delivery.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (delivery.deliveryFee != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '+ ₹${delivery.deliveryFee!.toStringAsFixed(2)} delivery fee',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Route information with enhanced layout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[50]!, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Pickup section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                delivery.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Farmer: ${delivery.farmerName}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Arrow divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.arrow_downward, color: Colors.grey[400], size: 20),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Delivery section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Location',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                delivery.distributorLocation,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Distributor: ${delivery.distributorName}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Delivery completion info
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delivered on ${delivery.deliveredAt?.toString().split(' ')[0] ?? 'Unknown date'}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Earned: ₹${(delivery.deliveryFee ?? 0).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        final allOrders = transportOrderProvider.transporterTransportOrders;
        final completedOrders = transportOrderProvider.deliveredTransportOrders;
        final totalEarnings = completedOrders.fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
        final averageEarnings = completedOrders.isNotEmpty ? totalEarnings / completedOrders.length : 0;
        
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Statistics Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Orders', allOrders.length.toString(), Icons.list_alt, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Completed', completedOrders.length.toString(), Icons.check_circle, Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Total Earnings', '₹${totalEarnings.toStringAsFixed(0)}', Icons.trending_up, Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Avg. Per Order', '₹${averageEarnings.toStringAsFixed(0)}', Icons.analytics, Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Recent Activity
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              if (allOrders.isEmpty)
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.analytics, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No activity yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              else
                ...allOrders.take(5).map((order) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(order.status).withOpacity(0.1),
                      child: Icon(_getStatusIcon(order.status), color: _getStatusColor(order.status)),
                    ),
                    title: Text(order.cropName),
                    subtitle: Text('${order.status} - ${order.createdAt.toString().split(' ')[0]}'),
                    trailing: Text(
                      '₹${(order.deliveryFee ?? 0).toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )).toList(),
            ],
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}
