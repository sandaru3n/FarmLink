// Test your new API key here
// Replace 'YOUR_NEW_API_KEY_HERE' with your actual key and run this

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // Replace this with your new API key
  const apiKey = 'YOUR_NEW_API_KEY_HERE';
  const city = 'London,UK';
  
  print('🧪 Testing New API Key...');
  print('API Key: $apiKey');
  print('City: $city');
  print('');
  
  try {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    print('🌐 Calling: $url');
    print('');
    
    final response = await http.get(Uri.parse(url));
    
    print('📊 Response Status: ${response.statusCode}');
    print('📄 Response Body: ${response.body}');
    print('');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('✅ SUCCESS! Weather data received:');
      print('🏙️  City: ${data['name']}');
      print('🌡️  Temperature: ${data['main']['temp']}°C');
      print('🌤️  Description: ${data['weather'][0]['description']}');
      print('💧 Humidity: ${data['main']['humidity']}%');
      print('💨 Wind: ${data['wind']['speed']} m/s');
      print('');
      print('🎉 Your API key is working! Update the weather service with this key.');
    } else if (response.statusCode == 401) {
      print('❌ STILL INVALID API KEY');
      print('The new API key is also invalid. Please:');
      print('1. Make sure you verified your email');
      print('2. Wait 10 minutes for activation');
      print('3. Try generating another key');
    } else {
      print('❌ ERROR: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('❌ NETWORK ERROR: $e');
  }
}
