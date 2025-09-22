import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_localizations.dart';
import '../../settings/fooddistributor_settings_screen.dart';
import '../../distributor/crop_marketplace_screen.dart';
import '../../distributor/distributor_orders_screen.dart';
import '../../distributor/product_list_screen.dart';
import '../../../services/crop_service.dart';
import '../../../services/order_service.dart';
import '../../../models/crop_model.dart';

class FoodDistributorDashboard extends StatefulWidget {
  final int? initialTabIndex;
  const FoodDistributorDashboard({super.key, this.initialTabIndex});

  @override
  State<FoodDistributorDashboard> createState() => _FoodDistributorDashboardState();
}

class _FoodDistributorDashboardState extends State<FoodDistributorDashboard> {
  static int _lastIndex = 0;
  int _currentIndex = 0;
  int _analyticsDays = 7; // 7 or 30

  @override
  void initState() {
    super.initState();
    // Preserve last selected tab across rebuilds or use explicitly provided initial index
    _currentIndex = widget.initialTabIndex ?? _lastIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!authProvider.isLoggedIn) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in'),
            ),
          );
        }

        final userProfile = authProvider.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: Text('Distributor Dashboard'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const FoodDistributorSettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: _buildDashboardContent(userProfile),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _lastIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.store),
                label: 'Marketplace',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.shopping_bag),
                label: 'My Orders',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.people),
                label: 'Suppliers',
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.inventory_2),
                label: 'Products',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(UserModel? userProfile) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(userProfile);
      case 1:
        return _buildMarketplaceTab();
      case 2:
        return const DistributorOrdersScreen();
      case 3:
        return _buildSuppliersTab();
      case 4:
        return const ProductListScreen();
      default:
        return _buildHomeTab(userProfile);
    }
  }

  Widget _buildMarketplaceTab() {
    return Column(
      children: [
        // Bold "Crop Marketplace" title
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.orange.shade200, width: 1),
            ),
          ),
          child: const Text(
            'Crop Marketplace',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Crop Marketplace Screen
        const Expanded(
          child: CropMarketplaceScreen(),
        ),
      ],
    );
  }

  Widget _buildHomeTab(UserModel? userProfile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (userProfile != null) _buildBidAnalyticsSection(userProfile),
        ],
      ),
    );
  }

  Widget _buildBidAnalyticsSection(UserModel userProfile) {
    final cropService = CropService();
    final orderService = OrderService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bid Analytics',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        _rangeSelector(),
        const SizedBox(height: 12),
        // Streams: Active crops (to count my bids), Distributor crops (won), Orders (spent)
        StreamBuilder<List<CropModel>>(
          stream: cropService.getActiveCrops(),
          builder: (context, activeSnap) {
            final activeCrops = activeSnap.data ?? const <CropModel>[];
            final windowStart = DateTime.now().subtract(Duration(days: _analyticsDays));
            final myActiveBids = activeCrops
                .expand((c) => c.bids)
                .where((b) => b.distributorId == userProfile.uid)
                .toList();
            final myWindowBids = myActiveBids.where((b) => b.createdAt.isAfter(windowStart)).toList();
            final bidsPlaced = myWindowBids.length;
            final avgBid = myWindowBids.isEmpty
                ? 0.0
                : myWindowBids.map((b) => b.amount).reduce((a, b) => a + b) / myWindowBids.length;
            final leadingNow = activeCrops.where((c) => c.highestBid?.distributorId == userProfile.uid).length;
            final endingSoon = activeCrops.where((c) => c.endDate.difference(DateTime.now()).inHours <= 24 && c.endDate.isAfter(DateTime.now())).length;

            return StreamBuilder<List<CropModel>>(
              stream: cropService.getDistributorCrops(userProfile.uid),
              builder: (context, distCropSnap) {
                final distCrops = distCropSnap.data ?? const <CropModel>[];
                final wonAuctions = distCrops.where((c) => c.status == 'expired' && c.isUserHighestBidder(userProfile.uid)).length;
                final winRate = bidsPlaced == 0 ? 0.0 : wonAuctions / bidsPlaced;

                return StreamBuilder<List<OrderModel>>(
                  stream: orderService.getDistributorOrders(userProfile.uid),
                  builder: (context, ordersSnap) {
                    final orders = ordersSnap.data ?? const <OrderModel>[];
                    final totalSpent = orders
                        .where((o) => o.paymentStatus == 'completed')
                        .fold<double>(0.0, (sum, o) => sum + o.finalPrice);

                    // Spend by crop (top 3)
                    final Map<String, double> spendByCrop = {};
                    for (final o in orders.where((o) => o.paymentStatus == 'completed')) {
                      spendByCrop[o.cropName] = (spendByCrop[o.cropName] ?? 0.0) + o.finalPrice;
                    }
                    final topSpend = spendByCrop.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
                    final top3Spend = topSpend.take(3).toList();

                    // Ending soon list (top 3 by endDate)
                    final soonList = [...activeCrops]
                      ..sort((a, b) => a.endDate.compareTo(b.endDate));
                    final endingSoonItems = soonList.take(3).toList();

                    // Build 2x2 metrics grid
                    return Column(
                      children: [
                        Row(
                          children: [
                            _analyticsMetric('Active auctions', '${activeCrops.length}', Colors.orange, Icons.gavel),
                            const SizedBox(width: 12),
                            _analyticsMetric('My bids', '$bidsPlaced', Colors.blue, Icons.trending_up),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _analyticsMetric('Won auctions', '$wonAuctions', Colors.green, Icons.emoji_events),
                            const SizedBox(width: 12),
                            _analyticsMetric('Total spent', '₹${totalSpent.toStringAsFixed(0)}', Colors.purple, Icons.account_balance_wallet),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _analyticsMetric('Leading now', '$leadingNow', Colors.teal, Icons.leaderboard),
                            const SizedBox(width: 12),
                            _analyticsMetric('Ending ≤24h', '$endingSoon', Colors.red, Icons.timer),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _bidTrendCard(myWindowBids, avgBid, winRate),
                        const SizedBox(height: 12),
                        _endingSoonCard(endingSoonItems, userProfile.uid),
                        const SizedBox(height: 12),
                        _topSpendCard(top3Spend),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _analyticsMetric(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bidTrendCard(List<BidModel> myBids, double avgBid, double winRate) {
    // Prepare 7-day bins
    final now = DateTime.now();
    List<double> bins = List.filled(7, 0.0);
    for (final bid in myBids) {
      final diff = now.difference(bid.createdAt).inDays;
      if (diff >= 0 && diff < 7) {
        bins[6 - diff] += bid.amount;
      }
    }
    final double maxVal = bins.fold<double>(0.0, (m, v) => v > m ? v : m);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.analytics, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Last 7 days bid trend',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    _smallPill('Avg bid: ₹${avgBid.toStringAsFixed(0)}', Colors.blue),
                    _smallPill('Win rate: ${(winRate * 100).round()}%', Colors.green),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(7, (i) {
                  final double v = bins[i];
                  final double h = maxVal == 0.0 ? 0.0 : (v / maxVal) * 70.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: h,
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Day -6', style: TextStyle(fontSize: 10, color: Colors.grey)),
                Text('Day 0', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _endingSoonCard(List<CropModel> items, String distributorId) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.timer, color: Colors.red),
                SizedBox(width: 8),
                Text('Ending soon', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((c) {
              final leading = c.highestBid?.distributorId == distributorId;
              final timeLeft = c.endDate.difference(DateTime.now());
              String tl;
              if (timeLeft.inHours >= 1) {
                tl = '${timeLeft.inHours}h';
              } else {
                tl = '${timeLeft.inMinutes}m';
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: c.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(c.imageUrl, fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => const Icon(Icons.image, color: Colors.grey)),
                            )
                          : const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.cropName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Row(
                            children: [
                              _smallPill('Ends in $tl', Colors.red),
                              const SizedBox(width: 6),
                              _smallPill(leading ? 'You are leading' : 'Not leading', leading ? Colors.green : Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('₹${c.highestBid?.amount.toStringAsFixed(0) ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _topSpendCard(List<MapEntry<String, double>> top3Spend) {
    if (top3Spend.isEmpty) return const SizedBox.shrink();
    final double maxVal = top3Spend.map((e) => e.value).fold<double>(0.0, (m, v) => v > m ? v : m);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.bar_chart, color: Colors.purple),
                SizedBox(width: 8),
                Text('Top spend by crop', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...top3Spend.map((e) {
              final double pct = maxVal == 0.0 ? 0.0 : e.value / maxVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(e.key, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 8),
                        Text('₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _rangeSelector() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Last 7 days'),
          selected: _analyticsDays == 7,
          onSelected: (s) {
            if (s) setState(() => _analyticsDays = 7);
          },
        ),
        ChoiceChip(
          label: const Text('Last 30 days'),
          selected: _analyticsDays == 30,
          onSelected: (s) {
            if (s) setState(() => _analyticsDays = 30);
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Supplier Network',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect with local farmers and build relationships',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Text(
            'Coming Soon',
            style: TextStyle(
              fontSize: 18,
              color: Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }


}
