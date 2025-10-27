import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/consumer_purchase_analysis_model.dart';
import '../models/consumer_order_model.dart';

class ConsumerPurchaseAnalysisService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // OpenAI API configuration
  static const String _openaiApiKey = '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'; // Replace with actual API key
  static const String _openaiBaseUrl = 'https://api.openai.com/v1/chat/completions';
  
  // Collection references
  CollectionReference get _consumerOrdersCollection => _firestore.collection('consumer_orders');
  CollectionReference get _consumerAnalysisCollection => _firestore.collection('consumer_purchase_analysis');
  CollectionReference get _productsCollection => _firestore.collection('products');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Get AI-powered consumer purchase analysis and recommendations
  Future<ConsumerPurchaseAnalysisModel?> getConsumerPurchaseAnalysis(String consumerId) async {
    try {
      // Check for cached analysis first
      final cachedAnalysis = await _getCachedAnalysis(consumerId);
      if (cachedAnalysis != null && !cachedAnalysis.expiresAt.isBefore(DateTime.now())) {
        return cachedAnalysis;
      }

      // Get consumer purchase history
      final purchaseHistory = await _getConsumerPurchaseHistory(consumerId);
      if (purchaseHistory.purchases.isEmpty) {
        return null; // No purchase data available
      }

      // Get market trends
      final marketTrends = await _getMarketTrends();

      // Generate AI analysis
      final aiAnalysis = await _generateAIAnalysis(purchaseHistory, marketTrends);
      
      if (aiAnalysis != null) {
        // Cache the analysis
        await _cacheAnalysis(aiAnalysis);
        return aiAnalysis;
      }

      return null;
    } catch (e) {
      print('Error getting consumer purchase analysis: $e');
      return null;
    }
  }

  /// Get cached analysis if available and not expired
  Future<ConsumerPurchaseAnalysisModel?> _getCachedAnalysis(String consumerId) async {
    try {
      final querySnapshot = await _consumerAnalysisCollection
          .where('consumerId', isEqualTo: consumerId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return ConsumerPurchaseAnalysisModel.fromMap(
          querySnapshot.docs.first.data() as Map<String, dynamic>
        );
      }
      return null;
    } catch (e) {
      print('Error getting cached analysis: $e');
      return null;
    }
  }

  /// Cache analysis result
  Future<void> _cacheAnalysis(ConsumerPurchaseAnalysisModel analysis) async {
    try {
      await _consumerAnalysisCollection.doc(analysis.id).set(analysis.toMap());
    } catch (e) {
      print('Error caching analysis: $e');
    }
  }

  /// Get consumer purchase history from Firebase
  Future<ConsumerPurchaseHistoryModel> _getConsumerPurchaseHistory(String consumerId) async {
    try {
      // Get consumer orders
      final ordersSnapshot = await _consumerOrdersCollection
          .where('consumerId', isEqualTo: consumerId)
          .where('orderStatus', isEqualTo: 'delivered')
          .orderBy('deliveredAt', descending: true)
          .limit(50) // Last 50 orders
          .get();

      final purchases = <PurchaseRecord>[];
      final productFrequency = <String, int>{};
      final averageSpending = <String, double>{};
      final seasonalSpending = <String, double>{};
      double totalSpent = 0.0;
      DateTime? firstPurchase;
      DateTime? lastPurchase;
      final favoriteProducts = <String, int>{};
      final favoriteDistributors = <String, int>{};

      for (final orderDoc in ordersSnapshot.docs) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final order = ConsumerOrderModel.fromMap(orderData);
        
        totalSpent += order.totalAmount;
        
        if (firstPurchase == null || order.createdAt.isBefore(firstPurchase)) {
          firstPurchase = order.createdAt;
        }
        if (lastPurchase == null || order.createdAt.isAfter(lastPurchase)) {
          lastPurchase = order.createdAt;
        }

        for (final item in order.items) {
          final season = _getSeason(order.createdAt);
          final category = _getProductCategory(item.productName);
          
          purchases.add(PurchaseRecord(
            orderId: order.id,
            productName: item.productName,
            distributorName: item.distributorName,
            pricePerKg: item.pricePerKg,
            quantity: item.quantity,
            totalPrice: item.totalPrice,
            purchaseDate: order.createdAt,
            season: season,
            category: category,
          ));

          // Update frequency counts
          productFrequency[item.productName] = (productFrequency[item.productName] ?? 0) + 1;
          favoriteProducts[item.productName] = (favoriteProducts[item.productName] ?? 0) + 1;
          favoriteDistributors[item.distributorName] = (favoriteDistributors[item.distributorName] ?? 0) + 1;

          // Update average spending
          if (averageSpending.containsKey(item.productName)) {
            averageSpending[item.productName] = (averageSpending[item.productName]! + item.pricePerKg) / 2;
          } else {
            averageSpending[item.productName] = item.pricePerKg;
          }

          // Update seasonal spending
          final seasonalKey = '${season}_${item.productName}';
          seasonalSpending[seasonalKey] = (seasonalSpending[seasonalKey] ?? 0) + item.totalPrice;
        }
      }

      // Sort favorites by frequency
      final sortedProducts = favoriteProducts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final sortedDistributors = favoriteDistributors.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ConsumerPurchaseHistoryModel(
        consumerId: consumerId,
        purchases: purchases,
        productFrequency: productFrequency,
        averageSpending: averageSpending,
        seasonalSpending: seasonalSpending,
        totalSpent: totalSpent,
        totalOrders: ordersSnapshot.docs.length,
        firstPurchase: firstPurchase ?? DateTime.now(),
        lastPurchase: lastPurchase ?? DateTime.now(),
        favoriteProducts: sortedProducts.take(5).map((e) => e.key).toList(),
        favoriteDistributors: sortedDistributors.take(3).map((e) => e.key).toList(),
      );
    } catch (e) {
      print('Error getting consumer purchase history: $e');
      return ConsumerPurchaseHistoryModel(
        consumerId: consumerId,
        purchases: [],
        productFrequency: {},
        averageSpending: {},
        seasonalSpending: {},
        totalSpent: 0.0,
        totalOrders: 0,
        firstPurchase: DateTime.now(),
        lastPurchase: DateTime.now(),
        favoriteProducts: [],
        favoriteDistributors: [],
      );
    }
  }

  /// Get market trends and pricing data
  Future<ConsumerMarketTrendsModel> _getMarketTrends() async {
    try {
      // Get recent product data
      final productsSnapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get();

      final productPriceTrends = <String, double>{};
      final seasonalPriceVariations = <String, double>{};
      final productAvailability = <String, int>{};
      final distributorRatings = <String, double>{};
      final trendingProducts = <String>[];
      final bestValueProducts = <String>[];

      for (final productDoc in productsSnapshot.docs) {
        final productData = productDoc.data() as Map<String, dynamic>;
        final productName = productData['name'] ?? '';
        final price = (productData['pricePerKg'] ?? 0.0).toDouble();
        final stock = productData['stock'] ?? 0;
        final distributorId = productData['distributorId'] ?? '';
        final rating = (productData['rating'] ?? 0.0).toDouble();

        if (productName.isNotEmpty) {
          productPriceTrends[productName] = price;
          productAvailability[productName] = stock;
          
          if (distributorId.isNotEmpty) {
            distributorRatings[distributorId] = rating;
          }

          // Simple trending logic based on stock and rating
          if (stock > 50 && rating > 4.0) {
            trendingProducts.add(productName);
          }
          if (rating > 4.5 && price < 200) { // Assuming LKR
            bestValueProducts.add(productName);
          }
        }
      }

      return ConsumerMarketTrendsModel(
        productPriceTrends: productPriceTrends,
        seasonalPriceVariations: seasonalPriceVariations,
        productAvailability: productAvailability,
        distributorRatings: distributorRatings,
        trendingProducts: trendingProducts.take(10).toList(),
        bestValueProducts: bestValueProducts.take(10).toList(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error getting market trends: $e');
      return ConsumerMarketTrendsModel(
        productPriceTrends: {},
        seasonalPriceVariations: {},
        productAvailability: {},
        distributorRatings: {},
        trendingProducts: [],
        bestValueProducts: [],
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Generate AI analysis using OpenAI API
  Future<ConsumerPurchaseAnalysisModel?> _generateAIAnalysis(
    ConsumerPurchaseHistoryModel purchaseHistory,
    ConsumerMarketTrendsModel marketTrends,
  ) async {
    try {
      final prompt = _buildAnalysisPrompt(purchaseHistory, marketTrends);
      
      final response = await http.post(
        Uri.parse(_openaiBaseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openaiApiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an AI assistant specialized in analyzing consumer purchase patterns and providing personalized shopping recommendations for agricultural products in Sri Lanka. Provide practical, actionable advice based on purchase history and market trends.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 1500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiResponse = responseData['choices'][0]['message']['content'];
        return _parseAIResponse(aiResponse, purchaseHistory.consumerId);
      } else {
        print('OpenAI API error: ${response.statusCode} - ${response.body}');
        return _generateFallbackAnalysis(purchaseHistory, marketTrends);
      }
    } catch (e) {
      print('Error generating AI analysis: $e');
      return _generateFallbackAnalysis(purchaseHistory, marketTrends);
    }
  }

  /// Build comprehensive prompt for AI analysis
  String _buildAnalysisPrompt(
    ConsumerPurchaseHistoryModel purchaseHistory,
    ConsumerMarketTrendsModel marketTrends,
  ) {
    final favoriteProducts = purchaseHistory.favoriteProducts.take(3).join(', ');
    final totalSpent = purchaseHistory.totalSpent.toStringAsFixed(2);
    final totalOrders = purchaseHistory.totalOrders;
    final avgOrderValue = totalOrders > 0 ? (purchaseHistory.totalSpent / totalOrders).toStringAsFixed(2) : '0';
    
    final trendingProducts = marketTrends.trendingProducts.take(5).join(', ');
    final bestValueProducts = marketTrends.bestValueProducts.take(5).join(', ');

    return '''
Analyze this consumer's purchase history and provide personalized recommendations:

CONSUMER PURCHASE HISTORY:
- Total spent: LKR $totalSpent across $totalOrders orders
- Average order value: LKR $avgOrderValue
- Favorite products: $favoriteProducts
- Purchase frequency: ${_getPurchaseFrequency(purchaseHistory)}
- Seasonal patterns: ${_getSeasonalPatterns(purchaseHistory)}

MARKET TRENDS:
- Trending products: $trendingProducts
- Best value products: $bestValueProducts
- Current season: ${_getCurrentSeason()}

Please provide a JSON response with the following structure:
{
  "recommendations": ["3-5 personalized shopping recommendations"],
  "moneySavingTips": ["3-5 specific money-saving tips"],
  "productSuggestions": ["3-5 product suggestions based on preferences"],
  "purchasePatterns": {
    "frequency": "analysis of purchase frequency",
    "seasonal": "seasonal buying patterns",
    "budget": "budget analysis"
  },
  "budgetInsights": {
    "monthlyAverage": "estimated monthly spending",
    "savingsPotential": "potential savings amount",
    "optimizationTips": ["budget optimization tips"]
  },
  "seasonalAdvice": {
    "currentSeason": "advice for current season",
    "upcomingSeason": "preparation for next season",
    "bestBuyingTimes": ["optimal times to buy specific products"]
  },
  "confidenceScore": 0.85,
  "reasoning": "brief explanation of analysis approach"
}

Focus on practical, actionable advice for Sri Lankan consumers buying agricultural products.
''';
  }

  /// Parse AI response into analysis model
  ConsumerPurchaseAnalysisModel? _parseAIResponse(String aiResponse, String consumerId) {
    try {
      // Extract JSON from response
      final jsonStart = aiResponse.indexOf('{');
      final jsonEnd = aiResponse.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        return null;
      }
      
      final jsonString = aiResponse.substring(jsonStart, jsonEnd);
      final analysisData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      final analysisId = DateTime.now().millisecondsSinceEpoch.toString();
      
      return ConsumerPurchaseAnalysisModel(
        id: analysisId,
        consumerId: consumerId,
        analysisType: 'general',
        recommendations: List<String>.from(analysisData['recommendations'] ?? []),
        moneySavingTips: List<String>.from(analysisData['moneySavingTips'] ?? []),
        productSuggestions: List<String>.from(analysisData['productSuggestions'] ?? []),
        purchasePatterns: Map<String, dynamic>.from(analysisData['purchasePatterns'] ?? {}),
        budgetInsights: Map<String, dynamic>.from(analysisData['budgetInsights'] ?? {}),
        seasonalAdvice: Map<String, dynamic>.from(analysisData['seasonalAdvice'] ?? {}),
        confidenceScore: (analysisData['confidenceScore'] ?? 0.8).toDouble(),
        reasoning: analysisData['reasoning'] ?? 'AI-generated analysis based on purchase history and market trends',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
        isAIGenerated: true,
      );
    } catch (e) {
      print('Error parsing AI response: $e');
      return null;
    }
  }

  /// Generate fallback analysis when AI is unavailable
  ConsumerPurchaseAnalysisModel _generateFallbackAnalysis(
    ConsumerPurchaseHistoryModel purchaseHistory,
    ConsumerMarketTrendsModel marketTrends,
  ) {
    final analysisId = DateTime.now().millisecondsSinceEpoch.toString();
    
    return ConsumerPurchaseAnalysisModel(
      id: analysisId,
      consumerId: purchaseHistory.consumerId,
      analysisType: 'general',
      recommendations: _generateFallbackRecommendations(purchaseHistory, marketTrends),
      moneySavingTips: _generateFallbackMoneySavingTips(purchaseHistory),
      productSuggestions: _generateFallbackProductSuggestions(purchaseHistory, marketTrends),
      purchasePatterns: _generateFallbackPurchasePatterns(purchaseHistory),
      budgetInsights: _generateFallbackBudgetInsights(purchaseHistory),
      seasonalAdvice: _generateFallbackSeasonalAdvice(),
      confidenceScore: 0.6,
      reasoning: 'Analysis based on purchase patterns and market data (AI unavailable)',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
      isAIGenerated: false,
    );
  }

  // Helper methods for fallback analysis
  List<String> _generateFallbackRecommendations(
    ConsumerPurchaseHistoryModel purchaseHistory,
    ConsumerMarketTrendsModel marketTrends,
  ) {
    final recommendations = <String>[];
    
    if (purchaseHistory.favoriteProducts.isNotEmpty) {
      recommendations.add('Consider buying ${purchaseHistory.favoriteProducts.first} in bulk for better value');
    }
    
    if (marketTrends.bestValueProducts.isNotEmpty) {
      recommendations.add('Try ${marketTrends.bestValueProducts.first} - great value for money');
    }
    
    recommendations.add('Shop during off-peak hours for better deals');
    recommendations.add('Consider seasonal products for better prices');
    
    return recommendations;
  }

  List<String> _generateFallbackMoneySavingTips(ConsumerPurchaseHistoryModel purchaseHistory) {
    return [
      'Buy in bulk for frequently purchased items',
      'Compare prices across different distributors',
      'Look for seasonal discounts',
      'Consider buying during weekdays for better deals',
      'Join distributor loyalty programs for discounts',
    ];
  }

  List<String> _generateFallbackProductSuggestions(
    ConsumerPurchaseHistoryModel purchaseHistory,
    ConsumerMarketTrendsModel marketTrends,
  ) {
    final suggestions = <String>[];
    
    // Suggest trending products not in favorites
    for (final trending in marketTrends.trendingProducts.take(3)) {
      if (!purchaseHistory.favoriteProducts.contains(trending)) {
        suggestions.add(trending);
      }
    }
    
    // Suggest best value products
    suggestions.addAll(marketTrends.bestValueProducts.take(2));
    
    return suggestions.take(5).toList();
  }

  Map<String, dynamic> _generateFallbackPurchasePatterns(ConsumerPurchaseHistoryModel purchaseHistory) {
    return {
      'frequency': 'Regular buyer with ${purchaseHistory.totalOrders} orders',
      'seasonal': 'Purchase patterns vary by season',
      'budget': 'Average spending: LKR ${(purchaseHistory.totalSpent / purchaseHistory.totalOrders).toStringAsFixed(2)} per order',
    };
  }

  Map<String, dynamic> _generateFallbackBudgetInsights(ConsumerPurchaseHistoryModel purchaseHistory) {
    final monthlyAverage = purchaseHistory.totalSpent / 12; // Rough estimate
    return {
      'monthlyAverage': 'LKR ${monthlyAverage.toStringAsFixed(2)}',
      'savingsPotential': 'LKR ${(monthlyAverage * 0.1).toStringAsFixed(2)} per month',
      'optimizationTips': ['Buy seasonal products', 'Compare distributor prices', 'Use bulk discounts'],
    };
  }

  Map<String, dynamic> _generateFallbackSeasonalAdvice() {
    return {
      'currentSeason': 'Current season offers good variety of products',
      'upcomingSeason': 'Prepare for next season by checking availability',
      'bestBuyingTimes': ['Weekday mornings', 'Early in the month', 'During promotions'],
    };
  }

  // Utility methods
  String _getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    if (month >= 9 && month <= 11) return 'Autumn';
    return 'Winter';
  }

  String _getCurrentSeason() {
    return _getSeason(DateTime.now());
  }

  String _getProductCategory(String productName) {
    final name = productName.toLowerCase();
    if (name.contains('rice') || name.contains('grain')) return 'Grains';
    if (name.contains('vegetable') || name.contains('leafy')) return 'Vegetables';
    if (name.contains('fruit')) return 'Fruits';
    if (name.contains('spice') || name.contains('herb')) return 'Spices';
    return 'Other';
  }

  String _getPurchaseFrequency(ConsumerPurchaseHistoryModel purchaseHistory) {
    final daysSinceFirst = DateTime.now().difference(purchaseHistory.firstPurchase).inDays;
    if (daysSinceFirst == 0) return 'New customer';
    
    final frequency = purchaseHistory.totalOrders / (daysSinceFirst / 30);
    if (frequency > 4) return 'Very frequent';
    if (frequency > 2) return 'Regular';
    if (frequency > 1) return 'Occasional';
    return 'Infrequent';
  }

  String _getSeasonalPatterns(ConsumerPurchaseHistoryModel purchaseHistory) {
    final seasonalSpending = purchaseHistory.seasonalSpending;
    if (seasonalSpending.isEmpty) return 'No clear patterns';
    
    final seasons = ['Spring', 'Summer', 'Autumn', 'Winter'];
    final seasonTotals = <String, double>{};
    
    for (final season in seasons) {
      seasonTotals[season] = seasonalSpending.entries
          .where((e) => e.key.startsWith(season))
          .fold(0.0, (sum, e) => sum + e.value);
    }
    
    final maxSeason = seasonTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    return 'Highest spending in ${maxSeason.key}';
  }
}
