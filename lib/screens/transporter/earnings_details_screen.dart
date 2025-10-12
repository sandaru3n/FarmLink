import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transport_order_provider.dart';
import '../../models/transport_order_model.dart';
import '../../utils/app_localizations.dart';

class EarningsDetailsScreen extends StatefulWidget {
  const EarningsDetailsScreen({super.key});

  @override
  State<EarningsDetailsScreen> createState() => _EarningsDetailsScreenState();
}

class _EarningsDetailsScreenState extends State<EarningsDetailsScreen> {
  String _selectedFilter = 'Week';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Consumer<TransportOrderProvider>(
        builder: (context, transportOrderProvider, child) {
          final deliveredOrders = transportOrderProvider.deliveredTransportOrders;
          
          if (transportOrderProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.get('loading'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return Column(
            children: [
              // Modern Purple Header
              _buildModernHeader(context),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filter Options
                      _buildFilterSection(),
                      const SizedBox(height: 20),
                      
                      // Line Chart Card
                      _buildLineChartCard(deliveredOrders),
                      const SizedBox(height: 20),
                      
                      // Daily Earnings Bar Chart Card
                      _buildDailyEarningsCard(deliveredOrders),
                      const SizedBox(height: 20),
                      
                      // Earnings by Destination Pie Chart Card
                      _buildEarningsByDestinationCard(deliveredOrders),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade700,
            Colors.deepPurple.shade500,
            Colors.deepPurple.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.get('earnings'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  l10n.get('filter_by'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildFilterChip('Day', _selectedFilter == 'Day'),
                const SizedBox(width: 12),
                _buildFilterChip('Week', _selectedFilter == 'Week'),
                const SizedBox(width: 12),
                _buildFilterChip('Month', _selectedFilter == 'Month'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.deepPurple.shade600,
                    Colors.deepPurple.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              setState(() {
                _selectedFilter = label;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected) ...[
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartCard(List<TransportOrderModel> deliveredOrders) {
    final l10n = AppLocalizations.of(context);
    final earningsData = _getEarningsData(deliveredOrders);
    final totalEarnings = earningsData.fold<double>(0, (sum, data) => sum + (data['earnings'] as double));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade400,
                        Colors.deepPurple.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('earnings_trend'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'Total: LKR ${totalEarnings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade50,
                    Colors.deepPurple.shade100.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.deepPurple.shade200),
              ),
              child: _buildLineChart(earningsData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    final l10n = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
        child: Text(
          l10n.get('no_earnings_data'),
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      );
    }

    final maxEarnings = data.map((e) => e['earnings'] as double).reduce((a, b) => a > b ? a : b);
    
    return CustomPaint(
      painter: LineChartPainter(data, maxEarnings),
      size: const Size(double.infinity, 200),
    );
  }

  Widget _buildDailyEarningsCard(List<TransportOrderModel> deliveredOrders) {
    final l10n = AppLocalizations.of(context);
    final dailyData = _getDailyEarningsData(deliveredOrders);
    final totalDailyEarnings = dailyData.fold<double>(0, (sum, data) => sum + (data['earnings'] as double));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.get('earnings'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'Total: LKR ${totalDailyEarnings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.green.shade100.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: _buildBarChart(dailyData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    final l10n = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
        child: Text(
          l10n.get('no_earnings_data'),
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      );
    }

    final maxEarnings = data.map((e) => e['earnings'] as double).reduce((a, b) => a > b ? a : b);
    
    return CustomPaint(
      painter: BarChartPainter(data, maxEarnings),
      size: const Size(double.infinity, 200),
    );
  }

  Widget _buildEarningsByDestinationCard(List<TransportOrderModel> deliveredOrders) {
    final destinationData = _getEarningsByDestinationData(deliveredOrders);
    final totalDestinationEarnings = destinationData.fold<double>(0, (sum, data) => sum + (data['earnings'] as double));
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.shade400,
                        Colors.orange.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.pie_chart,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings by Destination',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        'Total: LKR ${totalDestinationEarnings.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade50,
                          Colors.orange.shade100.withOpacity(0.3),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: _buildPieChart(destinationData),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: _buildDestinationLegend(destinationData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> data) {
    final l10n = AppLocalizations.of(context);
    if (data.isEmpty) {
      return Center(
        child: Text(
          l10n.get('no_earnings_data'),
          style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        ),
      );
    }

    return CustomPaint(
      painter: PieChartPainter(data),
      size: const Size(200, 200),
    );
  }

  Widget _buildDestinationLegend(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const SizedBox();
    }

    final colors = [
      Colors.deepPurple.shade600,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final percentage = item['percentage'] as double;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getEarningsData(List<TransportOrderModel> deliveredOrders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedFilter) {
      case 'Day':
        return List.generate(24, (index) {
          final hour = index;
          final earnings = deliveredOrders
              .where((order) {
                if (order.deliveredAt == null) return false;
                return order.deliveredAt!.hour == hour;
              })
              .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
          
          return {
            'label': '${hour.toString().padLeft(2, '0')}:00',
            'earnings': earnings,
          };
        });
        
      case 'Week':
        return List.generate(7, (index) {
          final date = today.subtract(Duration(days: 6 - index));
          final earnings = deliveredOrders
              .where((order) {
                if (order.deliveredAt == null) return false;
                final deliveryDate = DateTime(
                  order.deliveredAt!.year,
                  order.deliveredAt!.month,
                  order.deliveredAt!.day,
                );
                return deliveryDate.isAtSameMomentAs(date);
              })
              .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
          
          final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          return {
            'label': weekdays[date.weekday - 1],
            'earnings': earnings,
          };
        });
        
      case 'Month':
        return List.generate(30, (index) {
          final date = today.subtract(Duration(days: 29 - index));
          final earnings = deliveredOrders
              .where((order) {
                if (order.deliveredAt == null) return false;
                final deliveryDate = DateTime(
                  order.deliveredAt!.year,
                  order.deliveredAt!.month,
                  order.deliveredAt!.day,
                );
                return deliveryDate.isAtSameMomentAs(date);
              })
              .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
          
          return {
            'label': '${date.day}',
            'earnings': earnings,
          };
        });
        
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getDailyEarningsData(List<TransportOrderModel> deliveredOrders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return List.generate(7, (index) {
      final date = today.subtract(Duration(days: 6 - index));
      final earnings = deliveredOrders
          .where((order) {
            if (order.deliveredAt == null) return false;
            final deliveryDate = DateTime(
              order.deliveredAt!.year,
              order.deliveredAt!.month,
              order.deliveredAt!.day,
            );
            return deliveryDate.isAtSameMomentAs(date);
          })
          .fold<double>(0, (sum, order) => sum + (order.deliveryFee ?? 0));
      
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return {
        'label': weekdays[date.weekday - 1],
        'earnings': earnings,
      };
    });
  }

  List<Map<String, dynamic>> _getEarningsByDestinationData(List<TransportOrderModel> deliveredOrders) {
    final Map<String, double> destinationEarnings = {};
    
    for (final order in deliveredOrders) {
      if (order.deliveredAt != null) {
        final destination = order.distributorLocation;
        destinationEarnings[destination] = (destinationEarnings[destination] ?? 0) + (order.deliveryFee ?? 0);
      }
    }
    
    final totalEarnings = destinationEarnings.values.fold<double>(0, (sum, earnings) => sum + earnings);
    
    return destinationEarnings.entries.map((entry) {
      return {
        'label': entry.key,
        'earnings': entry.value,
        'percentage': totalEarnings > 0 ? (entry.value / totalEarnings) * 100 : 0,
      };
    }).toList();
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxEarnings;

  LineChartPainter(this.data, this.maxEarnings);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Create gradient for the line
    final gradient = LinearGradient(
      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final pointPaint = Paint()
      ..color = Colors.deepPurple.shade600
      ..style = PaintingStyle.fill;

    final width = size.width / data.length;
    
    for (int i = 0; i < data.length; i++) {
      final earnings = data[i]['earnings'] as double;
      final x = (i * width) + (width / 2);
      final y = size.height - (earnings / maxEarnings) * size.height;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Draw gradient circle for points
      final circleGradient = RadialGradient(
        colors: [Colors.white, Colors.deepPurple.shade600],
        stops: const [0.3, 1.0],
      );
      final circlePaint = Paint()
        ..shader = circleGradient.createShader(Rect.fromCircle(center: Offset(x, y), radius: 6));
      
      canvas.drawCircle(Offset(x, y), 6, circlePaint);
    }
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxEarnings;

  BarChartPainter(this.data, this.maxEarnings);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final width = size.width / data.length;
    final colors = [
      Colors.deepPurple.shade400,
      Colors.green.shade400,
      Colors.blue.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.teal.shade400,
      Colors.indigo.shade400,
    ];
    
    for (int i = 0; i < data.length; i++) {
      final earnings = data[i]['earnings'] as double;
      final barWidth = width * 0.6;
      final barHeight = (earnings / maxEarnings) * size.height;
      final x = (i * width) + (width - barWidth) / 2;
      final y = size.height - barHeight;
      
      // Create gradient for each bar
      final gradient = LinearGradient(
        colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.7)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(Rect.fromLTWH(x, y, barWidth, barHeight));
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(6),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;
    
    final colors = [
      Colors.deepPurple.shade600,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.pink.shade600,
      Colors.teal.shade600,
      Colors.indigo.shade600,
    ];

    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < data.length; i++) {
      final percentage = data[i]['percentage'] as double;
      final sweepAngle = (percentage / 100) * 2 * math.pi;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}