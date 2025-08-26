# Real-Time Live Updates System

## Overview

The FarmLink app now implements a comprehensive real-time update system using Firestore's `snapshots()` method, similar to how StreamBuilder works. This system provides instant live updates when user roles change, ensuring that both settings pages and dashboards update automatically without manual refresh.

## Key Features

### 🔄 **Real-Time Role Switching**
- **Instant UI Updates**: When a user's role changes in Firestore, the UI updates immediately
- **Automatic Navigation**: Settings screens and dashboards automatically navigate to the correct role-specific screen
- **No Manual Refresh**: Users don't need to manually refresh or restart the app
- **Seamless Experience**: Smooth transitions between different role interfaces

### 📱 **Live Dashboard Updates**
- **Real-Time Dashboard Switching**: When role changes, dashboard automatically switches to the new role's dashboard
- **Instant Role Detection**: Dashboard router uses real-time listeners to detect role changes
- **Automatic Navigation**: No manual navigation required after role switch

### ⚙️ **Live Settings Updates**
- **Real-Time Settings Switching**: Settings screens automatically switch to the new role's settings
- **Instant UI Refresh**: All settings UI elements update immediately
- **Role-Specific Navigation**: Settings automatically navigate to the appropriate role screen

## Architecture

### 1. **Real-Time Wrappers**

#### `RealTimeSettingsWrapper`
```dart
class RealTimeSettingsWrapper extends StatelessWidget {
  final Widget Function(UserModel? userProfile) settingsBuilder;
  final String title;
  final Color themeColor;
  
  // Uses StreamBuilder with Firestore snapshots()
  // Automatically navigates to correct settings screen when role changes
}
```

#### `RealTimeDashboardWrapper`
```dart
class RealTimeDashboardWrapper extends StatelessWidget {
  final Widget Function(UserModel? userProfile) dashboardBuilder;
  
  // Uses StreamBuilder with Firestore snapshots()
  // Automatically navigates to correct dashboard when role changes
}
```

### 2. **Firestore Stream Implementation**

#### `AuthService.getUserProfileStream()`
```dart
Stream<UserModel?> getUserProfileStream(String uid) {
  return _firestore
      .collection('users')
      .doc(uid)
      .snapshots()  // Real-time listener
      .map((doc) {
        if (doc.exists) {
          return UserModel.fromMap(doc.data() as Map<String, dynamic>);
        }
        return null;
      });
}
```

### 3. **StreamBuilder Integration**

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .snapshots(),
  builder: (context, snapshot) {
    // Handle real-time updates
    // Navigate to appropriate screen based on role changes
  },
)
```

## Implementation Details

### Settings Screens

All settings screens now use `RealTimeSettingsWrapper`:

```dart
// Before (Manual Consumer)
return Scaffold(
  appBar: AppBar(title: Text('Settings')),
  body: Consumer<AuthProvider>(...)
);

// After (Real-Time)
return RealTimeSettingsWrapper(
  title: 'Farmer Settings',
  themeColor: Colors.green,
  settingsBuilder: (userProfile) {
    // Settings UI logic
  },
);
```

### Dashboard Router

The dashboard router uses `RealTimeDashboardWrapper`:

```dart
return RealTimeDashboardWrapper(
  dashboardBuilder: (userProfile) {
    // Route to appropriate dashboard based on currentActiveRole
    switch (userProfile.currentActiveRole) {
      case UserRole.farmer:
        return const FarmerDashboard();
      case UserRole.consumer:
        return const ConsumerDashboard();
      // ... other roles
    }
  },
);
```

## User Experience Flow

### Scenario 1: Farmer → Consumer Switch

1. **User clicks "Switch Role"** in Farmer Settings
2. **Dialog shows**: "Switch to: Consumer"
3. **User selects Consumer**
4. **Loading indicator**: Shows "Switching to Consumer..."
5. **Firestore Update**: `currentActiveRole` updated to "consumer"
6. **Real-Time Detection**: StreamBuilder detects the change
7. **Automatic Navigation**: Settings screen automatically navigates to Consumer Settings
8. **Instant UI Update**: All UI elements reflect the new Consumer role

### Scenario 2: Consumer → Farmer Switch

1. **User clicks "Switch Role"** in Consumer Settings
2. **Dialog shows**: "Switch to: Farmer"
3. **User selects Farmer**
4. **Loading indicator**: Shows "Switching to Farmer..."
5. **Firestore Update**: `currentActiveRole` updated to "farmer"
6. **Real-Time Detection**: StreamBuilder detects the change
7. **Automatic Navigation**: Settings screen automatically navigates to Farmer Settings
8. **Instant UI Update**: All UI elements reflect the new Farmer role

### Scenario 3: Dashboard Live Update

1. **User is on Consumer Dashboard**
2. **Admin changes role** in Firestore (e.g., "consumer" → "farmer")
3. **Real-Time Detection**: Dashboard router detects the change
4. **Automatic Navigation**: Dashboard automatically switches to Farmer Dashboard
5. **Instant UI Update**: All dashboard elements reflect the new Farmer role

## Benefits

### 🚀 **Performance**
- **No Manual Refresh**: Eliminates need for manual app refresh
- **Instant Updates**: UI updates immediately when Firestore changes
- **Efficient**: Uses Firestore's built-in real-time capabilities

### 🎯 **User Experience**
- **Seamless Transitions**: Smooth role switching without interruption
- **Consistent State**: UI always reflects current role
- **No Confusion**: Users always see the correct interface for their current role

### 🔧 **Developer Experience**
- **Automatic Handling**: No need to manually manage navigation after role changes
- **Clean Code**: Wrapper pattern keeps settings/dashboard code clean
- **Maintainable**: Centralized real-time logic in wrapper components

### 🛡️ **Reliability**
- **Error Handling**: Proper error handling for network issues
- **Loading States**: Appropriate loading indicators during updates
- **Fallback**: Graceful fallbacks when data is unavailable

## Technical Implementation

### Firestore Document Structure
```json
{
  "uid": "user123",
  "email": "user@example.com",
  "primaryRole": "farmer",
  "secondaryRole": "consumer",
  "currentActiveRole": "consumer",  // This field triggers real-time updates
  "displayName": "John Doe",
  "createdAt": "2024-01-01T00:00:00Z",
  "lastLoginAt": "2024-01-15T10:30:00Z"
}
```

### Real-Time Listener Setup
```dart
// In RealTimeSettingsWrapper and RealTimeDashboardWrapper
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .snapshots(),
  builder: (context, snapshot) {
    // Handle real-time updates
    final userData = snapshot.data!.data() as Map<String, dynamic>;
    final userProfile = UserModel.fromMap(userData);
    
    // Check if role has changed and navigate accordingly
    if (roleChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigateToCorrectScreen();
      });
    }
    
    return buildUI(userProfile);
  },
)
```

## Error Handling

### Network Issues
- **Connection Lost**: Shows appropriate error message
- **Reconnection**: Automatically resumes when connection restored
- **Fallback**: Uses cached data when available

### Data Parsing Errors
- **Invalid Data**: Shows error message with details
- **Graceful Degradation**: Falls back to basic UI
- **Logging**: Errors logged for debugging

### Navigation Errors
- **Route Not Found**: Falls back to default screen
- **Permission Issues**: Shows appropriate access denied message
- **State Conflicts**: Resolves conflicts automatically

## Future Enhancements

### 🔮 **Planned Features**
- **Offline Support**: Cache role data for offline usage
- **Push Notifications**: Notify users of role changes
- **Audit Trail**: Log all role changes for admin review
- **Role Permissions**: Real-time permission updates

### 📊 **Monitoring**
- **Performance Metrics**: Track real-time update performance
- **Error Tracking**: Monitor and alert on real-time errors
- **Usage Analytics**: Track role switching patterns

## Conclusion

The real-time live updates system provides a seamless, instant, and reliable user experience for role switching in the FarmLink app. By leveraging Firestore's `snapshots()` method and StreamBuilder, the app now offers:

- **Instant UI updates** when roles change
- **Automatic navigation** to appropriate screens
- **No manual refresh** required
- **Smooth user experience** with proper loading states
- **Robust error handling** for edge cases

This system ensures that users always see the correct interface for their current role, whether they're switching roles themselves or an admin is changing their role remotely.
