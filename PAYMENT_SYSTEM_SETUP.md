# Payment System Setup Guide

## Overview

This document explains the complete payment system implementation for FarmLink, including Stripe integration, order management, and payment status tracking without webhooks.

## Features Implemented

### ✅ **Complete Order & Payment System**
- **Order Creation**: Automatic order creation when distributor places order
- **Stripe Integration**: Payment intent creation and management
- **Payment Status Tracking**: Real-time payment status monitoring
- **Order Management**: Complete order lifecycle management
- **Location Tracking**: Pickup and distributor location management

### ✅ **Payment Flow**
1. **Bidding Ends**: Auction expires, highest bidder can place order
2. **Order Creation**: Order created with payment intent
3. **Payment Processing**: Distributor completes payment
4. **Status Tracking**: Automatic payment status monitoring
5. **Order Confirmation**: Order confirmed upon successful payment

## Database Schema

### **Orders Collection**
```javascript
{
  "id": "string",                    // Unique order ID
  "cropId": "string",                // Reference to crop
  "distributorId": "string",         // Distributor user ID
  "distributorName": "string",       // Distributor display name
  "distributorEmail": "string",      // Distributor email
  "distributorPhone": "string",      // Distributor phone
  "distributorLocation": "string",   // Distributor pickup location
  "farmerId": "string",              // Farmer user ID
  "farmerName": "string",            // Farmer display name
  "farmerEmail": "string",           // Farmer email
  "farmerPhone": "string",           // Farmer phone
  "cropName": "string",              // Crop name
  "quantity": "number",              // Quantity in kg
  "finalPrice": "number",            // Final bid amount
  "pickupLocation": "string",        // Crop pickup location
  "paymentStatus": "string",         // 'pending', 'processing', 'completed', 'failed'
  "orderStatus": "string",           // 'pending', 'confirmed', 'completed', 'cancelled'
  "stripePaymentIntentId": "string", // Stripe payment intent ID
  "stripeClientSecret": "string",    // Stripe client secret
  "createdAt": "timestamp",          // Order creation time
  "paymentCompletedAt": "timestamp", // Payment completion time
  "confirmedAt": "timestamp",        // Order confirmation time
  "completedAt": "timestamp",        // Order completion time
  "lastPaymentActivity": "timestamp" // Last payment activity
}
```

## Payment Status Tracking

### **How It Works (Without Webhooks)**
1. **Activity Tracking**: System tracks last payment activity timestamp
2. **Status Polling**: Checks payment status every 30 seconds
3. **Stripe API Calls**: Direct API calls to Stripe for status updates
4. **Automatic Updates**: Updates order status based on Stripe response

### **Payment Status Flow**
```
pending → processing → completed
    ↓
failed (if payment fails)
```

### **Status Detection Logic**
- **Last Activity Check**: If no activity for 5+ minutes, check with Stripe
- **Stripe Status Mapping**: Maps Stripe status to internal status
- **Real-time Updates**: Updates Firestore with latest status

## Stripe Integration

### **Configuration**
```dart
// In payment_service.dart
static const String _stripeSecretKey = 'sk_test_your_stripe_secret_key_here';
static const String _stripePublishableKey = 'pk_test_your_stripe_publishable_key_here';
```

### **Payment Intent Creation**
```dart
// Creates payment intent with order metadata
{
  'amount': (order.finalPrice * 100).round().toString(), // Convert to cents
  'currency': 'inr',
  'metadata[order_id]': order.id,
  'metadata[crop_id]': order.cropId,
  'metadata[distributor_id]': order.distributorId,
  'metadata[farmer_id]': order.farmerId,
}
```

### **Status Checking**
```dart
// Checks payment intent status with Stripe
GET https://api.stripe.com/v1/payment_intents/{paymentIntentId}
```

## User Flow

### **Distributor Flow**
1. **Browse Marketplace**: View available crops for bidding
2. **Place Bid**: Bid on crops (one bid per user per crop)
3. **Update Bid**: Increase bid amount if needed
4. **Win Auction**: Become highest bidder when auction expires
5. **Place Order**: Click "Place Order" button
6. **Enter Location**: Provide distributor location for pickup
7. **Payment**: Complete payment through Stripe
8. **Confirmation**: Order confirmed upon successful payment

### **Payment Screen Features**
- **Order Details**: Complete order information display
- **Payment Status**: Real-time payment status tracking
- **Payment Form**: Stripe payment integration
- **Activity Tracking**: Automatic payment activity monitoring
- **Success Handling**: Automatic success detection and navigation

## Implementation Details

### **Services Created**

#### **1. PaymentService**
- Stripe API integration
- Payment intent creation
- Payment status tracking
- Activity monitoring

#### **2. OrderService**
- Order creation and management
- Payment integration
- Status updates
- Statistics and reporting

### **Models Enhanced**

#### **OrderModel**
- Complete order information
- Payment details
- Location tracking
- Status management

### **Screens Created**

#### **PaymentScreen**
- Payment form integration
- Status tracking
- Order details display
- Success handling

## Setup Instructions

### **1. Stripe Configuration**
1. Create Stripe account
2. Get API keys (test and live)
3. Update `payment_service.dart` with your keys
4. Configure webhook endpoints (optional)

### **2. Firebase Setup**
1. Enable Firestore
2. Set up security rules for orders collection
3. Configure indexes for queries

### **3. Dependencies**
```yaml
dependencies:
  http: ^1.2.0  # For Stripe API calls
```

### **4. Environment Variables**
```dart
// Replace with your actual keys
static const String _stripeSecretKey = 'sk_test_your_key_here';
static const String _stripePublishableKey = 'pk_test_your_key_here';
```

## Security Considerations

### **API Key Security**
- Store keys securely (use environment variables)
- Use test keys for development
- Rotate keys regularly
- Never expose secret keys in client code

### **Firestore Security Rules**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /orders/{orderId} {
      allow read: if request.auth != null && 
        (request.auth.uid == resource.data.distributorId || 
         request.auth.uid == resource.data.farmerId);
      allow write: if request.auth != null && 
        request.auth.uid == resource.data.distributorId;
    }
  }
}
```

## Testing

### **Test Scenarios**
1. **Successful Payment**: Complete payment flow
2. **Failed Payment**: Handle payment failures
3. **Status Tracking**: Verify automatic status updates
4. **Order Creation**: Test order creation with payment
5. **Location Validation**: Test location requirements

### **Test Data**
```dart
// Test payment intent
{
  'amount': 5000, // ₹50.00
  'currency': 'inr',
  'payment_method_types': ['card'],
  'metadata': {
    'order_id': 'test_order_123',
    'crop_id': 'test_crop_456'
  }
}
```

## Production Considerations

### **1. Stripe Production Keys**
- Switch to live keys for production
- Configure webhook endpoints
- Set up proper error handling

### **2. Monitoring**
- Monitor payment success rates
- Track failed payments
- Set up alerts for payment issues

### **3. Performance**
- Optimize status checking frequency
- Implement caching for payment status
- Monitor API call limits

### **4. Compliance**
- Ensure PCI compliance
- Follow data protection regulations
- Implement proper logging

## Troubleshooting

### **Common Issues**

#### **1. Payment Intent Creation Fails**
- Check Stripe API keys
- Verify amount format (cents)
- Check network connectivity

#### **2. Status Not Updating**
- Verify payment intent ID
- Check last activity timestamp
- Monitor API response

#### **3. Order Creation Fails**
- Check Firestore permissions
- Verify user authentication
- Check required fields

### **Debug Steps**
1. Check console logs for errors
2. Verify Stripe dashboard for payment status
3. Check Firestore for order data
4. Monitor network requests

## Future Enhancements

### **Planned Features**
1. **Webhook Integration**: Real-time payment notifications
2. **Multiple Payment Methods**: Support for UPI, net banking
3. **Payment Analytics**: Detailed payment reports
4. **Refund Handling**: Automatic refund processing
5. **Subscription Payments**: Recurring payment support

### **Performance Optimizations**
1. **Caching**: Cache payment status
2. **Batch Processing**: Batch status updates
3. **Background Sync**: Background payment monitoring
4. **Offline Support**: Offline payment queue

## Support

For issues or questions:
1. Check Stripe documentation
2. Review Firebase logs
3. Test with Stripe test cards
4. Contact development team

---

**Note**: This implementation provides a complete payment system without webhooks, using direct API calls and status polling for real-time payment tracking.
