import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transport_order_provider.dart';
import '../../models/transport_order_model.dart';
import 'transport_order_detail_screen.dart';

class TransportOrdersScreen extends StatefulWidget {
  const TransportOrdersScreen({super.key});

  @override
  State<TransportOrdersScreen> createState() => _TransportOrdersScreenState();
}

class _TransportOrdersScreenState extends State<TransportOrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
    
    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
      transportOrderProvider.loadTransporterTransportOrders();
      transportOrderProvider.loadTransportStatistics();
    });
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
        title: const Text('My Transport Orders'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
              transportOrderProvider.loadTransporterTransportOrders();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Accepted'),
            Tab(text: 'In Transit'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAcceptedTransportsTab(),
          _buildInTransitTransportsTab(),
          _buildDeliveredTransportsTab(),
          _buildCancelledTransportsTab(),
        ],
      ),
    );
  }

  Widget _buildAcceptedTransportsTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final acceptedTransports = transportOrderProvider.acceptedTransportOrders;
        print('TransportOrdersScreen: Total transport orders: ${transportOrderProvider.transporterTransportOrders.length}');
        print('TransportOrdersScreen: Accepted transport orders: ${acceptedTransports.length}');

        if (acceptedTransports.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No accepted transports',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Accepted transport orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 16),
                Text(
                  'Total orders: ${transportOrderProvider.transporterTransportOrders.length}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (transportOrderProvider.error != null)
                  Text(
                    'Error: ${transportOrderProvider.error}',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await transportOrderProvider.loadTransporterTransportOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: acceptedTransports.length,
            itemBuilder: (context, index) {
              final transportOrder = acceptedTransports[index];
              return _buildTransportCard(transportOrder);
            },
          ),
        );
      },
    );
  }

  Widget _buildInTransitTransportsTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final inTransitTransports = transportOrderProvider.inTransitTransportOrders;

        if (inTransitTransports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No in-transit transports',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'In-transit transport orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await transportOrderProvider.loadTransporterTransportOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: inTransitTransports.length,
            itemBuilder: (context, index) {
              final transportOrder = inTransitTransports[index];
              return _buildTransportCard(transportOrder);
            },
          ),
        );
      },
    );
  }

  Widget _buildDeliveredTransportsTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final deliveredTransports = transportOrderProvider.deliveredTransportOrders;

        if (deliveredTransports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No delivered transports',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Delivered transport orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await transportOrderProvider.loadTransporterTransportOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveredTransports.length,
            itemBuilder: (context, index) {
              final transportOrder = deliveredTransports[index];
              return _buildTransportCard(transportOrder);
            },
          ),
        );
      },
    );
  }

  Widget _buildCancelledTransportsTab() {
    return Consumer<TransportOrderProvider>(
      builder: (context, transportOrderProvider, child) {
        if (transportOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final cancelledTransports = transportOrderProvider.cancelledTransportOrders;

        if (cancelledTransports.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No cancelled transports',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Cancelled transport orders will appear here',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await transportOrderProvider.loadTransporterTransportOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cancelledTransports.length,
            itemBuilder: (context, index) {
              final transportOrder = cancelledTransports[index];
              return _buildTransportCard(transportOrder);
            },
          ),
        );
      },
    );
  }

  Widget _buildTransportCard(TransportOrderModel transportOrder) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransportOrderDetailScreen(transportOrder: transportOrder),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with image and status
              Row(
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      transportOrder.cropImageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Order details
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
                        const SizedBox(height: 4),
                        Text(
                          '${transportOrder.quantity} kg',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '₹${transportOrder.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (transportOrder.deliveryFee != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '+ ₹${transportOrder.deliveryFee!.toStringAsFixed(2)} fee',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transportOrder.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(transportOrder.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Route information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Pickup location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 8),
                          Text(
                            transportOrder.pickupLocation,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transportOrder.farmerName,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(Icons.arrow_forward, color: Colors.grey[400]),
                    ),
                    
                    // Delivery location
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.location_on, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 8),
                          Text(
                            transportOrder.distributorLocation,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            transportOrder.distributorName,
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
              
              // Action buttons based on status
              if (transportOrder.canBeInTransit) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showCancelDialog(transportOrder),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _markInTransit(transportOrder),
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
                  ],
                ),
              ] else if (transportOrder.canBeDelivered) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _markDelivered(transportOrder),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Mark as Delivered'),
                  ),
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

  String _getStatusText(String status) {
    switch (status) {
      case 'accepted':
        return 'Accepted';
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

  Future<void> _markInTransit(TransportOrderModel transportOrder) async {
    final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);

    final success = await transportOrderProvider.markTransportInTransit(transportOrder.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport marked as in transit'),
          backgroundColor: Colors.blue,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${transportOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markDelivered(TransportOrderModel transportOrder) async {
    final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);

    final success = await transportOrderProvider.markTransportDelivered(transportOrder.id);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport marked as delivered'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${transportOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelDialog(TransportOrderModel transportOrder) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Transport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this transport?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              await _cancelTransport(transportOrder, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Transport'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTransport(TransportOrderModel transportOrder, String reason) async {
    final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);

    final success = await transportOrderProvider.cancelTransportOrder(
      transportOrder.id,
      reason.isEmpty ? 'No reason provided' : reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transport cancelled'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel transport: ${transportOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 