import 'package:cloud_firestore/cloud_firestore.dart';

class CartItemModel {
  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double pricePerKg;
  final double quantity; // quantity in cart
  final double availableQuantity; // total available quantity
  final String distributorId;
  final DateTime addedAt;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.pricePerKg,
    required this.quantity,
    required this.availableQuantity,
    required this.distributorId,
    required this.addedAt,
  });

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return CartItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      pricePerKg: (data['pricePerKg'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      availableQuantity: (data['availableQuantity'] ?? 0).toDouble(),
      distributorId: data['distributorId'] ?? '',
      addedAt: (data['addedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'pricePerKg': pricePerKg,
      'quantity': quantity,
      'availableQuantity': availableQuantity,
      'distributorId': distributorId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  double get totalPrice => quantity * pricePerKg;

  CartItemModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    double? pricePerKg,
    double? quantity,
    double? availableQuantity,
    String? distributorId,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      quantity: quantity ?? this.quantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      distributorId: distributorId ?? this.distributorId,
      addedAt: addedAt ?? this.addedAt,
    );
  }
} 