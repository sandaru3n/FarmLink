import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/delivery_order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/delivery_order_model.dart';
import 'delivery_order_detail_screen.dart';
import '../dashboards/transporter/transporter_dashboard.dart';

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    deliveryOrderProvider.loadPendingDeliveryOrders();
    deliveryOrderProvider.loadTransporterDeliveryOrders();
    deliveryOrderProvider.loadDeliveryStatistics();
  }

  void _refreshData() {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    deliveryOrderProvider.loadPendingDeliveryOrders();
    deliveryOrderProvider.loadTransporterDeliveryOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Delivery Orders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAvailableDeliveriesTab(),
          _buildActiveDeliveriesTab(),
          _buildCompletedDeliveriesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildAvailableDeliveriesTab() {
    return Consumer<DeliveryOrderProvider>(
      builder: (context, deliveryOrderProvider, child) {
        if (deliveryOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (deliveryOrderProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Error: ${deliveryOrderProvider.error}',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    deliveryOrderProvider.clearError();
                    deliveryOrderProvider.loadPendingDeliveryOrders();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (deliveryOrderProvider.pendingDeliveryOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No available deliveries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New delivery orders will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await deliveryOrderProvider.loadPendingDeliveryOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveryOrderProvider.pendingDeliveryOrders.length,
            itemBuilder: (context, index) {
              final deliveryOrder = deliveryOrderProvider.pendingDeliveryOrders[index];
              return _buildDeliveryCard(deliveryOrder, isAvailable: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveDeliveriesTab() {
    return Consumer<DeliveryOrderProvider>(
      builder: (context, deliveryOrderProvider, child) {
        final activeDeliveries = deliveryOrderProvider.activeDeliveryOrders;

        if (deliveryOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (activeDeliveries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No active deliveries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Accepted deliveries will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await deliveryOrderProvider.loadTransporterDeliveryOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeDeliveries.length,
            itemBuilder: (context, index) {
              final deliveryOrder = activeDeliveries[index];
              return _buildDeliveryCard(deliveryOrder, isAvailable: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildCompletedDeliveriesTab() {
    return Consumer<DeliveryOrderProvider>(
      builder: (context, deliveryOrderProvider, child) {
        final completedDeliveries = deliveryOrderProvider.completedDeliveryOrders;

        if (deliveryOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (completedDeliveries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No completed deliveries',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed deliveries will appear here',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await deliveryOrderProvider.loadTransporterDeliveryOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: completedDeliveries.length,
            itemBuilder: (context, index) {
              final deliveryOrder = completedDeliveries[index];
              return _buildDeliveryCard(deliveryOrder, isAvailable: false);
            },
          ),
        );
      },
    );
  }

  Widget _buildDeliveryCard(DeliveryOrderModel deliveryOrder, {required bool isAvailable}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DeliveryOrderDetailScreen(deliveryOrder: deliveryOrder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and status
              Row(
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      deliveryOrder.cropImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Order details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliveryOrder.cropName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${deliveryOrder.quantity} kg',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${deliveryOrder.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(deliveryOrder.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(deliveryOrder.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Route information
              Row(
                children: [
                  // Pickup location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.green, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Pickup',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryOrder.pickupLocation,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryOrder.farmerName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                  ),
                  
                  // Delivery location
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.red, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Delivery',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryOrder.distributorLocation,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          deliveryOrder.distributorName,
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
              
              // Action buttons for available deliveries
              if (isAvailable) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(deliveryOrder),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _acceptDelivery(deliveryOrder),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Accept'),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Action buttons for active deliveries (accepted or in_transit)
              if (!isAvailable && (deliveryOrder.status == 'accepted' || deliveryOrder.status == 'in_transit')) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (deliveryOrder.status == 'accepted') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _markInTransit(deliveryOrder),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Start Delivery'),
                        ),
                      ),
                    ] else if (deliveryOrder.status == 'in_transit') ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _markDelivered(deliveryOrder),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Mark Delivered'),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Available';
      case 'accepted':
        return 'Accepted';
      case 'in_transit':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  Future<void> _acceptDelivery(DeliveryOrderModel deliveryOrder) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    final transporterName = authProvider.userProfile?.displayName ?? 'Transporter';
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Accepting delivery...'),
          ],
        ),
      ),
    );
    
    final success = await deliveryOrderProvider.acceptDeliveryOrder(
      deliveryOrder.orderId, // Use orderId instead of deliveryOrder.id
      transporterName,
    );
    
    // Close loading dialog first
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery accepted successfully! Redirecting to My Transport Orders...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Use a post-frame callback to ensure navigation happens after the current frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Navigate to transporter dashboard with My Transports tab selected
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TransporterDashboard(initialTabIndex: 2), // Index 2 is My Transports
            ),
          );
        }
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept delivery: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRejectDialog(DeliveryOrderModel deliveryOrder) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Delivery'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this delivery?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _rejectDelivery(deliveryOrder, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectDelivery(DeliveryOrderModel deliveryOrder, String reason) async {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    final success = await deliveryOrderProvider.rejectDeliveryOrder(
      deliveryOrder.orderId, // Use orderId instead of deliveryOrder.id
      reason.isEmpty ? 'No reason provided' : reason,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject delivery: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markInTransit(DeliveryOrderModel deliveryOrder) async {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    final success = await deliveryOrderProvider.markDeliveryInTransit(deliveryOrder.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery marked as in transit'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update delivery status: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markDelivered(DeliveryOrderModel deliveryOrder) async {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    final success = await deliveryOrderProvider.markDeliveryCompleted(deliveryOrder.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to complete delivery: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 