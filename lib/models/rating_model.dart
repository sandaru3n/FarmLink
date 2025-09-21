import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String deliveryOrderId;
  final String transporterId;
  final String distributorId;
  final String transporterName;
  final String distributorName;
  final double rating; // 1.0 to 5.0
  final String? comment;
  final String? feedback; // Additional feedback
  final List<String>? categories; // e.g., ['punctuality', 'communication', 'care']
  final DateTime createdAt;
  final DateTime? updatedAt;

  RatingModel({
    required this.id,
    required this.deliveryOrderId,
    required this.transporterId,
    required this.distributorId,
    required this.transporterName,
    required this.distributorName,
    required this.rating,
    this.comment,
    this.feedback,
    this.categories,
    required this.createdAt,
    this.updatedAt,
  });

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] ?? '',
      deliveryOrderId: map['deliveryOrderId'] ?? '',
      transporterId: map['transporterId'] ?? '',
      distributorId: map['distributorId'] ?? '',
      transporterName: map['transporterName'] ?? '',
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
      'deliveryOrderId': deliveryOrderId,
      'transporterId': transporterId,
      'distributorId': distributorId,
      'transporterName': transporterName,
      'distributorName': distributorName,
      'rating': rating,
      'comment': comment,
      'feedback': feedback,
      'categories': categories,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  RatingModel copyWith({
    String? id,
    String? deliveryOrderId,
    String? transporterId,
    String? distributorId,
    String? transporterName,
    String? distributorName,
    double? rating,
    String? comment,
    String? feedback,
    List<String>? categories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RatingModel(
      id: id ?? this.id,
      deliveryOrderId: deliveryOrderId ?? this.deliveryOrderId,
      transporterId: transporterId ?? this.transporterId,
      distributorId: distributorId ?? this.distributorId,
      transporterName: transporterName ?? this.transporterName,
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
