# Transporter Features Documentation

## Overview

The transporter features enable delivery personnel to manage crop deliveries from farmers to distributors. When a distributor completes payment for an order, a delivery order is automatically created and made available for transporters to accept and manage.

## Features

### 1. Delivery Order Management

#### Automatic Delivery Order Creation
- When an order status is updated to "completed" in the orders collection, a delivery order is automatically created
- Delivery orders are stored in a separate `delivery_orders` collection
- Each delivery order contains all necessary information for transportation

#### Delivery Order Data Structure
```json
{
  "id": "delivery_order_id",
  "orderId": "original_order_id",
  "cropImageUrl": "crop_image_url",
  "cropName": "Crop Name",
  "quantity": 100.0,
  "farmerName": "Farmer Name",
  "pickupLocation": "Farm Location",
  "distributorName": "Distributor Name",
  "distributorLocation": "Delivery Location",
  "price": 5000.0,
  "status": "pending|accepted|rejected|in_transit|delivered",
  "transporterId": "transporter_user_id",
  "transporterName": "Transporter Name",
  "createdAt": "timestamp",
  "acceptedAt": "timestamp",
  "rejectedAt": "timestamp",
  "deliveredAt": "timestamp",
  "rejectionReason": "reason_for_rejection"
}
```

### 2. Transporter Dashboard

#### Available Deliveries Tab
- Shows all pending delivery orders available for acceptance
- Displays crop image, name, quantity, and price
- Shows pickup and delivery locations with route visualization
- Provides Accept/Reject buttons for each delivery

#### Active Deliveries Tab
- Shows deliveries that have been accepted by the transporter
- Displays current status (accepted, in transit)
- Allows status updates (start delivery, mark as delivered)

#### Completed Deliveries Tab
- Shows all completed deliveries
- Displays delivery history and earnings

### 3. Delivery Order Actions

#### Accept Delivery
- Transporter can accept available delivery orders
- Updates delivery order status to "accepted"
- Assigns transporter ID and name to the delivery order

#### Reject Delivery
- Transporter can reject delivery orders with optional reason
- Updates delivery order status to "rejected"
- Stores rejection reason for reference

#### Start Delivery
- Transporter can mark accepted deliveries as "in transit"
- Indicates that the delivery process has begun

#### Complete Delivery
- Transporter can mark in-transit deliveries as "delivered"
- Finalizes the delivery process
- Records delivery completion timestamp

### 4. UI/UX Features

#### Uber-like Interface
- Card-based layout for delivery orders
- Status indicators with color coding
- Route visualization with pickup and delivery locations
- Real-time status updates

#### Responsive Design
- Tabbed interface for different delivery states
- Pull-to-refresh functionality
- Loading states and error handling
- Empty state messages

### 5. Real-time Updates

#### Live Data Synchronization
- Real-time updates when delivery orders are created
- Automatic refresh when status changes
- Live statistics updates

## Technical Implementation

### Services

#### DeliveryOrderService
- Manages delivery order CRUD operations
- Handles status updates and transitions
- Provides real-time data streams
- Calculates delivery statistics

#### OrderService Integration
- Automatically creates delivery orders when payments are completed
- Maintains data consistency between orders and delivery orders

### Providers

#### DeliveryOrderProvider
- Manages delivery order state
- Handles loading and error states
- Provides filtered data for different tabs
- Manages user interactions

### Models

#### DeliveryOrderModel
- Complete data model for delivery orders
- Status management and validation
- Helper methods for status checks
- Serialization for Firestore

### Firestore Collections

#### delivery_orders
- Stores all delivery order data
- Indexed for efficient querying
- Real-time listeners for updates

#### Indexes
```json
{
  "collectionGroup": "delivery_orders",
  "queryScope": "COLLECTION",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```

## Usage Flow

### 1. Order Completion
1. Distributor completes payment for an order
2. Order status is updated to "completed"
3. Delivery order is automatically created
4. Delivery order appears in Available tab for transporters

### 2. Delivery Acceptance
1. Transporter views available deliveries
2. Transporter accepts a delivery order
3. Delivery order status changes to "accepted"
4. Delivery appears in Active tab

### 3. Delivery Process
1. Transporter starts delivery (status: "in_transit")
2. Transporter completes delivery (status: "delivered")
3. Delivery appears in Completed tab
4. Transporter earns delivery fee

## Error Handling

### Network Issues
- Graceful handling of connection failures
- Retry mechanisms for failed operations
- Offline state management

### Data Validation
- Input validation for all user actions
- Status transition validation
- Error messages for invalid operations

### Error Recovery
- Automatic retry for failed operations
- User-friendly error messages
- Fallback states for missing data

## Security

### Data Access
- Transporters can only access their own deliveries
- Delivery orders are protected by Firestore security rules
- User authentication required for all operations

### Status Transitions
- Validated status transitions prevent invalid states
- Audit trail for all status changes
- Timestamp tracking for accountability

## Future Enhancements

### Planned Features
- Route optimization and navigation
- Real-time location tracking
- Delivery time estimates
- Rating and feedback system
- Earnings dashboard and analytics
- Push notifications for new deliveries
- Offline mode support

### Integration Opportunities
- Maps integration for route planning
- Payment processing for delivery fees
- Communication system between parties
- Document management for delivery receipts 