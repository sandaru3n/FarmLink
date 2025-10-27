import 'package:cloud_firestore/cloud_firestore.dart';

class BiddingAnalysisModel {
  final String id;
  final String distributorId;
  final String cropId;
  final String cropName;
  final double recommendedBid;
  final double confidenceScore; // 0.0 to 1.0
  final String reasoning;
  final Map<String, dynamic> marketFactors;
  final Map<String, dynamic> farmerReliability;
  final Map<String, dynamic> historicalData;
  final DateTime createdAt;
  final DateTime expiresAt;

  BiddingAnalysisModel({
    required this.id,
    required this.distributorId,
    required this.cropId,
    required this.cropName,
    required this.recommendedBid,
    required this.confidenceScore,
    required this.reasoning,
    required this.marketFactors,
    required this.farmerReliability,
    required this.historicalData,
    required this.createdAt,
    required this.expiresAt,
  });

  factory BiddingAnalysisModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BiddingAnalysisModel(
      id: doc.id,
      distributorId: data['distributorId'] ?? '',
      cropId: data['cropId'] ?? '',
      cropName: data['cropName'] ?? '',
      recommendedBid: (data['recommendedBid'] ?? 0).toDouble(),
      confidenceScore: (data['confidenceScore'] ?? 0).toDouble(),
      reasoning: data['reasoning'] ?? '',
      marketFactors: Map<String, dynamic>.from(data['marketFactors'] ?? {}),
      farmerReliability: Map<String, dynamic>.from(data['farmerReliability'] ?? {}),
      historicalData: Map<String, dynamic>.from(data['historicalData'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorId': distributorId,
      'cropId': cropId,
      'cropName': cropName,
      'recommendedBid': recommendedBid,
      'confidenceScore': confidenceScore,
      'reasoning': reasoning,
      'marketFactors': marketFactors,
      'farmerReliability': farmerReliability,
      'historicalData': historicalData,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  BiddingAnalysisModel copyWith({
    String? id,
    String? distributorId,
    String? cropId,
    String? cropName,
    double? recommendedBid,
    double? confidenceScore,
    String? reasoning,
    Map<String, dynamic>? marketFactors,
    Map<String, dynamic>? farmerReliability,
    Map<String, dynamic>? historicalData,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BiddingAnalysisModel(
      id: id ?? this.id,
      distributorId: distributorId ?? this.distributorId,
      cropId: cropId ?? this.cropId,
      cropName: cropName ?? this.cropName,
      recommendedBid: recommendedBid ?? this.recommendedBid,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reasoning: reasoning ?? this.reasoning,
      marketFactors: marketFactors ?? this.marketFactors,
      farmerReliability: farmerReliability ?? this.farmerReliability,
      historicalData: historicalData ?? this.historicalData,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isHighConfidence => confidenceScore >= 0.8;
  bool get isMediumConfidence => confidenceScore >= 0.6 && confidenceScore < 0.8;
  bool get isLowConfidence => confidenceScore < 0.6;

  String get confidenceLevel {
    if (isHighConfidence) return 'High';
    if (isMediumConfidence) return 'Medium';
    return 'Low';
  }

  String get confidencePercentage => '${(confidenceScore * 100).round()}%';
}

class MarketDataModel {
  final String cropName;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int totalAuctions;
  final int successfulAuctions;
  final double successRate;
  final Map<String, double> seasonalTrends;
  final Map<String, double> locationFactors;
  final DateTime lastUpdated;

  MarketDataModel({
    required this.cropName,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.totalAuctions,
    required this.successfulAuctions,
    required this.successRate,
    required this.seasonalTrends,
    required this.locationFactors,
    required this.lastUpdated,
  });

  factory MarketDataModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return MarketDataModel(
      cropName: data['cropName'] ?? '',
      averagePrice: (data['averagePrice'] ?? 0).toDouble(),
      minPrice: (data['minPrice'] ?? 0).toDouble(),
      maxPrice: (data['maxPrice'] ?? 0).toDouble(),
      totalAuctions: data['totalAuctions'] ?? 0,
      successfulAuctions: data['successfulAuctions'] ?? 0,
      successRate: (data['successRate'] ?? 0).toDouble(),
      seasonalTrends: Map<String, double>.from(data['seasonalTrends'] ?? {}),
      locationFactors: Map<String, double>.from(data['locationFactors'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cropName': cropName,
      'averagePrice': averagePrice,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'totalAuctions': totalAuctions,
      'successfulAuctions': successfulAuctions,
      'successRate': successRate,
      'seasonalTrends': seasonalTrends,
      'locationFactors': locationFactors,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class FarmerReliabilityModel {
  final String farmerId;
  final String farmerName;
  final double reliabilityScore; // 0.0 to 1.0
  final int totalCrops;
  final int successfulDeliveries;
  final double deliverySuccessRate;
  final double averageQualityRating;
  final int totalRatings;
  final Map<String, dynamic> deliveryHistory;
  final Map<String, dynamic> qualityMetrics;
  final DateTime lastUpdated;

  FarmerReliabilityModel({
    required this.farmerId,
    required this.farmerName,
    required this.reliabilityScore,
    required this.totalCrops,
    required this.successfulDeliveries,
    required this.deliverySuccessRate,
    required this.averageQualityRating,
    required this.totalRatings,
    required this.deliveryHistory,
    required this.qualityMetrics,
    required this.lastUpdated,
  });

  factory FarmerReliabilityModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return FarmerReliabilityModel(
      farmerId: doc.id,
      farmerName: data['farmerName'] ?? '',
      reliabilityScore: (data['reliabilityScore'] ?? 0).toDouble(),
      totalCrops: data['totalCrops'] ?? 0,
      successfulDeliveries: data['successfulDeliveries'] ?? 0,
      deliverySuccessRate: (data['deliverySuccessRate'] ?? 0).toDouble(),
      averageQualityRating: (data['averageQualityRating'] ?? 0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      deliveryHistory: Map<String, dynamic>.from(data['deliveryHistory'] ?? {}),
      qualityMetrics: Map<String, dynamic>.from(data['qualityMetrics'] ?? {}),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'farmerName': farmerName,
      'reliabilityScore': reliabilityScore,
      'totalCrops': totalCrops,
      'successfulDeliveries': successfulDeliveries,
      'deliverySuccessRate': deliverySuccessRate,
      'averageQualityRating': averageQualityRating,
      'totalRatings': totalRatings,
      'deliveryHistory': deliveryHistory,
      'qualityMetrics': qualityMetrics,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  bool get isHighlyReliable => reliabilityScore >= 0.8;
  bool get isModeratelyReliable => reliabilityScore >= 0.6 && reliabilityScore < 0.8;
  bool get isLowReliability => reliabilityScore < 0.6;

  String get reliabilityLevel {
    if (isHighlyReliable) return 'High';
    if (isModeratelyReliable) return 'Medium';
    return 'Low';
  }
}

class DistributorBiddingHistoryModel {
  final String distributorId;
  final String distributorName;
  final Map<String, List<BidHistoryEntry>> bidHistory;
  final Map<String, double> winRatesByCrop;
  final Map<String, double> averageBidsByCrop;
  final double overallWinRate;
  final double averageBidAmount;
  final int totalBids;
  final int totalWins;
  final DateTime lastUpdated;

  DistributorBiddingHistoryModel({
    required this.distributorId,
    required this.distributorName,
    required this.bidHistory,
    required this.winRatesByCrop,
    required this.averageBidsByCrop,
    required this.overallWinRate,
    required this.averageBidAmount,
    required this.totalBids,
    required this.totalWins,
    required this.lastUpdated,
  });

  factory DistributorBiddingHistoryModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return DistributorBiddingHistoryModel(
      distributorId: doc.id,
      distributorName: data['distributorName'] ?? '',
      bidHistory: Map<String, List<BidHistoryEntry>>.from(
        (data['bidHistory'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>).map((e) => BidHistoryEntry.fromMap(e)).toList(),
          ),
        ),
      ),
      winRatesByCrop: Map<String, double>.from(data['winRatesByCrop'] ?? {}),
      averageBidsByCrop: Map<String, double>.from(data['averageBidsByCrop'] ?? {}),
      overallWinRate: (data['overallWinRate'] ?? 0).toDouble(),
      averageBidAmount: (data['averageBidAmount'] ?? 0).toDouble(),
      totalBids: data['totalBids'] ?? 0,
      totalWins: data['totalWins'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'distributorName': distributorName,
      'bidHistory': bidHistory.map(
        (key, value) => MapEntry(key, value.map((e) => e.toMap()).toList()),
      ),
      'winRatesByCrop': winRatesByCrop,
      'averageBidsByCrop': averageBidsByCrop,
      'overallWinRate': overallWinRate,
      'averageBidAmount': averageBidAmount,
      'totalBids': totalBids,
      'totalWins': totalWins,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

class BidHistoryEntry {
  final String cropId;
  final String cropName;
  final double bidAmount;
  final bool won;
  final DateTime bidDate;
  final double finalPrice;

  BidHistoryEntry({
    required this.cropId,
    required this.cropName,
    required this.bidAmount,
    required this.won,
    required this.bidDate,
    required this.finalPrice,
  });

  factory BidHistoryEntry.fromMap(Map<String, dynamic> map) {
    return BidHistoryEntry(
      cropId: map['cropId'] ?? '',
      cropName: map['cropName'] ?? '',
      bidAmount: (map['bidAmount'] ?? 0).toDouble(),
      won: map['won'] ?? false,
      bidDate: (map['bidDate'] as Timestamp).toDate(),
      finalPrice: (map['finalPrice'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cropId': cropId,
      'cropName': cropName,
      'bidAmount': bidAmount,
      'won': won,
      'bidDate': Timestamp.fromDate(bidDate),
      'finalPrice': finalPrice,
    };
  }
}
