# Firestore Indexes Setup

## Overview
This document explains the Firestore index requirements for the FarmLink application and how to handle composite index issues.

## Current Implementation

### Query Optimization
To avoid composite index requirements, we've implemented the following optimizations:

1. **Active Crops Query**: 
   - **Before**: `where('status', isEqualTo: 'active').orderBy('endDate', descending: false)`
   - **After**: `where('status', isEqualTo: 'active')` with in-memory sorting
   - **Reason**: Avoids composite index requirement for `status + endDate`

2. **Farmer Crops Query**:
   - **Before**: `where('farmerId', isEqualTo: farmerId).orderBy('createdAt', descending: true)`
   - **After**: `where('farmerId', isEqualTo: farmerId)` with in-memory sorting
   - **Reason**: Avoids composite index requirement for `farmerId + createdAt`

## If You Need Composite Indexes

If you want to use Firestore's built-in ordering for better performance, you can create the required composite indexes:

### 1. Active Crops Index
```json
{
  "collectionGroup": "crops",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "status",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "endDate",
      "order": "ASCENDING"
    }
  ]
}
```

### 2. Farmer Crops Index
```json
{
  "collectionGroup": "crops",
  "queryScope": "COLLECTION",
  "fields": [
    {
      "fieldPath": "farmerId",
      "order": "ASCENDING"
    },
    {
      "fieldPath": "createdAt",
      "order": "DESCENDING"
    }
  ]
}
```

## How to Create Indexes

### Method 1: Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to Firestore Database
4. Click on "Indexes" tab
5. Click "Create Index"
6. Add the required fields and order
7. Wait for the index to build (can take several minutes)

### Method 2: Firebase CLI
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase init firestore`
4. Add indexes to `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "crops",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "endDate",
          "order": "ASCENDING"
        }
      ]
    }
  ]
}
```
5. Deploy: `firebase deploy --only firestore:indexes`

### Method 3: Direct Link (Easiest)
When you get an index error, Firebase provides a direct link to create the required index. Simply click the link in the error message and follow the prompts.

## Performance Considerations

### In-Memory Sorting (Current Approach)
- **Pros**: No index setup required, works immediately
- **Cons**: Limited to 1000 documents per query, slower for large datasets
- **Best for**: Development and small to medium datasets

### Firestore Indexing (Alternative Approach)
- **Pros**: Better performance for large datasets, no document limit
- **Cons**: Requires index setup, additional cost for index storage
- **Best for**: Production with large datasets

## Current Query Structure

### Crop Service Queries

```dart
// Get all active crops (optimized)
Stream<List<CropModel>> getActiveCrops() {
  return _cropsCollection
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
    List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
    // Sort in memory instead of in Firestore
    crops.sort((a, b) => a.endDate.compareTo(b.endDate));
    return crops;
  });
}

// Get farmer's crops (optimized)
Stream<List<CropModel>> getFarmerCrops(String farmerId) {
  return _cropsCollection
      .where('farmerId', isEqualTo: farmerId)
      .snapshots()
      .map((snapshot) {
    List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
    // Sort in memory instead of in Firestore
    crops.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return crops;
  });
}
```

## Troubleshooting

### Common Index Errors

1. **FAILED_PRECONDITION**: Query requires an index
   - **Solution**: Create the required composite index
   - **Quick Fix**: Use the direct link provided in the error message

2. **PERMISSION_DENIED**: Cannot read from collection
   - **Solution**: Check Firestore security rules
   - **Common Cause**: Missing read permissions

3. **RESOURCE_EXHAUSTED**: Query quota exceeded
   - **Solution**: Implement pagination or reduce query frequency
   - **Common Cause**: Too many queries in a short time

### Index Building Status

- **Building**: Index is being created (can take 1-10 minutes)
- **Enabled**: Index is ready to use
- **Disabled**: Index is not available (check for errors)

## Best Practices

1. **Start Simple**: Use single-field queries when possible
2. **Add Indexes Gradually**: Only create indexes when needed
3. **Monitor Usage**: Check Firestore usage in Firebase Console
4. **Test Performance**: Compare in-memory vs indexed sorting for your use case
5. **Consider Pagination**: For large datasets, implement pagination

## Migration Strategy

If you want to switch from in-memory sorting to Firestore indexing:

1. **Create Indexes**: Set up the required composite indexes
2. **Update Queries**: Modify service methods to use `.orderBy()`
3. **Test Performance**: Verify that indexing improves performance
4. **Monitor Costs**: Check if index storage costs are acceptable

## Example Migration

### Before (In-Memory Sorting)
```dart
Stream<List<CropModel>> getActiveCrops() {
  return _cropsCollection
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
    List<CropModel> crops = snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
    crops.sort((a, b) => a.endDate.compareTo(b.endDate));
    return crops;
  });
}
```

### After (Firestore Indexing)
```dart
Stream<List<CropModel>> getActiveCrops() {
  return _cropsCollection
      .where('status', isEqualTo: 'active')
      .orderBy('endDate', descending: false)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => CropModel.fromFirestore(doc)).toList();
  });
}
```

## Security Rules

Make sure your Firestore security rules allow the required queries:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow reading crops for authenticated users
    match /crops/{cropId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (request.auth.uid == resource.data.farmerId || 
         request.auth.uid == request.resource.data.farmerId);
    }
  }
}
```

## Monitoring

Monitor your Firestore usage in the Firebase Console:
- **Queries**: Number of queries executed
- **Documents**: Number of documents read/written
- **Indexes**: Index storage and usage
- **Costs**: Estimated costs for the current usage

This will help you optimize your queries and manage costs effectively.
