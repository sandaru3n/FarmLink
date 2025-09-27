import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  // ⚠️ IMPORTANT: Replace with your actual OpenWeatherMap API key
  // Get your FREE API key from: https://openweathermap.org/api
  // Then replace 'YOUR_API_KEY_HERE' with your actual key
  static const String _apiKey = '85c9257c5d42a1db66d16ccd6e8aafe4'; // ← Get a new API key from openweathermap.org
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Default city for farming areas (you can change this)
  static const String _defaultCity = 'London,UK'; // Try a different city for testing

  /// Fetch current weather data for a specific city
  Future<WeatherModel> getCurrentWeather(String cityName) async {
    // Check if API key is set
    if (!isApiKeySet()) {
      throw Exception('OpenWeatherMap API key not configured. Please set your API key in lib/services/weather_service.dart');
    }

    try {
      final url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
      
      // Debug: Print the URL (remove this in production)
      print('Weather API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Debug: Print response details
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please check the city name.');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenWeatherMap API key. Make sure your account is verified and the key is activated.');
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw Exception('No internet connection. Please check your network.');
      }
      throw Exception('Error fetching weather data: $e');
    }
  }

  /// Fetch current weather data for the default city
  Future<WeatherModel> getDefaultWeather() async {
    return getCurrentWeather(_defaultCity);
  }

  /// Get a list of popular farming cities in India
  static List<String> getPopularFarmingCities() {
    return [
      'Delhi,IN',
      'Mumbai,IN',
      'Bangalore,IN',
      'Chennai,IN',
      'Kolkata,IN',
      'Hyderabad,IN',
      'Pune,IN',
      'Ahmedabad,IN',
      'Jaipur,IN',
      'Lucknow,IN',
      'Kanpur,IN',
      'Nagpur,IN',
      'Indore,IN',
      'Thane,IN',
      'Bhopal,IN',
      'Visakhapatnam,IN',
      'Pimpri-Chinchwad,IN',
      'Patna,IN',
      'Vadodara,IN',
      'Ludhiana,IN',
    ];
  }

  /// Validate if the API key is set
  static bool isApiKeySet() {
    return _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;
  }

  /// Get the default city
  static String getDefaultCity() {
    return _defaultCity;
  }

  /// Set a new default city (for future use)
  static String setDefaultCity(String newCity) {
    return newCity;
  }
}
