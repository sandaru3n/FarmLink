import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumerOrderModel {
  final String id;
  final String consumerId;
  final String consumerName;
  final String consumerEmail;
  final String consumerPhone;
  final String consumerLocation;
  final List<ConsumerOrderItem> items;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final String paymentStatus; // 'pending', 'processing', 'completed', 'failed'
  final String orderStatus; // 'pending', 'confirmed', 'shipped', 'delivered', 'cancelled'
  final String? stripePaymentIntentId;
  final String? stripeClientSecret;
  final DateTime createdAt;
  final DateTime? paymentCompletedAt;
  final DateTime? confirmedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final DateTime? lastPaymentActivity;

  ConsumerOrderModel({
    required this.id,
    required this.consumerId,
    required this.consumerName,
    required this.consumerEmail,
    required this.consumerPhone,
    required this.consumerLocation,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.totalAmount,
    this.paymentStatus = 'pending',
    this.orderStatus = 'pending',
    this.stripePaymentIntentId,
    this.stripeClientSecret,
    required this.createdAt,
    this.paymentCompletedAt,
    this.confirmedAt,
    this.shippedAt,
    this.deliveredAt,
    this.lastPaymentActivity,
  });

  factory ConsumerOrderModel.fromMap(Map<String, dynamic> map) {
    return ConsumerOrderModel(
      id: map['id'] ?? '',
      consumerId: map['consumerId'] ?? '',
      consumerName: map['consumerName'] ?? '',
      consumerEmail: map['consumerEmail'] ?? '',
      consumerPhone: map['consumerPhone'] ?? '',
      consumerLocation: map['consumerLocation'] ?? '',
      items: List<ConsumerOrderItem>.from(
        (map['items'] ?? []).map((item) => ConsumerOrderItem.fromMap(item)),
      ),
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      tax: (map['tax'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
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
      shippedAt: map['shippedAt'] != null 
          ? (map['shippedAt'] as Timestamp).toDate() 
          : null,
      deliveredAt: map['deliveredAt'] != null 
          ? (map['deliveredAt'] as Timestamp).toDate() 
          : null,
      lastPaymentActivity: map['lastPaymentActivity'] != null 
          ? (map['lastPaymentActivity'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumerId': consumerId,
      'consumerName': consumerName,
      'consumerEmail': consumerEmail,
      'consumerPhone': consumerPhone,
      'consumerLocation': consumerLocation,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'stripePaymentIntentId': stripePaymentIntentId,
      'stripeClientSecret': stripeClientSecret,
      'createdAt': Timestamp.fromDate(createdAt),
      'paymentCompletedAt': paymentCompletedAt != null 
          ? Timestamp.fromDate(paymentCompletedAt!) 
          : null,
      'confirmedAt': confirmedAt != null 
          ? Timestamp.fromDate(confirmedAt!) 
          : null,
      'shippedAt': shippedAt != null 
          ? Timestamp.fromDate(shippedAt!) 
          : null,
      'deliveredAt': deliveredAt != null 
          ? Timestamp.fromDate(deliveredAt!) 
          : null,
      'lastPaymentActivity': lastPaymentActivity != null 
          ? Timestamp.fromDate(lastPaymentActivity!) 
          : null,
    };
  }

  ConsumerOrderModel copyWith({
    String? id,
    String? consumerId,
    String? consumerName,
    String? consumerEmail,
    String? consumerPhone,
    String? consumerLocation,
    List<ConsumerOrderItem>? items,
    double? subtotal,
    double? tax,
    double? totalAmount,
    String? paymentStatus,
    String? orderStatus,
    String? stripePaymentIntentId,
    String? stripeClientSecret,
    DateTime? createdAt,
    DateTime? paymentCompletedAt,
    DateTime? confirmedAt,
    DateTime? shippedAt,
    DateTime? deliveredAt,
    DateTime? lastPaymentActivity,
  }) {
    return ConsumerOrderModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      consumerName: consumerName ?? this.consumerName,
      consumerEmail: consumerEmail ?? this.consumerEmail,
      consumerPhone: consumerPhone ?? this.consumerPhone,
      consumerLocation: consumerLocation ?? this.consumerLocation,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      stripePaymentIntentId: stripePaymentIntentId ?? this.stripePaymentIntentId,
      stripeClientSecret: stripeClientSecret ?? this.stripeClientSecret,
      createdAt: createdAt ?? this.createdAt,
      paymentCompletedAt: paymentCompletedAt ?? this.paymentCompletedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      shippedAt: shippedAt ?? this.shippedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      lastPaymentActivity: lastPaymentActivity ?? this.lastPaymentActivity,
    );
  }
}

class ConsumerOrderItem {
  final String productId;
  final String productName;
  final String imageUrl;
  final String distributorId;
  final String distributorName;
  final double pricePerKg;
  final double quantity;
  final double totalPrice;

  ConsumerOrderItem({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.distributorId,
    required this.distributorName,
    required this.pricePerKg,
    required this.quantity,
    required this.totalPrice,
  });

  factory ConsumerOrderItem.fromMap(Map<String, dynamic> map) {
    return ConsumerOrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      distributorId: map['distributorId'] ?? '',
      distributorName: map['distributorName'] ?? '',
      pricePerKg: (map['pricePerKg'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'distributorId': distributorId,
      'distributorName': distributorName,
      'pricePerKg': pricePerKg,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
} 