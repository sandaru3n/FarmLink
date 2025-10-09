# ✅ FIXED: Google Maps API Key Error

## What Was the Problem?

Your app was crashing with this error:
```
java.lang.IllegalStateException: API key not found. Check that <meta-data android:name="com.google.android.geo.API_KEY" android:value="your API key"/> is in the <application> element of AndroidManifest.xml
```

## ✅ What I Fixed

1. ✅ Added required permissions to `AndroidManifest.xml`:
   - `INTERNET`
   - `ACCESS_FINE_LOCATION`
   - `ACCESS_COARSE_LOCATION`

2. ✅ Added Google Maps API key meta-data to `AndroidManifest.xml` (line 40-42)

3. ✅ Cleaned the build (`flutter clean`)

4. ✅ Reinstalled dependencies (`flutter pub get`)

## 🚀 Next Steps

Your API key is already in the file: `AIzaSyCWUOys019eKI0kEqZQqxHV0mIuqojFhqI`

But you need to **verify it's properly configured** in Google Cloud Console:

### Step 1: Verify Required APIs Are Enabled

Go to [Google Cloud Console](https://console.cloud.google.com/) and make sure these are enabled:

1. **Maps SDK for Android** ✅
2. **Geocoding API** ✅
3. **Maps SDK for iOS** (if testing iOS) ✅

**How to check:**
1. Open Google Cloud Console
2. Select your project
3. Search for each API in the search bar
4. Click on it
5. If it says "Enable" → Click it
6. If it says "Manage" → It's already enabled ✅

### Step 2: Check API Key Restrictions (Optional but Important)

1. Go to **Credentials** in Google Cloud Console
2. Click on your API key
3. Under **API restrictions**:
   - Select "Restrict key"
   - Make sure these are checked:
     - Maps SDK for Android
     - Geocoding API
     - Maps SDK for iOS (if using)

### Step 3: Rebuild and Run

Now rebuild your app completely:

```bash
flutter run
```

**Important**: After changing AndroidManifest.xml, you MUST rebuild the app completely. Hot reload won't work!

## 🎯 Testing the Fix

After running `flutter run`:

1. App should start without crashing ✅
2. Navigate to **Farmer Dashboard**
3. Tap **"Add New Crop"**
4. Scroll to **"Pickup Location"**
5. Tap **"Select on Map"**
6. **Grant location permission** when asked
7. **Map should load!** 🗺️✨

## ⚠️ If Still Not Working

### Problem: Map is blank/white

**Solution 1**: Wait 2-3 minutes
- New API keys take a few minutes to activate
- Wait and try again

**Solution 2**: Check API key status
- Go to Google Cloud Console
- Check if key is active
- Check if required APIs are enabled

### Problem: "API_KEY_INVALID" error

**Solution**: The API key might be restricted
1. Go to Google Cloud Console → Credentials
2. Click your API key
3. Under "Application restrictions" → Select "None" (for testing)
4. Under "API restrictions" → Select "Don't restrict key" (for testing)
5. Click "Save"
6. Wait 1-2 minutes
7. Try again

### Problem: Location permission denied

**Solution**: Grant permission manually
- Android: Settings → Apps → FarmLink → Permissions → Location → Allow

### Problem: Still crashing with same error

**Solution**: Complete rebuild
```bash
flutter clean
flutter pub get
flutter run
```

If still not working, try:
```bash
cd android
./gradlew clean
cd ..
flutter run
```

## 📋 Quick Checklist

Before running the app, verify:

- ✅ API key is in `AndroidManifest.xml` (line 42)
- ✅ Maps SDK for Android is enabled in Google Cloud
- ✅ Geocoding API is enabled in Google Cloud
- ✅ Ran `flutter clean` and `flutter pub get`
- ✅ Completely stopped and restarted the app (not hot reload)
- ✅ Location permission granted on device
- ✅ Internet connection is working

## 🎉 Success Indicators

You'll know it's working when:
1. ✅ App launches without crash
2. ✅ No "API key not found" error
3. ✅ Map loads when clicking "Select on Map"
4. ✅ Can see current location on map
5. ✅ Can tap to select location
6. ✅ Address appears in bottom sheet

## 💡 Pro Tips

1. **For Development**: Keep API restrictions OFF for easier testing
2. **For Production**: Enable restrictions for security
3. **API Key Security**: Never commit real API keys to public repos
4. **Monitor Usage**: Check Google Cloud Console to monitor API usage
5. **Free Tier**: $200/month free = 28,500 map loads (plenty for dev!)

## 🔍 Understanding the Error

The error happened because:
1. Google Maps SDK needs an API key to authenticate requests
2. The key must be in `AndroidManifest.xml` for Android
3. The manifest is compiled into the APK at build time
4. Hot reload doesn't rebuild the manifest
5. **Solution**: Complete rebuild after manifest changes

## 📞 Still Having Issues?

If you're still stuck after following all steps:

1. **Check API Key Format**:
   - Should look like: `AIzaSyB...` (starts with AIzaSy)
   - No spaces before or after
   - Between the quotes

2. **Check Console Errors**:
   - Look for detailed error messages
   - Share the exact error for better help

3. **Test API Key**:
   - Try creating a new API key in Google Cloud
   - Replace the old one with the new one

4. **Verify Project**:
   - Make sure you're using the correct Google Cloud project
   - Make sure billing is enabled (even for free tier)

## 🎊 What's Next?

Once the map is working, you can:
- Select precise pickup locations
- See your current location
- Drag marker to adjust position
- Get automatic address lookup
- Save GPS coordinates with crops
- Build distance-based features later

---

**The fix is complete!** Just run `flutter run` and your map should work! 🚀
