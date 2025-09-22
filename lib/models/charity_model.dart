import 'package:cloud_firestore/cloud_firestore.dart';

class CharityModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String registrationNumber;
  final List<String> categories; // ['food', 'education', 'health', 'environment']
  final bool isActive;
  final double rating;
  final int totalDonations;
  final DateTime createdAt;
  final DateTime? lastUpdated;

  CharityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.address,
    required this.phone,
    required this.email,
    this.website = '',
    required this.registrationNumber,
    this.categories = const [],
    this.isActive = true,
    this.rating = 0.0,
    this.totalDonations = 0,
    required this.createdAt,
    this.lastUpdated,
  });

  factory CharityModel.fromMap(Map<String, dynamic> map) {
    return CharityModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      categories: (map['categories'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      isActive: map['isActive'] ?? true,
      rating: (map['rating'] ?? 0).toDouble(),
      totalDonations: map['totalDonations'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'registrationNumber': registrationNumber,
      'categories': categories,
      'isActive': isActive,
      'rating': rating,
      'totalDonations': totalDonations,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
    };
  }

  CharityModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? registrationNumber,
    List<String>? categories,
    bool? isActive,
    double? rating,
    int? totalDonations,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return CharityModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      categories: categories ?? this.categories,
      isActive: isActive ?? this.isActive,
      rating: rating ?? this.rating,
      totalDonations: totalDonations ?? this.totalDonations,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get displayCategories {
    if (categories.isEmpty) return 'General';
    return categories.join(', ');
  }

  String get ratingDisplay {
    if (rating == 0.0) return 'New';
    return rating.toStringAsFixed(1);
  }
}
