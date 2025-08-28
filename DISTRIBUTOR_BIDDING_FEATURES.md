# Distributor Bidding and Ordering System

## Overview
This document describes the enhanced crop marketplace system for distributors, including bidding functionality, order management, and auction features.

## Features Implemented

### 1. Enhanced Crop Marketplace Screen
- **Location**: `lib/screens/distributor/crop_marketplace_screen.dart`
- **Features**:
  - Display crop listings with images, quantity, max bid, location, and time left
  - Bidding history dropdown for each listing
  - One bid per user validation
  - Bid increase functionality for existing bids
  - Place order button for expired auctions (highest bidder only)

### 2. Distributor Orders Screen
- **Location**: `lib/screens/distributor/distributor_orders_screen.dart`
- **Features**:
  - View all orders placed by the distributor
  - Order status tracking (pending, confirmed, completed, cancelled)
  - Order details and history
  - Contact farmer functionality
  - Mark orders as completed

### 3. Enhanced Data Models
- **Location**: `lib/models/crop_model.dart`
- **New Features**:
  - `OrderModel` class for order management
  - Enhanced `CropModel` with order support
  - User bid validation methods
  - Highest bidder detection

### 4. Enhanced Services
- **Location**: `lib/services/crop_service.dart`
- **New Methods**:
  - `updateBid()` - Update existing bid amounts
  - `placeOrder()` - Create orders for highest bidders
  - Enhanced bid validation (one bid per user)
  - Order status management

### 5. Enhanced Provider
- **Location**: `lib/providers/crop_provider.dart`
- **New Methods**:
  - `updateBid()` - Update bid functionality
  - `placeOrder()` - Place order functionality

## User Flow

### For Distributors:

1. **Browse Marketplace**:
   - View all active crop auctions
   - See crop images, details, current highest bid, and time remaining
   - Expand bidding history to see all bids

2. **Place Initial Bid**:
   - Click "Place Bid" button
   - Enter bid amount (must be higher than minimum)
   - System validates one bid per user per listing

3. **Update Existing Bid**:
   - If already bid, see "Update Bid" button
   - Can increase bid amount
   - System prevents decreasing bid amount

4. **Win Auction**:
   - When auction expires, highest bidder sees "Place Order" button
   - Other bidders see who won the auction
   - No bids placed shows "Auction ended" message

5. **Manage Orders**:
   - View all won auctions in "My Orders" tab
   - Track order status (pending → confirmed → completed)
   - Contact farmers for pickup arrangements
   - Mark orders as completed

## Technical Implementation

### Key Features:

1. **One Bid Per User**:
   ```dart
   bool hasUserBid(String userId) {
     return bids.any((bid) => bid.distributorId == userId);
   }
   ```

2. **Bid Update Validation**:
   ```dart
   if (newAmount <= userBid.amount) {
     throw Exception('New bid amount must be higher than your current bid');
   }
   ```

3. **Highest Bidder Detection**:
   ```dart
   bool isUserHighestBidder(String userId) {
     final highest = highestBid;
     return highest != null && highest.distributorId == userId;
   }
   ```

4. **Order Creation**:
   ```dart
   OrderModel order = OrderModel(
     id: DateTime.now().millisecondsSinceEpoch.toString(),
     cropId: cropId,
     distributorId: distributorId,
     distributorName: highestBid.distributorName,
     farmerId: crop.farmerId,
     farmerName: 'Farmer',
     cropName: crop.cropName,
     quantity: crop.quantity,
     finalPrice: highestBid.amount,
     pickupLocation: crop.pickupLocation,
     status: 'pending',
     createdAt: DateTime.now(),
   );
   ```

## UI Components

### Crop Cards Include:
- Crop image with loading/error states
- Crop name and expiration status
- Quantity and minimum bid price
- Current highest bid (if any)
- User's current bid (if any)
- Bidding history dropdown
- Action buttons based on auction status

### Order Cards Include:
- Crop image and name
- Order status chip with color coding
- Order details (ID, quantity, price, location)
- Order dates (created, confirmed, completed)
- Action buttons based on order status

## Navigation Integration

The new screens are integrated into the distributor dashboard:
- **Home Tab**: Overview and quick actions
- **Marketplace Tab**: Crop marketplace with bidding
- **My Orders Tab**: Order management
- **Suppliers Tab**: Future supplier network
- **Analytics Tab**: Future analytics dashboard

## Database Schema

### Crops Collection:
```json
{
  "farmerId": "string",
  "cropName": "string",
  "quantity": "number",
  "imageUrl": "string",
  "minBidPrice": "number",
  "startDate": "timestamp",
  "endDate": "timestamp",
  "pickupLocation": "string",
  "status": "string", // 'active', 'expired', 'sold'
  "createdAt": "timestamp",
  "bids": [
    {
      "id": "string",
      "distributorId": "string",
      "distributorName": "string",
      "amount": "number",
      "createdAt": "timestamp"
    }
  ],
  "order": {
    "id": "string",
    "cropId": "string",
    "distributorId": "string",
    "distributorName": "string",
    "farmerId": "string",
    "farmerName": "string",
    "cropName": "string",
    "quantity": "number",
    "finalPrice": "number",
    "pickupLocation": "string",
    "status": "string", // 'pending', 'confirmed', 'completed', 'cancelled'
    "createdAt": "timestamp",
    "confirmedAt": "timestamp",
    "completedAt": "timestamp"
  }
}
```

## Future Enhancements

1. **Real-time Updates**: Implement WebSocket connections for live bid updates
2. **Push Notifications**: Notify users of bid status changes
3. **Payment Integration**: Add payment processing for orders
4. **Rating System**: Allow farmers and distributors to rate each other
5. **Advanced Analytics**: Detailed bidding and market trend analysis
6. **Mobile Notifications**: Push notifications for auction updates

## Testing

To test the implementation:

1. **Create Test Data**:
   - Add crop listings with different end dates
   - Create multiple distributor accounts
   - Place bids from different distributors

2. **Test Scenarios**:
   - Place initial bid on a crop
   - Try to place second bid (should show error)
   - Update existing bid with higher amount
   - Update existing bid with lower amount (should show error)
   - Wait for auction to expire
   - Place order as highest bidder
   - View orders in My Orders tab

3. **Edge Cases**:
   - Auction with no bids
   - Multiple bidders with same amount
   - Network errors during bidding
   - Concurrent bid updates

## Security Considerations

1. **Bid Validation**: Server-side validation of bid amounts
2. **User Authentication**: Verify user identity for all operations
3. **Transaction Safety**: Use Firestore transactions for bid updates
4. **Data Integrity**: Prevent race conditions in bidding
5. **Input Validation**: Sanitize all user inputs

## Performance Optimizations

1. **Lazy Loading**: Load crop images on demand
2. **Pagination**: Implement pagination for large crop lists
3. **Caching**: Cache frequently accessed data
4. **Indexing**: Optimize Firestore queries with proper indexes
5. **Image Optimization**: Compress and resize crop images
