import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/consumer_order_model.dart';
import '../../models/consumer_rating_model.dart';
import '../../services/consumer_order_service.dart';
import '../../services/consumer_rating_service.dart';
import '../../utils/app_localizations.dart';
import 'consumer_order_details_screen.dart';

class ConsumerOrdersScreen extends StatefulWidget {
  const ConsumerOrdersScreen({super.key});

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConsumerOrderService _orderService = ConsumerOrderService();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Modern Stylish Header with Tabs
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade500,
                  Colors.blue.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).get('my_orders'),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      labelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      labelPadding: EdgeInsets.zero,
                      tabs: [
                        Tab(
                          height: 40,
                          child: Center(child: Text(AppLocalizations.of(context).get('pending'))),
                        ),
                        Tab(
                          height: 40,
                          child: Center(child: Text(AppLocalizations.of(context).get('delivered'))),
                        ),
                        Tab(
                          height: 40,
                          child: Center(child: Text(AppLocalizations.of(context).get('history'))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.userProfile == null) {
            return Center(
              child: Text(AppLocalizations.of(context).get('please_log_in')),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(authProvider.userProfile!.uid, 'pending'),
              _buildOrdersList(authProvider.userProfile!.uid, 'completed'),
              _buildOrdersList(authProvider.userProfile!.uid, 'reviewed'),
            ],
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String consumerId, String status) {
    if (status == 'reviewed') {
      return _buildReviewedOrdersList(consumerId);
    }
    
    return StreamBuilder<List<ConsumerOrderModel>>(
      stream: _orderService.getConsumerOrders(consumerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading orders',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data ?? [];
        
        // Filter orders based on status
        List<ConsumerOrderModel> filteredOrders = [];
        switch (status) {
          case 'pending':
            filteredOrders = orders.where((order) => 
              order.orderStatus == 'pending' || 
              order.orderStatus == 'confirmed' || 
              order.orderStatus == 'shipped'
            ).toList();
            break;
          case 'completed':
            filteredOrders = orders.where((order) => 
              order.orderStatus == 'delivered' && 
              order.paymentStatus == 'completed'
            ).toList();
            break;
        }

        if (filteredOrders.isEmpty) {
          return _buildEmptyState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildReviewedOrdersList(String consumerId) {
    return StreamBuilder<List<ConsumerRatingModel>>(
      stream: ConsumerRatingService().getConsumerRatings(consumerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading reviews',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final ratings = snapshot.data ?? [];

        if (ratings.isEmpty) {
          return _buildEmptyState('reviewed');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final rating = ratings[index];
            return _buildReviewedOrderCard(rating);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String status) {
    final l10n = AppLocalizations.of(context);
    String message;
    String subtitle;
    IconData icon;
    Color iconColor;
    
    switch (status) {
      case 'pending':
        message = l10n.get('no_pending_orders');
        subtitle = l10n.get('place_order_to_see');
        icon = Icons.shopping_bag_outlined;
        iconColor = Colors.orange;
        break;
      case 'completed':
        message = l10n.get('no_completed_orders');
        subtitle = l10n.get('completed_orders_appear_here');
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'reviewed':
        message = l10n.get('no_reviewed_orders');
        subtitle = l10n.get('rate_completed_orders');
        icon = Icons.star_outline;
        iconColor = Colors.amber;
        break;
      default:
        message = l10n.get('no_orders');
        subtitle = l10n.get('check_back_later');
        icon = Icons.receipt_long_outlined;
        iconColor = Colors.blue;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(ConsumerOrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue.shade50.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.blue.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ConsumerOrderDetailsScreen(order: order),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top section with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade500,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '#${order.id.substring(order.id.length - 6)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusChip(order.orderStatus, order.paymentStatus),
                  ],
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
              // Order items preview
              ...order.items.take(2).map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.shade100,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.imageUrl.isNotEmpty
                            ? Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => 
                                    Icon(Icons.image, color: Colors.blue.shade300, size: 20),
                              )
                            : Icon(Icons.image, color: Colors.blue.shade300, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity.toStringAsFixed(1)} kg × LKR ${item.pricePerKg.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'LKR',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            item.totalPrice.toStringAsFixed(0),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
              
              if (order.items.length > 2)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '+${order.items.length - 2} more items',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              
              const SizedBox(height: 14),
              
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              const SizedBox(height: 14),
              
              // Order summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade600),
                          const SizedBox(width: 6),
                          Text(
                            _formatDate(order.createdAt),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (order.deliveredAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green[600]),
                              const SizedBox(width: 6),
                              Text(
                                'Delivered ${_formatDate(order.deliveredAt!)}',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'LKR ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            order.totalAmount.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      if (order.paymentStatus == 'completed')
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Paid',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
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

  Widget _buildStatusChip(String orderStatus, String paymentStatus) {
    String status;
    IconData icon;
    Color color;
    
    if (paymentStatus == 'completed') {
      switch (orderStatus) {
        case 'pending':
          status = 'Confirmed';
          icon = Icons.check_circle;
          color = Colors.blue;
          break;
        case 'confirmed':
          status = 'Processing';
          icon = Icons.hourglass_bottom;
          color = Colors.orange;
          break;
        case 'shipped':
          status = 'Shipped';
          icon = Icons.local_shipping;
          color = Colors.purple;
          break;
        case 'delivered':
          status = 'Delivered';
          icon = Icons.done_all;
          color = Colors.green;
          break;
        default:
          status = 'Unknown';
          icon = Icons.help_outline;
          color = Colors.grey;
      }
    } else {
      status = 'Pending';
      icon = Icons.payment;
      color = Colors.red;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildReviewedOrderCard(ConsumerRatingModel rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.amber.shade50.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.amber.shade100,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.amber.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Get the original order details
            final order = await _orderService.getOrderById(rating.consumerOrderId);
            if (order != null && context.mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ConsumerOrderDetailsScreen(order: order),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top section with gradient
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade600,
                      Colors.amber.shade500,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '#${rating.consumerOrderId.substring(rating.consumerOrderId.length - 6)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            color: Colors.green.shade600,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Reviewed',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              
              // Distributor info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        rating.distributorName.isNotEmpty
                            ? rating.distributorName[0].toUpperCase()
                            : 'D',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rating.distributorName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          Text(
                            'Distributor',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 14),
              
              // Rating display
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < rating.rating.floor()
                            ? Icons.star
                            : index < rating.rating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber.shade700,
                        size: 22,
                      );
                    }),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        rating.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${rating.ratingText})',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (rating.comment != null && rating.comment!.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.comment, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 6),
                          Text(
                            'Comment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        rating.comment!,
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (rating.categories != null && rating.categories!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: rating.categories!.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade600,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              const SizedBox(height: 14),
              
              Container(
                height: 1,
                color: Colors.grey.shade200,
              ),
              
              const SizedBox(height: 10),
              
              // Review date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 6),
                      Text(
                        'Reviewed ${_formatDate(rating.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (rating.updatedAt != null)
                    Row(
                      children: [
                        Icon(Icons.update, size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Updated ${_formatDate(rating.updatedAt!)}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                ],
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
}

