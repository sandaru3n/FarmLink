import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_localizations.dart';
import '../../settings/fooddistributor_settings_screen.dart';
import '../../distributor/crop_marketplace_screen.dart';
import '../../distributor/distributor_orders_screen.dart';
import '../../distributor/product_list_screen.dart';

class FoodDistributorDashboard extends StatefulWidget {
  final int? initialTabIndex;
  const FoodDistributorDashboard({super.key, this.initialTabIndex});

  @override
  State<FoodDistributorDashboard> createState() => _FoodDistributorDashboardState();
}

class _FoodDistributorDashboardState extends State<FoodDistributorDashboard> {
  static int _lastIndex = 0;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Preserve last selected tab across rebuilds or use explicitly provided initial index
    _currentIndex = widget.initialTabIndex ?? _lastIndex;
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
            title: Text('Distributor Dashboard'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FoodDistributorSettingsScreen(),
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
                _lastIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.store),
                label: 'Marketplace',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag),
                label: 'My Orders',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: 'Suppliers',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.inventory_2),
                label: 'Products',
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
        return _buildMarketplaceTab();
      case 2:
        return const DistributorOrdersScreen();
      case 3:
        return _buildSuppliersTab();
      case 4:
        return const ProductListScreen();
      default:
        return _buildHomeTab(userProfile);
    }
  }

  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        // Bold "Crop Marketplace" title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200, width: 1),
            ),
          ),
          child: const Text(
            'Crop Marketplace',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Crop Marketplace Screen
        const Expanded(
          child: CropMarketplaceScreen(),
        ),
      ],
    );
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
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        child: const Icon(
                          Icons.store,
                          size: 30,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, Distributor!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              userProfile?.displayName ?? userProfile?.email ?? 'Distributor',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              'Connect with farmers and source quality crops!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.orange,
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
                child: _buildStatCard('Active Auctions', '12', Icons.gavel, Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('My Bids', '8', Icons.trending_up, Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Won Auctions', '3', Icons.emoji_events, Colors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard('Total Spent', '₹45,000', Icons.account_balance_wallet, Colors.purple),
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
            'Browse Marketplace',
            'View available crop auctions and place bids',
            Icons.store,
            () {
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'My Orders',
            'View your won auctions and manage orders',
            Icons.shopping_bag,
            () {
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'My Products',
            'Manage your product inventory',
            Icons.inventory_2,
            () {
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'Supplier Network',
            'Connect with local farmers',
            Icons.people,
            () {
              setState(() {
                _currentIndex = 3;
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
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
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

  Widget _buildSuppliersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Supplier Network',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect with local farmers and build relationships',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


}
