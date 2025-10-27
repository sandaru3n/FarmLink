import 'package:flutter/material.dart';
import '../services/market_insights_service.dart';

class MarketInsightsWidget extends StatefulWidget {
  final String? cropName;
  final bool showAllCrops;

  const MarketInsightsWidget({
    super.key,
    this.cropName,
    this.showAllCrops = false,
  });

  @override
  State<MarketInsightsWidget> createState() => _MarketInsightsWidgetState();
}

class _MarketInsightsWidgetState extends State<MarketInsightsWidget> {
  final MarketInsightsService _marketInsightsService = MarketInsightsService();
  Map<String, dynamic>? _insights;
  List<Map<String, dynamic>>? _allInsights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.showAllCrops) {
        _allInsights = await _marketInsightsService.getAllMarketInsights();
      } else if (widget.cropName != null) {
        _insights = await _marketInsightsService.getBestTimeToBuyInsights(widget.cropName!);
      }
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

    if (widget.showAllCrops && _allInsights != null) {
      return _buildAllInsightsWidget();
    } else if (_insights != null) {
      return _buildSingleInsightWidget();
    }

    return _buildNoDataWidget();
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Analyzing market trends...'),
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
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[600]!,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load market insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[700]!,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]!),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadInsights,
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
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            color: Colors.grey[600]!,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No market data available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700]!,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Market insights will appear as more data becomes available',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]!),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleInsightWidget() {
    final insights = _insights!;
    final recommendations = insights['recommendations'] as List<String>;
    final warnings = insights['warnings'] as List<String>;
    final confidence = insights['confidence'] as String;
    final dataPoints = insights['dataPoints'] as int;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(insights['cropName'], confidence, dataPoints),
          const SizedBox(height: 16),
          if (recommendations.isNotEmpty) ...[
            _buildSection('💡 Recommendations', recommendations, Colors.green),
            const SizedBox(height: 16),
          ],
          if (warnings.isNotEmpty) ...[
            _buildSection('⚠️ Warnings', warnings, Colors.orange),
            const SizedBox(height: 16),
          ],
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildAllInsightsWidget() {
    final insights = _allInsights!;
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: Colors.blue[600]!,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Market Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700]!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Crops Analyzed', insights.length.toString(), Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('High Confidence', 
                      insights.where((i) => i['confidence'] == 'High').length.toString(), 
                      Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...insights.map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildInsightCard(insight),
        )),
      ],
    );
  }

  Widget _buildHeader(String cropName, String confidence, int dataPoints) {
    Color confidenceColor;
    switch (confidence) {
      case 'High':
        confidenceColor = Colors.green;
        break;
      case 'Medium':
        confidenceColor = Colors.orange;
        break;
      default:
        confidenceColor = Colors.red;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.schedule,
            color: Colors.blue[600]!,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Best Time to Buy - $cropName',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: confidenceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$confidence Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: confidenceColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$dataPoints data points',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600]!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green[700]!,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.green[600]!,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue[600]!,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Insights based on historical price data. Always verify current market conditions.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[700]!,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    final recommendations = insight['recommendations'] as List<String>;
    final warnings = insight['warnings'] as List<String>;
    final confidence = insight['confidence'] as String;
    final dataPoints = insight['dataPoints'] as int;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                insight['cropName'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
          if (recommendations.isNotEmpty)
            Text(
              recommendations.first,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700]!,
              ),
            ),
          if (warnings.isNotEmpty)
            Text(
              warnings.first,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[700]!,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            '$dataPoints data points',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
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
