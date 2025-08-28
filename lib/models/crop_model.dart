import 'package:cloud_firestore/cloud_firestore.dart';

class CropModel {
  final String id;
  final String farmerId;
  final String cropName;
  final double quantity; // in kg
  final String imageUrl;
  final double minBidPrice;
  final DateTime startDate;
  final DateTime endDate;
  final String pickupLocation;
  final String status; // 'active', 'expired', 'sold'
  final DateTime createdAt;
  final List<BidModel> bids;
  final OrderModel? order; // New field for order

  CropModel({
    required this.id,
    required this.farmerId,
    required this.cropName,
    required this.quantity,
    required this.imageUrl,
    required this.minBidPrice,
    required this.startDate,
    required this.endDate,
    required this.pickupLocation,
    this.status = 'active',
    required this.createdAt,
    this.bids = const [],
    this.order,
  });

  factory CropModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CropModel(
      id: doc.id,
      farmerId: data['farmerId'] ?? '',
      cropName: data['cropName'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      minBidPrice: (data['minBidPrice'] ?? 0).toDouble(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      pickupLocation: data['pickupLocation'] ?? '',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      bids: (data['bids'] as List<dynamic>? ?? [])
          .map((bid) => BidModel.fromMap(bid))
          .toList(),
      order: data['order'] != null ? OrderModel.fromMap(data['order']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'farmerId': farmerId,
      'cropName': cropName,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'minBidPrice': minBidPrice,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'pickupLocation': pickupLocation,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'bids': bids.map((bid) => bid.toMap()).toList(),
      'order': order?.toMap(),
    };
  }

  CropModel copyWith({
    String? id,
    String? farmerId,
    String? cropName,
    double? quantity,
    String? imageUrl,
    double? minBidPrice,
    DateTime? startDate,
    DateTime? endDate,
    String? pickupLocation,
    String? status,
    DateTime? createdAt,
    List<BidModel>? bids,
    OrderModel? order,
  }) {
    return CropModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      cropName: cropName ?? this.cropName,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      minBidPrice: minBidPrice ?? this.minBidPrice,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      bids: bids ?? this.bids,
      order: order ?? this.order,
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => !isExpired && status == 'active';
  bool get isSold => order != null;
  
  Duration get timeLeft {
    if (isExpired) return Duration.zero;
    return endDate.difference(DateTime.now());
  }

  BidModel? get highestBid {
    if (bids.isEmpty) return null;
    bids.sort((a, b) => b.amount.compareTo(a.amount));
    return bids.first;
  }

  // Check if a user has already bid on this crop
  bool hasUserBid(String userId) {
    return bids.any((bid) => bid.distributorId == userId);
  }

  // Get user's current bid
  BidModel? getUserBid(String userId) {
    try {
      return bids.firstWhere((bid) => bid.distributorId == userId);
    } catch (e) {
      return null;
    }
  }

  // Check if user is the highest bidder
  bool isUserHighestBidder(String userId) {
    final highest = highestBid;
    return highest != null && highest.distributorId == userId;
  }
}

class BidModel {
  final String id;
  final String distributorId;
  final String distributorName;
  final double amount;
  final DateTime createdAt;

  BidModel({
    required this.id,
    required this.distributorId,
    required this.distributorName,
    required this.amount,
    required this.createdAt,
  });

  factory BidModel.fromMap(Map<String, dynamic> map) {
    return BidModel(
      id: map['id'] ?? '',
      distributorId: map['distributorId'] ?? '',
      distributorName: map['distributorName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'distributorId': distributorId,
      'distributorName': distributorName,
      'amount': amount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  BidModel copyWith({
    String? id,
    String? distributorId,
    String? distributorName,
    double? amount,
    DateTime? createdAt,
  }) {
    return BidModel(
      id: id ?? this.id,
      distributorId: distributorId ?? this.distributorId,
      distributorName: distributorName ?? this.distributorName,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OrderModel {
  final String id;
  final String cropId;
  final String distributorId;
  final String distributorName;
  final String distributorEmail;
  final String distributorPhone;
  final String distributorLocation;
  final String farmerId;
  final String farmerName;
  final String farmerEmail;
  final String farmerPhone;
  final String cropName;
  final String cropImageUrl;
  final double quantity;
  final double finalPrice;
  final String pickupLocation;
  final String paymentStatus; // 'pending', 'processing', 'completed', 'failed'
  final String orderStatus; // 'pending', 'confirmed', 'completed', 'cancelled'
  final String? stripePaymentIntentId;
  final String? stripeClientSecret;
  final DateTime createdAt;
  final DateTime? paymentCompletedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime? lastPaymentActivity;

  OrderModel({
    required this.id,
    required this.cropId,
    required this.distributorId,
    required this.distributorName,
    required this.distributorEmail,
    required this.distributorPhone,
    required this.distributorLocation,
    required this.farmerId,
    required this.farmerName,
    required this.farmerEmail,
    required this.farmerPhone,
    required this.cropName,
    required this.cropImageUrl,
    required this.quantity,
    required this.finalPrice,
    required this.pickupLocation,
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.stripePaymentIntentId,
    this.stripeClientSecret,
    required this.createdAt,
    this.paymentCompletedAt,
    this.confirmedAt,
    this.completedAt,
    this.lastPaymentActivity,
  });

    factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      cropId: map['cropId'] ?? '',
      distributorId: map['distributorId'] ?? '',
      distributorName: map['distributorName'] ?? '',
      distributorEmail: map['distributorEmail'] ?? '',
      distributorPhone: map['distributorPhone'] ?? '',
      distributorLocation: map['distributorLocation'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      farmerEmail: map['farmerEmail'] ?? '',
      farmerPhone: map['farmerPhone'] ?? '',
      cropName: map['cropName'] ?? '',
      cropImageUrl: map['cropImageUrl'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      finalPrice: (map['finalPrice'] ?? 0).toDouble(),
      pickupLocation: map['pickupLocation'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      orderStatus: map['orderStatus'] ?? 'pending',
      stripePaymentIntentId: map['stripePaymentIntentId'],
      stripeClientSecret: map['stripeClientSecret'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      paymentCompletedAt: map['paymentCompletedAt'] != null
          ? (map['paymentCompletedAt'] as Timestamp).toDate()
          : null,
      confirmedAt: map['confirmedAt'] != null
          ? (map['confirmedAt'] as Timestamp).toDate()
          : null,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
      lastPaymentActivity: map['lastPaymentActivity'] != null
          ? (map['lastPaymentActivity'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cropId': cropId,
      'distributorId': distributorId,
      'distributorName': distributorName,
      'distributorEmail': distributorEmail,
      'distributorPhone': distributorPhone,
      'distributorLocation': distributorLocation,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'farmerEmail': farmerEmail,
      'farmerPhone': farmerPhone,
      'cropName': cropName,
      'cropImageUrl': cropImageUrl,
      'quantity': quantity,
      'finalPrice': finalPrice,
      'pickupLocation': pickupLocation,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeClientSecret': stripeClientSecret,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentCompletedAt': paymentCompletedAt != null ? Timestamp.fromDate(paymentCompletedAt!) : null,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'lastPaymentActivity': lastPaymentActivity != null ? Timestamp.fromDate(lastPaymentActivity!) : null,
    };
  }

  OrderModel copyWith({
    String? id,
    String? cropId,
    String? distributorId,
    String? distributorName,
    String? distributorEmail,
    String? distributorPhone,
    String? distributorLocation,
    String? farmerId,
    String? farmerName,
    String? farmerEmail,
    String? farmerPhone,
    String? cropName,
    String? cropImageUrl,
    double? quantity,
    double? finalPrice,
    String? pickupLocation,
    String? paymentStatus,
    String? orderStatus,
    String? stripePaymentIntentId,
    String? stripeClientSecret,
    DateTime? createdAt,
    DateTime? paymentCompletedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? lastPaymentActivity,
  }) {
    return OrderModel(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      distributorId: distributorId ?? this.distributorId,
      distributorName: distributorName ?? this.distributorName,
      distributorEmail: distributorEmail ?? this.distributorEmail,
      distributorPhone: distributorPhone ?? this.distributorPhone,
      distributorLocation: distributorLocation ?? this.distributorLocation,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      farmerEmail: farmerEmail ?? this.farmerEmail,
      farmerPhone: farmerPhone ?? this.farmerPhone,
      cropName: cropName ?? this.cropName,
      cropImageUrl: cropImageUrl ?? this.cropImageUrl,
      quantity: quantity ?? this.quantity,
      finalPrice: finalPrice ?? this.finalPrice,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeClientSecret: stripeClientSecret ?? this.stripeClientSecret,
      createdAt: createdAt ?? this.createdAt,
      paymentCompletedAt: paymentCompletedAt ?? this.paymentCompletedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
      lastPaymentActivity: lastPaymentActivity ?? this.lastPaymentActivity,
    );
  }
}
