# 🔔 FCM Push Notification - Quick Reference Card

## ⚡ Quick Start (3 Steps)

1. **Run the app and sign in**
   ```bash
   flutter clean && flutter pub get && flutter run
   ```

2. **Copy FCM token from console output**
   ```
   ═══════════════════════════════════════════════════════
   📱 FCM REGISTRATION TOKEN FOR TESTING:
   ═══════════════════════════════════════════════════════
   [YOUR_TOKEN_HERE] ← Copy this!
   ═══════════════════════════════════════════════════════
   ```

3. **Send test from Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Navigate to: Messaging → New Campaign → Notification messages
   - Click: "Send test message"
   - Paste your token → Click "Test" ✅

## 📱 Display FCM Token in UI

### Option 1: Use the Widget Anywhere
```dart
import 'package:farmlink/widgets/fcm_token_display.dart';

// Add to any screen
FCMTokenDisplay()
```

### Option 2: Use the Test Screen
```dart
import 'package:farmlink/screens/test_notification_screen.dart';

// Navigate to test screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TestNotificationScreen()),
);
```

### Option 3: Get Token Programmatically
```dart
import 'package:farmlink/services/notification_service.dart';

final token = await NotificationService().getFCMToken();
print('Token: $token');
```

## 🎯 What Was Fixed

| Issue | Solution | File |
|-------|----------|------|
| No foreground notifications | Added `flutter_local_notifications` | `pubspec.yaml` |
| Missing FCM config | Updated manifest with FCM metadata | `AndroidManifest.xml` |
| No background handler | Added message handlers | `main.dart` |
| No token display | Created display widget & service method | `notification_service.dart` |
| Missing notification icon | Created Android drawable | `ic_notification.xml` |
| Missing FCM dependency | Added firebase-messaging | `build.gradle.kts` |

## 🧪 Test All 3 States

| State | How to Test | Expected Result |
|-------|-------------|-----------------|
| 🟢 Foreground | App is open and visible | Notification pops up on screen |
| 🟡 Background | App is minimized | Notification in system tray |
| 🔴 Terminated | App is completely closed | Notification in system tray |

## 📋 Testing Checklist

```
□ Dependencies installed (flutter pub get)
□ App running without errors
□ Signed in to app
□ FCM token displayed in console
□ Token copied to clipboard
□ Test notification sent from Firebase Console
□ ✅ Foreground notification received
□ ✅ Background notification received
□ ✅ Terminated notification received
□ ✅ Tapping notification opens app
```

## 🔍 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| No token in console | Ensure you're signed in & check internet |
| No foreground notifications | Check notification permissions |
| No background notifications | Verify google-services.json exists |
| Notification icon missing | Run `flutter clean && flutter run` |

## 🚀 Send Test with cURL

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN",
    "notification": {
      "title": "Test",
      "body": "Hello from cURL!"
    }
  }'
```

## 📱 Notification Behavior

```
App State         →  Notification Location  →  Handler
═══════════════════════════════════════════════════════════════
Foreground (Open) →  Local notification     →  onMessage
Background (Min)  →  System tray            →  onMessageOpenedApp
Terminated (Off)  →  System tray            →  getInitialMessage
```

## 📂 Key Files Modified

```
✅ pubspec.yaml                          (Added dependency)
✅ android/app/src/main/AndroidManifest.xml  (FCM config)
✅ lib/services/notification_service.dart    (Core logic)
✅ lib/main.dart                         (Message handlers)
✅ android/app/build.gradle.kts          (Firebase messaging)
```

## 📂 New Files Created

```
✨ lib/widgets/fcm_token_display.dart            (Token widget)
✨ lib/screens/test_notification_screen.dart     (Test UI)
✨ android/app/src/main/res/drawable/ic_notification.xml
✨ FCM_PUSH_NOTIFICATION_TESTING_GUIDE.md
✨ NOTIFICATION_FIX_SUMMARY.md
✨ FCM_QUICK_REFERENCE.md (this file)
```

## 💡 Pro Tips

1. **Auto-print token**: Token prints automatically when you sign in
2. **Widget reusable**: Use `FCMTokenDisplay()` on any screen
3. **Test systematically**: Test all 3 states (foreground, background, terminated)
4. **Check console**: All notification events are logged
5. **Debug mode**: Firebase App Check uses debug provider for development

## 🔗 Important Links

- **Firebase Console**: https://console.firebase.google.com/
- **Testing Guide**: See `FCM_PUSH_NOTIFICATION_TESTING_GUIDE.md`
- **Full Summary**: See `NOTIFICATION_FIX_SUMMARY.md`

## ✅ Success Indicators

You'll know it's working when:
- ✅ Token appears in console on sign-in
- ✅ Notifications appear in all 3 states
- ✅ Tapping notification opens the app
- ✅ Console logs show message details

---

**Need the full guide?** → Read `FCM_PUSH_NOTIFICATION_TESTING_GUIDE.md`

**Need technical details?** → Read `NOTIFICATION_FIX_SUMMARY.md`

