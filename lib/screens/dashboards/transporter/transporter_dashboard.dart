import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/transport_order_provider.dart';
import '../../../providers/delivery_order_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_localizations.dart';
import '../../settings/transporter_settings_screen.dart';
import '../../transporter/delivery_orders_screen.dart';
import '../../transporter/transport_orders_screen.dart';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.purple.withOpacity(0.1),
                            child: const Icon(
                              Icons.local_shipping,
                              size: 30,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, Transporter!',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userProfile?.displayName ?? userProfile?.email ?? 'Transporter',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Delivering fresh produce safely!',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
              const SizedBox(height: 24),

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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Available Deliveries', availableDeliveries.toString(), Icons.local_shipping_outlined, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Total Earnings', '₹${totalEarnings.toStringAsFixed(0)}', Icons.trending_up, Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.purple,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
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
        final completedDeliveries = transportOrderProvider.deliveredTransportOrders;
        
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (completedDeliveries.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No delivery history',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Completed deliveries will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: completedDeliveries.length,
          itemBuilder: (context, index) {
            final delivery = completedDeliveries[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withOpacity(0.1),
                  child: Icon(Icons.check_circle, color: Colors.green),
                ),
                title: Text(delivery.cropName),
                subtitle: Text('Delivered on ${delivery.deliveredAt?.toString().split(' ')[0] ?? 'Unknown date'}'),
                trailing: Text(
                  '₹${(delivery.deliveryFee ?? 0).toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        );
      },
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
