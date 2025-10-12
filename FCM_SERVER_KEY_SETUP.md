# 🔑 FCM Server Key Setup Guide

## Problem Fixed
Your app was only creating notification documents in Firestore but wasn't sending actual push notifications to devices. Now it sends real push notifications when crops become active!

## ⚠️ Important Security Note
Storing the Firebase Server Key in your client app is **NOT RECOMMENDED for production**. This is a temporary solution for testing. For production, use Firebase Cloud Functions (instructions below).

---

## 🚀 Quick Solution (Testing Only)

### Step 1: Get Your Firebase Server Key

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com/
   - Select your FarmLink project

2. **Navigate to Cloud Messaging Settings**
   - Click the ⚙️ **Settings** icon (top left)
   - Click **Project settings**
   - Click the **Cloud Messaging** tab

3. **Find Your Server Key**
   - Scroll down to **Cloud Messaging API (Legacy)**
   - Copy the **Server key**
   - It looks like: `AAAA...xyz` (a long string)

### Step 2: Add Server Key to Your App

1. **Open the file:**
   ```
   lib/services/notification_service.dart
   ```

2. **Find line 298 (around that line):**
   ```dart
   const String serverKey = 'YOUR_FIREBASE_SERVER_KEY';
   ```

3. **Replace with your actual server key:**
   ```dart
   const String serverKey = 'AAAAxxxxxxx:APAxxxxxxxxxxxxxxxxxxxxxxxxxx';
   ```

4. **Save the file**

### Step 3: Test It

1. **Run the app:**
   ```bash
   flutter run
   ```

2. **Sign in as a farmer** and add a new crop

3. **Wait for the crop to become active** (based on start time)

4. **Check if distributors receive push notifications** 📱

---

## ✅ How It Works Now

When a crop becomes active, the system will:

1. ✅ Update crop status in Firestore (`pending` → `active`)
2. ✅ Create notification documents in Firestore
3. ✅ **Send push notifications to all distributor devices** 📱
4. ✅ Display notifications in system tray
5. ✅ Allow tapping to open the app

### Console Output

You'll see messages like:
```
Updated 1 crop statuses
✅ Push notification sent to user abc123
✅ Push notification sent to user def456
✅ Sent 2 push notifications to distributors about new crop: Tomatoes
```

If server key is not configured:
```
⚠️ FCM Server Key not configured. Please update notification_service.dart
   Get your key from Firebase Console > Project Settings > Cloud Messaging
```

---

## 🏆 Production Solution (Recommended)

For production, you should use **Firebase Cloud Functions** instead of storing the server key in the app.

### Why Cloud Functions?

| Client-Side (Current) | Cloud Functions (Recommended) |
|----------------------|------------------------------|
| ❌ Server key exposed | ✅ Server key secure |
| ❌ Can be extracted | ✅ Runs on server |
| ❌ Easy to abuse | ✅ Rate limited |
| ✅ Works immediately | ⏱️ Requires setup |

### Setup Cloud Functions

1. **Install Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**
   ```bash
   firebase login
   ```

3. **Initialize Functions**
   ```bash
   firebase init functions
   ```
   - Select your FarmLink project
   - Choose TypeScript or JavaScript
   - Install dependencies

4. **Create Notification Function**

Create `functions/src/index.ts`:

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Send push notification when a new notification document is created
export const sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notification = snapshot.data();
    
    // Get user's FCM token
    const userDoc = await admin.firestore()
      .collection('users')
      .doc(notification.userId)
      .get();
    
    const fcmToken = userDoc.data()?.fcmToken;
    
    if (!fcmToken) {
      console.log('No FCM token for user:', notification.userId);
      return null;
    }
    
    // Send push notification
    const message = {
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: notification.data || {},
      token: fcmToken,
    };
    
    try {
      await admin.messaging().send(message);
      console.log('✅ Push notification sent to:', notification.userId);
    } catch (error) {
      console.error('❌ Error sending notification:', error);
    }
    
    return null;
  });
```

5. **Deploy the Function**
   ```bash
   firebase deploy --only functions
   ```

6. **Remove Server Key from App**

In `lib/services/notification_service.dart`, remove the `_sendPushNotificationToUser` method since Cloud Functions will handle it:

```dart
// Remove the entire _sendPushNotificationToUser method
// Notifications will be sent automatically by Cloud Functions
// when documents are created in the notifications collection
```

And update `notifyDistributorsAboutNewCrop`:

```dart
// Remove this line:
await _sendPushNotificationToUser(...);

// Keep only the Firestore batch commit
await batch.commit();
```

---

## 🧪 Testing Checklist

### Before Testing
- [ ] Server key added to `notification_service.dart` (line 298)
- [ ] App rebuilt: `flutter clean && flutter pub get && flutter run`
- [ ] At least one distributor user signed in (to have FCM token)

### Test Scenario 1: Immediate Active Crop
1. [ ] Sign in as farmer
2. [ ] Add new crop with start time = now
3. [ ] Wait 1 minute (automatic status check)
4. [ ] Distributor should receive push notification 📱

### Test Scenario 2: Scheduled Crop
1. [ ] Sign in as farmer
2. [ ] Add new crop with start time = 5 minutes from now
3. [ ] Wait until start time passes
4. [ ] Distributor should receive push notification 📱

### Verify Notifications Work
- [ ] Notification appears in system tray (background/terminated)
- [ ] Notification appears on screen (foreground)
- [ ] Tapping notification opens the app
- [ ] Console shows "✅ Push notification sent" messages

---

## 🔍 Troubleshooting

### "⚠️ FCM Server Key not configured"
**Solution:** Add your server key to line 298 of `notification_service.dart`

### "No FCM token found for user"
**Solution:** 
- Ensure distributors have signed in to the app at least once
- Check Firestore: `users/{userId}` should have `fcmToken` field

### "No distributors found to notify"
**Solution:**
- Ensure users have `currentActiveRole: 'foodDistributor'` in Firestore
- Check the users collection in Firebase Console

### Notifications not appearing
**Solution:**
1. Check notification permissions are granted
2. Verify FCM token exists in Firestore
3. Check console for error messages
4. Test with Firebase Console first (manual test)

### HTTP 401 Unauthorized
**Solution:** Your server key is incorrect or expired. Get a new one from Firebase Console.

### HTTP 400 Bad Request
**Solution:** The FCM token might be invalid or expired. User needs to sign in again.

---

## 📊 Notification Flow

```
Farmer adds crop
      ↓
Crop created with "pending" status
      ↓
CropStatusService runs (every 1 minute)
      ↓
Checks if crop should be "active"
      ↓
Updates crop status to "active"
      ↓
NotificationService.notifyDistributorsAboutNewCrop()
      ↓
For each distributor:
  1. Create notification document in Firestore
  2. Get distributor's FCM token
  3. Send HTTP request to FCM API
  4. Push notification delivered to device 📱
```

---

## 📝 Code Changes Summary

### What Changed
1. **Added HTTP package import** for FCM API calls
2. **Added `_sendPushNotificationToUser` method** to send actual push notifications
3. **Updated `notifyDistributorsAboutNewCrop`** to call the new method
4. **Added server key placeholder** for FCM authentication

### Files Modified
- ✅ `lib/services/notification_service.dart` - Added push notification logic

---

## 🎯 Next Steps

1. **Add your server key** to `notification_service.dart` (line 298)
2. **Rebuild and test** the app
3. **For production:** Set up Firebase Cloud Functions (recommended)
4. **Optional:** Add error handling and retry logic

---

## 🆘 Need Help?

- **Server key not working?** Check Firebase Console > Cloud Messaging > Make sure Legacy API is enabled
- **Still no notifications?** Check all items in the troubleshooting section
- **Want Cloud Functions?** Follow the production solution steps above

---

**Status:** ✅ Push notifications for new crops are now implemented!

**Security Note:** Remember to move this to Cloud Functions for production! 🔒

