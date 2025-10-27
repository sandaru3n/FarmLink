import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../models/crop_model.dart';
import '../models/user_model.dart';
import 'weather_service.dart';
import 'location_service.dart';

class CropAdvisoryService {
  // Gemini API Configuration
  static const String _geminiApiKey = 'AIzaSyBaFuJUj2nReTooMQ0BNxBnTRmwMZaN_SM'; // Replace with actual key
  static const String _geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';
  
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get AI-powered crop advisory using Gemini API with real farmer data
  Future<String> getCropAdvisory({
    required String crop,
    required String soilType,
    String? additionalInfo,
    String? userId,
    String? manualLocation,
    String? manualWeather,
  }) async {
    try {
      // Get real farmer data if userId is provided
      Map<String, dynamic> farmerData = {};
      if (userId != null) {
        farmerData = await _getFarmerData(userId);
      }

      // Auto-detect location and weather
      String location;
      String weather;
      Map<String, dynamic> weatherData = {};
      Map<String, dynamic> locationData = {};

      if (manualLocation != null && manualWeather != null) {
        // Use manual inputs
        location = manualLocation;
        weather = manualWeather;
        weatherData = await _getRealWeatherData(location);
        locationData = await _getRealLocationData(location);
      } else {
        // Auto-detect location and weather
        final autoDetection = await _autoDetectLocationAndWeather();
        location = autoDetection['location'] ?? 'Unknown Location';
        weather = autoDetection['weather'] ?? 'Unknown Weather';
        weatherData = autoDetection['weatherData'] ?? {};
        locationData = autoDetection['locationData'] ?? {};
      }

      // Create comprehensive context for Gemini
      final context = _buildFarmerContext(
        crop: crop,
        location: location,
        soilType: soilType,
        weather: weather,
        additionalInfo: additionalInfo,
        farmerData: farmerData,
        weatherData: weatherData,
        locationData: locationData,
      );

      // Call Gemini API
      final advisory = await _callGeminiAPI(context);

      return advisory;
    } catch (e) {
      print('Error getting AI advisory: $e');
      // Fallback to rule-based advisory
      return _generateFreeAdvisory(crop: crop, location: 'Auto-detected', soilType: soilType, weather: 'Auto-detected', additionalInfo: additionalInfo);
    }
  }

  /// Auto-detect location and weather for the farmer
  Future<Map<String, dynamic>> _autoDetectLocationAndWeather() async {
    try {
      // Get current location
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Unable to get current location');
      }

      // Get address from coordinates
      final address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Get weather data for current location
      final weather = await _weatherService.getCurrentWeatherByCoordinates(
        position.latitude,
        position.longitude,
      );

      // Get detailed weather data
      final weatherData = {
        'temperature': weather.temperature,
        'humidity': weather.humidity,
        'description': weather.description,
        'windSpeed': weather.windSpeed,
        'pressure': weather.pressure,
        'feelsLike': weather.feelsLike,
      };

      // Get detailed location data
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
      };

      return {
        'location': address ?? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        'weather': weather.description,
        'weatherData': weatherData,
        'locationData': locationData,
      };
    } catch (e) {
      print('Error auto-detecting location and weather: $e');
      // Return fallback data
      return {
        'location': 'Location detection failed',
        'weather': 'Weather detection failed',
        'weatherData': {},
        'locationData': {},
      };
    }
  }

  /// Get AI advisory for farmer's existing crops using real data
  Future<String> getAdvisoryForFarmerCrops(String userId) async {
    try {
      // Get farmer's crops
      final crops = await _getFarmerCrops(userId);
      if (crops.isEmpty) {
        return "You don't have any crops yet. Add some crops to get personalized AI advisory!";
      }

      // Get farmer's location
      final farmerData = await _getFarmerData(userId);
      final location = farmerData['location'] ?? 'Unknown';

      // Get real weather data
      final weatherData = await _getRealWeatherData(location);

      // Create context for all crops
      final context = _buildMultiCropContext(crops, farmerData, weatherData, location);

      // Call Gemini API
      final advisory = await _callGeminiAPI(context);

      return advisory;
    } catch (e) {
      print('Error getting farmer crop advisory: $e');
      return "Unable to generate advisory at the moment. Please try again later.";
    }
  }

  /// Get farmer's data from Firestore
  Future<Map<String, dynamic>> _getFarmerData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (e) {
      print('Error getting farmer data: $e');
    }
    return {};
  }

  /// Get farmer's crops from Firestore
  Future<List<CropModel>> _getFarmerCrops(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('crops')
          .where('farmerId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => CropModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting farmer crops: $e');
      return [];
    }
  }

  /// Get real weather data for location
  Future<Map<String, dynamic>> _getRealWeatherData(String location) async {
    try {
      final weather = await _weatherService.getCurrentWeather(location);
      return {
        'temperature': weather.temperature,
        'humidity': weather.humidity,
        'description': weather.description,
        'windSpeed': weather.windSpeed,
        'pressure': weather.pressure,
        'feelsLike': weather.feelsLike,
      };
    } catch (e) {
      print('Error getting weather data: $e');
      return {};
    }
  }

  /// Get real location data
  Future<Map<String, dynamic>> _getRealLocationData(String location) async {
    try {
      // Try to get coordinates for the location
      final position = await _locationService.getCoordinatesFromAddress(location);
      if (position != null) {
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': await _locationService.getAddressFromCoordinates(
            position.latitude, 
            position.longitude
          ),
        };
      }
    } catch (e) {
      print('Error getting location data: $e');
    }
    return {};
  }

  /// Build comprehensive context for Gemini API
  String _buildFarmerContext({
    required String crop,
    required String location,
    required String soilType,
    required String weather,
    String? additionalInfo,
    required Map<String, dynamic> farmerData,
    required Map<String, dynamic> weatherData,
    required Map<String, dynamic> locationData,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert agricultural AI advisor. Provide detailed, practical farming advice.');
    buffer.writeln('');
    
    buffer.writeln('FARMER REQUEST:');
    buffer.writeln('- Crop: $crop');
    buffer.writeln('- Location: $location');
    buffer.writeln('- Soil Type: $soilType');
    buffer.writeln('- Weather: $weather');
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      buffer.writeln('- Additional Info: $additionalInfo');
    }
    buffer.writeln('');
    
    if (farmerData.isNotEmpty) {
      buffer.writeln('FARMER PROFILE:');
      if (farmerData['name'] != null) buffer.writeln('- Name: ${farmerData['name']}');
      if (farmerData['location'] != null) buffer.writeln('- Farm Location: ${farmerData['location']}');
      if (farmerData['experience'] != null) buffer.writeln('- Experience: ${farmerData['experience']}');
      buffer.writeln('');
    }
    
    if (weatherData.isNotEmpty) {
      buffer.writeln('REAL-TIME WEATHER DATA:');
      if (weatherData['temperature'] != null) buffer.writeln('- Temperature: ${weatherData['temperature']}°C');
      if (weatherData['humidity'] != null) buffer.writeln('- Humidity: ${weatherData['humidity']}%');
      if (weatherData['description'] != null) buffer.writeln('- Conditions: ${weatherData['description']}');
      if (weatherData['windSpeed'] != null) buffer.writeln('- Wind Speed: ${weatherData['windSpeed']} m/s');
      buffer.writeln('');
    }
    
    if (locationData.isNotEmpty) {
      buffer.writeln('LOCATION DATA:');
      if (locationData['latitude'] != null) buffer.writeln('- Coordinates: ${locationData['latitude']}, ${locationData['longitude']}');
      if (locationData['address'] != null) buffer.writeln('- Address: ${locationData['address']}');
      buffer.writeln('');
    }
    
    buffer.writeln('Please provide comprehensive advisory covering:');
    buffer.writeln('1. Planting recommendations and timing');
    buffer.writeln('2. Soil preparation and management');
    buffer.writeln('3. Watering and irrigation advice');
    buffer.writeln('4. Fertilizer and nutrient management');
    buffer.writeln('5. Pest and disease control');
    buffer.writeln('6. Weather considerations and protection');
    buffer.writeln('7. Harvest timing and techniques');
    buffer.writeln('8. Market timing and pricing advice');
    buffer.writeln('9. Risk management and contingency planning');
    buffer.writeln('10. Sustainable farming practices');
    buffer.writeln('');
    buffer.writeln('IMPORTANT: Format your response using markdown-style formatting:');
    buffer.writeln('- Use ## for section titles (e.g., ## 🌱 Planting Recommendations)');
    buffer.writeln('- Use • for bullet points');
    buffer.writeln('- Use numbered lists (1., 2., etc.) for step-by-step instructions');
    buffer.writeln('- Include emojis for visual appeal');
    buffer.writeln('- Make titles bold and clear');
    buffer.writeln('- Use clear, actionable language');
    
    return buffer.toString();
  }

  /// Build context for multiple crops
  String _buildMultiCropContext(
    List<CropModel> crops,
    Map<String, dynamic> farmerData,
    Map<String, dynamic> weatherData,
    String location,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are an expert agricultural AI advisor. Provide comprehensive farming advice for multiple crops.');
    buffer.writeln('');
    
    buffer.writeln('FARMER PROFILE:');
    if (farmerData['name'] != null) buffer.writeln('- Name: ${farmerData['name']}');
    buffer.writeln('- Location: $location');
    buffer.writeln('- Number of Crops: ${crops.length}');
    buffer.writeln('');
    
    buffer.writeln('CURRENT CROPS:');
    for (int i = 0; i < crops.length; i++) {
      final crop = crops[i];
      buffer.writeln('${i + 1}. ${crop.cropName}');
      buffer.writeln('   - Status: ${crop.status}');
      buffer.writeln('   - Quantity: ${crop.quantity} kg');
      buffer.writeln('   - Price: \$${crop.minBidPrice} per kg');
      buffer.writeln('   - Location: ${crop.pickupLocation}');
    }
    buffer.writeln('');
    
    if (weatherData.isNotEmpty) {
      buffer.writeln('CURRENT WEATHER CONDITIONS:');
      if (weatherData['temperature'] != null) buffer.writeln('- Temperature: ${weatherData['temperature']}°C');
      if (weatherData['humidity'] != null) buffer.writeln('- Humidity: ${weatherData['humidity']}%');
      if (weatherData['description'] != null) buffer.writeln('- Conditions: ${weatherData['description']}');
      buffer.writeln('');
    }
    
    buffer.writeln('Please provide:');
    buffer.writeln('1. Overall farm management strategy');
    buffer.writeln('2. Crop-specific recommendations for each crop');
    buffer.writeln('3. Seasonal planning and rotation advice');
    buffer.writeln('4. Resource optimization (water, fertilizer, labor)');
    buffer.writeln('5. Market timing and pricing strategies');
    buffer.writeln('6. Risk management across all crops');
    buffer.writeln('7. Sustainable farming practices');
    buffer.writeln('8. Technology and innovation recommendations');
    buffer.writeln('');
    buffer.writeln('IMPORTANT: Format your response using markdown-style formatting:');
    buffer.writeln('- Use ## for section titles (e.g., ## 🌾 Farm Management Strategy)');
    buffer.writeln('- Use • for bullet points');
    buffer.writeln('- Use numbered lists (1., 2., etc.) for step-by-step instructions');
    buffer.writeln('- Include emojis for visual appeal');
    buffer.writeln('- Make titles bold and clear');
    buffer.writeln('- Use clear, actionable language');
    
    return buffer.toString();
  }

  /// Call Gemini API
  Future<String> _callGeminiAPI(String context) async {
    try {
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': context,
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];
          return content;
        }
      }
      
      throw Exception('Failed to get response from Gemini API');
    } catch (e) {
      print('Gemini API error: $e');
      throw Exception('AI service temporarily unavailable');
    }
  }

  /// Generate free advisory using rule-based system
  String _generateFreeAdvisory({
    required String crop,
    required String location,
    required String soilType,
    required String weather,
    String? additionalInfo,
  }) {
    final cropLower = crop.toLowerCase();
    final soilLower = soilType.toLowerCase();
    final weatherLower = weather.toLowerCase();
    
    // Simulate AI processing delay
    Future.delayed(const Duration(seconds: 2));
    
    StringBuffer advisory = StringBuffer();
    
    // Header
    advisory.writeln('## 🌾 AI Crop Advisory for ${crop.toUpperCase()}');
    advisory.writeln('');
    advisory.writeln('📍 Location: $location');
    advisory.writeln('🌱 Soil Type: $soilType');
    advisory.writeln('🌤️ Weather: $weather');
    advisory.writeln('');
    
    // 1. Planting Recommendations
    advisory.writeln('## 🌱 Planting Recommendations');
    advisory.writeln(_getPlantingAdvice(cropLower, soilLower, weatherLower));
    advisory.writeln('');
    
    // 2. Growing Conditions
    advisory.writeln('## 💧 Growing Conditions');
    advisory.writeln(_getGrowingAdvice(cropLower, soilLower, weatherLower));
    advisory.writeln('');
    
    // 3. Weather Considerations
    advisory.writeln('## 🌤️ Weather Considerations');
    advisory.writeln(_getWeatherAdvice(weatherLower, cropLower));
    advisory.writeln('');
    
    // 4. Soil Management
    advisory.writeln('## 🌍 Soil Management');
    advisory.writeln(_getSoilAdvice(soilLower, cropLower));
    advisory.writeln('');
    
    // 5. Harvest Planning
    advisory.writeln('## 🚜 Harvest Planning');
    advisory.writeln(_getHarvestAdvice(cropLower));
    advisory.writeln('');
    
    // 6. General Tips
    advisory.writeln('## 💡 General Tips');
    advisory.writeln(_getGeneralTips(cropLower, location));
    advisory.writeln('');
    
    // Additional Info
    if (additionalInfo != null && additionalInfo.isNotEmpty) {
      advisory.writeln('## ❓ **Additional Considerations**');
      advisory.writeln('Based on your specific concerns: $additionalInfo');
      advisory.writeln(_getAdditionalAdvice(additionalInfo.toLowerCase()));
    }
    
    return advisory.toString();
  }
  
  String _getPlantingAdvice(String crop, String soil, String weather) {
    String advice = '';
    
    // Crop-specific planting advice
    if (crop.contains('rice')) {
      advice = '• Best planting time: June-July for Kharif season\n';
      advice += '• Seed rate: 20-25 kg per acre\n';
      advice += '• Spacing: 20cm x 15cm\n';
      advice += '• Depth: 2-3 cm in puddled soil\n';
    } else if (crop.contains('wheat')) {
      advice = '• Best planting time: October-November\n';
      advice += '• Seed rate: 40-50 kg per acre\n';
      advice += '• Spacing: 20cm row to row\n';
      advice += '• Depth: 3-4 cm\n';
    } else if (crop.contains('tomato')) {
      advice = '• Best planting time: February-March or September-October\n';
      advice += '• Seed rate: 200-250g per acre\n';
      advice += '• Spacing: 60cm x 45cm\n';
      advice += '• Depth: 1-2 cm\n';
    } else {
      advice = '• Planting time: Depends on season and crop variety\n';
      advice += '• Seed rate: Follow package instructions\n';
      advice += '• Spacing: Allow adequate space for growth\n';
      advice += '• Depth: 2-3 times seed diameter\n';
    }
    
    // Soil-specific advice
    if (soil.contains('clay')) {
      advice += '\nClay Soil Tips:\n';
      advice += '• Improve drainage with organic matter\n';
      advice += '• Avoid over-watering\n';
      advice += '• Consider raised beds for better drainage\n';
    } else if (soil.contains('sandy')) {
      advice += '\nSandy Soil Tips:\n';
      advice += '• Add organic matter to improve water retention\n';
      advice += '• Frequent light watering\n';
      advice += '• Use mulch to conserve moisture\n';
    }
    
    return advice;
  }
  
  String _getGrowingAdvice(String crop, String soil, String weather) {
    String advice = '';
    
    // Watering advice
    if (weather.contains('sunny') || weather.contains('hot')) {
      advice = '• Watering: Increase frequency during hot weather\n';
      advice += '• Best time: Early morning or evening\n';
      advice += '• Amount: Deep watering 2-3 times per week\n';
    } else if (weather.contains('rainy')) {
      advice = '• Watering: Reduce frequency during rainy season\n';
      advice += '• Drainage: Ensure proper drainage to prevent waterlogging\n';
      advice += '• Monitor: Check soil moisture before watering\n';
    } else {
      advice = '• Watering: Regular schedule based on soil moisture\n';
      advice += '• Frequency: 2-3 times per week\n';
      advice += '• Amount: 1-2 inches per week\n';
    }
    
    // Fertilizer advice
    advice += '\nFertilization:\n';
    advice += '• Organic: Use compost and manure\n';
    advice += '• NPK: Balanced fertilizer (10-10-10)\n';
    advice += '• Timing: Apply before planting and during growth\n';
    
    // Pest management
    advice += '\nPest Management:\n';
    advice += '• Prevention: Keep field clean and weed-free\n';
    advice += '• Monitoring: Regular field inspection\n';
    advice += '• Natural: Use neem oil and other organic methods\n';
    
    return advice;
  }
  
  String _getWeatherAdvice(String weather, String crop) {
    String advice = '';
    
    if (weather.contains('sunny')) {
      advice = '• **Sunny Weather**: Excellent for most crops\n';
      advice += '• **Protection**: Provide shade for young plants if needed\n';
      advice += '• **Watering**: Increase frequency to prevent wilting\n';
    } else if (weather.contains('rainy')) {
      advice = '• **Rainy Weather**: Good for water supply but watch for diseases\n';
      advice += '• **Drainage**: Ensure proper drainage to prevent waterlogging\n';
      advice += '• **Diseases**: Monitor for fungal diseases\n';
    } else if (weather.contains('cloudy')) {
      advice = '• **Cloudy Weather**: Good for planting and transplanting\n';
      advice += '• **Growth**: May slow down growth slightly\n';
      advice += '• **Diseases**: Lower risk of sunburn\n';
    } else if (weather.contains('hot')) {
      advice = '• **Hot Weather**: Provide extra water and shade\n';
      advice += '• **Timing**: Avoid working during peak heat hours\n';
      advice += '• **Mulching**: Use mulch to retain soil moisture\n';
    }
    
    return advice;
  }
  
  String _getSoilAdvice(String soil, String crop) {
    String advice = '';
    
    if (soil.contains('clay')) {
      advice = '• **Clay Soil**: Heavy and retains water\n';
      advice += '• **Improvement**: Add sand and organic matter\n';
      advice += '• **pH**: Test and adjust to 6.0-7.0\n';
      advice += '• **Drainage**: Improve drainage with raised beds\n';
    } else if (soil.contains('sandy')) {
      advice = '• **Sandy Soil**: Light and well-draining\n';
      advice += '• **Improvement**: Add compost and clay\n';
      advice += '• **Watering**: Frequent light watering needed\n';
      advice += '• **Fertilization**: Regular fertilization required\n';
    } else if (soil.contains('loamy')) {
      advice = '• **Loamy Soil**: Ideal for most crops\n';
      advice += '• **Maintenance**: Add organic matter regularly\n';
      advice += '• **pH**: Maintain 6.0-7.0\n';
      advice += '• **Structure**: Maintain good soil structure\n';
    }
    
    return advice;
  }
  
  String _getHarvestAdvice(String crop) {
    String advice = '';
    
    if (crop.contains('rice')) {
      advice = '• **Harvest Time**: 120-150 days after planting\n';
      advice += '• **Signs**: 80% of grains are golden yellow\n';
      advice += '• **Method**: Cut at ground level\n';
      advice += '• **Storage**: Dry to 14% moisture before storage\n';
    } else if (crop.contains('wheat')) {
      advice = '• **Harvest Time**: 120-140 days after planting\n';
      advice += '• **Signs**: Stems turn golden and grains are hard\n';
      advice += '• **Method**: Use combine harvester or manual cutting\n';
      advice += '• **Storage**: Clean and dry to 12% moisture\n';
    } else if (crop.contains('tomato')) {
      advice = '• **Harvest Time**: 70-90 days after planting\n';
      advice += '• **Signs**: Firm, fully colored fruits\n';
      advice += '• **Method**: Pick when fully ripe\n';
      advice += '• **Storage**: Store at room temperature\n';
    } else {
      advice = '• **Harvest Time**: Varies by crop variety\n';
      advice += '• **Signs**: Check maturity indicators\n';
      advice += '• **Method**: Use appropriate harvesting tools\n';
      advice += '• **Storage**: Follow crop-specific storage requirements\n';
    }
    
    return advice;
  }
  
  String _getGeneralTips(String crop, String location) {
    String advice = '';
    
    advice = '• **Field Preparation**: Plow and level the field properly\n';
    advice += '• **Seed Quality**: Use certified, disease-free seeds\n';
    advice += '• **Crop Rotation**: Rotate crops to maintain soil health\n';
    advice += '• **Record Keeping**: Maintain records of planting and harvest\n';
    advice += '• **Market Research**: Know your market before planting\n';
    
    if (location.toLowerCase().contains('delhi') || location.toLowerCase().contains('punjab')) {
      advice += '\n**Regional Tips for North India**:\n';
      advice += '• **Season**: Follow traditional cropping patterns\n';
      advice += '• **Climate**: Adapt to local weather conditions\n';
      advice += '• **Varieties**: Choose varieties suited to the region\n';
    }
    
    return advice;
  }
  
  String _getAdditionalAdvice(String additionalInfo) {
    String advice = '';
    
    if (additionalInfo.contains('pest') || additionalInfo.contains('disease')) {
      advice = '• **Pest Control**: Use integrated pest management\n';
      advice += '• **Prevention**: Keep field clean and monitor regularly\n';
      advice += '• **Treatment**: Use appropriate pesticides if needed\n';
    } else if (additionalInfo.contains('yield') || additionalInfo.contains('production')) {
      advice = '• **Yield Optimization**: Use high-yielding varieties\n';
      advice += '• **Fertilization**: Apply balanced fertilizers\n';
      advice += '• **Spacing**: Maintain proper plant spacing\n';
    } else if (additionalInfo.contains('cost') || additionalInfo.contains('budget')) {
      advice = '• **Cost Management**: Plan your budget carefully\n';
      advice += '• **Inputs**: Use quality inputs for better results\n';
      advice += '• **Labor**: Plan labor requirements in advance\n';
    }
    
    return advice;
  }

  /// Get popular crop types for suggestions
  static List<String> getPopularCrops() {
    return [
      'Rice',
      'Wheat',
      'Maize (Corn)',
      'Sugarcane',
      'Cotton',
      'Potato',
      'Tomato',
      'Onion',
      'Chili',
      'Cabbage',
      'Cauliflower',
      'Brinjal (Eggplant)',
      'Okra',
      'Spinach',
      'Cucumber',
      'Pumpkin',
      'Watermelon',
      'Mango',
      'Banana',
      'Citrus',
      'Grapes',
      'Strawberry',
      'Herbs',
      'Spices',
    ];
  }

  /// Get soil types for suggestions
  static List<String> getSoilTypes() {
    return [
      'Clay Soil',
      'Sandy Soil',
      'Loamy Soil',
      'Silty Soil',
      'Peaty Soil',
      'Chalky Soil',
      'Red Soil',
      'Black Soil',
      'Alluvial Soil',
      'Laterite Soil',
    ];
  }

  /// Get weather conditions for suggestions
  static List<String> getWeatherConditions() {
    return [
      'Sunny',
      'Partly Cloudy',
      'Cloudy',
      'Rainy',
      'Heavy Rain',
      'Drought',
      'Humid',
      'Dry',
      'Windy',
      'Foggy',
      'Stormy',
      'Cold',
      'Hot',
      'Moderate',
    ];
  }
}
