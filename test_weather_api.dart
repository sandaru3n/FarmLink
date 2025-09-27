import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = '055eec6551429b959c978fd76171ecad';
  const city = 'Delhi,IN';
  
  print('Testing OpenWeatherMap API...');
  print('API Key: $apiKey');
  print('City: $city');
  print('');
  
  try {
    final url = 'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    print('URL: $url');
    print('');
    
    final response = await http.get(Uri.parse(url));
    
    print('Response Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('');
      print('✅ SUCCESS!');
      print('City: ${data['name']}');
      print('Temperature: ${data['main']['temp']}°C');
      print('Description: ${data['weather'][0]['description']}');
    } else if (response.statusCode == 401) {
      print('');
      print('❌ INVALID API KEY');
      print('The API key is not valid or not activated yet.');
    } else {
      print('');
      print('❌ ERROR: ${response.statusCode}');
    }
  } catch (e) {
    print('');
    print('❌ NETWORK ERROR: $e');
  }
}
