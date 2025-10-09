import 'package:flutter/material.dart';
import '../../models/consumer_order_model.dart';
import '../../models/consumer_rating_model.dart';
import '../../services/consumer_rating_service.dart';
import 'consumer_rating_dialog.dart';

class ConsumerOrderDetailsScreen extends StatefulWidget {
  final ConsumerOrderModel order;

  const ConsumerOrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  State<ConsumerOrderDetailsScreen> createState() => _ConsumerOrderDetailsScreenState();
}

class _ConsumerOrderDetailsScreenState extends State<ConsumerOrderDetailsScreen> {
  bool _isOrderStatusExpanded = false;
  bool _isOrderItemsExpanded = false;
  bool _isOrderSummaryExpanded = false;
  bool _isDeliveryInfoExpanded = false;
  bool _isPaymentInfoExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Modern Gradient Header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade500,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 25),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            '#${widget.order.id.substring(widget.order.id.length - 6)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status Card
                  _buildExpandableSection(
                    title: 'Order Status',
                    icon: Icons.local_shipping,
                    iconColor: Colors.blue.shade600,
                    isExpanded: _isOrderStatusExpanded,
                    onTap: () {
                      setState(() {
                        _isOrderStatusExpanded = !_isOrderStatusExpanded;
                      });
                    },
                    child: _buildOrderStatusContent(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Order Items
                  _buildExpandableSection(
                    title: 'Order Items',
                    icon: Icons.shopping_bag,
                    iconColor: Colors.blue.shade600,
                    badge: '${widget.order.items.length} items',
                    isExpanded: _isOrderItemsExpanded,
                    onTap: () {
                      setState(() {
                        _isOrderItemsExpanded = !_isOrderItemsExpanded;
                      });
                    },
                    child: _buildOrderItemsContent(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Order Summary
                  _buildExpandableSection(
                    title: 'Order Summary',
                    icon: Icons.receipt,
                    iconColor: Colors.blue.shade600,
                    isExpanded: _isOrderSummaryExpanded,
                    onTap: () {
                      setState(() {
                        _isOrderSummaryExpanded = !_isOrderSummaryExpanded;
                      });
                    },
                    child: _buildOrderSummaryContent(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery Information
                  _buildExpandableSection(
                    title: 'Delivery Information',
                    icon: Icons.local_shipping,
                    iconColor: Colors.green.shade600,
                    isExpanded: _isDeliveryInfoExpanded,
                    onTap: () {
                      setState(() {
                        _isDeliveryInfoExpanded = !_isDeliveryInfoExpanded;
                      });
                    },
                    child: _buildDeliveryInfoContent(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Payment Information
                  _buildExpandableSection(
                    title: 'Payment Information',
                    icon: Icons.payment,
                    iconColor: Colors.purple.shade600,
                    isExpanded: _isPaymentInfoExpanded,
                    onTap: () {
                      setState(() {
                        _isPaymentInfoExpanded = !_isPaymentInfoExpanded;
                      });
                    },
                    child: _buildPaymentInfoContent(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  if (widget.order.orderStatus == 'delivered' && widget.order.paymentStatus == 'completed')
                    _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 1,
              color: Colors.grey.shade200,
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderStatusContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox.shrink(),
            _buildStatusChip(widget.order.orderStatus, widget.order.paymentStatus),
          ],
        ),
        const SizedBox(height: 18),
        _buildStatusTimeline(),
      ],
    );
  }


  Widget _buildStatusTimeline() {
    final statuses = [
      {
        'status': 'Order Placed',
        'date': widget.order.createdAt,
        'completed': true,
        'icon': Icons.shopping_cart,
      },
      {
        'status': 'Payment',
        'date': widget.order.paymentCompletedAt,
        'completed': widget.order.paymentStatus == 'completed',
        'icon': Icons.payment,
      },
      {
        'status': 'Confirmed',
        'date': widget.order.confirmedAt,
        'completed': widget.order.orderStatus != 'pending',
        'icon': Icons.check_circle,
      },
      {
        'status': 'Shipped',
        'date': widget.order.shippedAt,
        'completed': widget.order.orderStatus == 'shipped' || widget.order.orderStatus == 'delivered',
        'icon': Icons.local_shipping,
      },
      {
        'status': 'Delivered',
        'date': widget.order.deliveredAt,
        'completed': widget.order.orderStatus == 'delivered',
        'icon': Icons.home,
      },
    ];

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        final isLast = index == statuses.length - 1;
        final isCompleted = status['completed'] as bool;
        
        return Row(
          children: [
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: isCompleted 
                        ? LinearGradient(
                            colors: [Colors.green.shade600, Colors.green.shade700],
                          )
                        : null,
                    color: isCompleted ? null : Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: isCompleted
                        ? [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    status['icon'] as IconData,
                    color: isCompleted ? Colors.white : Colors.grey[500],
                    size: 20,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 3,
                    height: 35,
                    decoration: BoxDecoration(
                      gradient: isCompleted
                          ? LinearGradient(
                              colors: [Colors.green.shade600, Colors.green.shade700],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isCompleted ? null : Colors.grey[300],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status['status'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isCompleted ? Colors.grey.shade900 : Colors.grey[500],
                      ),
                    ),
                    if (status['date'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(status['date'] as DateTime),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildOrderItemsContent() {
    return Column(
      children: widget.order.items.map((item) => _buildOrderItem(item)).toList(),
    );
  }

  Widget _buildOrderItem(ConsumerOrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50.withOpacity(0.5),
        border: Border.all(color: Colors.blue.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.blue.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(Icons.image, color: Colors.blue.shade300, size: 30),
                    )
                  : Icon(Icons.image, color: Colors.blue.shade300, size: 30),
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
                    fontSize: 15,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.store, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item.distributorName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Text(
                        '${item.quantity.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LKR ${item.pricePerKg.toStringAsFixed(2)}/kg',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'LKR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item.totalPrice.toStringAsFixed(0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'LKR ${widget.order.subtotal.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (18% GST):',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'LKR ${widget.order.tax.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade200,
                    Colors.blue.shade100,
                    Colors.blue.shade200,
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade700],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'LKR ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.order.totalAmount.toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
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

  Widget _buildDeliveryInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Customer Name', widget.order.consumerName, Icons.person),
        _buildInfoRow('Email', widget.order.consumerEmail, Icons.email),
        _buildInfoRow('Phone', widget.order.consumerPhone, Icons.phone),
        _buildInfoRow('Delivery Address', widget.order.consumerLocation, Icons.location_on),
        if (widget.order.deliveredAt != null)
          _buildInfoRow('Delivered On', _formatDateTime(widget.order.deliveredAt!), Icons.check_circle),
      ],
    );
  }

  Widget _buildPaymentInfoContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Payment Status', _getPaymentStatusText(), Icons.account_balance_wallet),
        if (widget.order.paymentCompletedAt != null)
          _buildInfoRow('Paid On', _formatDateTime(widget.order.paymentCompletedAt!), Icons.calendar_today),
        if (widget.order.stripePaymentIntentId != null)
          _buildInfoRow('Transaction ID', widget.order.stripePaymentIntentId!, Icons.receipt_long),
      ],
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
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
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Actions',
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
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement reorder functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reorder functionality coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.shopping_cart, size: 20),
                    label: const Text(
                      'Reorder',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FutureBuilder<bool>(
                  future: ConsumerRatingService().hasBeenRated(widget.order.id),
                  builder: (context, snapshot) {
                    final hasBeenRated = snapshot.data ?? false;
                    final color = hasBeenRated ? Colors.green : Colors.amber;
                    
                    return Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.shade600, color.shade700],
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
                      child: ElevatedButton.icon(
                        onPressed: () => _showRatingDialog(context, hasBeenRated),
                        icon: Icon(
                          hasBeenRated ? Icons.edit : Icons.star,
                          size: 20,
                        ),
                        label: Text(
                          hasBeenRated ? 'Edit Review' : 'Write Review',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade700,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      status = 'Pending Payment';
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

  String _getPaymentStatusText() {
    switch (widget.order.paymentStatus) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'completed':
        return 'Completed';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showRatingDialog(BuildContext context, bool hasBeenRated) async {
    ConsumerRatingModel? existingRating;
    
    if (hasBeenRated) {
      existingRating = await ConsumerRatingService().getRatingByConsumerOrder(widget.order.id);
    }

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConsumerRatingDialog(
        order: widget.order,
        existingRating: existingRating,
      ),
    );

    if (result == true && mounted) {
      setState(() {
        // Refresh the UI to show updated rating status
      });
    }
  }
}
