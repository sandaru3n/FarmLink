# Distributor Notification System

## Overview

The FarmLink app now includes a comprehensive notification system that automatically notifies all logged-in distributors when a farmer adds a new crop and it becomes active. The system uses Firestore as a real-time notification database and provides an elegant in-app notification experience.

## Features Implemented

### 1. Notification Model (`lib/models/notification_model.dart`)

A flexible notification data model that supports:
- **User-specific notifications**: Each notification targets a specific user
- **Notification types**: Support for different notification types (`new_crop`, `bid_update`, `order_update`, etc.)
- **Rich data payload**: Additional data can be attached to notifications
- **Read/unread status**: Track which notifications have been read
- **Timestamp tracking**: All notifications have creation timestamps

### 2. Enhanced Notification Service (`lib/services/notification_service.dart`)

The notification service now includes:

#### Core Methods:
- `notifyDistributorsAboutNewCrop()`: Sends notifications to all distributors when a crop becomes active
  - Gets all users with `currentActiveRole` = 'foodDistributor'
  - Creates a notification for each distributor
  - Includes crop name and quantity in the message
  - Uses batch writes for efficiency

- `getUserNotifications()`: Stream of notifications for a specific user
- `getUnreadNotificationCount()`: Real-time count of unread notifications
- `markNotificationAsRead()`: Mark individual notifications as read
- `markAllNotificationsAsRead()`: Mark all user notifications as read
- `deleteNotification()`: Delete a specific notification
- `deleteAllNotifications()`: Delete all notifications for a user

### 3. Crop Status Service Integration (`lib/services/crop_status_service.dart`)

The crop status service has been enhanced to:
- Automatically trigger notifications when crops transition from 'pending' to 'active' status
- Track which crops have been activated in each batch update
- Send notifications to all distributors for each newly activated crop
- Works both for automatic status updates (timer-based) and manual updates

### 4. Notification Provider (`lib/providers/notification_provider.dart`)

A state management provider that:
- Manages notification state across the app
- Provides real-time streams of notifications and unread counts
- Offers convenient methods for notification actions
- Handles loading states and errors
- Automatically subscribes and unsubscribes from notification streams

### 5. Notifications Screen (`lib/screens/notifications/notifications_screen.dart`)

A full-featured notification screen with:
- **List of all notifications**: Sorted by creation date (newest first)
- **Visual distinction**: Unread notifications have a highlighted background
- **Swipe to delete**: Dismiss notifications with a swipe gesture
- **Bulk actions**: Mark all as read or delete all notifications
- **Tap to navigate**: Tapping a notification marks it as read and navigates to relevant screen
- **Pull to refresh**: Refresh notifications by pulling down
- **Empty state**: Friendly message when no notifications exist
- **Relative timestamps**: Shows "5 minutes ago", "2 hours ago", etc. using the `timeago` package
- **Context menu**: Options to mark as read or delete individual notifications

### 6. Notification Badge Widget (`lib/widgets/notification_badge.dart`)

A reusable notification icon with badge that:
- Shows a notification bell icon
- Displays unread count as a red badge
- Automatically updates when new notifications arrive
- Can be customized with different colors and sizes
- Navigates to notifications screen when tapped

### 7. Distributor Dashboard Integration

The Food Distributor Dashboard now includes:
- **Notification badge** in the header next to settings
- **Auto-loading** of notifications when the dashboard initializes
- **Real-time updates** of the unread count badge

## How It Works

### Flow Diagram

```
Farmer adds crop (status: 'pending')
           ↓
Crop start date/time arrives
           ↓
CropStatusService detects and updates status to 'active'
           ↓
NotificationService.notifyDistributorsAboutNewCrop() is called
           ↓
Query all users where currentActiveRole = 'foodDistributor'
           ↓
Create notification for each distributor (batch write)
           ↓
Firestore saves notifications to 'notifications' collection
           ↓
Distributors' apps receive real-time updates via Firestore streams
           ↓
NotificationProvider updates state
           ↓
UI updates automatically (badge count, notification list)
```

### Database Structure

#### Notifications Collection
```
notifications/
  {notificationId}/
    - userId: string (distributor's user ID)
    - type: string ('new_crop', 'bid_update', etc.)
    - title: string ('New Crop Available')
    - message: string ('Tomatoes (50 kg) is now available for bidding!')
    - data: map
        - cropId: string
        - cropName: string
        - quantity: number
        - farmerId: string
    - isRead: boolean (false)
    - createdAt: timestamp
```

## User Experience

### For Distributors

1. **Real-time Notifications**: When a crop becomes active, distributors immediately see:
   - A red badge with count on the notification icon
   - The badge updates automatically without refreshing

2. **Notification Center**: Tapping the notification icon shows:
   - All notifications in chronological order
   - Unread notifications are highlighted
   - Each notification shows crop name and quantity
   - Relative time stamps (e.g., "5 minutes ago")

3. **Notification Actions**:
   - **Tap**: Mark as read and navigate to marketplace
   - **Swipe**: Delete the notification
   - **Menu**: Mark as read or delete individual notifications
   - **Bulk Actions**: Mark all as read or delete all

4. **Navigation**: Tapping a crop notification takes the distributor directly to the Crop Marketplace where they can place bids

### For Farmers

The notification system works automatically in the background:
- When a farmer adds a crop with a future start date, it's in 'pending' status
- When the start date/time arrives, the system automatically:
  - Changes status to 'active'
  - Notifies all distributors
- No additional action required from the farmer

## Technical Details

### Real-time Updates

The system uses Firestore's real-time streaming capabilities:
- Distributors subscribe to notification streams when they log in
- New notifications appear instantly without polling
- Unread counts update in real-time
- No manual refresh required

### Performance Optimizations

1. **Batch Writes**: All notifications for a crop activation are written in a single batch
2. **Limited Queries**: Notification queries are limited to 50 most recent
3. **Indexed Queries**: Firestore queries use efficient indexes on `userId` and `createdAt`
4. **Stream Management**: Proper subscription cleanup to prevent memory leaks

### Firestore Security Rules

Ensure the following security rules are set in Firestore:

```javascript
// Notification rules
match /notifications/{notificationId} {
  // Users can read their own notifications
  allow read: if request.auth != null && 
              resource.data.userId == request.auth.uid;
  
  // Only authenticated users can create notifications
  // (This is mainly for the app, but could be restricted further)
  allow create: if request.auth != null;
  
  // Users can update/delete their own notifications
  allow update, delete: if request.auth != null && 
                           resource.data.userId == request.auth.uid;
}
```

### Required Firestore Indexes

Create the following composite index in Firestore:

**Collection**: `notifications`
- **Field 1**: `userId` (Ascending)
- **Field 2**: `createdAt` (Descending)
- **Query scope**: Collection

You can create this index by:
1. Going to Firestore Console
2. Navigate to Indexes tab
3. Click "Create Index"
4. Or wait for the app to trigger the index creation automatically on first query

## Dependencies

The following new dependencies were added:

```yaml
timeago: ^3.6.1  # For relative time formatting ("5 minutes ago")
```

## Files Created/Modified

### New Files:
1. `lib/models/notification_model.dart` - Notification data model
2. `lib/providers/notification_provider.dart` - Notification state management
3. `lib/screens/notifications/notifications_screen.dart` - Notification UI screen
4. `lib/widgets/notification_badge.dart` - Notification badge widget

### Modified Files:
1. `lib/services/notification_service.dart` - Added notification methods
2. `lib/services/crop_status_service.dart` - Added notification triggers
3. `lib/screens/dashboards/fooddistributor/fooddistributor_dashboard.dart` - Added notification badge
4. `lib/main.dart` - Registered NotificationProvider
5. `pubspec.yaml` - Added timeago dependency

## Testing the System

### Manual Testing Steps:

1. **Setup**:
   - Log in as a farmer
   - Log in as a distributor (on another device/browser)

2. **Create Crop**:
   - As farmer, add a new crop
   - Set the start date/time to 2 minutes in the future
   - Submit the crop

3. **Wait for Activation**:
   - Wait for the start time to pass
   - CropStatusService checks every minute
   - Within 1 minute after start time, crop should become active

4. **Check Notifications**:
   - As distributor, check the dashboard
   - You should see a red badge on the notification icon
   - Tap the notification icon to see the notification
   - The message should show crop name and quantity

5. **Test Actions**:
   - Tap a notification → should mark as read and navigate to marketplace
   - Swipe a notification → should delete it
   - Use menu options → test mark as read and delete
   - Test bulk actions → mark all as read, delete all

### Automated Testing Considerations:

For future automated testing, consider:
- Mock the NotificationService
- Test NotificationProvider state changes
- Test notification badge count updates
- Test navigation from notifications
- Test CRUD operations on notifications

## Future Enhancements

Potential improvements for the notification system:

1. **Push Notifications**: 
   - Integrate FCM push notifications for background/offline scenarios
   - Requires backend Cloud Functions

2. **Notification Categories**:
   - Bid updates (when outbid)
   - Order confirmations
   - Payment reminders
   - Delivery updates

3. **Notification Preferences**:
   - Allow users to customize which notifications they receive
   - Email/SMS notification options

4. **Rich Notifications**:
   - Add crop images to notifications
   - Add action buttons (e.g., "Bid Now")

5. **Notification History**:
   - Archive old notifications
   - Search and filter notifications

6. **Analytics**:
   - Track notification engagement
   - Measure notification effectiveness

## Troubleshooting

### Notifications Not Appearing

1. **Check Firestore Connection**:
   - Verify Firebase is initialized
   - Check Firestore security rules

2. **Check User Role**:
   - Ensure user has `currentActiveRole` set to 'foodDistributor'
   - Verify user is logged in

3. **Check Crop Status**:
   - Verify crop status changed from 'pending' to 'active'
   - Check CropStatusService logs

4. **Check Provider**:
   - Ensure NotificationProvider is registered in main.dart
   - Verify provider is initialized on dashboard

### Badge Count Not Updating

1. **Check Stream Subscription**:
   - Verify NotificationProvider is subscribed
   - Check for stream subscription errors

2. **Check Widget Tree**:
   - Ensure NotificationBadge is wrapped with Consumer
   - Verify Provider is accessible in widget tree

## Conclusion

The notification system provides a seamless way to keep distributors informed about new crop availability. The system is:

- ✅ **Real-time**: Uses Firestore streams for instant updates
- ✅ **Scalable**: Batch writes and efficient queries
- ✅ **User-friendly**: Clean UI with intuitive interactions
- ✅ **Maintainable**: Well-structured code with clear separation of concerns
- ✅ **Extensible**: Easy to add new notification types and features

All logged-in distributors will now be notified immediately when farmers add new crops that become active!

