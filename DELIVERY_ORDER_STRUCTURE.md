# Delivery Order Structure - Simplified

## Overview

We have simplified the delivery system by using only **Delivery Orders** instead of having both Delivery Orders and Transport Orders. This eliminates redundancy and confusion.

## Single Collection: `delivery_orders`

### Data Flow

1. **Orders Collection** (`orders`)
   - Contains orders with `paymentStatus: "completed"`
   - These appear in the "Available" tab for transporters

2. **Delivery Orders Collection** (`delivery_orders`)
   - Created when transporter accepts an order
   - Contains all order data + transporter info + delivery tracking
   - These appear in "Active" and "Completed" tabs

### Delivery Order Status Flow

```
pending → accepted → in_transit → delivered
```

- **pending**: Available for transporters to accept
- **accepted**: Transporter has accepted the delivery
- **in_transit**: Transporter has started the delivery
- **delivered**: Delivery completed successfully
- **rejected**: Transporter rejected the delivery

### Key Fields in Delivery Orders

#### Order Information
- `orderId`: Reference to original order
- `cropName`, `cropImageUrl`, `quantity`
- `farmerName`, `pickupLocation`
- `distributorName`, `distributorLocation`
- `price`: Original order price

#### Transporter Information
- `transporterId`, `transporterName`
- `acceptedAt`: When transporter accepted

#### Delivery Tracking
- `status`: Current delivery status
- `createdAt`: When delivery order was created
- `inTransitAt`: When delivery started
- `deliveredAt`: When delivery completed
- `rejectedAt`: When delivery was rejected

#### Transport-Specific Fields
- `deliveryFee`: Calculated delivery fee (10% of order price)
- `estimatedDeliveryTime`: Estimated delivery duration
- `actualDeliveryTime`: Actual delivery time
- `notes`: Transporter notes

#### Original Order Data
- All fields from the original order (cropId, distributorId, etc.)
- Payment information (stripePaymentIntentId, etc.)
- Timestamps (paymentCompletedAt, confirmedAt, etc.)

## Benefits of Simplified Structure

✅ **Single Source of Truth**: All delivery data in one collection  
✅ **No Data Duplication**: Eliminates sync issues  
✅ **Simpler Queries**: No need to join multiple collections  
✅ **Easier Maintenance**: Less code to maintain  
✅ **Better Performance**: Fewer database reads/writes  
✅ **Clearer Logic**: One collection, one status flow  

## Usage Examples

### Get Available Deliveries
```dart
// Query orders collection for completed payments
.where('paymentStatus', isEqualTo: 'completed')
```

### Get Transporter's Active Deliveries
```dart
// Query delivery_orders collection
.where('transporterId', isEqualTo: transporterId)
.where('status', whereIn: ['accepted', 'in_transit'])
```

### Get Completed Deliveries
```dart
// Query delivery_orders collection
.where('transporterId', isEqualTo: transporterId)
.where('status', isEqualTo: 'delivered')
```

## Migration from Old Structure

The old structure had:
- `delivery_orders` collection
- `transport_orders` collection (redundant)

The new structure has:
- `delivery_orders` collection (enhanced with transport fields)
- No `transport_orders` collection needed

All transport-specific functionality is now integrated into the delivery orders collection. 