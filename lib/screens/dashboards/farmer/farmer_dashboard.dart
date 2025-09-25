import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/crop_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_localizations.dart';
import '../../../services/farmer_dashboard_service.dart';
import '../../settings/farmer_settings_screen.dart';
import '../../farmer/crop_listing_screen.dart';
import '../../farmer/add_crop_screen.dart';
import '../../farmer/farmer_orders_screen.dart';
import '../../farmer/farmer_analytics_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _currentIndex = 0;
  final FarmerDashboardService _dashboardService = FarmerDashboardService();
  FarmerDashboardStats? _dashboardStats;
  bool _isLoadingStats = true;
  bool _hasLoadedStats = false;
  DateTime? _lastStatsUpdate;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats({bool showLoading = false}) async {
    // Only show loading state on first load or when manually refreshing
    if (showLoading || !_hasLoadedStats) {
      setState(() {
        _isLoadingStats = true;
      });
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile?.uid != null) {
        final stats = await _dashboardService.getFarmerDashboardStats(authProvider.userProfile!.uid);
        setState(() {
          _dashboardStats = stats;
          _isLoadingStats = false;
          _hasLoadedStats = true;
          _lastStatsUpdate = DateTime.now();
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      // Handle error silently for now, show default values
    }
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
            title: Text('Farmer Dashboard'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FarmerSettingsScreen(),
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
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.agriculture),
                label: 'Crops',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.local_shipping),
                label: 'Delivery',
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
    // Check if stats need refreshing when returning to home tab
    if (_currentIndex == 0 && _hasLoadedStats) {
      _checkAndRefreshStats();
    }

    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(userProfile);
      case 1:
        return _buildCropsTab();
        case 2:
          return _buildDeliveryTab();
      case 3:
        return _buildAnalyticsTab();
      default:
        return _buildHomeTab(userProfile);
    }
  }

  void _checkAndRefreshStats() {
    // Only refresh if it's been more than 30 seconds since last update
    if (_lastStatsUpdate == null || 
        DateTime.now().difference(_lastStatsUpdate!).inSeconds > 30) {
      _loadDashboardStats(showLoading: false);
    }
  }

  Widget _buildHomeTab(UserModel? userProfile) {
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
                        backgroundColor: Colors.green.withOpacity(0.1),
                        child: const Icon(
                          Icons.agriculture,
                          size: 30,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Farmer!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userProfile?.displayName ?? userProfile?.email ?? 'Farmer',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Ready to grow and sell!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
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

          // Quick Stats Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Farm Statistics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => _loadDashboardStats(showLoading: true),
                icon: _isLoadingStats 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
                tooltip: 'Refresh Statistics',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Crops', 
                  '${_dashboardStats?.activeCrops ?? 0}', 
                  Icons.agriculture, 
                  Colors.green
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sold Crops', 
                  '${_dashboardStats?.soldCrops ?? 0}', 
                  Icons.check_circle, 
                  Colors.blue
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Crops', 
                  '${_dashboardStats?.pendingOrders ?? 0}', 
                  Icons.agriculture, 
                  Colors.orange
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'This Month Sales', 
                  '₹${_dashboardStats?.thisMonthSales.toStringAsFixed(0) ?? '0'}', 
                  Icons.trending_up, 
                  Colors.purple
                ),
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
          _buildQuickActionCard(
            'Add New Crop',
            'List your fresh produce for bidding',
            Icons.add_circle,
            () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddCropScreen(),
                ),
              );
              // Refresh stats if a crop was added
              if (result == true) {
                _loadDashboardStats(showLoading: false);
              }
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'Manage Crops',
            'View and manage your crop listings',
            Icons.agriculture,
            () {
              setState(() {
                _currentIndex = 1; // Switch to crops tab
              });
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'Track Deliveries',
            'Monitor delivery status of your crops',
            Icons.local_shipping,
            () {
              setState(() {
                _currentIndex = 2; // Switch to delivery tab
              });
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'View Analytics',
            'Track earnings and performance',
            Icons.analytics,
            () {
              setState(() {
                _currentIndex = 3; // Switch to analytics tab
              });
            },
          ),
        ],
      ),
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
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.green,
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

  Widget _buildCropsTab() {
    return const CropListingScreen();
  }


  Widget _buildDeliveryTab() {
    return const FarmerOrdersScreen();
  }

  Widget _buildAnalyticsTab() {
    return const FarmerAnalyticsScreen();
  }
}
