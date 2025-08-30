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

  ProductModel({
    required this.id,
    required this.distributorId,
    required this.productName,
    required this.imageUrl,
    required this.quantity,
    required this.pricePerKg,
    required this.createdAt,
    this.isAvailable = true,
  });

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
    );
  }
} 