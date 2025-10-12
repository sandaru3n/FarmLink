# ☁️ Firebase Cloud Functions - Secure Push Notification Solution

This guide shows you how to set up Firebase Cloud Functions to send push notifications securely without exposing your server key in the client app.

## 🎯 Why Use Cloud Functions?

| Feature | Client-Side | Cloud Functions |
|---------|-------------|-----------------|
| Security | ❌ Server key exposed | ✅ Server key secure |
| Scalability | ⚠️ Limited | ✅ Auto-scales |
| Reliability | ⚠️ Depends on app | ✅ Always available |
| Cost | ✅ Free | ✅ Generous free tier |

---

## 📋 Prerequisites

- Node.js installed (v16 or higher)
- Firebase CLI installed
- Your FarmLink Firebase project

---

## 🚀 Quick Setup (15 minutes)

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
```

Verify installation:
```bash
firebase --version
```

### Step 2: Login to Firebase

```bash
firebase login
```

This will open a browser window. Sign in with your Firebase account.

### Step 3: Initialize Firebase Functions

Navigate to your project directory:
```bash
cd D:\FarmLink
```

Initialize Functions:
```bash
firebase init functions
```

Answer the prompts:
- **Select your project:** Choose your FarmLink project
- **Language:** TypeScript (recommended) or JavaScript
- **ESLint:** Yes
- **Install dependencies:** Yes

This creates a `functions` folder with:
```
functions/
├── src/
│   └── index.ts (or index.js)
├── package.json
└── tsconfig.json (if TypeScript)
```

### Step 4: Install Admin SDK

```bash
cd functions
npm install firebase-admin
npm install firebase-functions
```

### Step 5: Create Notification Function

Edit `functions/src/index.ts` (or `index.js`):

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Send push notification when a notification document is created
 * Triggers automatically when a document is added to 'notifications' collection
 */
export const sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId;
    
    console.log(`📬 New notification created: ${notificationId}`);
    console.log('Notification data:', notificationData);
    
    try {
      // Get user's FCM token from Firestore
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(notificationData.userId)
        .get();
      
      if (!userDoc.exists) {
        console.log(`❌ User ${notificationData.userId} not found`);
        return null;
      }
      
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;
      
      if (!fcmToken) {
        console.log(`⚠️ No FCM token for user: ${notificationData.userId}`);
        return null;
      }
      
      // Prepare the notification payload
      const message: admin.messaging.Message = {
        notification: {
          title: notificationData.title,
          body: notificationData.message,
        },
        data: {
          type: notificationData.type || 'general',
          notificationId: notificationId,
          ...convertDataToStrings(notificationData.data || {}),
        },
        android: {
          notification: {
            channelId: 'farmlink_notifications',
            sound: 'default',
            priority: 'high' as 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        token: fcmToken,
      };
      
      // Send the push notification
      const response = await admin.messaging().send(message);
      console.log(`✅ Push notification sent successfully: ${response}`);
      
      // Optional: Mark notification as sent
      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: true, messageId: response };
    } catch (error) {
      console.error(`❌ Error sending push notification:`, error);
      
      // Optional: Mark notification as failed
      await snapshot.ref.update({
        sent: false,
        error: String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: false, error: String(error) };
    }
  });

/**
 * Helper function to convert all data values to strings
 * FCM data payload must only contain strings
 */
function convertDataToStrings(data: any): { [key: string]: string } {
  const result: { [key: string]: string } = {};
  for (const key in data) {
    if (data.hasOwnProperty(key)) {
      result[key] = String(data[key]);
    }
  }
  return result;
}

/**
 * Optional: Send notification to multiple devices
 * Useful for sending to all distributors at once
 */
export const sendBulkNotification = functions.https.onCall(async (data, context) => {
  // Verify the user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }
  
  const { userIds, title, body, notificationData } = data;
  
  if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'userIds must be a non-empty array'
    );
  }
  
  console.log(`📤 Sending bulk notification to ${userIds.length} users`);
  
  const results = await Promise.allSettled(
    userIds.map(async (userId: string) => {
      // Get user's FCM token
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      
      const fcmToken = userDoc.data()?.fcmToken;
      
      if (!fcmToken) {
        console.log(`⚠️ No FCM token for user: ${userId}`);
        return { userId, success: false, reason: 'No FCM token' };
      }
      
      // Send notification
      const message: admin.messaging.Message = {
        notification: {
          title: title,
          body: body,
        },
        data: convertDataToStrings(notificationData || {}),
        token: fcmToken,
      };
      
      try {
        const response = await admin.messaging().send(message);
        console.log(`✅ Sent to ${userId}: ${response}`);
        return { userId, success: true, messageId: response };
      } catch (error) {
        console.error(`❌ Failed to send to ${userId}:`, error);
        return { userId, success: false, error: String(error) };
      }
    })
  );
  
  const summary = {
    total: results.length,
    successful: results.filter(r => r.status === 'fulfilled').length,
    failed: results.filter(r => r.status === 'rejected').length,
  };
  
  console.log(`📊 Bulk notification summary:`, summary);
  
  return { summary, results };
});
```

### Step 6: Deploy to Firebase

```bash
firebase deploy --only functions
```

You'll see:
```
✔  functions[sendNotificationOnCreate(us-central1)] Successful create operation.
Function URL: https://us-central1-your-project.cloudfunctions.net/...
```

### Step 7: Update Your App

Since Cloud Functions now handle sending push notifications, update your app:

**Open:** `lib/services/notification_service.dart`

**Remove or comment out** the `_sendPushNotificationToUser` method and its call:

```dart
// BEFORE (remove this):
await _sendPushNotificationToUser(
  userId: distributorId,
  title: 'New Crop Available',
  body: '$cropName ($quantity kg) is now available for bidding!',
  data: {...},
);

// AFTER (just create the document, Cloud Function will send notification):
// Cloud Functions will automatically send push notification
// when the document is created in Firestore
```

Updated `notifyDistributorsAboutNewCrop` method:

```dart
Future<void> notifyDistributorsAboutNewCrop({
  required String cropId,
  required String cropName,
  required double quantity,
  required String farmerId,
}) async {
  try {
    final distributorIds = await _getAllDistributorIds();
    
    if (distributorIds.isEmpty) {
      print('No distributors found to notify');
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (String distributorId in distributorIds) {
      if (distributorId == farmerId) continue;

      final notificationRef = _notificationsCollection.doc();
      final notification = NotificationModel(
        id: notificationRef.id,
        userId: distributorId,
        type: 'new_crop',
        title: 'New Crop Available',
        message: '$cropName ($quantity kg) is now available for bidding!',
        data: {
          'cropId': cropId,
          'cropName': cropName,
          'quantity': quantity,
          'farmerId': farmerId,
        },
        isRead: false,
        createdAt: now,
      );

      batch.set(notificationRef, notification.toFirestore());
      
      // No need to call _sendPushNotificationToUser anymore!
      // Cloud Function will handle it automatically
    }

    await batch.commit();
    print('✅ Created notification documents. Cloud Functions will send push notifications.');
  } catch (e) {
    print('❌ Error creating notifications: $e');
  }
}
```

---

## 🧪 Testing

1. **Check Function Deployment**
   ```bash
   firebase functions:log
   ```

2. **Test the Flow**
   - Sign in as farmer
   - Add new crop
   - Wait for it to become active
   - Check Cloud Functions logs:
     ```bash
     firebase functions:log --only sendNotificationOnCreate
     ```

3. **Expected Logs**
   ```
   📬 New notification created: abc123xyz
   ✅ Push notification sent successfully: projects/...
   ```

---

## 📊 Monitor Functions

### View Logs in Firebase Console
1. Go to Firebase Console
2. Click **Functions** in left menu
3. Click on `sendNotificationOnCreate`
4. View **Logs** tab

### View Logs in Terminal
```bash
# All functions
firebase functions:log

# Specific function
firebase functions:log --only sendNotificationOnCreate

# Follow logs in real-time
firebase functions:log --only sendNotificationOnCreate --follow
```

---

## 💰 Cost

Firebase Functions has a generous free tier:
- **2M invocations/month free**
- **400,000 GB-seconds free**
- **200,000 CPU-seconds free**

For a typical app with 1,000 users receiving 10 notifications/day:
- **Monthly invocations:** ~300,000
- **Cost:** $0 (within free tier) ✅

---

## 🔧 Advanced Features

### Add Rate Limiting

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const rateLimitMap = new Map<string, number>();

export const sendNotificationOnCreate = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const userId = notificationData.userId;
    
    // Rate limit: max 10 notifications per minute per user
    const now = Date.now();
    const userKey = `${userId}_${Math.floor(now / 60000)}`;
    const count = rateLimitMap.get(userKey) || 0;
    
    if (count >= 10) {
      console.log(`⚠️ Rate limit exceeded for user: ${userId}`);
      return null;
    }
    
    rateLimitMap.set(userKey, count + 1);
    
    // ... rest of the function
  });
```

### Add Retry Logic

```typescript
async function sendWithRetry(message: admin.messaging.Message, maxRetries = 3) {
  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    try {
      return await admin.messaging().send(message);
    } catch (error: any) {
      if (attempt === maxRetries) throw error;
      
      // Exponential backoff
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
    }
  }
}
```

---

## 🔍 Troubleshooting

### Functions not deploying
```bash
# Clear cache and redeploy
firebase functions:delete sendNotificationOnCreate
firebase deploy --only functions
```

### No logs appearing
- Check Firebase Console > Functions > Logs
- Ensure function is triggered (create a test notification in Firestore)

### "Permission denied" errors
```bash
# Reinstall dependencies
cd functions
rm -rf node_modules
npm install
```

---

## ✅ Benefits of Cloud Functions

1. ✅ **Secure** - Server key never exposed
2. ✅ **Reliable** - Always available, even when app is closed
3. ✅ **Scalable** - Auto-scales with usage
4. ✅ **Maintainable** - Easy to update without app redeployment
5. ✅ **Audit Trail** - Full logs of all notifications sent

---

## 🎉 Success!

Your push notifications are now sent securely from the cloud! 🚀

**Next Steps:**
1. Remove server key from client app
2. Test thoroughly
3. Monitor logs for any issues
4. Consider adding analytics

---

**Need help?** Check Firebase Functions documentation: https://firebase.google.com/docs/functions

