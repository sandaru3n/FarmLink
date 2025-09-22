import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String id;
  final String consumerId;
  final String consumerName;
  final String charityId;
  final String charityName;
  final List<DonationItem> items;
  final double totalValue;
  final String status; // 'pending', 'confirmed', 'picked_up', 'completed', 'cancelled'
  final String? notes;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? pickedUpAt;
  final DateTime? completedAt;
  final String? pickupAddress;
  final String? contactPhone;
  final String? taxReceiptId;

  DonationModel({
    required this.id,
    required this.consumerId,
    required this.consumerName,
    required this.charityId,
    required this.charityName,
    required this.items,
    required this.totalValue,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.confirmedAt,
    this.pickedUpAt,
    this.completedAt,
    this.pickupAddress,
    this.contactPhone,
    this.taxReceiptId,
  });

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] ?? '',
      consumerId: map['consumerId'] ?? '',
      consumerName: map['consumerName'] ?? '',
      charityId: map['charityId'] ?? '',
      charityName: map['charityName'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((item) => DonationItem.fromMap(item))
          .toList(),
      totalValue: (map['totalValue'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      confirmedAt: map['confirmedAt'] != null 
          ? (map['confirmedAt'] as Timestamp).toDate() 
          : null,
      pickedUpAt: map['pickedUpAt'] != null 
          ? (map['pickedUpAt'] as Timestamp).toDate() 
          : null,
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] as Timestamp).toDate() 
          : null,
      pickupAddress: map['pickupAddress'],
      contactPhone: map['contactPhone'],
      taxReceiptId: map['taxReceiptId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumerId': consumerId,
      'consumerName': consumerName,
      'charityId': charityId,
      'charityName': charityName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalValue': totalValue,
      'status': status,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'pickedUpAt': pickedUpAt != null ? Timestamp.fromDate(pickedUpAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'pickupAddress': pickupAddress,
      'contactPhone': contactPhone,
      'taxReceiptId': taxReceiptId,
    };
  }

  DonationModel copyWith({
    String? id,
    String? consumerId,
    String? consumerName,
    String? charityId,
    String? charityName,
    List<DonationItem>? items,
    double? totalValue,
    String? status,
    String? notes,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? pickedUpAt,
    DateTime? completedAt,
    String? pickupAddress,
    String? contactPhone,
    String? taxReceiptId,
  }) {
    return DonationModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      consumerName: consumerName ?? this.consumerName,
      charityId: charityId ?? this.charityId,
      charityName: charityName ?? this.charityName,
      items: items ?? this.items,
      totalValue: totalValue ?? this.totalValue,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      completedAt: completedAt ?? this.completedAt,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      contactPhone: contactPhone ?? this.contactPhone,
      taxReceiptId: taxReceiptId ?? this.taxReceiptId,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Pending Confirmation';
      case 'confirmed':
        return 'Confirmed';
      case 'picked_up':
        return 'Picked Up';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get isCompleted => status == 'completed';
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
}

class DonationItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final double quantity; // in kg
  final double estimatedValue; // estimated value per kg
  final String unit; // kg, pieces, etc.
  final String? notes;

  DonationItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.estimatedValue,
    this.unit = 'kg',
    this.notes,
  });

  factory DonationItem.fromMap(Map<String, dynamic> map) {
    return DonationItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      estimatedValue: (map['estimatedValue'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'kg',
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'estimatedValue': estimatedValue,
      'unit': unit,
      'notes': notes,
    };
  }

  double get totalValue => quantity * estimatedValue;
}
