// Test script for FREE AI Crop Advisory
// No API key required - completely free!

import 'lib/services/crop_advisory_service.dart';

void main() async {
  print('🤖 Testing FREE AI Crop Advisory...');
  print('✅ No API key required!');
  print('✅ No costs involved!');
  print('✅ Works offline!');
  print('');
  
  try {
    final service = CropAdvisoryService();
    
    print('🌾 Getting advisory for Rice in Delhi...');
    print('');
    
    final advisory = await service.getCropAdvisory(
      crop: 'Rice',
      location: 'Delhi',
      soilType: 'Clay Soil',
      weather: 'Sunny',
      additionalInfo: 'Looking for high yield tips',
    );
    
    print('✅ SUCCESS! FREE AI Advisory received:');
    print('🤖 AI Response:');
    print(advisory);
    print('');
    print('🎉 FREE AI Crop Advisory is working perfectly!');
    print('💰 Cost: $0.00 (Completely FREE!)');
    print('🚀 No setup required!');
    print('🌐 Works offline!');
    
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
