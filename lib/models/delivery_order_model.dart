import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryOrderModel {
  final String id;
  final String orderId; // Reference to the original order
  final String cropImageUrl;
  final String cropName;
  final double quantity;
  final String farmerName;
  final String pickupLocation;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String distributorName;
  final String distributorLocation;
  final double? distributorLatitude;
  final double? distributorLongitude;
  final double price;
  final String status; // 'pending', 'accepted', 'rejected', 'in_transit', 'delivered'
  final String? transporterId;
  final String? transporterName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  final DateTime? deliveredAt;
  final String? rejectionReason;
  
  // Additional fields from the order
  final String cropId;
  final String distributorId;
  final String distributorEmail;
  final String distributorPhone;
  final String farmerId;
  final String farmerEmail;
  final String farmerPhone;
  final String? stripePaymentIntentId;
  final String? stripeClientSecret;
  final DateTime? paymentCompletedAt;
  final DateTime? confirmedAt;
  final DateTime? lastPaymentActivity;
  
  // Transport-specific fields
  final double? deliveryFee;
  final String? estimatedDeliveryTime;
  final String? actualDeliveryTime;
  final String? notes;
  final DateTime? inTransitAt;

  DeliveryOrderModel({
    required this.id,
    required this.orderId,
    required this.cropImageUrl,
    required this.cropName,
    required this.quantity,
    required this.farmerName,
    required this.pickupLocation,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.distributorName,
    required this.distributorLocation,
    this.distributorLatitude,
    this.distributorLongitude,
    required this.price,
    this.status = 'pending',
    this.transporterId,
    this.transporterName,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.deliveredAt,
    this.rejectionReason,
    // Additional fields
    this.cropId = '',
    this.distributorId = '',
    this.distributorEmail = '',
    this.distributorPhone = '',
    this.farmerId = '',
    this.farmerEmail = '',
    this.farmerPhone = '',
    this.stripePaymentIntentId,
    this.stripeClientSecret,
    this.paymentCompletedAt,
    this.confirmedAt,
    this.lastPaymentActivity,
    // Transport-specific fields
    this.deliveryFee,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.notes,
    this.inTransitAt,
  });

  factory DeliveryOrderModel.fromMap(Map<String, dynamic> map) {
    return DeliveryOrderModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      cropImageUrl: map['cropImageUrl'] ?? '',
      cropName: map['cropName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      farmerName: map['farmerName'] ?? '',
      pickupLocation: map['pickupLocation'] ?? '',
      pickupLatitude: map['pickupLatitude']?.toDouble(),
      pickupLongitude: map['pickupLongitude']?.toDouble(),
      distributorName: map['distributorName'] ?? '',
      distributorLocation: map['distributorLocation'] ?? '',
      distributorLatitude: map['distributorLatitude']?.toDouble(),
      distributorLongitude: map['distributorLongitude']?.toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      transporterId: map['transporterId'],
      transporterName: map['transporterName'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      rejectedAt: map['rejectedAt'] != null
          ? (map['rejectedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      rejectionReason: map['rejectionReason'],
      // Additional fields
      cropId: map['cropId'] ?? '',
      distributorId: map['distributorId'] ?? '',
      distributorEmail: map['distributorEmail'] ?? '',
      distributorPhone: map['distributorPhone'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerEmail: map['farmerEmail'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      stripePaymentIntentId: map['stripePaymentIntentId'],
      stripeClientSecret: map['stripeClientSecret'],
      paymentCompletedAt: map['paymentCompletedAt'] != null
          ? (map['paymentCompletedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
      lastPaymentActivity: map['lastPaymentActivity'] != null
          ? (map['lastPaymentActivity'] as Timestamp).toDate()
          : null,
      // Transport-specific fields
      deliveryFee: map['deliveryFee'] != null ? (map['deliveryFee'] as double) : null,
      estimatedDeliveryTime: map['estimatedDeliveryTime'],
      actualDeliveryTime: map['actualDeliveryTime'],
      notes: map['notes'],
      inTransitAt: map['inTransitAt'] != null ? (map['inTransitAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'cropImageUrl': cropImageUrl,
      'cropName': cropName,
      'quantity': quantity,
      'farmerName': farmerName,
      'pickupLocation': pickupLocation,
      'pickupLatitude': pickupLatitude,
      'pickupLongitude': pickupLongitude,
      'distributorName': distributorName,
      'distributorLocation': distributorLocation,
      'distributorLatitude': distributorLatitude,
      'distributorLongitude': distributorLongitude,
      'price': price,
      'status': status,
      'transporterId': transporterId,
      'transporterName': transporterName,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'rejectionReason': rejectionReason,
      // Additional fields
      'cropId': cropId,
      'distributorId': distributorId,
      'distributorEmail': distributorEmail,
      'distributorPhone': distributorPhone,
      'farmerId': farmerId,
      'farmerEmail': farmerEmail,
      'farmerPhone': farmerPhone,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeClientSecret': stripeClientSecret,
      'paymentCompletedAt': paymentCompletedAt != null ? Timestamp.fromDate(paymentCompletedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'lastPaymentActivity': lastPaymentActivity != null ? Timestamp.fromDate(lastPaymentActivity!) : null,
      // Transport-specific fields
      'deliveryFee': deliveryFee,
      'estimatedDeliveryTime': estimatedDeliveryTime,
      'actualDeliveryTime': actualDeliveryTime,
      'notes': notes,
      'inTransitAt': inTransitAt != null ? Timestamp.fromDate(inTransitAt!) : null,
    };
  }

  DeliveryOrderModel copyWith({
    String? id,
    String? orderId,
    String? cropImageUrl,
    String? cropName,
    double? quantity,
    String? farmerName,
    String? pickupLocation,
    double? pickupLatitude,
    double? pickupLongitude,
    String? distributorName,
    String? distributorLocation,
    double? distributorLatitude,
    double? distributorLongitude,
    double? price,
    String? status,
    String? transporterId,
    String? transporterName,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    DateTime? deliveredAt,
    String? rejectionReason,
    // Additional fields
    String? cropId,
    String? distributorId,
    String? distributorEmail,
    String? distributorPhone,
    String? farmerId,
    String? farmerEmail,
    String? farmerPhone,
    String? stripePaymentIntentId,
    String? stripeClientSecret,
    DateTime? paymentCompletedAt,
    DateTime? confirmedAt,
    DateTime? lastPaymentActivity,
    // Transport-specific fields
    double? deliveryFee,
    String? estimatedDeliveryTime,
    String? actualDeliveryTime,
    String? notes,
    DateTime? inTransitAt,
  }) {
    return DeliveryOrderModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      cropImageUrl: cropImageUrl ?? this.cropImageUrl,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      farmerName: farmerName ?? this.farmerName,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      distributorName: distributorName ?? this.distributorName,
      distributorLocation: distributorLocation ?? this.distributorLocation,
      distributorLatitude: distributorLatitude ?? this.distributorLatitude,
      distributorLongitude: distributorLongitude ?? this.distributorLongitude,
      price: price ?? this.price,
      status: status ?? this.status,
      transporterId: transporterId ?? this.transporterId,
      transporterName: transporterName ?? this.transporterName,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      // Additional fields
      cropId: cropId ?? this.cropId,
      distributorId: distributorId ?? this.distributorId,
      distributorEmail: distributorEmail ?? this.distributorEmail,
      distributorPhone: distributorPhone ?? this.distributorPhone,
      farmerId: farmerId ?? this.farmerId,
      farmerEmail: farmerEmail ?? this.farmerEmail,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeClientSecret: stripeClientSecret ?? this.stripeClientSecret,
      paymentCompletedAt: paymentCompletedAt ?? this.paymentCompletedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      lastPaymentActivity: lastPaymentActivity ?? this.lastPaymentActivity,
      // Transport-specific fields
      deliveryFee: deliveryFee ?? this.deliveryFee,
      estimatedDeliveryTime: estimatedDeliveryTime ?? this.estimatedDeliveryTime,
      actualDeliveryTime: actualDeliveryTime ?? this.actualDeliveryTime,
      notes: notes ?? this.notes,
      inTransitAt: inTransitAt ?? this.inTransitAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isInTransit => status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get canBeAccepted => status == 'pending';
  bool get canBeRejected => status == 'pending';
  bool get canBeDelivered => status == 'accepted' || status == 'in_transit';
} 