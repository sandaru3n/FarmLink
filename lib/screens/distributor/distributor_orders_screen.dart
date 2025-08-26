import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';

class DistributorOrdersScreen extends StatefulWidget {
  const DistributorOrdersScreen({super.key});

  @override
  State<DistributorOrdersScreen> createState() => _DistributorOrdersScreenState();
}

class _DistributorOrdersScreenState extends State<DistributorOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      cropProvider.loadAllActiveCrops();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CropProvider>(
        builder: (context, cropProvider, child) {
          if (cropProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.userProfile?.uid ?? '';
          
          // Filter crops that have orders placed by current distributor
          final myOrders = cropProvider.allActiveCrops
              .where((crop) => crop.order != null && crop.order!.distributorId == currentUserId)
              .toList();

          if (myOrders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Place bids on crops and win auctions to see your orders here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: myOrders.length,
            itemBuilder: (context, index) {
              final crop = myOrders[index];
              return _buildOrderCard(crop);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(CropModel crop) {
    final order = crop.order!;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              crop.imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  color: Colors.grey.shade200,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.blue,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey.shade300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.image_not_supported,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Image not available',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crop.cropName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildStatusChip(order.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Order Details
                _buildOrderDetail('Order ID', order.id),
                _buildOrderDetail('Quantity', '${order.quantity} kg'),
                _buildOrderDetail('Final Price', '₹${order.finalPrice}'),
                _buildOrderDetail('Pickup Location', order.pickupLocation),
                _buildOrderDetail('Order Date', _formatDateTime(order.createdAt)),
                
                if (order.confirmedAt != null)
                  _buildOrderDetail('Confirmed Date', _formatDateTime(order.confirmedAt!)),
                if (order.completedAt != null)
                  _buildOrderDetail('Completed Date', _formatDateTime(order.completedAt!)),
                
                const SizedBox(height: 16),

                // Action Buttons based on status
                _buildActionButtons(order),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    IconData chipIcon;
    String chipText;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        chipIcon = Icons.schedule;
        chipText = 'Pending';
        break;
      case 'confirmed':
        chipColor = Colors.blue;
        chipIcon = Icons.check_circle;
        chipText = 'Confirmed';
        break;
      case 'completed':
        chipColor = Colors.green;
        chipIcon = Icons.done_all;
        chipText = 'Completed';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        chipIcon = Icons.cancel;
        chipText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        chipIcon = Icons.help;
        chipText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, size: 16, color: chipColor),
          const SizedBox(width: 4),
          Text(
            chipText,
            style: TextStyle(
              color: chipColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OrderModel order) {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactFarmer(order),
                icon: const Icon(Icons.message),
                label: const Text('Contact Farmer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewOrderDetails(order),
                icon: const Icon(Icons.visibility),
                label: const Text('View Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _contactFarmer(order),
                icon: const Icon(Icons.message),
                label: const Text('Contact Farmer'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _markAsCompleted(order),
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      case 'completed':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _viewOrderDetails(order),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _viewOrderDetails(order),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _contactFarmer(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Farmer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Farmer: ${order.farmerName}'),
            Text('Crop: ${order.cropName}'),
            Text('Pickup Location: ${order.pickupLocation}'),
            const SizedBox(height: 16),
            const Text(
              'Contact the farmer to arrange pickup and payment.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
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

  void _viewOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - ${order.cropName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Order ID', order.id),
              _buildDetailRow('Crop Name', order.cropName),
              _buildDetailRow('Quantity', '${order.quantity} kg'),
              _buildDetailRow('Final Price', '₹${order.finalPrice}'),
              _buildDetailRow('Pickup Location', order.pickupLocation),
              _buildDetailRow('Status', order.status.toUpperCase()),
              _buildDetailRow('Order Date', _formatDateTime(order.createdAt)),
              if (order.confirmedAt != null)
                _buildDetailRow('Confirmed Date', _formatDateTime(order.confirmedAt!)),
              if (order.completedAt != null)
                _buildDetailRow('Completed Date', _formatDateTime(order.completedAt!)),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _markAsCompleted(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Order as Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${order.cropName}'),
            Text('Quantity: ${order.quantity} kg'),
            Text('Final Price: ₹${order.finalPrice}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to mark this order as completed?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement order completion logic
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order marked as completed!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );
  }
}
