import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String distributorId;
  final String productName;
  final String imageUrl;
  final double quantity; // in kg
  final double pricePerKg;
  final DateTime createdAt;
  final bool isAvailable;
  final double reorderLevel; // threshold in kg for low-stock alerts
  final DateTime lastUpdatedAt;
  final double initialQuantity; // baseline for percentage calculations

  ProductModel({
    required this.id,
    required this.distributorId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.pricePerKg,
    required this.createdAt,
    this.isAvailable = true,
    this.reorderLevel = 0.0,
    DateTime? lastUpdatedAt,
    this.initialQuantity = 0.0,
  }) : lastUpdatedAt = lastUpdatedAt ?? DateTime.now();

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return ProductModel(
      id: doc.id,
      distributorId: data['distributorId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      pricePerKg: (data['pricePerKg'] ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isAvailable: data['isAvailable'] ?? true,
      reorderLevel: (data['reorderLevel'] ?? 0).toDouble(),
      lastUpdatedAt: (data['lastUpdatedAt'] is Timestamp)
          ? (data['lastUpdatedAt'] as Timestamp).toDate()
          : ((data['createdAt'] is Timestamp)
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now()),
      initialQuantity: (data['initialQuantity'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorId': distributorId,
      'productName': productName,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'pricePerKg': pricePerKg,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
      'reorderLevel': reorderLevel,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'initialQuantity': initialQuantity,
    };
  }

  ProductModel copyWith({
    String? id,
    String? distributorId,
    String? productName,
    String? imageUrl,
    double? quantity,
    double? pricePerKg,
    DateTime? createdAt,
    bool? isAvailable,
    double? reorderLevel,
    DateTime? lastUpdatedAt,
    double? initialQuantity,
  }) {
    return ProductModel(
      id: id ?? this.id,
      distributorId: distributorId ?? this.distributorId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? this.quantity,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      initialQuantity: initialQuantity ?? this.initialQuantity,
    );
  }
} 