# 🚀 Quick Start: Map Location Picker

## What's New?

Farmers can now select their crop pickup location on a map (like Uber) when adding or editing crops!

## ⚡ 3-Minute Setup

### 🚨 IMPORTANT: App needs API key to work!

The Android files have been pre-configured with a placeholder. You just need to add your API key!

### Step 1: Get Google Maps API Key (2 minutes)

👉 **Follow the detailed guide**: `GET_API_KEY_NOW.md` 

Or quick steps:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing one
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API
4. Create API Key → Copy it

### Step 2: Add API Key to Android (30 seconds)

**File**: `android/app/src/main/AndroidManifest.xml` (Line 42)

**FIND** this line:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
```

**REPLACE** `YOUR_GOOGLE_MAPS_API_KEY_HERE` with your actual key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBxxxxxxxxxxxxxxxxxxxxxxxxxxxx"/>
```

### Step 3: Add API Key to iOS (30 seconds)

**File**: `ios/Runner/AppDelegate.swift`

Add this line in `application` function:
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

And add import at top:
```swift
import GoogleMaps
```

### Step 4: Run! (10 seconds)

```bash
flutter pub get
flutter run
```

## 🎯 How to Use (For Farmers)

1. Open FarmLink app
2. Go to **Farmer Dashboard**
3. Tap **"Add New Crop"**
4. Scroll to **"Pickup Location"**
5. Tap **"Select on Map"** button 🗺️
6. Tap or drag marker to your location
7. Tap **"Confirm Location"**
8. Done! ✅

## 🎨 What Users Will See

```
┌────────────────────────────────────────┐
│  ← Select Pickup Location              │
│     Tap on map or drag marker          │
├────────────────────────────────────────┤
│                                         │
│          [INTERACTIVE MAP]              │
│               📍                        │
│                                         │
│                                    🎯   │
├────────────────────────────────────────┤
│  📍 Selected Location                  │
│     123 Farm Road, Village,            │
│     District, State                     │
│                                         │
│  [     Confirm Location     ]          │
└────────────────────────────────────────┘
```

## ✨ Features

✅ Tap anywhere to select  
✅ Drag marker to adjust  
✅ Auto-detect current location  
✅ Address shown automatically  
✅ Works in Add & Edit screens  
✅ Beautiful Uber-like UI  

## 🆘 Quick Troubleshooting

### Map not loading?
→ Check API key is correct in `AndroidManifest.xml` and `AppDelegate.swift`

### Location permission denied?
→ Grant permission in phone Settings → FarmLink → Location

### Build errors?
→ Run: `flutter clean && flutter pub get`

### iOS build errors?
→ Run: `cd ios && pod install && cd ..`

## 📚 Full Documentation

- **Setup Guide**: `GOOGLE_MAPS_SETUP.md`
- **Feature Details**: `MAP_LOCATION_PICKER_FEATURE.md`

## 💰 Is it Free?

**YES!** Google provides $200/month free credit which covers:
- 28,500 map loads per month
- 40,000 geocoding requests per month

Perfect for most apps! 🎉

## ✅ Quick Verification

After setup, test these:
- [ ] Map opens when clicking "Select on Map"
- [ ] Current location appears
- [ ] Can tap to select location
- [ ] Address shows in bottom sheet
- [ ] "Confirm Location" saves data
- [ ] Location appears in crop form

## 🎯 What's Saved

When farmer selects location, it saves:
```javascript
{
  pickupLocation: "123 Farm Road, Village...",
  pickupLatitude: 28.614000,
  pickupLongitude: 77.209000
}
```

## 🚀 Future Features Enabled

With GPS coordinates saved, you can add:
- Distance calculations
- Route planning for transporters  
- Map view of all crops
- Nearby crops for distributors
- Delivery radius filtering

---

**That's it!** Get your API key and you're ready to go! 🎉

For detailed help, see `GOOGLE_MAPS_SETUP.md`
