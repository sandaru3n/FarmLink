# 🌤️ Weather API Setup Guide

## ⚠️ IMPORTANT: API Key Required

**The Weather Forecast feature requires an OpenWeatherMap API key to function.**

## 🚀 Quick Setup (2 minutes)

### Step 1: Get Your FREE API Key

1. **Visit**: [OpenWeatherMap API](https://openweathermap.org/api)
2. **Sign up**: Create a free account (takes 30 seconds)
3. **Get key**: Navigate to "API keys" section
4. **Copy**: Your API key (starts with letters/numbers)

### Step 2: Configure in App

1. **Open file**: `lib/services/weather_service.dart`
2. **Find line 7**: 
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. **Replace with your key**:
   ```dart
   static const String _apiKey = 'your_actual_api_key_here';
   ```
4. **Save file** and restart the app

### Step 3: Test It!

1. Run the app: `flutter run`
2. Go to Farmer Dashboard
3. Tap "Weather Forecast" in Quick Actions
4. You should see real weather data! 🌤️

### Step 3: Test the Integration

1. Run the app: `flutter run`
2. Navigate to Farmer Dashboard
3. Tap on "Weather Forecast" in Quick Actions
4. The app should now display real weather data

### Features

- **Real-time Weather Data**: Current temperature, humidity, wind speed, and pressure
- **City Selection**: Choose from popular farming cities in India
- **Weather Icons**: Visual weather representation
- **Farming Recommendations**: AI-powered suggestions based on weather conditions
- **Error Handling**: Graceful handling of network issues and API errors

### Default Cities

The app includes these popular farming cities:
- Delhi, Mumbai, Bangalore, Chennai, Kolkata
- Hyderabad, Pune, Ahmedabad, Jaipur, Lucknow
- And many more...

### API Limits

- Free tier: 1,000 calls per day
- 60 calls per minute
- Perfect for development and small-scale usage

### Troubleshooting

**Error: "Invalid API key"**
- Double-check your API key in `weather_service.dart`
- Ensure there are no extra spaces or characters

**Error: "City not found"**
- Try using the format: "City,Country" (e.g., "Delhi,IN")
- Check the city name spelling

**Error: "No internet connection"**
- Check your device's internet connection
- Ensure the app has network permissions

### Customization

You can easily customize:
- Default city by changing `_defaultCity` in `WeatherService`
- Add more cities to `getPopularFarmingCities()`
- Modify farming recommendations in the modal

### Security Note

⚠️ **Important**: Never commit your API key to version control. Consider using environment variables or a secure configuration file for production apps.
