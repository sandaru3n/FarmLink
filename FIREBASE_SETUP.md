# Firebase Setup Guide for FarmLink

This guide will help you set up Firebase for the FarmLink Flutter app.

## Prerequisites

1. A Google account
2. Flutter SDK installed
3. Android Studio or VS Code

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: "FarmLink"
4. Choose whether to enable Google Analytics (recommended)
5. Click "Create project"

## Step 2: Enable Authentication

1. In Firebase Console, go to "Authentication" in the left sidebar
2. Click "Get started"
3. Go to "Sign-in method" tab
4. Enable "Email/Password" authentication
5. Click "Save"

## Step 3: Enable Firestore Database

1. In Firebase Console, go to "Firestore Database" in the left sidebar
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location for your database
5. Click "Done"

## Step 4: Add Android App

1. In Firebase Console, click the gear icon next to "Project Overview"
2. Select "Project settings"
3. Scroll down to "Your apps" section
4. Click the Android icon to add an Android app
5. Enter package name: `com.example.farmlink`
6. Enter app nickname: "FarmLink"
7. Click "Register app"
8. Download the `google-services.json` file

## Step 5: Configure Android App

1. Replace the placeholder `google-services.json` file in `android/app/` with your downloaded file
2. The file should contain your actual Firebase project configuration

## Step 6: Firestore Security Rules

Update your Firestore security rules to allow read/write access for authenticated users:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow authenticated users to read all user data (for role-based features)
    match /users/{userId} {
      allow read: if request.auth != null;
    }
  }
}
```

## Step 7: Test the Setup

1. Run `flutter pub get` to install dependencies
2. Run `flutter run` to test the app
3. Try to register a new user and verify that:
   - User is created in Firebase Authentication
   - User data is saved to Firestore
   - Role selection works correctly

## Troubleshooting

### Common Issues:

1. **Build errors**: Make sure you've replaced the placeholder `google-services.json` file
2. **Authentication errors**: Verify that Email/Password authentication is enabled in Firebase Console
3. **Firestore errors**: Check that Firestore is created and security rules are properly configured

### Error Messages:

- "Default FirebaseApp is not initialized": Make sure Firebase is properly initialized in `main.dart`
- "Permission denied": Check Firestore security rules
- "Network error": Verify internet connection and Firebase project configuration

## Next Steps

After setting up Firebase:

1. Test user registration and login
2. Verify role selection and storage
3. Test role switching functionality
4. Implement additional features like product management, orders, etc.

## Security Considerations

For production:

1. Update Firestore security rules to be more restrictive
2. Enable additional authentication methods if needed
3. Set up proper user roles and permissions
4. Configure Firebase App Check for additional security

## Support

If you encounter issues:

1. Check Firebase Console for error logs
2. Verify all configuration steps are completed
3. Test with a simple Firebase app first
4. Consult Firebase documentation for detailed guides
