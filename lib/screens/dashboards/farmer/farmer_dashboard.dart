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
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'AI Crop Advisory',
            'Get AI-powered farming advice and insights',
            Icons.psychology,
            () {
              _showAICropAdvisory(context);
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionCard(
            'Weather Forecast',
            'Check weather conditions for farming decisions',
            Icons.wb_sunny,
            () {
              _showWeatherForecast(context);
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

  void _showAICropAdvisory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Crop Advisory',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Get personalized farming advice',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Coming Soon Message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.construction,
                            size: 48,
                            color: Colors.purple[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'AI Crop Advisory Coming Soon!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We\'re working on bringing you AI-powered farming insights and personalized crop advice.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Feature Preview
                    const Text(
                      'Planned Features:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildFeatureItem(
                      Icons.eco,
                      'Crop Health Analysis',
                      'AI-powered disease and pest detection',
                    ),
                    _buildFeatureItem(
                      Icons.water_drop,
                      'Irrigation Recommendations',
                      'Smart watering schedules based on weather',
                    ),
                    _buildFeatureItem(
                      Icons.calendar_today,
                      'Planting Calendar',
                      'Optimal planting times for your region',
                    ),
                    _buildFeatureItem(
                      Icons.trending_up,
                      'Yield Optimization',
                      'Tips to maximize your crop yields',
                    ),
                    _buildFeatureItem(
                      Icons.cloud,
                      'Weather Insights',
                      'Weather-based farming recommendations',
                    ),
                    _buildFeatureItem(
                      Icons.analytics,
                      'Market Analysis',
                      'Price predictions and market trends',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Get Notified Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You\'ll be notified when AI Crop Advisory is available!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.notifications),
                        label: const Text('Notify Me When Available'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.purple,
              size: 20,
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
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
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
    );
  }

  void _showWeatherForecast(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wb_sunny,
                      color: Colors.blue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weather Forecast',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Current and upcoming weather conditions',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Current Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Farm Location, Agricultural District',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Current Weather
                    const Text(
                      'Current Weather',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.wb_sunny,
                            color: Colors.orange,
                            size: 48,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sunny',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                                Text(
                                  '28°C',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                                Text(
                                  'Feels like 31°C',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildWeatherDetail('Humidity', '65%'),
                              const SizedBox(height: 8),
                              _buildWeatherDetail('Wind', '12 km/h'),
                              const SizedBox(height: 8),
                              _buildWeatherDetail('Pressure', '1013 hPa'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 7-Day Forecast
                    const Text(
                      '7-Day Forecast',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Sample forecast data
                    _buildForecastDay('Today', Icons.wb_sunny, 'Sunny', '28°C', '24°C'),
                    _buildForecastDay('Tomorrow', Icons.wb_cloudy, 'Partly Cloudy', '26°C', '22°C'),
                    _buildForecastDay('Wed', Icons.grain, 'Light Rain', '24°C', '20°C'),
                    _buildForecastDay('Thu', Icons.wb_cloudy, 'Cloudy', '25°C', '21°C'),
                    _buildForecastDay('Fri', Icons.wb_sunny, 'Sunny', '27°C', '23°C'),
                    _buildForecastDay('Sat', Icons.wb_cloudy, 'Partly Cloudy', '26°C', '22°C'),
                    _buildForecastDay('Sun', Icons.grain, 'Light Rain', '24°C', '20°C'),
                    
                    const SizedBox(height: 24),
                    
                    // Farming Recommendations
                    const Text(
                      'Farming Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildRecommendationCard(
                      Icons.water_drop,
                      'Irrigation',
                      'Moderate watering recommended. Current humidity levels are optimal.',
                      Colors.blue,
                    ),
                    _buildRecommendationCard(
                      Icons.agriculture,
                      'Planting',
                      'Good conditions for planting. Soil temperature is favorable.',
                      Colors.green,
                    ),
                    _buildRecommendationCard(
                      Icons.pest_control,
                      'Pest Control',
                      'Monitor for pests. Current weather may increase pest activity.',
                      Colors.orange,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Refresh Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Weather data refreshed!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Weather Data'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildForecastDay(String day, IconData icon, String condition, String high, String low) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              day,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Icon(
            icon,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              condition,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$high / $low',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
