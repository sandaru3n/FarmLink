# Bidding Status Functionality

## Overview

This document describes the implementation of the bidding status functionality for crops in the FarmLink application. The system now supports a "pending" status for crops that allows farmers to schedule future bidding start times.

## Crop Status Flow

### 1. Pending Status
- **When**: When a farmer creates a new crop listing with a future start date
- **Visibility**: Only visible to the farmer who created it
- **Actions Available**: 
  - Edit crop details
  - Delete crop
  - View crop information
- **Bidding**: Not allowed

### 2. Active Status
- **When**: Automatically activated when the start date is reached
- **Visibility**: Visible to all distributors in the marketplace
- **Actions Available**:
  - Distributors can place bids
  - Distributors can update their bids
  - View bidding history
- **Bidding**: Allowed

### 3. Expired Status
- **When**: Automatically activated when the end date is reached
- **Visibility**: 
  - Visible to all users but bidding is closed
  - **Special case**: Expired crops are also visible to distributors who won the auction (highest bidder)
- **Actions Available**:
  - View final bidding results
  - **For winning distributor**: Place order button is available
  - **For others**: View who won the auction
- **Bidding**: Not allowed

### 4. Sold Status
- **When**: When an order is placed by the highest bidder
- **Visibility**: Visible to all users
- **Actions Available**:
  - View order details
  - **For winning distributor**: Shows "You won this auction!" message
- **Bidding**: Not allowed

## Key Features

### For Farmers
1. **Future Scheduling**: Farmers can set a future start date for bidding
2. **Pending Management**: Farmers can edit and delete crops while in pending status
3. **Status Visibility**: Clear indication of crop status with color coding
4. **Time Information**: Shows time until bidding starts for pending crops

### For Distributors
1. **Active Crops**: Marketplace shows crops that are currently active for bidding
2. **Won Expired Crops**: Distributors can see expired crops they've won and place orders
3. **Status Validation**: System prevents bidding on non-active crops
4. **Clear Messaging**: Informative messages for different crop states
5. **Pull to Refresh**: Refresh marketplace to see updated crop statuses

### Automatic Status Updates
1. **Background Service**: Crop status service runs every minute to update statuses
2. **Batch Updates**: Efficient batch processing for multiple crops
3. **Real-time Updates**: Status changes are reflected immediately in the UI

## Technical Implementation

### Model Changes
- Added `isPending`, `canStartBidding`, `shouldBeActive` getters
- Added `timeUntilStart` getter for pending crops
- Updated status validation logic

### Service Layer
- `CropStatusService`: Handles automatic status updates
- `CropService`: Enhanced with status-based filtering and validation
- `getDistributorCrops()`: New method to get active + won expired crops
- Batch update functionality for efficiency

### UI Updates
- **Farmer Dashboard**: 4-tab layout (Pending, Active, Expired, All)
- **Distributor Dashboard**: Shows active crops + expired crops they've won
- **Status Indicators**: Color-coded status badges
- **Action Buttons**: Context-aware based on crop status
- **Pull to Refresh**: Refresh marketplace functionality

### Data Flow
1. Farmer creates crop → Status: "pending"
2. Background service checks start dates → Updates to "active" when time reached
3. Distributors can bid on active crops
4. Background service checks end dates → Updates to "expired" when time reached
5. **Winning distributor sees expired crop in marketplace**
6. **Winning distributor places order → Status: "sold"**

## Security & Validation

### Status-based Permissions
- Only pending crops can be edited/deleted by farmers
- Only active crops can receive bids from distributors
- Only winning distributors can see expired crops in marketplace
- Status changes are validated at both client and server levels

### Time Validation
- Start date must be in the future when creating crops
- End date must be after start date
- System prevents manipulation of dates for active/expired crops

## Error Handling

### User-friendly Messages
- Clear error messages for invalid actions
- Status-specific guidance for users
- Graceful handling of edge cases

### System Robustness
- Background service error handling
- Fallback mechanisms for status updates
- Data consistency checks

## Future Enhancements

1. **Notifications**: Push notifications when crops become active or when you win an auction
2. **Advanced Scheduling**: Recurring crop listings
3. **Status History**: Track all status changes with timestamps
4. **Analytics**: Status transition analytics for farmers
5. **Manual Override**: Admin ability to manually change statuses
6. **Order Management**: Better order tracking and management for distributors

## Testing Scenarios

### Farmer Scenarios
1. Create crop with future start date → Verify pending status
2. Edit pending crop → Verify changes are saved
3. Delete pending crop → Verify successful deletion
4. Try to edit active crop → Verify error message

### Distributor Scenarios
1. View marketplace → Verify active crops shown
2. Try to bid on pending crop → Verify error message
3. Bid on active crop → Verify successful bid
4. **Win expired auction → Verify crop appears in marketplace**
5. **Place order on won expired crop → Verify order creation**
6. **View sold crop → Verify "You won this auction!" message**
7. **Pull to refresh → Verify updated crop list**

### System Scenarios
1. Start date reached → Verify automatic status change to active
2. End date reached → Verify automatic status change to expired
3. **Expired crop with bids → Verify winning distributor can see it**
4. Multiple crops updating → Verify batch processing works
5. Network issues → Verify graceful error handling
