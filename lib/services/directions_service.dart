import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class DirectionsService {
  // Replace with your Google Maps API key
  static const String _apiKey = 'AIzaSyCWUOys019eKI0kEqZQqxHV0mIuqojFhqI';
  
  Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    final String url = 'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$_apiKey';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          // Get polyline points
          final polylinePoints = PolylinePoints();
          final String encodedPolyline = route['overview_polyline']['points'];
          final List<PointLatLng> decodedPoints = 
              polylinePoints.decodePolyline(encodedPolyline);
          
          final List<LatLng> polylineCoordinates = decodedPoints
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          
          return DirectionsResult(
            distance: leg['distance']['text'],
            distanceValue: leg['distance']['value'], // in meters
            duration: leg['duration']['text'],
            durationValue: leg['duration']['value'], // in seconds
            polylinePoints: polylineCoordinates,
            distanceInKm: (leg['distance']['value'] / 1000).toDouble(),
          );
        } else {
          print('Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching directions: $e');
      return null;
    }
  }
}

class DirectionsResult {
  final String distance;
  final int distanceValue; // in meters
  final String duration;
  final int durationValue; // in seconds
  final List<LatLng> polylinePoints;
  final double distanceInKm;

  DirectionsResult({
    required this.distance,
    required this.distanceValue,
    required this.duration,
    required this.durationValue,
    required this.polylinePoints,
    required this.distanceInKm,
  });

  // Calculate price: Rs. 100 per km
  double get deliveryPrice => distanceInKm * 100;
}

