# Firestore Indexes Setup

This document explains how to set up the required Firestore indexes to fix the query errors in the FarmLink application.

## Problem

The application is experiencing Firestore query errors because composite indexes are required for queries that filter and order by different fields. The specific error is:

```
FAILED_PRECONDITION: The query requires an index. You can create it here: https://console.firebase.google.com/v1/r/project/farmlink-sliit/firestore/indexes?create_composite=...
```

## Solution

### Option 1: Create Indexes via Firebase Console (Recommended)

1. **For the main error (farmerId + createdAt):**
   - Go to [Firebase Console](https://console.firebase.google.com/project/farmlink-sliit/firestore/indexes)
   - Click "Create Index"
   - Collection ID: `crops`
   - Fields:
     - `farmerId` (Ascending)
     - `createdAt` (Descending)
     - `__name__` (Descending)
   - Click "Create"

2. **For the status + endDate query:**
   - Create another index
   - Collection ID: `crops`
   - Fields:
     - `status` (Ascending)
     - `endDate` (Ascending)

### Option 2: Deploy Indexes via Firebase CLI

1. Install Firebase CLI if not already installed:
   ```bash
   npm install -g firebase-tools
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Initialize Firebase in your project (if not already done):
   ```bash
   firebase init firestore
   ```

4. Deploy the indexes:
   ```bash
   firebase deploy --only firestore:indexes
   ```

### Option 3: Use the Direct Link

Click this link to create the required index directly:
```
https://console.firebase.google.com/v1/r/project/farmlink-sliit/firestore/indexes?create_composite=Ckxwcm9qZWN0cy9mYXJtbGluay1zbGlpdC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY3JvcHMvaW5kZXhlcy9fEAEaDAoIZmFybWVySWQQARoNCgljcmVhdGVkQXQQAhoMCghfX25hbWVfXxAC
```

## Temporary Fix

While the indexes are being created (which can take a few minutes), the application has been modified to work without the composite index by:

1. Removing the `orderBy` clause from the Firestore query
2. Sorting the results in memory instead

This temporary fix is already implemented in `lib/services/crop_service.dart`.

## Reverting the Temporary Fix

Once the indexes are created and active, you can revert the temporary fix by uncommenting the `orderBy` clause in `lib/services/crop_service.dart`:

```dart
// Get all crops for a specific farmer
Stream<List<CropModel>> getFarmerCrops(String farmerId) {
  return _cropsCollection
      .where('farmerId', isEqualTo: farmerId)
      .orderBy('createdAt', descending: true)  // Uncomment this line
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
  });
}
```

## Index Status

You can check the status of your indexes in the Firebase Console under:
**Firestore Database → Indexes**

Indexes typically take 1-5 minutes to build, depending on the size of your collection.

## Why This Happens

Firestore requires composite indexes when you:
1. Filter by one field AND order by a different field
2. Use multiple inequality filters
3. Use array-contains-any with orderBy

This is because Firestore needs to efficiently query and sort the data, which requires pre-built indexes.
