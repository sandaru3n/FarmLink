import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for AI-powered consumer purchase analysis and recommendations
class ConsumerPurchaseAnalysisModel {
  final String id;
  final String consumerId;
  final String analysisType; // 'general', 'product_specific', 'seasonal', 'budget'
  final List<String> recommendations;
  final List<String> moneySavingTips;
  final List<String> productSuggestions;
  final Map<String, dynamic> purchasePatterns;
  final Map<String, dynamic> budgetInsights;
  final Map<String, dynamic> seasonalAdvice;
  final double confidenceScore;
  final String reasoning;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isAIGenerated;

  ConsumerPurchaseAnalysisModel({
    required this.id,
    required this.consumerId,
    required this.analysisType,
    required this.recommendations,
    required this.moneySavingTips,
    required this.productSuggestions,
    required this.purchasePatterns,
    required this.budgetInsights,
    required this.seasonalAdvice,
    required this.confidenceScore,
    required this.reasoning,
    required this.createdAt,
    required this.expiresAt,
    this.isAIGenerated = true,
  });

  factory ConsumerPurchaseAnalysisModel.fromMap(Map<String, dynamic> map) {
    return ConsumerPurchaseAnalysisModel(
      id: map['id'] ?? '',
      consumerId: map['consumerId'] ?? '',
      analysisType: map['analysisType'] ?? 'general',
      recommendations: List<String>.from(map['recommendations'] ?? []),
      moneySavingTips: List<String>.from(map['moneySavingTips'] ?? []),
      productSuggestions: List<String>.from(map['productSuggestions'] ?? []),
      purchasePatterns: Map<String, dynamic>.from(map['purchasePatterns'] ?? {}),
      budgetInsights: Map<String, dynamic>.from(map['budgetInsights'] ?? {}),
      seasonalAdvice: Map<String, dynamic>.from(map['seasonalAdvice'] ?? {}),
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
      reasoning: map['reasoning'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (map['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(hours: 24)),
      isAIGenerated: map['isAIGenerated'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'consumerId': consumerId,
      'analysisType': analysisType,
      'recommendations': recommendations,
      'moneySavingTips': moneySavingTips,
      'productSuggestions': productSuggestions,
      'purchasePatterns': purchasePatterns,
      'budgetInsights': budgetInsights,
      'seasonalAdvice': seasonalAdvice,
      'confidenceScore': confidenceScore,
      'reasoning': reasoning,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'isAIGenerated': isAIGenerated,
    };
  }

  ConsumerPurchaseAnalysisModel copyWith({
    String? id,
    String? consumerId,
    String? analysisType,
    List<String>? recommendations,
    List<String>? moneySavingTips,
    List<String>? productSuggestions,
    Map<String, dynamic>? purchasePatterns,
    Map<String, dynamic>? budgetInsights,
    Map<String, dynamic>? seasonalAdvice,
    double? confidenceScore,
    String? reasoning,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isAIGenerated,
  }) {
    return ConsumerPurchaseAnalysisModel(
      id: id ?? this.id,
      consumerId: consumerId ?? this.consumerId,
      analysisType: analysisType ?? this.analysisType,
      recommendations: recommendations ?? this.recommendations,
      moneySavingTips: moneySavingTips ?? this.moneySavingTips,
      productSuggestions: productSuggestions ?? this.productSuggestions,
      purchasePatterns: purchasePatterns ?? this.purchasePatterns,
      budgetInsights: budgetInsights ?? this.budgetInsights,
      seasonalAdvice: seasonalAdvice ?? this.seasonalAdvice,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reasoning: reasoning ?? this.reasoning,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
    );
  }
}

/// Model for consumer purchase history analysis
class ConsumerPurchaseHistoryModel {
  final String consumerId;
  final List<PurchaseRecord> purchases;
  final Map<String, int> productFrequency;
  final Map<String, double> averageSpending;
  final Map<String, double> seasonalSpending;
  final double totalSpent;
  final int totalOrders;
  final DateTime firstPurchase;
  final DateTime lastPurchase;
  final List<String> favoriteProducts;
  final List<String> favoriteDistributors;

  ConsumerPurchaseHistoryModel({
    required this.consumerId,
    required this.purchases,
    required this.productFrequency,
    required this.averageSpending,
    required this.seasonalSpending,
    required this.totalSpent,
    required this.totalOrders,
    required this.firstPurchase,
    required this.lastPurchase,
    required this.favoriteProducts,
    required this.favoriteDistributors,
  });

  factory ConsumerPurchaseHistoryModel.fromMap(Map<String, dynamic> map) {
    return ConsumerPurchaseHistoryModel(
      consumerId: map['consumerId'] ?? '',
      purchases: (map['purchases'] as List<dynamic>?)
          ?.map((p) => PurchaseRecord.fromMap(p))
          .toList() ?? [],
      productFrequency: Map<String, int>.from(map['productFrequency'] ?? {}),
      averageSpending: Map<String, double>.from(map['averageSpending'] ?? {}),
      seasonalSpending: Map<String, double>.from(map['seasonalSpending'] ?? {}),
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      firstPurchase: (map['firstPurchase'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPurchase: (map['lastPurchase'] as Timestamp?)?.toDate() ?? DateTime.now(),
      favoriteProducts: List<String>.from(map['favoriteProducts'] ?? []),
      favoriteDistributors: List<String>.from(map['favoriteDistributors'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consumerId': consumerId,
      'purchases': purchases.map((p) => p.toMap()).toList(),
      'productFrequency': productFrequency,
      'averageSpending': averageSpending,
      'seasonalSpending': seasonalSpending,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'firstPurchase': Timestamp.fromDate(firstPurchase),
      'lastPurchase': Timestamp.fromDate(lastPurchase),
      'favoriteProducts': favoriteProducts,
      'favoriteDistributors': favoriteDistributors,
    };
  }
}

/// Model for individual purchase record
class PurchaseRecord {
  final String orderId;
  final String productName;
  final String distributorName;
  final double pricePerKg;
  final double quantity;
  final double totalPrice;
  final DateTime purchaseDate;
  final String season;
  final String category;

  PurchaseRecord({
    required this.orderId,
    required this.productName,
    required this.distributorName,
    required this.pricePerKg,
    required this.quantity,
    required this.totalPrice,
    required this.purchaseDate,
    required this.season,
    required this.category,
  });

  factory PurchaseRecord.fromMap(Map<String, dynamic> map) {
    return PurchaseRecord(
      orderId: map['orderId'] ?? '',
      productName: map['productName'] ?? '',
      distributorName: map['distributorName'] ?? '',
      pricePerKg: (map['pricePerKg'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      purchaseDate: (map['purchaseDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      season: map['season'] ?? '',
      category: map['category'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'productName': productName,
      'distributorName': distributorName,
      'pricePerKg': pricePerKg,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'season': season,
      'category': category,
    };
  }
}

/// Model for market trends and pricing data
class ConsumerMarketTrendsModel {
  final Map<String, double> productPriceTrends;
  final Map<String, double> seasonalPriceVariations;
  final Map<String, int> productAvailability;
  final Map<String, double> distributorRatings;
  final List<String> trendingProducts;
  final List<String> bestValueProducts;
  final DateTime lastUpdated;

  ConsumerMarketTrendsModel({
    required this.productPriceTrends,
    required this.seasonalPriceVariations,
    required this.productAvailability,
    required this.distributorRatings,
    required this.trendingProducts,
    required this.bestValueProducts,
    required this.lastUpdated,
  });

  factory ConsumerMarketTrendsModel.fromMap(Map<String, dynamic> map) {
    return ConsumerMarketTrendsModel(
      productPriceTrends: Map<String, double>.from(map['productPriceTrends'] ?? {}),
      seasonalPriceVariations: Map<String, double>.from(map['seasonalPriceVariations'] ?? {}),
      productAvailability: Map<String, int>.from(map['productAvailability'] ?? {}),
      distributorRatings: Map<String, double>.from(map['distributorRatings'] ?? {}),
      trendingProducts: List<String>.from(map['trendingProducts'] ?? []),
      bestValueProducts: List<String>.from(map['bestValueProducts'] ?? []),
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productPriceTrends': productPriceTrends,
      'seasonalPriceVariations': seasonalPriceVariations,
      'productAvailability': productAvailability,
      'distributorRatings': distributorRatings,
      'trendingProducts': trendingProducts,
      'bestValueProducts': bestValueProducts,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}
