import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/bidding_analysis_model.dart';
import '../models/crop_model.dart';

class SmartBiddingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _openaiApiKey = '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'; // Replace with actual API key
  static const String _openaiBaseUrl = 'https://api.openai.com/v1/chat/completions';

  // Collection references
  CollectionReference get _biddingAnalysisCollection => _firestore.collection('bidding_analysis');
  CollectionReference get _marketDataCollection => _firestore.collection('market_data');
  CollectionReference get _farmerReliabilityCollection => _firestore.collection('farmer_reliability');
  CollectionReference get _distributorHistoryCollection => _firestore.collection('distributor_bidding_history');
  CollectionReference get _cropsCollection => _firestore.collection('crops');
  CollectionReference get _ordersCollection => _firestore.collection('orders');

  /// Generate AI-powered bid recommendation for a specific crop
  Future<BiddingAnalysisModel?> generateBidRecommendation({
    required String distributorId,
    required String distributorName,
    required CropModel crop,
  }) async {
    try {
      // Check if we have a recent analysis for this crop
      final existingAnalysis = await _getExistingAnalysis(distributorId, crop.id);
      if (existingAnalysis != null && !existingAnalysis.isExpired) {
        return existingAnalysis;
      }

      // Gather all necessary data
      final marketData = await _getMarketData(crop.cropName);
      final farmerReliability = await _getFarmerReliability(crop.farmerId);
      final distributorHistory = await _getDistributorHistory(distributorId);
      final historicalData = await _getHistoricalBiddingData(crop.cropName);

      // Prepare data for AI analysis
      final analysisData = _prepareAnalysisData(
        crop: crop,
        marketData: marketData,
        farmerReliability: farmerReliability,
        distributorHistory: distributorHistory,
        historicalData: historicalData,
      );

      // Call OpenAI API for bid recommendation
      final aiResponse = await _callOpenAI(analysisData);
      
      if (aiResponse == null) {
        // Fallback to rule-based recommendation if AI fails
        return _generateFallbackRecommendation(
          distributorId: distributorId,
          distributorName: distributorName,
          crop: crop,
          marketData: marketData,
          farmerReliability: farmerReliability,
          distributorHistory: distributorHistory,
        );
      }

      // Create and save the analysis
      final analysis = BiddingAnalysisModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        distributorId: distributorId,
        cropId: crop.id,
        cropName: crop.cropName,
        recommendedBid: aiResponse['recommendedBid'],
        confidenceScore: aiResponse['confidenceScore'],
        reasoning: aiResponse['reasoning'],
        marketFactors: marketData?.toFirestore() ?? {},
        farmerReliability: farmerReliability?.toFirestore() ?? {},
        historicalData: historicalData,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)), // Expires in 2 hours
      );

      // Save to Firestore
      await _biddingAnalysisCollection.doc(analysis.id).set(analysis.toFirestore());
      
      return analysis;
    } catch (e) {
      print('Error generating bid recommendation: $e');
      return null;
    }
  }

  /// Get existing analysis if available and not expired
  Future<BiddingAnalysisModel?> _getExistingAnalysis(String distributorId, String cropId) async {
    try {
      final querySnapshot = await _biddingAnalysisCollection
          .where('distributorId', isEqualTo: distributorId)
          .where('cropId', isEqualTo: cropId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return BiddingAnalysisModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting existing analysis: $e');
      return null;
    }
  }

  /// Get market data for a specific crop
  Future<MarketDataModel?> _getMarketData(String cropName) async {
    try {
      final docSnapshot = await _marketDataCollection.doc(cropName.toLowerCase()).get();
      if (docSnapshot.exists) {
        return MarketDataModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting market data: $e');
      return null;
    }
  }

  /// Get farmer reliability data
  Future<FarmerReliabilityModel?> _getFarmerReliability(String farmerId) async {
    try {
      final docSnapshot = await _farmerReliabilityCollection.doc(farmerId).get();
      if (docSnapshot.exists) {
        return FarmerReliabilityModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting farmer reliability: $e');
      return null;
    }
  }

  /// Get distributor bidding history
  Future<DistributorBiddingHistoryModel?> _getDistributorHistory(String distributorId) async {
    try {
      final docSnapshot = await _distributorHistoryCollection.doc(distributorId).get();
      if (docSnapshot.exists) {
        return DistributorBiddingHistoryModel.fromFirestore(docSnapshot);
      }
      return null;
    } catch (e) {
      print('Error getting distributor history: $e');
      return null;
    }
  }

  /// Get historical bidding data for a crop
  Future<Map<String, dynamic>> _getHistoricalBiddingData(String cropName) async {
    try {
      final querySnapshot = await _cropsCollection
          .where('cropName', isEqualTo: cropName)
          .where('status', isEqualTo: 'sold')
          .limit(50)
          .get();

      final List<Map<String, dynamic>> historicalBids = [];
      double totalFinalPrice = 0;
      int successfulAuctions = 0;

      for (final doc in querySnapshot.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.order != null) {
          historicalBids.add({
            'finalPrice': crop.order!.finalPrice,
            'quantity': crop.quantity,
            'date': crop.order!.createdAt.toIso8601String(),
          });
          totalFinalPrice += crop.order!.finalPrice;
          successfulAuctions++;
        }
      }

      final averagePrice = successfulAuctions > 0 ? totalFinalPrice / successfulAuctions : 0.0;

      return {
        'historicalBids': historicalBids,
        'averagePrice': averagePrice,
        'successfulAuctions': successfulAuctions,
        'totalValue': totalFinalPrice,
      };
    } catch (e) {
      print('Error getting historical data: $e');
      return {};
    }
  }

  /// Prepare data for AI analysis
  Map<String, dynamic> _prepareAnalysisData({
    required CropModel crop,
    MarketDataModel? marketData,
    FarmerReliabilityModel? farmerReliability,
    DistributorBiddingHistoryModel? distributorHistory,
    required Map<String, dynamic> historicalData,
  }) {
    return {
      'crop': {
        'name': crop.cropName,
        'quantity': crop.quantity,
        'minBidPrice': crop.minBidPrice,
        'currentHighestBid': crop.highestBid?.amount ?? 0,
        'timeLeft': crop.timeLeft.inHours,
        'pickupLocation': crop.pickupLocation,
      },
      'marketData': marketData != null ? {
        'averagePrice': marketData.averagePrice,
        'minPrice': marketData.minPrice,
        'maxPrice': marketData.maxPrice,
        'successRate': marketData.successRate,
        'totalAuctions': marketData.totalAuctions,
      } : null,
      'farmerReliability': farmerReliability != null ? {
        'reliabilityScore': farmerReliability.reliabilityScore,
        'deliverySuccessRate': farmerReliability.deliverySuccessRate,
        'averageQualityRating': farmerReliability.averageQualityRating,
        'totalCrops': farmerReliability.totalCrops,
      } : null,
      'distributorHistory': distributorHistory != null ? {
        'overallWinRate': distributorHistory.overallWinRate,
        'averageBidAmount': distributorHistory.averageBidAmount,
        'totalBids': distributorHistory.totalBids,
        'winRatesByCrop': distributorHistory.winRatesByCrop,
      } : null,
      'historicalData': historicalData,
    };
  }

  /// Call OpenAI API for bid recommendation
  Future<Map<String, dynamic>?> _callOpenAI(Map<String, dynamic> analysisData) async {
    try {
      final prompt = _buildPrompt(analysisData);
      
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
              'content': 'You are a smart bidding assistant for agricultural crop auctions. Analyze the provided data and give a bid recommendation with confidence score and reasoning.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final content = responseData['choices'][0]['message']['content'];
        return _parseAIResponse(content);
      } else {
        print('OpenAI API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling OpenAI API: $e');
      return null;
    }
  }

  /// Build prompt for OpenAI
  String _buildPrompt(Map<String, dynamic> analysisData) {
    return '''
Analyze the following crop auction data and provide a bid recommendation:

CROP DETAILS:
- Name: ${analysisData['crop']['name']}
- Quantity: ${analysisData['crop']['quantity']} kg
- Minimum Bid: LKR ${analysisData['crop']['minBidPrice']}
- Current Highest Bid: LKR ${analysisData['crop']['currentHighestBid']}
- Time Left: ${analysisData['crop']['timeLeft']} hours
- Location: ${analysisData['crop']['pickupLocation']}

MARKET DATA:
${analysisData['marketData'] != null ? '''
- Average Price: LKR ${analysisData['marketData']['averagePrice']}
- Price Range: LKR ${analysisData['marketData']['minPrice']} - LKR ${analysisData['marketData']['maxPrice']}
- Market Success Rate: ${(analysisData['marketData']['successRate'] * 100).toStringAsFixed(1)}%
- Total Auctions: ${analysisData['marketData']['totalAuctions']}
''' : 'No market data available'}

FARMER RELIABILITY:
${analysisData['farmerReliability'] != null ? '''
- Reliability Score: ${(analysisData['farmerReliability']['reliabilityScore'] * 100).toStringAsFixed(1)}%
- Delivery Success Rate: ${(analysisData['farmerReliability']['deliverySuccessRate'] * 100).toStringAsFixed(1)}%
- Quality Rating: ${analysisData['farmerReliability']['averageQualityRating']}/5
- Total Crops Sold: ${analysisData['farmerReliability']['totalCrops']}
''' : 'No farmer reliability data available'}

DISTRIBUTOR HISTORY:
${analysisData['distributorHistory'] != null ? '''
- Overall Win Rate: ${(analysisData['distributorHistory']['overallWinRate'] * 100).toStringAsFixed(1)}%
- Average Bid Amount: LKR ${analysisData['distributorHistory']['averageBidAmount']}
- Total Bids Placed: ${analysisData['distributorHistory']['totalBids']}
''' : 'No distributor history available'}

HISTORICAL DATA:
- Historical Average Price: LKR ${analysisData['historicalData']['averagePrice']}
- Successful Auctions: ${analysisData['historicalData']['successfulAuctions']}

Please provide your recommendation in the following JSON format:
{
  "recommendedBid": [number],
  "confidenceScore": [number between 0.0 and 1.0],
  "reasoning": "[explanation of your recommendation]"
}

Consider factors like:
1. Market trends and average prices
2. Farmer reliability and quality
3. Time remaining in auction
4. Distributor's historical performance
5. Current competition level
6. Risk vs reward balance

Make sure the recommended bid is competitive but not excessive.
''';
  }

  /// Parse AI response
  Map<String, dynamic>? _parseAIResponse(String content) {
    try {
      // Extract JSON from the response
      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        return null;
      }
      
      final jsonString = content.substring(jsonStart, jsonEnd);
      final response = jsonDecode(jsonString);
      
      return {
        'recommendedBid': (response['recommendedBid'] ?? 0).toDouble(),
        'confidenceScore': (response['confidenceScore'] ?? 0.5).toDouble(),
        'reasoning': response['reasoning'] ?? 'AI analysis completed',
      };
    } catch (e) {
      print('Error parsing AI response: $e');
      return null;
    }
  }

  /// Generate fallback recommendation using rule-based logic
  BiddingAnalysisModel _generateFallbackRecommendation({
    required String distributorId,
    required String distributorName,
    required CropModel crop,
    MarketDataModel? marketData,
    FarmerReliabilityModel? farmerReliability,
    DistributorBiddingHistoryModel? distributorHistory,
  }) {
    double recommendedBid = crop.minBidPrice;
    double confidenceScore = 0.5;
    String reasoning = 'Rule-based recommendation';

    // Base recommendation on minimum bid
    recommendedBid = crop.minBidPrice;

    // Adjust based on market data
    if (marketData != null) {
      final marketAverage = marketData.averagePrice;
      if (marketAverage > crop.minBidPrice) {
        recommendedBid = (crop.minBidPrice + marketAverage) / 2;
        confidenceScore += 0.2;
        reasoning += '. Adjusted for market average (LKR ${marketAverage.toStringAsFixed(0)})';
      }
    }

    // Adjust based on farmer reliability
    if (farmerReliability != null) {
      if (farmerReliability.isHighlyReliable) {
        recommendedBid *= 1.05; // 5% premium for reliable farmers
        confidenceScore += 0.1;
        reasoning += '. Premium added for highly reliable farmer';
      } else if (farmerReliability.isLowReliability) {
        recommendedBid *= 0.95; // 5% discount for unreliable farmers
        confidenceScore -= 0.1;
        reasoning += '. Discount applied for farmer reliability concerns';
      }
    }

    // Adjust based on distributor history
    if (distributorHistory != null) {
      if (distributorHistory.overallWinRate > 0.7) {
        recommendedBid *= 1.03; // 3% premium for successful distributors
        confidenceScore += 0.1;
        reasoning += '. Premium for high win rate';
      }
    }

    // Adjust based on time left
    final hoursLeft = crop.timeLeft.inHours;
    if (hoursLeft < 2) {
      recommendedBid *= 1.1; // 10% premium for urgent auctions
      reasoning += '. Premium for urgent auction';
    } else if (hoursLeft > 24) {
      recommendedBid *= 0.98; // 2% discount for long auctions
      reasoning += '. Discount for long auction duration';
    }

    // Ensure bid is at least minimum
    recommendedBid = recommendedBid < crop.minBidPrice ? crop.minBidPrice : recommendedBid;

    // Cap confidence score
    confidenceScore = confidenceScore.clamp(0.0, 1.0);

    return BiddingAnalysisModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      distributorId: distributorId,
      cropId: crop.id,
      cropName: crop.cropName,
      recommendedBid: recommendedBid,
      confidenceScore: confidenceScore,
      reasoning: reasoning,
      marketFactors: marketData?.toFirestore() ?? {},
      farmerReliability: farmerReliability?.toFirestore() ?? {},
      historicalData: {},
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
    );
  }

  /// Update market data for a crop
  Future<void> updateMarketData(String cropName) async {
    try {
      final querySnapshot = await _cropsCollection
          .where('cropName', isEqualTo: cropName)
          .where('status', isEqualTo: 'sold')
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final List<double> prices = [];
      final Map<String, int> seasonalData = {};
      final Map<String, double> locationData = {};
      int successfulAuctions = 0;

      for (final doc in querySnapshot.docs) {
        final crop = CropModel.fromFirestore(doc);
        if (crop.order != null) {
          final pricePerKg = crop.order!.finalPrice / crop.quantity;
          prices.add(pricePerKg);
          successfulAuctions++;

          // Seasonal data
          final month = crop.createdAt.month.toString();
          seasonalData[month] = (seasonalData[month] ?? 0) + 1;

          // Location data
          final location = crop.pickupLocation;
          locationData[location] = (locationData[location] ?? 0) + pricePerKg;
        }
      }

      if (prices.isEmpty) return;

      prices.sort();
      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final minPrice = prices.first;
      final maxPrice = prices.last;
      final successRate = successfulAuctions / querySnapshot.docs.length;

      // Calculate seasonal trends
      final Map<String, double> seasonalTrends = {};
      for (final entry in seasonalData.entries) {
        seasonalTrends[entry.key] = entry.value / successfulAuctions;
      }

      // Calculate location factors
      final Map<String, double> locationFactors = {};
      for (final entry in locationData.entries) {
        locationFactors[entry.key] = entry.value / seasonalData.length;
      }

      final marketData = MarketDataModel(
        cropName: cropName,
        averagePrice: averagePrice,
        minPrice: minPrice,
        maxPrice: maxPrice,
        totalAuctions: querySnapshot.docs.length,
        successfulAuctions: successfulAuctions,
        successRate: successRate,
        seasonalTrends: seasonalTrends,
        locationFactors: locationFactors,
        lastUpdated: DateTime.now(),
      );

      await _marketDataCollection.doc(cropName.toLowerCase()).set(marketData.toFirestore());
    } catch (e) {
      print('Error updating market data: $e');
    }
  }

  /// Update farmer reliability data
  Future<void> updateFarmerReliability(String farmerId) async {
    try {
      final querySnapshot = await _cropsCollection
          .where('farmerId', isEqualTo: farmerId)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final List<CropModel> crops = querySnapshot.docs
          .map((doc) => CropModel.fromFirestore(doc))
          .toList();

      int totalCrops = crops.length;
      int successfulDeliveries = 0;
      double totalQualityRating = 0;
      int totalRatings = 0;
      final Map<String, dynamic> deliveryHistory = {};
      final Map<String, dynamic> qualityMetrics = {};

      for (final crop in crops) {
        if (crop.order != null && crop.order!.orderStatus == 'completed') {
          successfulDeliveries++;
          
          // Simulate quality rating (in real app, this would come from reviews)
          final qualityRating = 4.0 + (crop.order!.finalPrice / crop.quantity) / 100;
          totalQualityRating += qualityRating;
          totalRatings++;
        }
      }

      final deliverySuccessRate = totalCrops > 0 ? successfulDeliveries / totalCrops : 0.0;
      final averageQualityRating = totalRatings > 0 ? totalQualityRating / totalRatings : 0.0;
      
      // Calculate reliability score
      final reliabilityScore = (deliverySuccessRate * 0.6) + (averageQualityRating / 5.0 * 0.4);

      final farmerReliability = FarmerReliabilityModel(
        farmerId: farmerId,
        farmerName: 'Farmer', // Would get from user profile
        reliabilityScore: reliabilityScore,
        totalCrops: totalCrops,
        successfulDeliveries: successfulDeliveries,
        deliverySuccessRate: deliverySuccessRate,
        averageQualityRating: averageQualityRating,
        totalRatings: totalRatings,
        deliveryHistory: deliveryHistory,
        qualityMetrics: qualityMetrics,
        lastUpdated: DateTime.now(),
      );

      await _farmerReliabilityCollection.doc(farmerId).set(farmerReliability.toFirestore());
    } catch (e) {
      print('Error updating farmer reliability: $e');
    }
  }

  /// Update distributor bidding history
  Future<void> updateDistributorHistory(String distributorId) async {
    try {
      final querySnapshot = await _cropsCollection
          .where('bids', arrayContains: {'distributorId': distributorId})
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final Map<String, List<BidHistoryEntry>> bidHistory = {};
      final Map<String, double> winRatesByCrop = {};
      final Map<String, double> averageBidsByCrop = {};
      int totalBids = 0;
      int totalWins = 0;
      double totalBidAmount = 0;

      for (final doc in querySnapshot.docs) {
        final crop = CropModel.fromFirestore(doc);
        final userBid = crop.getUserBid(distributorId);
        
        if (userBid != null) {
          totalBids++;
          totalBidAmount += userBid.amount;
          
          final won = crop.isUserHighestBidder(distributorId);
          if (won) totalWins++;

          final entry = BidHistoryEntry(
            cropId: crop.id,
            cropName: crop.cropName,
            bidAmount: userBid.amount,
            won: won,
            bidDate: userBid.createdAt,
            finalPrice: crop.order?.finalPrice ?? userBid.amount,
          );

          if (bidHistory[crop.cropName] == null) {
            bidHistory[crop.cropName] = [];
          }
          bidHistory[crop.cropName]!.add(entry);
        }
      }

      // Calculate win rates and averages by crop
      for (final entry in bidHistory.entries) {
        final cropName = entry.key;
        final bids = entry.value;
        
        final wins = bids.where((b) => b.won).length;
        winRatesByCrop[cropName] = bids.isNotEmpty ? wins / bids.length : 0.0;
        
        final totalBidAmountForCrop = bids.fold<double>(0, (sum, bid) => sum + bid.bidAmount);
        averageBidsByCrop[cropName] = bids.isNotEmpty ? totalBidAmountForCrop / bids.length : 0.0;
      }

      final overallWinRate = totalBids > 0 ? totalWins / totalBids : 0.0;
      final averageBidAmount = totalBids > 0 ? totalBidAmount / totalBids : 0.0;

      final distributorHistory = DistributorBiddingHistoryModel(
        distributorId: distributorId,
        distributorName: 'Distributor', // Would get from user profile
        bidHistory: bidHistory,
        winRatesByCrop: winRatesByCrop,
        averageBidsByCrop: averageBidsByCrop,
        overallWinRate: overallWinRate,
        averageBidAmount: averageBidAmount,
        totalBids: totalBids,
        totalWins: totalWins,
        lastUpdated: DateTime.now(),
      );

      await _distributorHistoryCollection.doc(distributorId).set(distributorHistory.toFirestore());
    } catch (e) {
      print('Error updating distributor history: $e');
    }
  }

  /// Get all analyses for a distributor
  Stream<List<BiddingAnalysisModel>> getDistributorAnalyses(String distributorId) {
    return _biddingAnalysisCollection
        .where('distributorId', isEqualTo: distributorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BiddingAnalysisModel.fromFirestore(doc)).toList();
    });
  }

  /// Get analysis for a specific crop
  Future<BiddingAnalysisModel?> getAnalysisForCrop(String distributorId, String cropId) async {
    try {
      final querySnapshot = await _biddingAnalysisCollection
          .where('distributorId', isEqualTo: distributorId)
          .where('cropId', isEqualTo: cropId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return BiddingAnalysisModel.fromFirestore(querySnapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error getting analysis for crop: $e');
      return null;
    }
  }
}
