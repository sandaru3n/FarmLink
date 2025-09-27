# 🚀 Quick Fix: API Key Setup

## Current Problem:
```
API Key Required
To use weather features, you need to set up your OpenWeatherMap API key.
```

## Solution (2 minutes):

### 1. Get API Key (30 seconds)
- Go to: https://openweathermap.org/api
- Click "Sign Up" (free account)
- Verify email
- Go to "API keys" section
- Copy your key (looks like: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`)

### 2. Update Code (30 seconds)
Open `lib/services/weather_service.dart` and find line 9:

**BEFORE:**
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE';
```

**AFTER:**
```dart
static const String _apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
```
*(Replace with your actual API key)*

### 3. Test (30 seconds)
1. Save the file
2. Restart the app: `flutter run`
3. Go to Farmer Dashboard
4. Tap "Weather Forecast"
5. You should see real weather data! 🌤️

## Example API Key Format:
- ✅ **Good**: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`
- ✅ **Good**: `1234567890abcdef1234567890abcdef`
- ❌ **Wrong**: `YOUR_API_KEY_HERE`
- ❌ **Wrong**: `your_api_key_here`

## Free Tier:
- 1,000 API calls per day
- 60 calls per minute
- Perfect for development!

## Need Help?
The error message in the app now shows exactly what to do. Just follow the steps it displays!
