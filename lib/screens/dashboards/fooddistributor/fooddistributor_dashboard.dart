import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../models/user_model.dart';
import '../../../utils/app_localizations.dart';
import '../../settings/fooddistributor_settings_screen.dart';
import '../../distributor/crop_marketplace_screen.dart';
import '../../distributor/distributor_orders_tabbed_screen.dart';
import '../../distributor/product_list_screen.dart';
import '../../../services/crop_service.dart';
import '../../../services/order_service.dart';
import '../../../models/crop_model.dart';
import '../../../widgets/notification_badge.dart';
import '../../../widgets/smart_bidding_assistant_widget.dart';

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
    // Load notifications for distributor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.loadUserNotifications(authProvider.currentUser!.uid);
      }
    });
  }

  String _getAppBarTitle() {
    final l10n = AppLocalizations.of(context);
    switch (_currentIndex) {
      case 0:
        return l10n.get('home');
      case 1:
        return l10n.get('marketplace');
      case 2:
        return l10n.get('my_orders');
      case 3:
        return l10n.get('products');
      default:
        return l10n.get('distributor_dashboard');
    }
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
          return Scaffold(
            body: Center(
              child: Text(l10n.get('please_log_in')),
            ),
          );
        }

        final userProfile = authProvider.userProfile;

        return Scaffold(
          body: _buildDashboardContent(userProfile),
          bottomNavigationBar: Container(
            color: Colors.white,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: GNav(
                backgroundColor: Colors.white,
                color: Colors.black,
                activeColor: const Color(0xFFF57F17), // Deep yellow for active
                tabBackgroundColor: const Color(0xFFFFF9C4), // Light yellow background
                gap: 8,
                onTabChange: (index) {
                  setState(() {
                    _currentIndex = index;
                    _lastIndex = index;
                  });
                },
                padding: const EdgeInsets.all(16),
                tabs: [
                  GButton(
                    icon: LineAwesomeIcons.home,
                    text: l10n.get('home'),
                  ),
                  GButton(
                    icon: LineAwesomeIcons.store,
                    text: l10n.get('marketplace'),
                  ),
                  GButton(
                    icon: LineAwesomeIcons.shopping_bag,
                    text: l10n.get('my_orders'),
                  ),
                  GButton(
                    icon: LineAwesomeIcons.box,
                    text: l10n.get('products'),
                  ),
                ],
              ),
            ),
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
        return const DistributorOrdersTabbedScreen();
      case 3:
        return const ProductListScreen();
      default:
        return _buildHomeTab(userProfile);
    }
  }

  Widget _buildMarketplaceTab() {
    return const CropMarketplaceScreen();
  }

  Widget _buildHomeTab(UserModel? userProfile) {
    return Column(
      children: [
        // Modern Header
        _buildHomeHeader(userProfile),
        
        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 96),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (userProfile != null) _buildBidAnalyticsSection(userProfile),
                const SizedBox(height: 20),
                _buildSmartBiddingSection(userProfile),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeHeader(UserModel? userProfile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade700,
            Colors.orange.shade500,
            Colors.orange.shade400,
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
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade400, Colors.amber.shade600],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).get('home'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const NotificationBadge(
                        iconColor: Colors.white,
                        iconSize: 26,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FoodDistributorSettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Welcome Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: (userProfile?.photoUrl?.isEmpty ?? true)
                          ? const Icon(Icons.person, color: Colors.orange, size: 36)
                          : ClipOval(
                              child: Image.network(
                                userProfile!.photoUrl!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.person, color: Colors.orange, size: 36);
                                },
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context).get('hello')}, ${userProfile?.displayName ?? 'User'}! ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userProfile?.email ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              AppLocalizations.of(context).get('distributor'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildBidAnalyticsSection(UserModel userProfile) {
    final l10n = AppLocalizations.of(context);
    final cropService = CropService();
    final orderService = OrderService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('bid_analytics'),
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
                            _analyticsMetric(l10n.get('active_auctions'), '${activeCrops.length}', Colors.orange, Icons.gavel),
                            const SizedBox(width: 12),
                            _analyticsMetric(l10n.get('my_bids'), '$bidsPlaced', Colors.blue, Icons.trending_up),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _analyticsMetric(l10n.get('won_auctions'), '$wonAuctions', Colors.green, Icons.emoji_events),
                            const SizedBox(width: 12),
                            _analyticsMetric(l10n.get('total_spent'), 'LKR ${totalSpent.toStringAsFixed(0)}', Colors.purple, Icons.account_balance_wallet),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _analyticsMetric(l10n.get('leading_now'), '$leadingNow', Colors.teal, Icons.leaderboard),
                            const SizedBox(width: 12),
                            _analyticsMetric(l10n.get('ending_soon'), '$endingSoon', Colors.red, Icons.timer),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bidTrendCard(List<BidModel> myBids, double avgBid, double winRate) {
    final l10n = AppLocalizations.of(context);
    
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.analytics, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.get('last_7_days_trend'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    '${l10n.get('avg')}: LKR ${avgBid.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '${l10n.get('win')}: ${(winRate * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              children: [
                Text('${l10n.get('day')} -6', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text('${l10n.get('day')} 0', style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _endingSoonCard(List<CropModel> items, String distributorId) {
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.timer, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.get('ending_soon_label'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade900,
                  ),
                ),
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
                              Flexible(
                                child: _smallPill('${l10n.get('ends_in')} $tl', Colors.red),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: _smallPill(leading ? l10n.get('you_are_leading') : l10n.get('not_leading'), leading ? Colors.green : Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('LKR ${c.highestBid?.amount.toStringAsFixed(0) ?? '-'}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    final double maxVal = top3Spend.map((e) => e.value).fold<double>(0.0, (m, v) => v > m ? v : m);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 1,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bar_chart, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.get('top_spend_by_crop'),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade900,
                  ),
                ),
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
                        Text('LKR ${e.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: pct,
                        backgroundColor: Colors.grey.shade200,
                        color: Colors.blue,
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
    final l10n = AppLocalizations.of(context);
    
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.get('last_7_days')),
          selected: _analyticsDays == 7,
          onSelected: (s) {
            if (s) setState(() => _analyticsDays = 7);
          },
          selectedColor: Colors.amber.shade300,
          backgroundColor: Colors.amber.shade50,
          labelStyle: TextStyle(
            color: _analyticsDays == 7 ? Colors.grey.shade900 : Colors.grey.shade700,
            fontWeight: _analyticsDays == 7 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        ChoiceChip(
          label: Text(l10n.get('last_30_days')),
          selected: _analyticsDays == 30,
          onSelected: (s) {
            if (s) setState(() => _analyticsDays = 30);
          },
          selectedColor: Colors.amber.shade300,
          backgroundColor: Colors.amber.shade50,
          labelStyle: TextStyle(
            color: _analyticsDays == 30 ? Colors.grey.shade900 : Colors.grey.shade700,
            fontWeight: _analyticsDays == 30 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartBiddingSection(UserModel? userProfile) {
    final l10n = AppLocalizations.of(context);
    final cropService = CropService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.get('smart_bidding_assistant'),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<CropModel>>(
          stream: cropService.getActiveCrops(),
          builder: (context, activeSnap) {
            final activeCrops = activeSnap.data ?? const <CropModel>[];
            
            if (activeCrops.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.get('no_active_auctions'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI recommendations will appear when auctions are available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            // Show Smart Bidding Assistant for the first active crop (not expired)
            final activeNonExpiredCrops = activeCrops.where((crop) => !crop.isExpired && crop.status == 'active').toList();
            
            if (activeNonExpiredCrops.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.psychology_outlined,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.get('no_active_auctions'),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI recommendations will appear when active auctions are available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final firstActiveCrop = activeNonExpiredCrops.first;
            return SmartBiddingAssistantWidget(
              crop: firstActiveCrop,
              onBidRecommended: () {
                // Navigate to marketplace tab
                setState(() {
                  _currentIndex = 1; // Marketplace tab
                });
              },
            );
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

}
