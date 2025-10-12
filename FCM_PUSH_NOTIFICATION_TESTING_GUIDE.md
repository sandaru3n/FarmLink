# 🔔 FCM Push Notification Testing Guide

This guide will help you test Firebase Cloud Messaging (FCM) push notifications in your FarmLink Android app.

## ✅ What Was Fixed

1. **Added `flutter_local_notifications` package** - For displaying notifications when app is in foreground
2. **Updated AndroidManifest.xml** - Added FCM configuration and notification permissions
3. **Enhanced NotificationService** - Added foreground message handlers and token display
4. **Updated main.dart** - Added background and terminated state message handlers
5. **Created Android resources** - Added notification icon and colors
6. **Updated build.gradle.kts** - Added Firebase Messaging dependency

## 📱 FCM Token Display

### In Console (Automatically)
When you sign in to the app, the FCM token will be automatically printed in the console:
```
═══════════════════════════════════════════════════════
📱 FCM REGISTRATION TOKEN FOR TESTING:
═══════════════════════════════════════════════════════
[YOUR_FCM_TOKEN_HERE]
═══════════════════════════════════════════════════════
📋 Copy this token to use in Firebase Console for testing
═══════════════════════════════════════════════════════
```

### In UI (Using Widget)
You can add the `FCMTokenDisplay` widget to any screen to display and copy the FCM token:

```dart
import 'package:farmlink/widgets/fcm_token_display.dart';

// Add to your widget tree
FCMTokenDisplay()
```

Example usage in a screen:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Test Notifications')),
    body: SingleChildScrollView(
      child: Column(
        children: [
          FCMTokenDisplay(), // Shows token with copy button
          // ... other widgets
        ],
      ),
    ),
  );
}
```

## 🧪 Testing Push Notifications

### Method 1: Firebase Console (Recommended for Testing)

1. **Get your FCM token** from the console or UI widget

2. **Go to Firebase Console**
   - Open [Firebase Console](https://console.firebase.google.com/)
   - Select your FarmLink project
   - Navigate to: **Messaging** (in left sidebar under "Engage")

3. **Create a new notification**
   - Click "New Campaign" → "Firebase Notification messages"
   - Fill in:
     - **Notification title**: "Test Notification"
     - **Notification text**: "This is a test push notification"
     - (Optional) Add image URL
   - Click "Next"

4. **Target your device**
   - Select "Send test message"
   - Paste your FCM token
   - Click "Test"

5. **Verify**
   - App in foreground: Notification appears as a local notification
   - App in background: Notification appears in system tray
   - App terminated: Notification appears in system tray

### Method 2: Using cURL Command

```bash
# Replace with your values:
# - YOUR_FCM_TOKEN: The token from console/widget
# - YOUR_SERVER_KEY: From Firebase Console → Project Settings → Cloud Messaging → Server Key

curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test from cURL",
      "body": "This is a test notification sent via cURL"
    },
    "data": {
      "cropId": "test123",
      "type": "new_crop"
    }
  }'
```

### Method 3: Using Postman

1. **Setup Request**
   - Method: `POST`
   - URL: `https://fcm.googleapis.com/fcm/send`

2. **Headers**
   ```
   Authorization: key=YOUR_SERVER_KEY
   Content-Type: application/json
   ```

3. **Body (raw JSON)**
   ```json
   {
     "to": "YOUR_FCM_TOKEN",
     "notification": {
       "title": "Test Notification",
       "body": "Testing push notifications from Postman"
     },
     "data": {
       "cropId": "crop123",
       "type": "new_crop"
     }
   }
   ```

## 🔍 Notification Behavior

### Foreground (App is Open)
- ✅ Notification appears as local notification
- ✅ Can be tapped to navigate
- ✅ Plays sound and vibrates
- ✅ Console logs message details

### Background (App is Minimized)
- ✅ Notification appears in system tray
- ✅ Tapping opens the app
- ✅ Console logs message details
- ✅ `onMessageOpenedApp` handler triggered

### Terminated (App is Closed)
- ✅ Notification appears in system tray
- ✅ Tapping opens the app
- ✅ `getInitialMessage` returns notification data
- ✅ Can navigate to specific screen based on data

## 🐛 Troubleshooting

### Issue: No FCM Token
**Solution:**
1. Ensure you're signed in to the app
2. Check internet connection
3. Verify Firebase is properly initialized
4. Check console for errors

### Issue: Notifications Not Appearing
**Solution:**
1. Check notification permissions (Android 13+)
2. Verify google-services.json is in `android/app/`
3. Ensure Firebase Messaging is enabled in Firebase Console
4. Check app is connected to Firebase (no connection errors in logs)

### Issue: Foreground Notifications Not Showing
**Solution:**
1. Ensure notification channel is created
2. Check notification icon exists: `android/app/src/main/res/drawable/ic_notification.xml`
3. Verify `flutter_local_notifications` is properly installed

### Issue: Background Notifications Not Working
**Solution:**
1. Ensure background handler is registered in `main.dart`
2. Check AndroidManifest.xml has FCM configuration
3. Verify Firebase Messaging dependency in build.gradle.kts

## 📝 Implementation Details

### Notification Service Features
- ✅ Automatic FCM token registration
- ✅ Token refresh handling
- ✅ Foreground notification display
- ✅ Background message handling
- ✅ Notification channel creation
- ✅ Token display for testing

### Message Handlers
- `FirebaseMessaging.onMessage` - Foreground messages
- `FirebaseMessaging.onBackgroundMessage` - Background messages
- `FirebaseMessaging.onMessageOpenedApp` - Background tap
- `FirebaseMessaging.getInitialMessage` - Terminated tap

## 🎯 Next Steps

1. **Install dependencies**
   ```bash
   flutter pub get
   ```

2. **Clean and rebuild**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. **Sign in to the app** - Token will be printed in console

4. **Copy the FCM token** - From console or use the `FCMTokenDisplay` widget

5. **Send a test notification** - Using Firebase Console

6. **Verify notifications work** - Test all three states (foreground, background, terminated)

## 🔗 Useful Links

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase Messaging Plugin](https://pub.dev/packages/firebase_messaging)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)

## 📊 Testing Checklist

- [ ] Dependencies installed (`flutter pub get`)
- [ ] App rebuilt and running
- [ ] Signed in to the app
- [ ] FCM token obtained from console/widget
- [ ] Test notification sent from Firebase Console
- [ ] Notification received in foreground
- [ ] Notification received in background
- [ ] Notification received when app is terminated
- [ ] Notification tap opens the app
- [ ] Console logs showing message details

## 🎉 Success!

If you can check all items in the testing checklist, your push notifications are working correctly!

---

**Need Help?**
- Check console logs for errors
- Verify Firebase project configuration
- Ensure google-services.json is up to date
- Review Firestore security rules for notification access

