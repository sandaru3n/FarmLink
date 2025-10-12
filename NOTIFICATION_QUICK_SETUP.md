# Quick Setup Guide - Distributor Notification System

## Step 1: Firestore Setup

### 1.1 Add Security Rules

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Navigate to **Firestore Database** > **Rules**
4. Add the notification rules from `NOTIFICATION_FIRESTORE_RULES.txt`
5. Click **Publish**

### 1.2 Create Firestore Index

You have two options:

**Option A: Automatic (Recommended)**
1. Run the app as a distributor
2. Firestore will detect the missing index
3. Click the link in the error message to create the index automatically

**Option B: Manual**
1. Go to **Firestore Database** > **Indexes**
2. Click **Create Index**
3. Configure:
   - Collection ID: `notifications`
   - Field 1: `userId` (Ascending)
   - Field 2: `createdAt` (Descending)
   - Query scope: Collection
4. Click **Create**

## Step 2: Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

This will install the `timeago` package that was added to `pubspec.yaml`.

## Step 3: Test the System

### 3.1 Test as Farmer

1. Open the app and sign in as a farmer
2. Navigate to **Add Crop** screen
3. Fill in crop details:
   - Crop name: "Tomatoes"
   - Quantity: 50 kg
   - Start date: Current date + 2 minutes
   - End date: Current date + 1 day
4. Add an image and submit

### 3.2 Test as Distributor

1. Open the app on another device/browser/account
2. Sign in as a distributor (with role: Food Distributor)
3. Go to the distributor dashboard
4. Wait for 2-3 minutes (for the crop to become active)
5. Check the notification icon in the header
6. You should see:
   - A red badge with count "1"
   - Tap to open notifications
   - See notification: "Tomatoes (50 kg) is now available for bidding!"

### 3.3 Test Notification Features

**Test 1: Mark as Read**
- Tap on a notification
- It should mark as read (background color changes)
- Badge count should decrease

**Test 2: Delete Notification**
- Swipe a notification left
- Confirm deletion
- Notification should disappear

**Test 3: Bulk Actions**
- Tap the 3-dot menu in the app bar
- Test "Mark all as read"
- Test "Delete all"

**Test 4: Navigation**
- Tap a new crop notification
- Should navigate to Crop Marketplace
- Should mark notification as read

## Step 4: Verify Real-time Updates

### Test Real-time Behavior

1. Keep distributor app open on dashboard
2. On another device, sign in as farmer
3. Add a crop with start time = now + 1 minute
4. Wait for 1-2 minutes
5. Watch the distributor's notification badge
6. It should automatically update without refresh!

## Troubleshooting

### Issue: No notifications appearing

**Check 1: User Role**
```dart
// Verify in Firestore
users/{userId}/currentActiveRole = "foodDistributor"
```

**Check 2: Crop Status**
```dart
// Verify in Firestore
crops/{cropId}/status = "active"
```

**Check 3: Console Logs**
- Check browser/device console for errors
- Look for "Sent notifications to X distributors" message

### Issue: Badge not updating

**Check 1: Provider Registration**
- Verify `NotificationProvider` is in `main.dart`
- Check that it's above `MaterialApp` in widget tree

**Check 2: Stream Subscription**
- Restart the app
- Check if `loadUserNotifications()` is called

### Issue: Firestore permission denied

**Solution:**
- Apply the security rules from `NOTIFICATION_FIRESTORE_RULES.txt`
- Ensure user is authenticated
- Check Firestore console for rule evaluation errors

### Issue: Index not created

**Solution:**
- Wait a few minutes for index creation
- Check Firestore > Indexes for status
- If failed, delete and recreate the index

## Verification Checklist

Before considering the setup complete, verify:

- [ ] Security rules applied in Firestore
- [ ] Composite index created (userId + createdAt)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] App runs without errors
- [ ] Notification badge appears in distributor dashboard
- [ ] Notifications appear when crop becomes active
- [ ] Badge count updates in real-time
- [ ] Can mark notifications as read
- [ ] Can delete notifications
- [ ] Tap notification navigates to marketplace
- [ ] Multiple distributors receive same notification

## Performance Tips

1. **Limit Notification History**
   - Currently limited to 50 most recent
   - Consider adding pagination for large notification lists

2. **Clean Up Old Notifications**
   - Add a Cloud Function to delete notifications older than 30 days
   - Keeps database lean and queries fast

3. **Optimize Queries**
   - The current implementation uses efficient indexed queries
   - Monitor query performance in Firebase Console

## Next Steps

After basic setup is complete, consider:

1. **Add More Notification Types**
   - Bid updates (when outbid)
   - Order confirmations
   - Payment reminders

2. **Push Notifications (Optional)**
   - Set up Firebase Cloud Messaging
   - Add Cloud Functions for push notifications
   - See: [FCM Setup Guide](https://firebase.google.com/docs/cloud-messaging/flutter/client)

3. **Notification Preferences**
   - Let users customize notification settings
   - Add email/SMS options

## Support

If you encounter issues:

1. Check the `DISTRIBUTOR_NOTIFICATION_SYSTEM.md` for detailed documentation
2. Review console logs for error messages
3. Verify Firestore data structure matches the documentation
4. Check Firebase Console for security rule errors

## Summary

You've successfully implemented a real-time notification system! All logged-in distributors will now be notified when farmers add new active crops. The system is:

✅ Real-time with Firestore streams  
✅ Scalable with batch writes  
✅ User-friendly with clean UI  
✅ Production-ready with proper error handling

Happy farming! 🌾

