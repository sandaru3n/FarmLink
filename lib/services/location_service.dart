import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationService with ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;
  String? _error;
  bool _isDisposed = false;

  // Getters
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLocation => _currentPosition != null;

  /// Get current location with high accuracy
  Future<Position?> getCurrentLocation() async {
    if (_isDisposed) return null;

    _setLoading(true);
    _clearError();

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('Location permission denied. Please enable location access to get weather for your area.');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setError('Location permission permanently denied. Please enable location access in device settings to get weather for your area.');
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('Location services are disabled. Please enable location services to get weather for your area.');
        return null;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      
      // Get address from coordinates
      await _getAddressFromPosition(position);
      
      _safeNotifyListeners();
      return position;

    } catch (e) {
      _setError('Failed to get current location: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    if (_isDisposed) return null;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.postalCode,
          place.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
      }
      
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      print('Error getting address: $e');
      return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
    }
  }

  /// Get coordinates from address (reverse geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    if (_isDisposed) return null;

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return Position(
          latitude: locations.first.latitude,
          longitude: locations.first.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }
    } catch (e) {
      print('Error getting coordinates from address: $e');
    }
    return null;
  }

  /// Get location for weather (with fallback to default)
  Future<Position?> getLocationForWeather() async {
    // Try to get current location first
    Position? position = await getCurrentLocation();
    
    if (position != null) {
      return position;
    }

    // Fallback to a default location (New Delhi, India)
    print('Using fallback location for weather');
    return Position(
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      return permission == LocationPermission.whileInUse || 
             permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Get distance between two coordinates in kilometers
  double getDistanceBetween(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Check if location is within a certain radius of another location
  bool isWithinRadius(double lat1, double lon1, double lat2, double lon2, double radiusKm) {
    double distance = getDistanceBetween(lat1, lon1, lat2, lon2);
    return distance <= radiusKm;
  }

  // Private methods
  Future<void> _getAddressFromPosition(Position position) async {
    try {
      _currentAddress = await getAddressFromCoordinates(
        position.latitude, 
        position.longitude
      );
    } catch (e) {
      _currentAddress = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
    }
  }

  void _setLoading(bool loading) {
    if (!_isDisposed) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void _setError(String error) {
    if (!_isDisposed) {
      _error = error;
      _safeNotifyListeners();
    }
  }

  void _clearError() {
    if (!_isDisposed) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Clear current location data
  void clearLocation() {
    if (!_isDisposed) {
      _currentPosition = null;
      _currentAddress = null;
      _clearError();
      _safeNotifyListeners();
    }
  }

  /// Refresh location data
  Future<void> refreshLocation() async {
    await getCurrentLocation();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
