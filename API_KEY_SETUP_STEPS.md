# 🔑 API Key Setup - Step by Step

## Current Problem:
```
{
  "cod": 401,
  "message": "Invalid API key. Please see https://openweathermap.org/faq#error401 for more info."
}
```

## Solution: Get a Fresh API Key

### Step 1: Create New Account (2 minutes)
1. Go to: https://openweathermap.org/api
2. Click "Sign Up"
3. Fill out the form
4. **VERIFY YOUR EMAIL** (check inbox, click verification link)

### Step 2: Generate API Key (1 minute)
1. Login to your account
2. Go to "API keys" section
3. Click "Generate" or "Create new key"
4. Copy the new API key (32 characters long)

### Step 3: Update Code (30 seconds)
1. Open `lib/services/weather_service.dart`
2. Find line 9:
   ```dart
   static const String _apiKey = 'YOUR_API_KEY_HERE';
   ```
3. Replace with your new key:
   ```dart
   static const String _apiKey = 'your_new_api_key_here';
   ```

### Step 4: Wait and Test (5 minutes)
1. **Wait 10 minutes** for API key activation
2. Save the file
3. Restart the app: `flutter run`
4. Test the weather feature

## Why the Old Key Didn't Work:
- ❌ Key might be from a different account
- ❌ Account email not verified
- ❌ Key was disabled or expired
- ❌ Key format was incorrect

## New Key Format:
- ✅ 32 characters long
- ✅ Mix of letters and numbers
- ✅ Example: `a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6`

## Free Tier Limits:
- 1,000 API calls per day
- 60 calls per minute
- Perfect for development!

## Success Indicators:
- No 401 error
- Real weather data appears
- Temperature and conditions shown
- No error messages
