import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/crop_provider.dart';
import '../../../models/user_model.dart';
import '../../../models/weather_model.dart';
import '../../../utils/app_localizations.dart';
import '../../../services/farmer_dashboard_service.dart';
import '../../../services/weather_service.dart';
import '../../settings/farmer_settings_screen.dart';
import '../../farmer/crop_listing_screen.dart';
import '../../farmer/add_crop_screen.dart';
import '../../farmer/farmer_orders_screen.dart';
import '../../farmer/farmer_analytics_screen.dart';
import '../../farmer/crop_advisory_screen.dart';

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
          bottomNavigationBar: Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: GNav(
                backgroundColor: Colors.white,
                color: Colors.black,
                activeColor: const Color(0xFF2E7D32), // Deep green for active
                tabBackgroundColor: const Color(0xFFE8F5E8), // Light green background
                gap: 8,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                padding: const EdgeInsets.all(16),
                tabs: const [
                  GButton(
                    icon: LineAwesomeIcons.home,
                    text: 'Home',
                  ),
                  GButton(
                    icon: LineAwesomeIcons.seedling,
                    text: 'Crops',
                  ),
                  GButton(
                    icon: LineAwesomeIcons.truck,
                    text: 'Delivery',
                  ),
                  GButton(
                    icon: Icons.analytics,
                    text: 'Analytics',
                  ),
                ],
              ),
            ),
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
                              'Welcome, ${userProfile?.displayName ?? 'User'}!',
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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CropAdvisoryScreen(),
          ),
        );
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


  void _showWeatherForecast(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeatherForecastModal(),
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

class WeatherForecastModal extends StatefulWidget {
  @override
  _WeatherForecastModalState createState() => _WeatherForecastModalState();
}

class _WeatherForecastModalState extends State<WeatherForecastModal> {
  final WeatherService _weatherService = WeatherService();
  WeatherModel? _weatherData;
  bool _isLoading = true;
  String _errorMessage = '';
  String _selectedCity = WeatherService.getDefaultCity();

  @override
  void initState() {
    super.initState();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final weather = await _weatherService.getCurrentWeather(_selectedCity);
      setState(() {
        _weatherData = weather;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showCitySelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select City',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: WeatherService.getPopularFarmingCities().length,
                itemBuilder: (context, index) {
                  final city = WeatherService.getPopularFarmingCities()[index];
                  final isSelected = city == _selectedCity;
                  
                  return ListTile(
                    title: Text(city),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      setState(() {
                        _selectedCity = city;
                      });
                      Navigator.pop(context);
                      _loadWeatherData();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                        'Real-time weather data',
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
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading weather data...'),
                      ],
                    ),
                  )
                : _errorMessage.isNotEmpty
                    ? _buildErrorWidget()
                    : _buildWeatherContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isApiKeyError = _errorMessage.contains('API key not configured');
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApiKeyError ? Icons.key_off : Icons.error_outline,
              size: 64,
              color: isApiKeyError ? Colors.orange[300] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              isApiKeyError ? 'API Key Required' : 'Failed to load weather data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isApiKeyError ? Colors.orange[700] : Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isApiKeyError 
                ? 'To use weather features, you need to set up your OpenWeatherMap API key.\n\n1. Get a free API key from openweathermap.org\n2. Open lib/services/weather_service.dart\n3. Replace YOUR_API_KEY_HERE with your actual key'
                : _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            if (isApiKeyError) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.info, color: Colors.blue, size: 24),
                    const SizedBox(height: 8),
                    const Text(
                      'Free API Key Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'OpenWeatherMap offers 1,000 free API calls per day',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _loadWeatherData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isApiKeyError ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherContent() {
    if (_weatherData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City Selection
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
                    const Spacer(),
                    IconButton(
                      onPressed: _showCitySelector,
                      icon: const Icon(
                        Icons.edit_location,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_weatherData!.city}, ${_weatherData!.country}',
                  style: const TextStyle(
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
                // Weather Icon
                if (_weatherData!.icon.isNotEmpty)
                  Image.network(
                    _weatherData!.getWeatherIcon(),
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.wb_sunny,
                      color: Colors.orange,
                      size: 48,
                    ),
                  )
                else
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
                      Text(
                        _weatherData!.description.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        _weatherData!.getTemperatureCelsius(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                      Text(
                        _weatherData!.getFeelsLikeCelsius(),
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
                    _buildWeatherDetail('Humidity', _weatherData!.getHumidityPercentage()),
                    const SizedBox(height: 8),
                    _buildWeatherDetail('Wind', _weatherData!.getWindSpeedKmh()),
                    const SizedBox(height: 8),
                    _buildWeatherDetail('Pressure', _weatherData!.getPressureHpa()),
                  ],
                ),
              ],
            ),
          ),
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
            _getIrrigationRecommendation(),
            Colors.blue,
          ),
          _buildRecommendationCard(
            Icons.agriculture,
            'Planting',
            _getPlantingRecommendation(),
            Colors.green,
          ),
          _buildRecommendationCard(
            Icons.pest_control,
            'Pest Control',
            _getPestControlRecommendation(),
            Colors.orange,
          ),
          
          const SizedBox(height: 24),
          
          // Refresh Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loadWeatherData,
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

  String _getIrrigationRecommendation() {
    if (_weatherData == null) return 'Unable to provide recommendation';
    
    final humidity = _weatherData!.humidity;
    final temperature = _weatherData!.temperature;
    
    if (humidity < 40) {
      return 'High irrigation needed. Low humidity levels detected.';
    } else if (humidity < 60) {
      return 'Moderate irrigation recommended. Monitor soil moisture.';
    } else {
      return 'Low irrigation needed. High humidity levels detected.';
    }
  }

  String _getPlantingRecommendation() {
    if (_weatherData == null) return 'Unable to provide recommendation';
    
    final temperature = _weatherData!.temperature;
    
    if (temperature < 15) {
      return 'Cold conditions. Consider delaying planting or use cold-resistant varieties.';
    } else if (temperature > 35) {
      return 'Hot conditions. Plant in early morning or evening. Provide shade.';
    } else {
      return 'Good conditions for planting. Temperature is favorable for most crops.';
    }
  }

  String _getPestControlRecommendation() {
    if (_weatherData == null) return 'Unable to provide recommendation';
    
    final humidity = _weatherData!.humidity;
    final temperature = _weatherData!.temperature;
    
    if (humidity > 70 && temperature > 25) {
      return 'High pest risk. Humid and warm conditions favor pest growth. Monitor closely.';
    } else if (humidity > 60) {
      return 'Moderate pest risk. Monitor for fungal diseases and pests.';
    } else {
      return 'Low pest risk. Current conditions are less favorable for pest development.';
    }
  }
}
