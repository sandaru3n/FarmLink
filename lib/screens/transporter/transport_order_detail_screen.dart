import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/transport_order_model.dart';
import '../../providers/transport_order_provider.dart';

class TransportOrderDetailScreen extends StatelessWidget {
  final TransportOrderModel transportOrder;

  const TransportOrderDetailScreen({
    super.key,
    required this.transportOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport Details'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildCropSection(),
            const SizedBox(height: 24),
            _buildRouteSection(),
            const SizedBox(height: 24),
            _buildTransportDetailsSection(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(transportOrder.status),
            _getStatusColor(transportOrder.status).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(transportOrder.status),
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(transportOrder.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Transport Order #${transportOrder.id}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crop Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    transportOrder.cropImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transportOrder.cropName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow('Quantity', '${transportOrder.quantity} kg'),
                      _buildDetailRow('Price', '₹${transportOrder.price.toStringAsFixed(2)}'),
                      if (transportOrder.deliveryFee != null)
                        _buildDetailRow('Delivery Fee', '₹${transportOrder.deliveryFee!.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Pickup Location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pickup Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transportOrder.pickupLocation,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Farmer: ${transportOrder.farmerName}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Delivery Location
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Location',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transportOrder.distributorLocation,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Distributor: ${transportOrder.distributorName}',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
    );
  }

  Widget _buildTransportDetailsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transport Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Transport Order ID', transportOrder.id),
            _buildDetailRow('Delivery Order ID', transportOrder.deliveryOrderId),
            _buildDetailRow('Original Order ID', transportOrder.orderId),
            _buildDetailRow('Transporter', transportOrder.transporterName),
            _buildDetailRow('Accepted At', _formatDateTime(transportOrder.acceptedAt)),
            if (transportOrder.inTransitAt != null)
              _buildDetailRow('In Transit At', _formatDateTime(transportOrder.inTransitAt!)),
            if (transportOrder.deliveredAt != null)
              _buildDetailRow('Delivered At', _formatDateTime(transportOrder.deliveredAt!)),
            if (transportOrder.cancelledAt != null)
              _buildDetailRow('Cancelled At', _formatDateTime(transportOrder.cancelledAt!)),
            if (transportOrder.estimatedDeliveryTime != null)
              _buildDetailRow('Estimated Time', transportOrder.estimatedDeliveryTime!),
            if (transportOrder.actualDeliveryTime != null)
              _buildDetailRow('Actual Time', transportOrder.actualDeliveryTime!),
            if (transportOrder.notes != null && transportOrder.notes!.isNotEmpty)
              _buildDetailRow('Notes', transportOrder.notes!),
            if (transportOrder.cancellationReason != null)
              _buildDetailRow('Cancellation Reason', transportOrder.cancellationReason!),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (transportOrder.canBeInTransit) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markInTransit(context),
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Start Delivery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(context),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel Transport'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else if (transportOrder.canBeDelivered) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markDelivered(context),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Delivered'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Text(
                'No actions available for this status',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'in_transit':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.directions_car;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Transport Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _markInTransit(BuildContext context) async {
    final provider = Provider.of<TransportOrderProvider>(context, listen: false);
    final success = await provider.markTransportInTransit(transportOrder.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport marked as in transit'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${provider.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _markDelivered(BuildContext context) async {
    final provider = Provider.of<TransportOrderProvider>(context, listen: false);
    final success = await provider.markTransportDelivered(transportOrder.id);
    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${provider.error ?? 'Unknown error'}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this transport?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<TransportOrderProvider>(context, listen: false);
              final success = await provider.cancelTransportOrder(
                transportOrder.id,
                reasonController.text.trim().isEmpty ? 'No reason provided' : reasonController.text.trim(),
              );
              if (!context.mounted) return;
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transport cancelled'),
                    backgroundColor: Colors.orange,
                  ),
                );
                Navigator.of(context).pop();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: ${provider.error ?? 'Unknown error'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Cancel Transport'),
          ),
        ],
      ),
    );
  }
} 