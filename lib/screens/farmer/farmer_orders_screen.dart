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
      appBar: AppBar(
        title: const Text('Delivery Tracking'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_shipping, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No deliveries in progress',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Delivery tracking will appear here once transporters accept your orders',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: deliveryOrders.length,
              itemBuilder: (context, index) {
                final deliveryOrder = deliveryOrders[index];
                return _buildDeliveryTrackingCard(deliveryOrder);
              },
            );
          },
        );
      },
    );
  }


  Widget _buildDeliveryTrackingCard(DeliveryOrderModel deliveryOrder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Delivery Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getDeliveryStatusColor(deliveryOrder.status).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getDeliveryStatusColor(deliveryOrder.status),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getDeliveryStatusIcon(deliveryOrder.status),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deliveryOrder.cropName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Delivery #${deliveryOrder.id.substring(0, 8)}',
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
                    color: _getDeliveryStatusColor(deliveryOrder.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getDeliveryStatusText(deliveryOrder.status),
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

          // Delivery Details
          Padding(
            padding: const EdgeInsets.all(16),
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
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Amount',
                        '₹${deliveryOrder.price.toStringAsFixed(0)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.scale,
                        'Quantity',
                        '${deliveryOrder.quantity} kg',
                      ),
                    ),
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
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on,
                  'Pickup',
                  deliveryOrder.pickupLocation,
                ),
                const SizedBox(height: 8),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
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
      builder: (context) => AlertDialog(
        title: Text('Delivery Details - ${deliveryOrder.cropName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Delivery ID', deliveryOrder.id),
              _buildDetailRow('Crop', deliveryOrder.cropName),
              _buildDetailRow('Quantity', '${deliveryOrder.quantity} kg'),
              _buildDetailRow('Price', '₹${deliveryOrder.price.toStringAsFixed(2)}'),
              _buildDetailRow('Buyer', deliveryOrder.distributorName),
              _buildDetailRow('Pickup Location', deliveryOrder.pickupLocation),
              _buildDetailRow('Delivery Address', deliveryOrder.distributorLocation),
              _buildDetailRow('Status', _getDeliveryStatusText(deliveryOrder.status)),
              if (deliveryOrder.transporterName != null)
                _buildDetailRow('Transporter', deliveryOrder.transporterName!),
              if (deliveryOrder.estimatedDeliveryTime != null)
                _buildDetailRow('Estimated Time', deliveryOrder.estimatedDeliveryTime!),
              if (deliveryOrder.actualDeliveryTime != null)
                _buildDetailRow('Actual Time', deliveryOrder.actualDeliveryTime!),
              _buildDetailRow('Created', _formatDate(deliveryOrder.createdAt)),
              if (deliveryOrder.acceptedAt != null)
                _buildDetailRow('Accepted', _formatDate(deliveryOrder.acceptedAt!)),
              if (deliveryOrder.inTransitAt != null)
                _buildDetailRow('In Transit', _formatDate(deliveryOrder.inTransitAt!)),
              if (deliveryOrder.deliveredAt != null)
                _buildDetailRow('Delivered', _formatDate(deliveryOrder.deliveredAt!)),
              if (deliveryOrder.rejectionReason != null)
                _buildDetailRow('Rejection Reason', deliveryOrder.rejectionReason!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
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
