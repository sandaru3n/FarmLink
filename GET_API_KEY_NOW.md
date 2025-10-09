# 🚨 Get Your Google Maps API Key NOW (5 Minutes)

## ⚠️ URGENT: App will crash without API key!

Your app is currently crashing because it needs a Google Maps API key. Follow these steps to fix it **right now**:

## 🎯 Step-by-Step (5 Minutes)

### Step 1: Go to Google Cloud Console (1 min)

👉 **Click here**: [https://console.cloud.google.com/](https://console.cloud.google.com/)

- Sign in with your Google account
- If you don't have one, create a free Google account

### Step 2: Create a Project (30 seconds)

1. Click the project dropdown at the top
2. Click **"New Project"**
3. Name it: `FarmLink` or any name you want
4. Click **"Create"**
5. Wait a few seconds for it to be created

### Step 3: Enable Required APIs (1 minute)

1. In the search bar at top, type: **"Maps SDK for Android"**
2. Click on it
3. Click **"Enable"**
4. Wait for it to enable
5. Repeat for:
   - **"Geocoding API"** - Enable it
   - **"Directions API"** - Enable it (Required for transporter routes!)
   - **"Maps SDK for iOS"** (if you plan to test on iOS) - Enable it

### Step 4: Create API Key (1 minute)

1. In the left menu, click **"Credentials"**
2. Click **"+ CREATE CREDENTIALS"** at the top
3. Select **"API Key"**
4. A popup appears with your API key - **COPY IT!**
5. It looks like: `AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

### Step 5: Add API Key to Your App (2 minutes)

#### For Android:

**File**: `android/app/src/main/AndroidManifest.xml`

Find line 42 (near the end):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

**Replace** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
```

#### For iOS (if testing on iPhone):

**File**: `ios/Runner/AppDelegate.swift`

Add this import at the top:
```swift
import GoogleMaps
```

Then add this line inside the `application` function:
```swift
GMSServices.provideAPIKey("AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
```

### Step 6: Run Your App! (30 seconds)

```bash
flutter run
```

The map should now work! 🎉

## ✅ Verification

After adding the API key:
1. Run the app
2. Go to Farmer Dashboard
3. Click "Add New Crop"
4. Click "Select on Map"
5. **Map should load!** ✨

## 🆘 Still Getting Errors?

### Error: "API key not found"
→ Make sure you saved the `AndroidManifest.xml` file after editing
→ Stop the app completely and run `flutter run` again

### Error: "API_KEY_INVALID"
→ Check there are no spaces before/after the API key
→ Make sure you copied the entire key
→ Verify the APIs are enabled in Google Cloud Console

### Map is blank/white
→ Wait 2-3 minutes - newly created keys take time to activate
→ Check internet connection
→ Verify "Maps SDK for Android" is enabled

## 💰 Is This Free?

**YES!** Google gives you:
- $200 free credit every month
- That's **28,500 map loads** per month FREE
- Perfect for development and small apps!

## 🔒 Important Security Note

**For Development**: Using the placeholder is fine  
**For Production**: You should restrict your API key:
1. Go back to Google Cloud Console
2. Click on your API key
3. Under "Application restrictions" → Select "Android apps"
4. Add your package name: `com.sliit.csseproject`
5. Add your SHA-1 fingerprint (get it from Android Studio)

## 📱 Quick Commands

If you're having issues, try:

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run with fresh build
flutter run
```

## 🎯 What If I Can't Get the API Key Right Now?

You can temporarily use a test key (for learning only, not for production):

⚠️ **This is just for testing - it may not work for long!**

But it's better to spend 5 minutes getting your own FREE key from Google Cloud Console.

## 📞 Need Help?

If you're stuck:
1. Check the error message carefully
2. Make sure the API key is between the quotes with no spaces
3. Verify you enabled "Maps SDK for Android" in Google Cloud
4. Wait 2-3 minutes after creating the key
5. Restart your app completely

---

## 🎉 Once It's Working

After your API key is working, you'll have:
- ✅ Beautiful map location picker
- ✅ Tap to select pickup location
- ✅ Automatic address lookup
- ✅ GPS coordinates saved
- ✅ Professional Uber-like interface

**Get your API key now and let's make it work!** 🚀
