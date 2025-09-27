// Test file to verify API key setup
// Run this to check if your API key is working

import 'package:flutter/material.dart';
import 'lib/services/weather_service.dart';

void main() async {
  // Test if API key is set
  if (WeatherService.isApiKeySet()) {
    print('✅ API key is configured');
    
    try {
      // Test API call
      final weather = await WeatherService().getCurrentWeather('Delhi,IN');
      print('✅ API call successful!');
      print('City: ${weather.city}');
      print('Temperature: ${weather.getTemperatureCelsius()}');
      print('Description: ${weather.description}');
    } catch (e) {
      print('❌ API call failed: $e');
    }
  } else {
    print('❌ API key not configured');
    print('Please set your API key in lib/services/weather_service.dart');
  }
}
