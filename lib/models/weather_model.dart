class WeatherModel {
  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String main;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final String icon;
  final DateTime timestamp;

  WeatherModel({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.main,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.icon,
    required this.timestamp,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      city: json['name'] ?? 'Unknown',
      country: json['sys']['country'] ?? '',
      temperature: (json['main']['temp'] ?? 0).toDouble(),
      feelsLike: (json['main']['feels_like'] ?? 0).toDouble(),
      description: json['weather'][0]['description'] ?? '',
      main: json['weather'][0]['main'] ?? '',
      humidity: json['main']['humidity'] ?? 0,
      windSpeed: (json['wind']['speed'] ?? 0).toDouble(),
      pressure: json['main']['pressure'] ?? 0,
      icon: json['weather'][0]['icon'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'temperature': temperature,
      'feelsLike': feelsLike,
      'description': description,
      'main': main,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'pressure': pressure,
      'icon': icon,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Helper method to get weather icon
  String getWeatherIcon() {
    return 'https://openweathermap.org/img/wn/$icon@2x.png';
  }

  // Helper method to get temperature in Celsius
  String getTemperatureCelsius() {
    return '${temperature.toStringAsFixed(0)}°C';
  }

  // Helper method to get feels like temperature
  String getFeelsLikeCelsius() {
    return 'Feels like ${feelsLike.toStringAsFixed(0)}°C';
  }

  // Helper method to get wind speed in km/h
  String getWindSpeedKmh() {
    return '${(windSpeed * 3.6).toStringAsFixed(0)} km/h';
  }

  // Helper method to get humidity percentage
  String getHumidityPercentage() {
    return '$humidity%';
  }

  // Helper method to get pressure in hPa
  String getPressureHpa() {
    return '$pressure hPa';
  }
}
