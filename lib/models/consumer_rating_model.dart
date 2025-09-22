import 'package:cloud_firestore/cloud_firestore.dart';

class ConsumerRatingModel {
  final String id;
  final String consumerOrderId;
  final String consumerId;
  final String distributorId;
  final String consumerName;
  final String distributorName;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String? feedback; // Additional feedback
  final List<String>? categories; // e.g., ['quality', 'delivery', 'packaging', 'value']
  final DateTime createdAt;
  final DateTime? updatedAt;

  ConsumerRatingModel({
    required this.id,
    required this.consumerOrderId,
    required this.consumerId,
    required this.distributorId,
    required this.consumerName,
    required this.distributorName,
    required this.rating,
    this.comment,
    this.feedback,
    this.categories,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConsumerRatingModel.fromMap(Map<String, dynamic> map) {
    return ConsumerRatingModel(
      id: map['id'] ?? '',
      consumerOrderId: map['consumerOrderId'] ?? '',
      consumerId: map['consumerId'] ?? '',
      distributorId: map['distributorId'] ?? '',
      consumerName: map['consumerName'] ?? '',
      distributorName: map['distributorName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'],
      feedback: map['feedback'],
      categories: map['categories'] != null 
          ? List<String>.from(map['categories']) 
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumerOrderId': consumerOrderId,
      'consumerId': consumerId,
      'distributorId': distributorId,
      'consumerName': consumerName,
      'distributorName': distributorName,
      'rating': rating,
      'comment': comment,
      'feedback': feedback,
      'categories': categories,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ConsumerRatingModel copyWith({
    String? id,
    String? consumerOrderId,
    String? consumerId,
    String? distributorId,
    String? consumerName,
    String? distributorName,
    double? rating,
    String? comment,
    String? feedback,
    List<String>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConsumerRatingModel(
      id: id ?? this.id,
      consumerOrderId: consumerOrderId ?? this.consumerOrderId,
      consumerId: consumerId ?? this.consumerId,
      distributorId: distributorId ?? this.distributorId,
      consumerName: consumerName ?? this.consumerName,
      distributorName: distributorName ?? this.distributorName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      feedback: feedback ?? this.feedback,
      categories: categories ?? this.categories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isRated => rating > 0;
  bool get hasComment => comment != null && comment!.isNotEmpty;
  bool get hasFeedback => feedback != null && feedback!.isNotEmpty;
  
  String get ratingText {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 4.0) return 'Very Good';
    if (rating >= 3.0) return 'Good';
    if (rating >= 2.0) return 'Fair';
    return 'Poor';
  }

  String get starDisplay {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    
    return '${'★' * fullStars}${hasHalfStar ? '☆' : ''}${'☆' * emptyStars}';
  }
}
