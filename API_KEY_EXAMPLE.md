# 🔑 API Key Setup Example

## Current Code (Needs to be changed):
```dart
// In lib/services/weather_service.dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

## After Getting Your API Key:
```dart
// Replace with your actual API key from OpenWeatherMap
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```

## Example API Key Format:
- ✅ **Valid**: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
- ✅ **Valid**: `1234567890abcdef1234567890abcdef`
- ❌ **Invalid**: `YOUR_API_KEY_HERE`
- ❌ **Invalid**: `your_api_key_here`

## Quick Steps:
1. Go to https://openweathermap.org/api
2. Sign up (free)
3. Go to "API keys" section
4. Copy your key
5. Replace `'YOUR_API_KEY_HERE'` in `lib/services/weather_service.dart`
6. Save and restart the app

## Free Tier Limits:
- 1,000 API calls per day
- 60 calls per minute
- Perfect for development and testing
