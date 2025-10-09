# 🗺️ Google Maps Location Picker Setup Guide

## Overview

The FarmLink app now includes an Uber-like map location picker that allows farmers to select their exact pickup location when adding crops. This feature requires Google Maps API keys for both Android and iOS.

## ⚡ Quick Setup

### Step 1: Get Google Maps API Key

1. **Visit Google Cloud Console**: [https://console.cloud.google.com/](https://console.cloud.google.com/)
2. **Create or Select a Project**: Create a new project or select an existing one
3. **Enable Required APIs**:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
   - **Directions API** (Required for transporter routes)
   - Places API (optional, for enhanced features)

4. **Create API Key**:
   - Go to "Credentials" section
   - Click "Create Credentials" → "API Key"
   - Copy the generated API key

5. **Restrict API Key** (Recommended for production):
   - Click on the API key you just created
   - Add application restrictions (Android/iOS app restrictions)
   - Add API restrictions (only enable the APIs you need)

### Step 2: Configure Android

1. **Open**: `android/app/src/main/AndroidManifest.xml`

2. **Add API Key** inside the `<application>` tag:
```xml
<manifest ...>
    <application ...>
        
        <!-- Add this meta-data tag with your Google Maps API key -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
        
        <!-- Rest of your application tags... -->
    </application>
</manifest>
```

3. **Add Permissions** (should already be present):
```xml
<manifest ...>
    <!-- Add these permissions before the <application> tag -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    
    <application ...>
        ...
    </application>
</manifest>
```

### Important: Enable Directions API

For transporter route visualization to work:
1. Go to Google Cloud Console
2. Search for **"Directions API"**
3. Click **"Enable"**
4. Wait a few seconds for activation

This is required for showing routes and calculating distances!

### Step 3: Configure iOS

1. **Open**: `ios/Runner/AppDelegate.swift`

2. **Add API Key** in the `application` function:
```swift
import UIKit
import Flutter
import GoogleMaps  // Add this import

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Add this line with your API key
    GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

3. **Update Info.plist** (`ios/Runner/Info.plist`):
```xml
<dict>
    <!-- Add these keys for location permissions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>FarmLink needs your location to help you select pickup locations on the map</string>
    
    <key>NSLocationAlwaysUsageDescription</key>
    <string>FarmLink needs your location to help you select pickup locations on the map</string>
    
    <!-- Rest of your Info.plist entries... -->
</dict>
```

### Step 4: Install Dependencies

Run the following command to install the new packages:

```bash
flutter pub get
```

### Step 5: Test the Feature

1. **Run the app**:
```bash
flutter run
```

2. **Test Location Picker**:
   - Navigate to Farmer Dashboard
   - Tap "Add New Crop"
   - Scroll to "Pickup Location" section
   - Tap "Select on Map" button
   - The map should load with your current location
   - Tap anywhere on the map to select a location
   - Tap "Confirm Location" to save

## 🎯 Features

### Map Location Picker Includes:
- ✅ **Current Location**: Automatically centers on user's current location
- ✅ **Tap to Select**: Tap anywhere on map to select pickup location
- ✅ **Draggable Marker**: Drag the green marker to adjust location
- ✅ **Address Display**: Automatically converts coordinates to readable address
- ✅ **My Location Button**: Quick button to return to current location
- ✅ **Uber-like UI**: Beautiful bottom sheet with location details
- ✅ **Coordinates Display**: Shows exact latitude/longitude
- ✅ **Edit Support**: Can update location when editing existing crops

### Where It's Used:
- ✅ Add New Crop screen
- ✅ Edit Crop screen
- ✅ Location data saved in Firestore with coordinates
- ✅ Coordinates available for future features (distance calculation, route planning)

## 🔧 Troubleshooting

### Issue: Map not loading

**Solution 1**: Verify API key is correct
- Check Android: `android/app/src/main/AndroidManifest.xml`
- Check iOS: `ios/Runner/AppDelegate.swift`
- Ensure there are no extra spaces or characters

**Solution 2**: Verify required APIs are enabled
- Maps SDK for Android
- Maps SDK for iOS
- Geocoding API

**Solution 3**: Check API key restrictions
- If you've restricted the API key, make sure your app's package name/bundle ID is allowed

### Issue: Location permission denied

**Solution**: Grant location permissions
- Android: Go to Settings → Apps → FarmLink → Permissions → Location → Allow
- iOS: Go to Settings → FarmLink → Location → While Using the App

### Issue: "Address not found" error

**Solution**: Enable Geocoding API
- Go to Google Cloud Console
- Enable "Geocoding API" for your project
- Wait a few minutes for it to activate

### Issue: Build errors after adding packages

**Solution**: Clean and rebuild
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean && cd ..
flutter run
```

### Issue: iOS build errors

**Solution**: Update Podfile
```bash
cd ios
pod install
cd ..
flutter run
```

## 💰 Cost Information

### Free Tier:
- **Maps SDK for Android**: $200 free monthly credit (28,500 map loads)
- **Maps SDK for iOS**: $200 free monthly credit (28,500 map loads)
- **Geocoding API**: $200 free monthly credit (40,000 requests)

Most small to medium apps stay within the free tier!

### Cost Optimization Tips:
1. **Restrict API Keys**: Only enable required APIs
2. **Set Usage Quotas**: Limit daily requests in Google Cloud Console
3. **Cache Results**: The app caches selected locations
4. **Use Efficiently**: Only open map when needed

## 📱 Testing on Devices

### Android Testing:
```bash
flutter run -d <device-id>
```

### iOS Testing:
1. Open Xcode: `open ios/Runner.xcworkspace`
2. Select your device/simulator
3. Run from Xcode OR use:
```bash
flutter run -d <device-id>
```

## 🎨 UI Customization

The map picker UI can be customized in:
- `lib/screens/farmer/map_location_picker_screen.dart`

Customizable elements:
- Marker color (currently green)
- Bottom sheet design
- Button styles
- Map type (normal, satellite, terrain, hybrid)

## 📚 Additional Resources

- [Google Maps Platform Documentation](https://developers.google.com/maps/documentation)
- [Flutter Google Maps Plugin](https://pub.dev/packages/google_maps_flutter)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Geocoding Package](https://pub.dev/packages/geocoding)

## 🚀 Next Steps

After setup is complete, farmers can:
1. Add crops with precise pickup locations
2. Edit crop locations on the map
3. Distributors can see exact pickup locations
4. Future: Navigate to pickup locations
5. Future: Calculate delivery distances
6. Future: Show all crops on a map view

## ⚠️ Important Notes

1. **Never commit API keys to version control**
   - Add `.env` file to `.gitignore`
   - Use environment variables for production

2. **Use different keys for development and production**
   - Create separate projects in Google Cloud
   - Restrict production keys properly

3. **Monitor API usage**
   - Check Google Cloud Console regularly
   - Set up billing alerts

4. **Location permissions**
   - Users can deny location permissions
   - App handles this gracefully with default location

## ✅ Verification Checklist

- [ ] Google Maps API key obtained
- [ ] Required APIs enabled in Google Cloud Console
- [ ] Android API key configured in AndroidManifest.xml
- [ ] iOS API key configured in AppDelegate.swift
- [ ] Location permissions added to AndroidManifest.xml
- [ ] Location permissions added to Info.plist
- [ ] `flutter pub get` executed successfully
- [ ] App builds without errors on Android
- [ ] App builds without errors on iOS
- [ ] Map loads correctly in app
- [ ] Current location feature works
- [ ] Tap to select location works
- [ ] Address geocoding works
- [ ] Confirm location saves data
- [ ] Location displays in crop form

---

**Need Help?** If you encounter any issues, check the troubleshooting section above or refer to the official Google Maps Platform documentation.
