import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../models/weather_model.dart';
import 'location_service.dart';

class WeatherService {
  // ⚠️ IMPORTANT: Replace with your actual OpenWeatherMap API key
  // Get your FREE API key from: https://openweathermap.org/api
  // Then replace 'YOUR_API_KEY_HERE' with your actual key
  static const String _apiKey = '85c9257c5d42a1db66d16ccd6e8aafe4'; // ← Get a new API key from openweathermap.org
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  
  // Default city for farming areas (you can change this)
  static const String _defaultCity = 'London,UK'; // Try a different city for testing

  final LocationService _locationService = LocationService();

  /// Fetch current weather data using coordinates (preferred method)
  Future<WeatherModel> getCurrentWeatherByCoordinates(double latitude, double longitude) async {
    // Check if API key is set
    if (!isApiKeySet()) {
      throw Exception('OpenWeatherMap API key not configured. Please set your API key in lib/services/weather_service.dart');
    }

    try {
      final url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      
      // Debug: Print the URL (remove this in production)
      print('Weather API URL (coordinates): $url');
      
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
        throw Exception('Location not found. Please check the coordinates.');
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

  /// Fetch current weather data for user's real location
  Future<WeatherModel> getCurrentWeatherForUserLocation() async {
    try {
      // Get user's current location
      Position? position = await _locationService.getLocationForWeather();
      
      if (position != null) {
        return await getCurrentWeatherByCoordinates(
          position.latitude, 
          position.longitude
        );
      } else {
        // Fallback to default city if location is not available
        print('Location not available, using default city: $_defaultCity');
        return await getCurrentWeather(_defaultCity);
      }
    } catch (e) {
      print('Error getting weather for user location: $e');
      // Fallback to default city
      return await getCurrentWeather(_defaultCity);
    }
  }

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

  /// Get weather for user's current location (simplified)
  Future<WeatherModel> getWeatherForUserLocation() async {
    try {
      return await getCurrentWeatherForUserLocation();
    } catch (e) {
      print('Failed to get weather for user location: $e');
      // Fallback to default city
      return await getCurrentWeather(_defaultCity);
    }
  }

  /// Get weather forecast for user's location (5-day forecast)
  Future<List<WeatherModel>> getWeatherForecastForUserLocation() async {
    try {
      Position? position = await _locationService.getLocationForWeather();
      
      if (position != null) {
        return await getWeatherForecastByCoordinates(
          position.latitude, 
          position.longitude
        );
      } else {
        // Fallback to default city
        return await getWeatherForecast(_defaultCity);
      }
    } catch (e) {
      print('Error getting weather forecast for user location: $e');
      // Fallback to default city
      return await getWeatherForecast(_defaultCity);
    }
  }

  /// Get 5-day weather forecast using coordinates
  Future<List<WeatherModel>> getWeatherForecastByCoordinates(double latitude, double longitude) async {
    if (!isApiKeySet()) {
      throw Exception('OpenWeatherMap API key not configured.');
    }

    try {
      final url = '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
      
      print('Weather Forecast API URL (coordinates): $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) => WeatherModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }

  /// Get 5-day weather forecast for a specific city
  Future<List<WeatherModel>> getWeatherForecast(String cityName) async {
    if (!isApiKeySet()) {
      throw Exception('OpenWeatherMap API key not configured.');
    }

    try {
      final url = '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric';
      
      print('Weather Forecast API URL (city): $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> forecastList = data['list'];
        
        return forecastList.map((item) => WeatherModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }

  /// Get location service instance
  LocationService get locationService => _locationService;
}
