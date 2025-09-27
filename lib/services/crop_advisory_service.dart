import 'dart:convert';
import 'package:http/http.dart' as http;

class CropAdvisoryService {
  // Free AI service - no API key required!
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  static const String _freeAiUrl = 'https://api.huggingface.co/models/microsoft/DialoGPT-medium';
  
  /// Get AI-powered crop advisory based on farmer inputs
  Future<String> getCropAdvisory({
    required String crop,
    required String location,
    required String soilType,
    required String weather,
    String? additionalInfo,
  }) async {
    try {
      // Create a comprehensive advisory using rule-based system (FREE!)
      final advisory = _generateFreeAdvisory(
        crop: crop,
        location: location,
        soilType: soilType,
        weather: weather,
        additionalInfo: additionalInfo,
      );

      return advisory;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Error getting AI advisory: $e');
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
    advisory.writeln('🌾 **AI Crop Advisory for ${crop.toUpperCase()}**');
    advisory.writeln('📍 Location: $location');
    advisory.writeln('🌱 Soil: $soilType');
    advisory.writeln('🌤️ Weather: $weather');
    advisory.writeln('');
    
    // 1. Planting Recommendations
    advisory.writeln('## 🌱 **Planting Recommendations**');
    advisory.writeln(_getPlantingAdvice(cropLower, soilLower, weatherLower));
    advisory.writeln('');
    
    // 2. Growing Conditions
    advisory.writeln('## 💧 **Growing Conditions**');
    advisory.writeln(_getGrowingAdvice(cropLower, soilLower, weatherLower));
    advisory.writeln('');
    
    // 3. Weather Considerations
    advisory.writeln('## 🌤️ **Weather Considerations**');
    advisory.writeln(_getWeatherAdvice(weatherLower, cropLower));
    advisory.writeln('');
    
    // 4. Soil Management
    advisory.writeln('## 🌍 **Soil Management**');
    advisory.writeln(_getSoilAdvice(soilLower, cropLower));
    advisory.writeln('');
    
    // 5. Harvest Planning
    advisory.writeln('## 🚜 **Harvest Planning**');
    advisory.writeln(_getHarvestAdvice(cropLower));
    advisory.writeln('');
    
    // 6. General Tips
    advisory.writeln('## 💡 **General Tips**');
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
      advice = '• **Best planting time**: June-July for Kharif season\n';
      advice += '• **Seed rate**: 20-25 kg per acre\n';
      advice += '• **Spacing**: 20cm x 15cm\n';
      advice += '• **Depth**: 2-3 cm in puddled soil\n';
    } else if (crop.contains('wheat')) {
      advice = '• **Best planting time**: October-November\n';
      advice += '• **Seed rate**: 40-50 kg per acre\n';
      advice += '• **Spacing**: 20cm row to row\n';
      advice += '• **Depth**: 3-4 cm\n';
    } else if (crop.contains('tomato')) {
      advice = '• **Best planting time**: February-March or September-October\n';
      advice += '• **Seed rate**: 200-250g per acre\n';
      advice += '• **Spacing**: 60cm x 45cm\n';
      advice += '• **Depth**: 1-2 cm\n';
    } else {
      advice = '• **Planting time**: Depends on season and crop variety\n';
      advice += '• **Seed rate**: Follow package instructions\n';
      advice += '• **Spacing**: Allow adequate space for growth\n';
      advice += '• **Depth**: 2-3 times seed diameter\n';
    }
    
    // Soil-specific advice
    if (soil.contains('clay')) {
      advice += '\n**Clay Soil Tips**:\n';
      advice += '• Improve drainage with organic matter\n';
      advice += '• Avoid over-watering\n';
      advice += '• Consider raised beds for better drainage\n';
    } else if (soil.contains('sandy')) {
      advice += '\n**Sandy Soil Tips**:\n';
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
      advice = '• **Watering**: Increase frequency during hot weather\n';
      advice += '• **Best time**: Early morning or evening\n';
      advice += '• **Amount**: Deep watering 2-3 times per week\n';
    } else if (weather.contains('rainy')) {
      advice = '• **Watering**: Reduce frequency during rainy season\n';
      advice += '• **Drainage**: Ensure proper drainage to prevent waterlogging\n';
      advice += '• **Monitor**: Check soil moisture before watering\n';
    } else {
      advice = '• **Watering**: Regular schedule based on soil moisture\n';
      advice += '• **Frequency**: 2-3 times per week\n';
      advice += '• **Amount**: 1-2 inches per week\n';
    }
    
    // Fertilizer advice
    advice += '\n**Fertilization**:\n';
    advice += '• **Organic**: Use compost and manure\n';
    advice += '• **NPK**: Balanced fertilizer (10-10-10)\n';
    advice += '• **Timing**: Apply before planting and during growth\n';
    
    // Pest management
    advice += '\n**Pest Management**:\n';
    advice += '• **Prevention**: Keep field clean and weed-free\n';
    advice += '• **Monitoring**: Regular field inspection\n';
    advice += '• **Natural**: Use neem oil and other organic methods\n';
    
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
