import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketInsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // AI Configuration
  static const String _geminiApiKey = 'AIzaSyBaFuJUj2nReTooMQ0BNxBnTRmwMZaN_SM';

  /// Get best time to buy insights for a specific crop
  Future<Map<String, dynamic>> getBestTimeToBuyInsights(String cropName) async {
    try {
      // Get historical price data
      final priceData = await _getHistoricalPriceData(cropName);
      
      // Analyze trends
      final trends = _analyzePriceTrends(priceData);
      
      // Generate insights
      final insights = _generateBuyTimingInsights(trends, cropName);
      
      return insights;
    } catch (e) {
      print('Error getting market insights: $e');
      return _getDefaultInsights(cropName);
    }
  }

  /// Get market insights for all crops
  Future<List<Map<String, dynamic>>> getAllMarketInsights() async {
    try {
      final crops = await _getPopularCrops();
      List<Map<String, dynamic>> insights = [];
      
      for (String crop in crops) {
        final insight = await getBestTimeToBuyInsights(crop);
        insights.add(insight);
      }
      
      return insights;
    } catch (e) {
      print('Error getting all market insights: $e');
      return [];
    }
  }

  /// Get historical price data from Firestore
  Future<List<Map<String, dynamic>>> _getHistoricalPriceData(String cropName) async {
    try {
      final querySnapshot = await _firestore
          .collection('crops')
          .where('cropName', isEqualTo: cropName)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'price': data['minBidPrice'] ?? 0.0,
          'date': (data['createdAt'] as Timestamp).toDate(),
          'dayOfWeek': (data['createdAt'] as Timestamp).toDate().weekday,
          'month': (data['createdAt'] as Timestamp).toDate().month,
        };
      }).toList();
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }

  /// Analyze price trends from historical data
  Map<String, dynamic> _analyzePriceTrends(List<Map<String, dynamic>> priceData) {
    if (priceData.isEmpty) {
      return _getDefaultTrends();
    }

    // Analyze by day of week
    Map<int, List<double>> pricesByDay = {};
    Map<int, List<double>> pricesByMonth = {};
    
    for (var data in priceData) {
      final day = data['dayOfWeek'] as int;
      final month = data['month'] as int;
      final price = data['price'] as double;
      
      pricesByDay[day] ??= [];
      pricesByDay[day]!.add(price);
      
      pricesByMonth[month] ??= [];
      pricesByMonth[month]!.add(price);
    }

    // Calculate average prices by day
    Map<int, double> avgPricesByDay = {};
    for (var entry in pricesByDay.entries) {
      avgPricesByDay[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Calculate average prices by month
    Map<int, double> avgPricesByMonth = {};
    for (var entry in pricesByMonth.entries) {
      avgPricesByMonth[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Find best and worst days
    final bestDay = _findBestDay(avgPricesByDay);
    final worstDay = _findWorstDay(avgPricesByDay);
    
    // Find best and worst months
    final bestMonth = _findBestMonth(avgPricesByMonth);
    final worstMonth = _findWorstMonth(avgPricesByMonth);

    return {
      'avgPricesByDay': avgPricesByDay,
      'avgPricesByMonth': avgPricesByMonth,
      'bestDay': bestDay,
      'worstDay': worstDay,
      'bestMonth': bestMonth,
      'worstMonth': worstMonth,
      'totalDataPoints': priceData.length,
    };
  }

  /// Generate buy timing insights
  Map<String, dynamic> _generateBuyTimingInsights(Map<String, dynamic> trends, String cropName) {
    final bestDay = trends['bestDay'];
    final worstDay = trends['worstDay'];
    final bestMonth = trends['bestMonth'];
    final worstMonth = trends['worstMonth'];
    final totalDataPoints = trends['totalDataPoints'];

    List<String> recommendations = [];
    List<String> warnings = [];
    String confidence = 'Low';

    // Day-based recommendations
    if (bestDay != null) {
      recommendations.add('Best day to buy: ${_getDayName(bestDay['day'])} (${bestDay['savings']}% cheaper)');
    }
    
    if (worstDay != null) {
      warnings.add('Avoid buying on ${_getDayName(worstDay['day'])} (${worstDay['premium']}% more expensive)');
    }

    // Month-based recommendations
    if (bestMonth != null) {
      recommendations.add('Best month to buy: ${_getMonthName(bestMonth['month'])} (${bestMonth['savings']}% cheaper)');
    }
    
    if (worstMonth != null) {
      warnings.add('Avoid buying in ${_getMonthName(worstMonth['month'])} (${worstMonth['premium']}% more expensive)');
    }

    // General recommendations
    recommendations.add('Monitor prices for 2-3 days before buying');
    recommendations.add('Consider bulk purchases during low-price periods');
    recommendations.add('Set price alerts for your target crops');

    // Determine confidence level
    if (totalDataPoints > 50) {
      confidence = 'High';
    } else if (totalDataPoints > 20) {
      confidence = 'Medium';
    }

    return {
      'cropName': cropName,
      'confidence': confidence,
      'recommendations': recommendations,
      'warnings': warnings,
      'dataPoints': totalDataPoints,
      'trends': trends,
      'lastUpdated': DateTime.now(),
    };
  }

  /// Find the best day to buy (lowest average price)
  Map<String, dynamic>? _findBestDay(Map<int, double> avgPricesByDay) {
    if (avgPricesByDay.isEmpty) return null;
    
    final sortedDays = avgPricesByDay.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final bestDay = sortedDays.first;
    final avgPrice = avgPricesByDay.values.reduce((a, b) => a + b) / avgPricesByDay.length;
    final savings = ((avgPrice - bestDay.value) / avgPrice * 100).round();
    
    return {
      'day': bestDay.key,
      'avgPrice': bestDay.value,
      'savings': savings,
    };
  }

  /// Find the worst day to buy (highest average price)
  Map<String, dynamic>? _findWorstDay(Map<int, double> avgPricesByDay) {
    if (avgPricesByDay.isEmpty) return null;
    
    final sortedDays = avgPricesByDay.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final worstDay = sortedDays.first;
    final avgPrice = avgPricesByDay.values.reduce((a, b) => a + b) / avgPricesByDay.length;
    final premium = ((worstDay.value - avgPrice) / avgPrice * 100).round();
    
    return {
      'day': worstDay.key,
      'avgPrice': worstDay.value,
      'premium': premium,
    };
  }

  /// Find the best month to buy
  Map<String, dynamic>? _findBestMonth(Map<int, double> avgPricesByMonth) {
    if (avgPricesByMonth.isEmpty) return null;
    
    final sortedMonths = avgPricesByMonth.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final bestMonth = sortedMonths.first;
    final avgPrice = avgPricesByMonth.values.reduce((a, b) => a + b) / avgPricesByMonth.length;
    final savings = ((avgPrice - bestMonth.value) / avgPrice * 100).round();
    
    return {
      'month': bestMonth.key,
      'avgPrice': bestMonth.value,
      'savings': savings,
    };
  }

  /// Find the worst month to buy
  Map<String, dynamic>? _findWorstMonth(Map<int, double> avgPricesByMonth) {
    if (avgPricesByMonth.isEmpty) return null;
    
    final sortedMonths = avgPricesByMonth.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final worstMonth = sortedMonths.first;
    final avgPrice = avgPricesByMonth.values.reduce((a, b) => a + b) / avgPricesByMonth.length;
    final premium = ((worstMonth.value - avgPrice) / avgPrice * 100).round();
    
    return {
      'month': worstMonth.key,
      'avgPrice': worstMonth.value,
      'premium': premium,
    };
  }

  /// Get day name from day number
  String _getDayName(int day) {
    const days = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day];
  }

  /// Get month name from month number
  String _getMonthName(int month) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month];
  }

  /// Get popular crops list
  Future<List<String>> _getPopularCrops() async {
    try {
      final querySnapshot = await _firestore
          .collection('crops')
          .get();
      
      Set<String> crops = {};
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['cropName'] != null) {
          crops.add(data['cropName']);
        }
      }
      
      return crops.toList();
    } catch (e) {
      print('Error getting popular crops: $e');
      return ['Rice', 'Wheat', 'Tomato', 'Potato', 'Onion'];
    }
  }

  /// Get default insights when no data is available
  Map<String, dynamic> _getDefaultInsights(String cropName) {
    return {
      'cropName': cropName,
      'confidence': 'Low',
      'recommendations': [
        'Monitor prices for 2-3 days before buying',
        'Consider bulk purchases during low-price periods',
        'Set price alerts for your target crops',
        'Compare prices across different suppliers',
      ],
      'warnings': [
        'Limited historical data available',
        'Prices may vary significantly',
      ],
      'dataPoints': 0,
      'trends': _getDefaultTrends(),
      'lastUpdated': DateTime.now(),
    };
  }

  /// Get default trends when no data is available
  Map<String, dynamic> _getDefaultTrends() {
    return {
      'avgPricesByDay': {},
      'avgPricesByMonth': {},
      'bestDay': null,
      'worstDay': null,
      'bestMonth': null,
      'worstMonth': null,
      'totalDataPoints': 0,
    };
  }

  /// Get current market status
  Future<Map<String, dynamic>> getCurrentMarketStatus() async {
    try {
      final insights = await getAllMarketInsights();
      
      int totalRecommendations = 0;
      int totalWarnings = 0;
      int highConfidenceInsights = 0;
      
      for (var insight in insights) {
        totalRecommendations += (insight['recommendations'] as List).length;
        totalWarnings += (insight['warnings'] as List).length;
        if (insight['confidence'] == 'High') {
          highConfidenceInsights++;
        }
      }
      
      return {
        'totalCrops': insights.length,
        'totalRecommendations': totalRecommendations,
        'totalWarnings': totalWarnings,
        'highConfidenceInsights': highConfidenceInsights,
        'lastUpdated': DateTime.now(),
      };
    } catch (e) {
      print('Error getting market status: $e');
      return {
        'totalCrops': 0,
        'totalRecommendations': 0,
        'totalWarnings': 0,
        'highConfidenceInsights': 0,
        'lastUpdated': DateTime.now(),
      };
    }
  }

  /// Get consumer-focused market insights with AI
  Future<Map<String, dynamic>> getConsumerMarketInsights() async {
    try {
      final insights = await getAllMarketInsights();
      
      // Generate AI-powered consumer insights
      final aiInsights = await _generateAIConsumerInsights(insights);
      
      return aiInsights;
    } catch (e) {
      print('Error getting AI consumer market insights: $e');
      return _getDefaultConsumerInsights();
    }
  }

  /// Generate AI-powered consumer insights using Gemini
  Future<Map<String, dynamic>> _generateAIConsumerInsights(List<Map<String, dynamic>> insights) async {
    try {
      // Prepare context for AI
      final context = _buildConsumerContext(insights);
      
      // Call Gemini AI
      final aiResponse = await _callGeminiForConsumerInsights(context);
      
      // Parse AI response
      return _parseAIConsumerResponse(aiResponse, insights);
    } catch (e) {
      print('Error generating AI consumer insights: $e');
      return _generateConsumerInsights(insights);
    }
  }

  /// Build context for AI consumer analysis
  String _buildConsumerContext(List<Map<String, dynamic>> insights) {
    final buffer = StringBuffer();
    buffer.writeln('You are an expert consumer shopping AI advisor. Analyze market data and provide smart shopping insights.');
    buffer.writeln('');
    buffer.writeln('MARKET DATA ANALYSIS:');
    buffer.writeln('Total products analyzed: ${insights.length}');
    buffer.writeln('');
    
    // Analyze patterns
    Map<int, int> dayFrequency = {};
    Map<int, double> daySavings = {};
    List<String> productNames = [];
    
    for (var insight in insights) {
      final productName = insight['cropName'] as String;
      productNames.add(productName);
      
      final trends = insight['trends'] as Map<String, dynamic>;
      final bestDay = trends['bestDay'];
      
      if (bestDay != null) {
        final day = bestDay['day'] as int;
        dayFrequency[day] = (dayFrequency[day] ?? 0) + 1;
        daySavings[day] = (daySavings[day] ?? 0) + bestDay['savings'];
      }
    }
    
    buffer.writeln('PRODUCTS ANALYZED:');
    for (var product in productNames) {
      buffer.writeln('- $product');
    }
    buffer.writeln('');
    
    if (dayFrequency.isNotEmpty) {
      buffer.writeln('TIMING PATTERNS:');
      for (var entry in dayFrequency.entries) {
        final dayName = _getDayName(entry.key);
        final avgSavings = daySavings[entry.key]! / entry.value;
        buffer.writeln('- $dayName: ${entry.value} products show best deals (${avgSavings.round()}% avg savings)');
      }
      buffer.writeln('');
    }
    
    buffer.writeln('Please provide comprehensive consumer shopping insights covering:');
    buffer.writeln('1. Smart timing recommendations (when to shop)');
    buffer.writeln('2. Money-saving strategies (how to save)');
    buffer.writeln('3. Product-specific tips (what to buy)');
    buffer.writeln('4. Quality and freshness advice');
    buffer.writeln('5. Seasonal shopping patterns');
    buffer.writeln('6. Deal optimization strategies');
    buffer.writeln('7. Budget-friendly shopping tips');
    buffer.writeln('8. Technology and app recommendations');
    buffer.writeln('');
    buffer.writeln('IMPORTANT: Format your response as JSON with these keys:');
    buffer.writeln('- "timingTips": Array of timing recommendations');
    buffer.writeln('- "moneySavingTips": Array of money-saving strategies');
    buffer.writeln('- "generalRecommendations": Array of general shopping tips');
    buffer.writeln('- "productInsights": Array of product-specific insights');
    buffer.writeln('- "seasonalAdvice": Array of seasonal shopping advice');
    buffer.writeln('- "technologyTips": Array of tech/app recommendations');
    buffer.writeln('- "summary": Brief summary of key insights');
    
    return buffer.toString();
  }

  /// Call Gemini AI for consumer insights
  Future<String> _callGeminiForConsumerInsights(String context) async {
    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$_geminiApiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': context,
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      }
      
      throw Exception('Failed to get AI response: ${response.statusCode}');
    } catch (e) {
      print('Error calling Gemini for consumer insights: $e');
      throw e;
    }
  }

  /// Parse AI response for consumer insights
  Map<String, dynamic> _parseAIConsumerResponse(String aiResponse, List<Map<String, dynamic>> insights) {
    try {
      // Try to parse as JSON first
      final jsonMatch = RegExp(r'\{.*\}', multiLine: true, dotAll: true).firstMatch(aiResponse);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final parsed = jsonDecode(jsonString) as Map<String, dynamic>;
        
        return {
          'generalRecommendations': parsed['generalRecommendations'] ?? [],
          'timingTips': parsed['timingTips'] ?? [],
          'moneySavingTips': parsed['moneySavingTips'] ?? [],
          'productInsights': parsed['productInsights'] ?? [],
          'seasonalAdvice': parsed['seasonalAdvice'] ?? [],
          'technologyTips': parsed['technologyTips'] ?? [],
          'summary': parsed['summary'] ?? 'AI-powered shopping insights',
          'bestDeals': _extractBestDeals(insights),
          'totalProductsAnalyzed': insights.length,
          'lastUpdated': DateTime.now(),
          'aiGenerated': true,
        };
      }
    } catch (e) {
      print('Error parsing AI JSON response: $e');
    }
    
    // Fallback: parse as text and extract insights
    return _parseTextAIConsumerResponse(aiResponse, insights);
  }

  /// Parse text-based AI response
  Map<String, dynamic> _parseTextAIConsumerResponse(String aiResponse, List<Map<String, dynamic>> insights) {
    final lines = aiResponse.split('\n');
    List<String> timingTips = [];
    List<String> moneySavingTips = [];
    List<String> generalRecommendations = [];
    List<String> productInsights = [];
    List<String> seasonalAdvice = [];
    List<String> technologyTips = [];
    
    String currentSection = '';
    
    for (var line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;
      
      // Detect sections
      if (trimmedLine.toLowerCase().contains('timing') || trimmedLine.toLowerCase().contains('when to shop')) {
        currentSection = 'timing';
      } else if (trimmedLine.toLowerCase().contains('money') || trimmedLine.toLowerCase().contains('save')) {
        currentSection = 'money';
      } else if (trimmedLine.toLowerCase().contains('general') || trimmedLine.toLowerCase().contains('shopping')) {
        currentSection = 'general';
      } else if (trimmedLine.toLowerCase().contains('product') || trimmedLine.toLowerCase().contains('specific')) {
        currentSection = 'product';
      } else if (trimmedLine.toLowerCase().contains('seasonal') || trimmedLine.toLowerCase().contains('season')) {
        currentSection = 'seasonal';
      } else if (trimmedLine.toLowerCase().contains('technology') || trimmedLine.toLowerCase().contains('app')) {
        currentSection = 'technology';
      } else if (trimmedLine.startsWith('-') || trimmedLine.startsWith('•') || trimmedLine.startsWith('*')) {
        // Add to current section
        final tip = trimmedLine.replaceFirst(RegExp(r'^[-•*]\s*'), '');
        switch (currentSection) {
          case 'timing':
            timingTips.add(tip);
            break;
          case 'money':
            moneySavingTips.add(tip);
            break;
          case 'general':
            generalRecommendations.add(tip);
            break;
          case 'product':
            productInsights.add(tip);
            break;
          case 'seasonal':
            seasonalAdvice.add(tip);
            break;
          case 'technology':
            technologyTips.add(tip);
            break;
        }
      }
    }
    
    return {
      'generalRecommendations': generalRecommendations.isNotEmpty ? generalRecommendations : _getDefaultGeneralRecommendations(),
      'timingTips': timingTips.isNotEmpty ? timingTips : _getDefaultTimingTips(),
      'moneySavingTips': moneySavingTips.isNotEmpty ? moneySavingTips : _getDefaultMoneySavingTips(),
      'productInsights': productInsights,
      'seasonalAdvice': seasonalAdvice,
      'technologyTips': technologyTips,
      'summary': 'AI-powered shopping insights',
      'bestDeals': _extractBestDeals(insights),
      'totalProductsAnalyzed': insights.length,
      'lastUpdated': DateTime.now(),
      'aiGenerated': true,
    };
  }

  /// Extract best deals from insights
  Map<String, dynamic> _extractBestDeals(List<Map<String, dynamic>> insights) {
    Map<String, dynamic> bestDeals = {};
    
    for (var insight in insights) {
      final productName = insight['cropName'] as String;
      final trends = insight['trends'] as Map<String, dynamic>;
      final bestDay = trends['bestDay'];
      final bestMonth = trends['bestMonth'];
      
      if (bestDay != null && bestMonth != null) {
        bestDeals[productName] = {
          'bestDay': _getDayName(bestDay['day']),
          'daySavings': bestDay['savings'],
          'bestMonth': _getMonthName(bestMonth['month']),
          'monthSavings': bestMonth['savings'],
          'confidence': insight['confidence'],
        };
      }
    }
    
    return bestDeals;
  }

  /// Get default general recommendations
  List<String> _getDefaultGeneralRecommendations() {
    return [
      'Shop early in the morning for freshest products',
      'Buy seasonal products for better prices',
      'Compare prices across multiple vendors',
      'Consider bulk purchases for non-perishables',
      'Look for local markets for direct deals',
      'Check expiration dates before purchasing',
      'Buy organic products when on sale',
    ];
  }

  /// Get default timing tips
  List<String> _getDefaultTimingTips() {
    return [
      'Prices usually drop on Fridays',
      'Avoid shopping on weekends for better deals',
      'Early morning purchases often have better quality',
      'End-of-day sales can offer significant discounts',
      'Mid-week shopping typically has lower prices',
      'Holiday sales offer 20-50% discounts',
      'Clearance sales happen at month-end',
    ];
  }

  /// Get default money saving tips
  List<String> _getDefaultMoneySavingTips() {
    return [
      'Buy in-season products for 20-30% savings',
      'Purchase directly from farmers when possible',
      'Use mobile apps to compare prices instantly',
      'Join local co-ops for bulk buying discounts',
      'Plan meals around sale items',
      'Freeze excess products to avoid waste',
      'Buy generic brands for 15-25% savings',
      'Use coupons and loyalty programs',
    ];
  }

  /// Generate consumer-specific insights for products
  Map<String, dynamic> _generateConsumerInsights(List<Map<String, dynamic>> insights) {
    List<String> generalRecommendations = [];
    List<String> timingTips = [];
    List<String> moneySavingTips = [];
    Map<String, dynamic> bestDeals = {};
    
    // Analyze all products for general patterns
    Map<int, int> dayFrequency = {};
    Map<int, double> daySavings = {};
    
    for (var insight in insights) {
      final trends = insight['trends'] as Map<String, dynamic>;
      final bestDay = trends['bestDay'];
      final worstDay = trends['worstDay'];
      
      if (bestDay != null) {
        final day = bestDay['day'] as int;
        dayFrequency[day] = (dayFrequency[day] ?? 0) + 1;
        daySavings[day] = (daySavings[day] ?? 0) + bestDay['savings'];
      }
    }
    
    // Find most common best day
    if (dayFrequency.isNotEmpty) {
      final mostCommonDay = dayFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);
      final avgSavings = daySavings[mostCommonDay.key]! / dayFrequency[mostCommonDay.key]!;
      
      timingTips.add('${_getDayName(mostCommonDay.key)} is the best day to buy products (${avgSavings.round()}% average savings)');
    }
    
    // Generate general recommendations for products
    generalRecommendations.addAll([
      'Shop early in the morning for freshest products',
      'Buy seasonal products for better prices',
      'Compare prices across multiple vendors',
      'Consider bulk purchases for non-perishables',
      'Look for local markets for direct deals',
      'Check expiration dates before purchasing',
      'Buy organic products when on sale',
    ]);
    
    // Generate timing tips for products
    timingTips.addAll([
      'Prices usually drop on Fridays',
      'Avoid shopping on weekends for better deals',
      'Early morning purchases often have better quality',
      'End-of-day sales can offer significant discounts',
      'Mid-week shopping typically has lower prices',
      'Holiday sales offer 20-50% discounts',
      'Clearance sales happen at month-end',
    ]);
    
    // Generate money-saving tips for products
    moneySavingTips.addAll([
      'Buy in-season products for 20-30% savings',
      'Purchase directly from farmers when possible',
      'Use mobile apps to compare prices instantly',
      'Join local co-ops for bulk buying discounts',
      'Plan meals around sale items',
      'Freeze excess products to avoid waste',
      'Buy generic brands for 15-25% savings',
      'Use coupons and loyalty programs',
    ]);
    
    // Find best deals by product
    for (var insight in insights) {
      final productName = insight['cropName'] as String; // Using cropName field for products
      final trends = insight['trends'] as Map<String, dynamic>;
      final bestDay = trends['bestDay'];
      final bestMonth = trends['bestMonth'];
      
      if (bestDay != null && bestMonth != null) {
        bestDeals[productName] = {
          'bestDay': _getDayName(bestDay['day']),
          'daySavings': bestDay['savings'],
          'bestMonth': _getMonthName(bestMonth['month']),
          'monthSavings': bestMonth['savings'],
          'confidence': insight['confidence'],
        };
      }
    }
    
    return {
      'generalRecommendations': generalRecommendations,
      'timingTips': timingTips,
      'moneySavingTips': moneySavingTips,
      'bestDeals': bestDeals,
      'totalProductsAnalyzed': insights.length,
      'lastUpdated': DateTime.now(),
    };
  }

  /// Get default consumer insights
  Map<String, dynamic> _getDefaultConsumerInsights() {
    return {
      'generalRecommendations': [
        'Shop early in the morning for freshest products',
        'Buy seasonal products for better prices',
        'Compare prices across multiple vendors',
        'Consider bulk purchases for non-perishables',
        'Look for local markets for direct deals',
        'Check expiration dates before purchasing',
        'Buy organic products when on sale',
      ],
      'timingTips': [
        'Prices usually drop on Fridays',
        'Avoid shopping on weekends for better deals',
        'Early morning purchases often have better quality',
        'End-of-day sales can offer significant discounts',
        'Mid-week shopping typically has lower prices',
        'Holiday sales offer 20-50% discounts',
        'Clearance sales happen at month-end',
      ],
      'moneySavingTips': [
        'Buy in-season products for 20-30% savings',
        'Purchase directly from farmers when possible',
        'Use mobile apps to compare prices instantly',
        'Join local co-ops for bulk buying discounts',
        'Plan meals around sale items',
        'Freeze excess products to avoid waste',
        'Buy generic brands for 15-25% savings',
        'Use coupons and loyalty programs',
      ],
      'bestDeals': {},
      'totalProductsAnalyzed': 0,
      'lastUpdated': DateTime.now(),
    };
  }
}
