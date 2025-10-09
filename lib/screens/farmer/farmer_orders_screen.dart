import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/delivery_order_model.dart';
import '../../services/delivery_order_service.dart';
import '../../providers/auth_provider.dart';

class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DeliveryOrderService _deliveryOrderService = DeliveryOrderService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade700,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Delivery Tracking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildDeliveryTrackingTab(),
    );
  }


  Widget _buildDeliveryTrackingTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.userProfile?.uid == null) {
          return const Center(child: Text('Please log in'));
        }

        return StreamBuilder<List<DeliveryOrderModel>>(
          stream: _deliveryOrderService.getFarmerDeliveryOrders(authProvider.userProfile!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final deliveryOrders = snapshot.data ?? [];

            if (deliveryOrders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade100,
                            Colors.green.shade50,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_shipping,
                        size: 64,
                        color: Colors.green.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No deliveries in progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Delivery tracking will appear here once transporters accept your orders',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              color: Colors.grey.shade50,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: deliveryOrders.length,
                itemBuilder: (context, index) {
                  final deliveryOrder = deliveryOrders[index];
                  return _buildDeliveryTrackingCard(deliveryOrder);
                },
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildDeliveryTrackingCard(DeliveryOrderModel deliveryOrder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getDeliveryStatusGradient(deliveryOrder.status),
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDeliveryStatusIcon(deliveryOrder.status),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryOrder.cropName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delivery #${deliveryOrder.id.substring(0, 8)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    _getDeliveryStatusText(deliveryOrder.status),
                    style: TextStyle(
                      color: _getDeliveryStatusTextColor(deliveryOrder.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Delivery Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.person,
                        'Buyer',
                        deliveryOrder.distributorName,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Amount',
                        'LKR ${deliveryOrder.price.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.scale,
                        'Quantity',
                        '${deliveryOrder.quantity} kg',
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (deliveryOrder.transporterName != null)
                      Expanded(
                        child: _buildInfoRow(
                          Icons.local_shipping,
                          'Transporter',
                          deliveryOrder.transporterName!,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.location_on,
                  'Pickup',
                  deliveryOrder.pickupLocation,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  Icons.location_city,
                  'Delivery',
                  deliveryOrder.distributorLocation,
                ),

                // Delivery Timeline
                if (deliveryOrder.status != 'pending') ...[
                  const SizedBox(height: 16),
                  _buildDeliveryTimeline(deliveryOrder),
                ],

                const SizedBox(height: 16),

                // Action Buttons
                if (deliveryOrder.status == 'pending')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeliveryDetails(deliveryOrder),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Waiting for Transporter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showDeliveryDetails(deliveryOrder),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Track Delivery'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                      if (deliveryOrder.status == 'delivered')
                        const SizedBox(width: 12),
                      if (deliveryOrder.status == 'delivered')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _confirmDelivery(deliveryOrder),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Confirm Received'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeline(DeliveryOrderModel deliveryOrder) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Timeline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimelineItem(
            'Order Created',
            deliveryOrder.createdAt,
            true,
            Icons.shopping_bag,
          ),
          if (deliveryOrder.acceptedAt != null)
            _buildTimelineItem(
              'Transporter Accepted',
              deliveryOrder.acceptedAt!,
              true,
              Icons.check_circle,
            ),
          if (deliveryOrder.inTransitAt != null)
            _buildTimelineItem(
              'In Transit',
              deliveryOrder.inTransitAt!,
              true,
              Icons.local_shipping,
            ),
          if (deliveryOrder.deliveredAt != null)
            _buildTimelineItem(
              'Delivered',
              deliveryOrder.deliveredAt!,
              true,
              Icons.home,
            ),
          if (deliveryOrder.estimatedDeliveryTime != null)
            _buildTimelineItem(
              'Estimated Delivery',
              null,
              false,
              Icons.schedule,
              subtitle: deliveryOrder.estimatedDeliveryTime,
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, DateTime? date, bool isCompleted, IconData icon, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
                    color: isCompleted ? Colors.green : Colors.grey.shade600,
                  ),
                ),
                if (date != null || subtitle != null)
                  Text(
                    date != null ? _formatDate(date) : subtitle!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Color _getDeliveryStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<Color> _getDeliveryStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'accepted':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'in_transit':
        return [Colors.purple.shade400, Colors.purple.shade600];
      case 'delivered':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'rejected':
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  Color _getDeliveryStatusTextColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'accepted':
        return Colors.blue.shade700;
      case 'in_transit':
        return Colors.purple.shade700;
      case 'delivered':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getDeliveryStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Waiting';
      case 'accepted':
        return 'Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  IconData _getDeliveryStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'accepted':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.home;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }


  void _showDeliveryDetails(DeliveryOrderModel deliveryOrder) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern Header with gradient
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getDeliveryStatusGradient(deliveryOrder.status),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getDeliveryStatusIcon(deliveryOrder.status),
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Details',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                deliveryOrder.cropName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Crop', deliveryOrder.cropName, Icons.agriculture),
                      _buildDetailRow('Delivery ID', deliveryOrder.id, Icons.tag),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow('Quantity', '${deliveryOrder.quantity} kg', Icons.scale),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildDetailRow('Price', 'LKR ${deliveryOrder.price.toStringAsFixed(2)}', Icons.attach_money),
                          ),
                        ],
                      ),
                      _buildDetailRow('Buyer', deliveryOrder.distributorName, Icons.person),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailRow('Status', _getDeliveryStatusText(deliveryOrder.status), Icons.info),
                          ),
                          const SizedBox(width: 10),
                          if (deliveryOrder.transporterName != null)
                            Expanded(
                              child: _buildDetailRow('Transporter', deliveryOrder.transporterName!, Icons.local_shipping),
                            ),
                        ],
                      ),
                      _buildDetailRow('Pickup Location', deliveryOrder.pickupLocation, Icons.location_on),
                      _buildDetailRow('Delivery Address', deliveryOrder.distributorLocation, Icons.location_city),
                      if (deliveryOrder.estimatedDeliveryTime != null)
                        _buildDetailRow('Estimated Time', deliveryOrder.estimatedDeliveryTime!, Icons.schedule),
                      if (deliveryOrder.actualDeliveryTime != null)
                        _buildDetailRow('Actual Time', deliveryOrder.actualDeliveryTime!, Icons.access_time),
                      _buildDetailRow('Created', _formatDate(deliveryOrder.createdAt), Icons.calendar_today),
                      if (deliveryOrder.acceptedAt != null)
                        _buildDetailRow('Accepted', _formatDate(deliveryOrder.acceptedAt!), Icons.check_circle),
                      if (deliveryOrder.inTransitAt != null)
                        _buildDetailRow('In Transit', _formatDate(deliveryOrder.inTransitAt!), Icons.local_shipping),
                      if (deliveryOrder.deliveredAt != null)
                        _buildDetailRow('Delivered', _formatDate(deliveryOrder.deliveredAt!), Icons.home),
                      if (deliveryOrder.rejectionReason != null)
                        _buildDetailRow('Rejection Reason', deliveryOrder.rejectionReason!, Icons.cancel),
                    ],
                  ),
                ),
              ),
              // Action Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getDeliveryStatusColor(deliveryOrder.status),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _confirmDelivery(DeliveryOrderModel deliveryOrder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: Text('Has ${deliveryOrder.cropName} been successfully delivered to ${deliveryOrder.distributorName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                // Here you could add additional logic to confirm delivery
                // For now, we'll just show a success message
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delivery confirmed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to confirm delivery: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}

