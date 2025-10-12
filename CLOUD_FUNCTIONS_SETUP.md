# ☁️ Firebase Cloud Functions Setup - Simple Guide

## 🎯 Why Cloud Functions?

Firebase **deprecated the legacy Server Key API**. The new recommended way is **Firebase Cloud Functions** which:
- ✅ Works with the latest Firebase APIs
- ✅ Keeps your credentials secure
- ✅ Runs automatically when notifications are created
- ✅ No server maintenance needed

---

## 🚀 Step-by-Step Setup (15 Minutes)

### Step 1: Initialize Firebase Functions

Open PowerShell/Terminal in your project folder (`D:\FarmLink`) and run:

```bash
firebase init functions
```

**Answer the prompts:**
1. **"Are you ready to proceed?"** → Press `Y` and Enter
2. **"Select a default Firebase project"** → Choose your FarmLink project
3. **"What language would you like to use?"** → Select `TypeScript` (recommended) or `JavaScript`
4. **"Do you want to use ESLint?"** → `Y` (recommended)
5. **"Do you want to install dependencies now?"** → `Y`

This creates a `functions` folder in your project.

---

### Step 2: Install Required Packages

```bash
cd functions
npm install firebase-admin firebase-functions
```

---

### Step 3: Create the Notification Function

Open the file: **`functions/src/index.ts`** (or `index.js` if you chose JavaScript)

**Replace the entire file with this code:**

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

/**
 * Automatically send push notification when a notification document is created
 * This triggers every time a document is added to the 'notifications' collection
 */
export const sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snapshot, context) => {
    const notificationData = snapshot.data();
    const notificationId = context.params.notificationId;
    
    console.log(`📬 New notification created: ${notificationId}`);
    
    try {
      // Get the user ID from the notification
      const userId = notificationData.userId;
      
      if (!userId) {
        console.log('❌ No userId in notification document');
        return null;
      }
      
      // Get user's FCM token from Firestore
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(userId)
        .get();
      
      if (!userDoc.exists) {
        console.log(`❌ User ${userId} not found`);
        return null;
      }
      
      const userData = userDoc.data();
      const fcmToken = userData?.fcmToken;
      
      if (!fcmToken) {
        console.log(`⚠️ No FCM token for user ${userId}`);
        return null;
      }
      
      // Prepare data payload (all values must be strings)
      const dataPayload: { [key: string]: string } = {
        notificationId: notificationId,
        type: notificationData.type || 'general',
      };
      
      // Add custom data from notification
      if (notificationData.data) {
        for (const key in notificationData.data) {
          dataPayload[key] = String(notificationData.data[key]);
        }
      }
      
      // Create the FCM message
      const message: admin.messaging.Message = {
        notification: {
          title: notificationData.title,
          body: notificationData.message,
        },
        data: dataPayload,
        android: {
          notification: {
            channelId: 'farmlink_notifications',
            sound: 'default',
            priority: 'high',
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
      
      console.log(`✅ Push notification sent successfully to user ${userId}`);
      console.log(`   Message ID: ${response}`);
      
      // Mark notification as sent in Firestore
      await snapshot.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: true, messageId: response };
      
    } catch (error) {
      console.error(`❌ Error sending push notification:`, error);
      
      // Mark notification as failed
      await snapshot.ref.update({
        sent: false,
        error: String(error),
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      
      return { success: false, error: String(error) };
    }
  });
```

**Save the file.**

---

### Step 4: Deploy to Firebase

From the `functions` folder, run:

```bash
firebase deploy --only functions
```

You'll see:
```
✔  functions[sendPushNotification]: Successful create operation.
```

**That's it!** Your Cloud Function is now live! 🎉

---

## 🧪 How to Test

### Test 1: Run Your App

1. **Rebuild your app:**
   ```bash
   cd ..
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Sign in as a farmer**

3. **Add a new crop** (set start time to now or soon)

4. **Wait 1 minute** for crop to become active

5. **Check console output:**
   ```
   ✅ Created 1 notification documents for new crop: Tomatoes
   📱 Push notifications will be sent by Firebase Cloud Functions
   ```

6. **Distributor should receive push notification!** 📱

---

### Test 2: Check Cloud Functions Logs

View logs to see if notifications are being sent:

```bash
firebase functions:log
```

Or view in Firebase Console:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Functions** in the left menu
4. Click on `sendPushNotification`
5. Click **Logs** tab

**Expected logs:**
```
📬 New notification created: abc123xyz
✅ Push notification sent successfully to user xyz789
   Message ID: projects/...
```

---

## 📊 How It Works

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Farmer adds crop                                         │
│    ↓                                                         │
│ 2. Crop becomes "active" (CropStatusService)                │
│    ↓                                                         │
│ 3. App creates notification document in Firestore           │
│    ↓                                                         │
│ 4. Cloud Function automatically triggers                    │
│    ↓                                                         │
│ 5. Function gets user's FCM token                           │
│    ↓                                                         │
│ 6. Function sends push notification via FCM API             │
│    ↓                                                         │
│ 7. Distributor receives notification 📱                     │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Troubleshooting

### Issue: Function not deploying

**Solution:**
```bash
cd functions
npm install
firebase deploy --only functions
```

### Issue: "User not found" in logs

**Solution:** Ensure distributors have signed in at least once so their user document exists in Firestore.

### Issue: "No FCM token" in logs

**Solution:** 
- User must sign in to the app to get FCM token
- Check Firestore: `users/{userId}` should have `fcmToken` field

### Issue: No push notifications received

**Check:**
1. Cloud Functions deployed successfully?
   ```bash
   firebase functions:list
   ```
2. Notification documents being created?
   - Check Firebase Console → Firestore → `notifications` collection
3. Users have FCM tokens?
   - Check Firebase Console → Firestore → `users/{uid}` → Look for `fcmToken` field
4. Check Cloud Functions logs:
   ```bash
   firebase functions:log --only sendPushNotification
   ```

### Issue: Permission denied errors

**Solution:**
```bash
firebase login --reauth
firebase use --add
# Select your project
firebase deploy --only functions
```

---

## 💰 Cost

Firebase Cloud Functions has a **generous free tier**:
- **2 million invocations/month** - FREE
- **400,000 GB-seconds** - FREE  
- **200,000 CPU-seconds** - FREE

For a typical app with notifications:
- **1,000 users × 10 notifications/day = 300,000 invocations/month**
- **Cost: $0** (well within free tier) ✅

---

## ✅ Success Checklist

When everything is working:
- [x] Cloud Function deployed successfully
- [x] Notification documents created in Firestore
- [x] Cloud Function logs show "✅ Push notification sent"
- [x] Distributors receive push notifications 📱
- [x] Notifications work in foreground, background, and terminated states

---

## 📝 What Changed in Your App

I've updated `lib/services/notification_service.dart`:
- ✅ Removed deprecated server key approach
- ✅ App now only creates Firestore documents
- ✅ Cloud Functions automatically send push notifications
- ✅ Cleaner, more secure code

---

## 🎯 Next Steps

1. **Run the commands above** to set up Cloud Functions
2. **Deploy the function** to Firebase
3. **Test** by adding a crop as a farmer
4. **Verify** distributors receive notifications

---

## 🆘 Need Help?

### View Logs in Real-Time
```bash
firebase functions:log --follow
```

### Redeploy Function
```bash
cd functions
firebase deploy --only functions:sendPushNotification
```

### Test Manually
Create a test notification document in Firebase Console:
1. Go to Firestore
2. Open `notifications` collection
3. Add document with:
   ```json
   {
     "userId": "YOUR_USER_ID",
     "title": "Test Notification",
     "message": "Testing push notifications",
     "type": "test",
     "isRead": false,
     "createdAt": "2024-01-01T00:00:00Z"
   }
   ```
4. Cloud Function should trigger automatically

---

## 📚 Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [Firebase Admin SDK Documentation](https://firebase.google.com/docs/admin/setup)

---

**Status:** ✅ **Ready to set up! Follow the steps above to enable push notifications.** 🚀

**Remember:** This solution is secure, scalable, and uses the latest Firebase APIs! 🔒

