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
    );
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActive => !isExpired && status == 'active';
  
  Duration get timeLeft {
    if (isExpired) return Duration.zero;
    return endDate.difference(DateTime.now());
  }

  BidModel? get highestBid {
    if (bids.isEmpty) return null;
    bids.sort((a, b) => b.amount.compareTo(a.amount));
    return bids.first;
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
}
