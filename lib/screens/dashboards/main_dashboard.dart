import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../utils/app_localizations.dart';
import '../settings/settings_screen.dart';
import 'farmer/farmer_dashboard.dart';
import 'consumer/consumer_dashboard.dart';
import 'fooddistributor/fooddistributor_dashboard.dart';
import 'transporter/transporter_dashboard.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _currentIndex = 0;

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

        final userRole = authProvider.currentActiveRole;
        final userProfile = authProvider.userProfile;

        // Route to role-specific dashboard
        switch (userRole) {
          case UserRole.farmer:
            return const FarmerDashboard();
          case UserRole.consumer:
            return const ConsumerDashboard();
          case UserRole.foodDistributor:
            return const FoodDistributorDashboard();
          case UserRole.transporter:
            return const TransporterDashboard(initialTabIndex: 0);
          default:
            // Fallback to generic dashboard
            return Scaffold(
              appBar: AppBar(
                title: Text(l10n.get('dashboard')),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: _buildDashboardContent(userRole, userProfile),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: Colors.grey,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.home),
                    label: l10n.get('home'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.shopping_cart),
                    label: l10n.get('my_products'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.receipt),
                    label: l10n.get('orders'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.analytics),
                    label: l10n.get('analytics'),
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.message),
                    label: l10n.get('messages'),
                  ),
                ],
              ),
            );
        }
      },
    );
  }

  Widget _buildDashboardContent(UserRole? userRole, UserModel? userProfile) {
    final l10n = AppLocalizations.of(context);
    
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(userRole, userProfile);
      case 1:
        return _buildProductsTab(userRole);
      case 2:
        return _buildOrdersTab(userRole);
      case 3:
        return _buildAnalyticsTab(userRole);
      case 4:
        return _buildMessagesTab();
      default:
        return _buildHomeTab(userRole, userProfile);
    }
  }

  Widget _buildHomeTab(UserRole? userRole, UserModel? userProfile) {
    final l10n = AppLocalizations.of(context);
    
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
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        child: Icon(
                          userRole?.icon ?? Icons.person,
                          size: 30,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userProfile?.displayName ?? userProfile?.email ?? 'User',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              userProfile?.roleDisplayText ?? userRole?.displayName ?? 'Unknown Role',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // Show role switch indicator
                            if (userProfile?.canSwitchRoles ?? false)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Tap settings to switch roles',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
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

          // Role-specific content
          if (userRole == UserRole.farmer) _buildFarmerContent(),
          if (userRole == UserRole.consumer) _buildConsumerContent(),
          if (userRole == UserRole.foodDistributor) _buildDistributorContent(),
          if (userRole == UserRole.transporter) _buildTransporterContent(),
        ],
      ),
    );
  }

  Widget _buildFarmerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farmer Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCard(
          'Add New Product',
          'List your fresh produce',
          Icons.add_circle,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'View Orders',
          'Check incoming orders',
          Icons.shopping_bag,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Crop Management',
          'Track your crops',
          Icons.agriculture,
          () {},
        ),
      ],
    );
  }

  Widget _buildConsumerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Consumer Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCard(
          'Browse Products',
          'Find fresh produce',
          Icons.search,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'My Orders',
          'Track your purchases',
          Icons.shopping_cart,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Favorites',
          'Your saved items',
          Icons.favorite,
          () {},
        ),
      ],
    );
  }

  Widget _buildDistributorContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Distributor Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCard(
          'Manage Inventory',
          'Track your stock',
          Icons.inventory,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Process Orders',
          'Handle customer orders',
          Icons.assignment,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Supplier Network',
          'Connect with farmers',
          Icons.people,
          () {},
        ),
      ],
    );
  }

  Widget _buildTransporterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transporter Dashboard',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildQuickActionCard(
          'Active Deliveries',
          'Track current shipments',
          Icons.local_shipping,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Route Planning',
          'Optimize delivery routes',
          Icons.map,
          () {},
        ),
        const SizedBox(height: 12),
        _buildQuickActionCard(
          'Delivery History',
          'View past deliveries',
          Icons.history,
          () {},
        ),
      ],
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
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
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

  Widget _buildProductsTab(UserRole? userRole) {
    return const Center(
      child: Text('Products Tab - Coming Soon'),
    );
  }

  Widget _buildOrdersTab(UserRole? userRole) {
    return const Center(
      child: Text('Orders Tab - Coming Soon'),
    );
  }

  Widget _buildAnalyticsTab(UserRole? userRole) {
    return const Center(
      child: Text('Analytics Tab - Coming Soon'),
    );
  }

  Widget _buildMessagesTab() {
    return const Center(
      child: Text('Messages Tab - Coming Soon'),
    );
  }
}
