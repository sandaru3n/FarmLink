import 'package:flutter/material.dart';
import '../services/market_insights_service.dart';

class ConsumerMarketInsightsWidget extends StatefulWidget {
  const ConsumerMarketInsightsWidget({super.key});

  @override
  State<ConsumerMarketInsightsWidget> createState() => _ConsumerMarketInsightsWidgetState();
}

class _ConsumerMarketInsightsWidgetState extends State<ConsumerMarketInsightsWidget> {
  final MarketInsightsService _marketInsightsService = MarketInsightsService();
  Map<String, dynamic>? _consumerInsights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConsumerInsights();
  }

  Future<void> _loadConsumerInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _consumerInsights = await _marketInsightsService.getConsumerMarketInsights();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_consumerInsights != null) {
      return _buildConsumerInsightsWidget();
    }

    return _buildNoDataWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing consumer trends...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load consumer insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadConsumerInsights,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            color: Colors.grey[600],
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No consumer data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Consumer insights will appear as more market data becomes available',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerInsightsWidget() {
    final insights = _consumerInsights!;
    final generalRecommendations = insights['generalRecommendations'] as List<String>;
    final timingTips = insights['timingTips'] as List<String>;
    final moneySavingTips = insights['moneySavingTips'] as List<String>;
    final bestDeals = insights['bestDeals'] as Map<String, dynamic>;
    final totalCrops = insights['totalProductsAnalyzed'] as int;
    final aiGenerated = insights['aiGenerated'] as bool? ?? false;
    final summary = insights['summary'] as String? ?? '';
    final productInsights = insights['productInsights'] as List<String>? ?? [];
    final seasonalAdvice = insights['seasonalAdvice'] as List<String>? ?? [];
    final technologyTips = insights['technologyTips'] as List<String>? ?? [];

    return Column(
      children: [
        // Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue[500]!,
                Colors.blue[700]!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue[300]!,
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      aiGenerated ? Icons.psychology : Icons.shopping_cart,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    aiGenerated ? 'AI Smart Shopping Guide' : 'Smart Shopping Guide',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (aiGenerated) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                aiGenerated 
                  ? 'AI-powered insights to help you save money and get the best deals on products'
                  : 'Data-driven insights to help you save money and get the best deals on products',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on $totalCrops products analyzed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white60,
                ),
              ),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Timing Tips Section
        _buildSectionCard(
          '⏰ Best Time to Buy Products',
          timingTips,
          Colors.blue,
          Icons.schedule,
        ),
        const SizedBox(height: 16),

        // Money Saving Tips Section
        _buildSectionCard(
          '💰 Money Saving Tips',
          moneySavingTips,
          Colors.green,
          Icons.savings,
        ),
        const SizedBox(height: 16),

        // General Recommendations Section
        _buildSectionCard(
          '🛒 Shopping Recommendations',
          generalRecommendations,
          Colors.orange,
          Icons.shopping_bag,
        ),
        const SizedBox(height: 16),

        // Product Insights Section (AI-specific)
        if (productInsights.isNotEmpty) ...[
          _buildSectionCard(
            '🎯 Product-Specific Insights',
            productInsights,
            Colors.purple,
            Icons.analytics,
          ),
          const SizedBox(height: 16),
        ],

        // Seasonal Advice Section (AI-specific)
        if (seasonalAdvice.isNotEmpty) ...[
          _buildSectionCard(
            '🌱 Seasonal Shopping Advice',
            seasonalAdvice,
            Colors.teal,
            Icons.calendar_today,
          ),
          const SizedBox(height: 16),
        ],

        // Technology Tips Section (AI-specific)
        if (technologyTips.isNotEmpty) ...[
          _buildSectionCard(
            '📱 Technology & App Tips',
            technologyTips,
            Colors.indigo,
            Icons.phone_android,
          ),
          const SizedBox(height: 16),
        ],

        // Best Deals Section
        if (bestDeals.isNotEmpty) ...[
          _buildBestDealsCard(bestDeals),
          const SizedBox(height: 16),
        ],

        // Footer
        _buildFooter(),
      ],
    );
  }

  Widget _buildSectionCard(String title, List<String> items, Color color, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.blue[100]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildBestDealsCard(Map<String, dynamic> bestDeals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.amber[100]!,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_offer,
                  color: Colors.amber[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '🔥 Best Deals by Product',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...bestDeals.entries.map((entry) {
            final cropName = entry.key;
            final deal = entry.value as Map<String, dynamic>;
            final bestDay = deal['bestDay'] as String;
            final daySavings = deal['daySavings'] as int;
            final bestMonth = deal['bestMonth'] as String;
            final monthSavings = deal['monthSavings'] as int;
            final confidence = deal['confidence'] as String;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        cropName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[800],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getConfidenceColor(confidence).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          confidence,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getConfidenceColor(confidence),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Best day: $bestDay (${daySavings}% off)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 14, color: Colors.amber[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Best month: $bestMonth (${monthSavings}% off)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600],
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Insights based on historical market data. Always verify current prices and availability.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(String confidence) {
    switch (confidence) {
      case 'High':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
