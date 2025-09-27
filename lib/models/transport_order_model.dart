import 'package:cloud_firestore/cloud_firestore.dart';

class TransportOrderModel {
  final String id;
  final String deliveryOrderId; // Reference to the delivery order
  final String orderId; // Reference to the original order
  final String cropImageUrl;
  final String cropName;
  final double quantity;
  final String farmerName;
  final String pickupLocation;
  final String distributorName;
  final String distributorLocation;
  final double price;
  final String transporterId;
  final String transporterName;
  final String status; // 'accepted', 'in_transit', 'delivered', 'cancelled'
  final DateTime createdAt;
  final DateTime acceptedAt;
  final DateTime? inTransitAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;
  final String? notes;
  final double? deliveryFee;
  final String? estimatedDeliveryTime;
  final String? actualDeliveryTime;
  final String? scheduledDay; // Day when delivery is scheduled (Mon, Tue, etc.)
  final DateTime? scheduledDate; // Specific date when delivery is scheduled
  final String? scheduledTime; // Specific time when delivery is scheduled (e.g., "09:00", "14:30")
  final String? deliveryLocation; // Specific delivery location/address

  TransportOrderModel({
    required this.id,
    required this.deliveryOrderId,
    required this.orderId,
    required this.cropImageUrl,
    required this.cropName,
    required this.quantity,
    required this.farmerName,
    required this.pickupLocation,
    required this.distributorName,
    required this.distributorLocation,
    required this.price,
    required this.transporterId,
    required this.transporterName,
    this.status = 'accepted',
    required this.createdAt,
    required this.acceptedAt,
    this.inTransitAt,
    this.deliveredAt,
    this.cancelledAt,
    this.cancellationReason,
    this.notes,
    this.deliveryFee,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.scheduledDay,
    this.scheduledDate,
    this.scheduledTime,
    this.deliveryLocation,
  });

  factory TransportOrderModel.fromMap(Map<String, dynamic> map) {
    return TransportOrderModel(
      id: map['id'] ?? '',
      deliveryOrderId: map['deliveryOrderId'] ?? '',
      orderId: map['orderId'] ?? '',
      cropImageUrl: map['cropImageUrl'] ?? '',
      cropName: map['cropName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      farmerName: map['farmerName'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      distributorName: map['distributorName'] ?? '',
      distributorLocation: map['distributorLocation'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      transporterId: map['transporterId'] ?? '',
      transporterName: map['transporterName'] ?? '',
      status: map['status'] ?? 'accepted',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: (map['acceptedAt'] as Timestamp).toDate(),
      inTransitAt: map['inTransitAt'] != null
          ? (map['inTransitAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      cancelledAt: map['cancelledAt'] != null
          ? (map['cancelledAt'] as Timestamp).toDate()
          : null,
      cancellationReason: map['cancellationReason'],
      notes: map['notes'],
      deliveryFee: map['deliveryFee']?.toDouble(),
      estimatedDeliveryTime: map['estimatedDeliveryTime'],
      actualDeliveryTime: map['actualDeliveryTime'],
      scheduledDay: map['scheduledDay'],
      scheduledDate: map['scheduledDate'] != null
          ? (map['scheduledDate'] as Timestamp).toDate()
          : null,
      scheduledTime: map['scheduledTime'],
      deliveryLocation: map['deliveryLocation'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryOrderId': deliveryOrderId,
      'orderId': orderId,
      'cropImageUrl': cropImageUrl,
      'cropName': cropName,
      'quantity': quantity,
      'farmerName': farmerName,
      'pickupLocation': pickupLocation,
      'distributorName': distributorName,
      'distributorLocation': distributorLocation,
      'price': price,
      'transporterId': transporterId,
      'transporterName': transporterName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': Timestamp.fromDate(acceptedAt),
      'inTransitAt': inTransitAt != null ? Timestamp.fromDate(inTransitAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancellationReason': cancellationReason,
      'notes': notes,
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'actualDeliveryTime': actualDeliveryTime,
      'scheduledDay': scheduledDay,
      'scheduledDate': scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'scheduledTime': scheduledTime,
      'deliveryLocation': deliveryLocation,
    };
  }

  TransportOrderModel copyWith({
    String? id,
    String? deliveryOrderId,
    String? orderId,
    String? cropImageUrl,
    String? cropName,
    double? quantity,
    String? farmerName,
    String? pickupLocation,
    String? distributorName,
    String? distributorLocation,
    double? price,
    String? transporterId,
    String? transporterName,
    String? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? inTransitAt,
    DateTime? deliveredAt,
    DateTime? cancelledAt,
    String? cancellationReason,
    String? notes,
    double? deliveryFee,
    String? estimatedDeliveryTime,
    String? actualDeliveryTime,
    String? scheduledDay,
    DateTime? scheduledDate,
    String? scheduledTime,
    String? deliveryLocation,
  }) {
    return TransportOrderModel(
      id: id ?? this.id,
      deliveryOrderId: deliveryOrderId ?? this.deliveryOrderId,
      orderId: orderId ?? this.orderId,
      cropImageUrl: cropImageUrl ?? this.cropImageUrl,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      farmerName: farmerName ?? this.farmerName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      distributorName: distributorName ?? this.distributorName,
      distributorLocation: distributorLocation ?? this.distributorLocation,
      price: price ?? this.price,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      inTransitAt: inTransitAt ?? this.inTransitAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      notes: notes ?? this.notes,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      scheduledDay: scheduledDay ?? this.scheduledDay,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
    );
  }

  // Getters for status checks
  bool get isAccepted => status == 'accepted';
  bool get isInTransit => status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get canBeInTransit => status == 'accepted';
  bool get canBeDelivered => status == 'accepted' || status == 'in_transit';
  bool get canBeCancelled => status == 'accepted' || status == 'in_transit';
} 