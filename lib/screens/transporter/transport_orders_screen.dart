import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../providers/transport_order_provider.dart';
import '../../models/transport_order_model.dart';
import 'transport_order_detail_screen.dart';
import 'distributor_feedback_dialog.dart';
import '../../providers/delivery_order_provider.dart'
    ;

class TransportOrdersScreen extends StatefulWidget {
  const TransportOrdersScreen({super.key});

  @override
  State<TransportOrdersScreen> createState() => _TransportOrdersScreenState();
}

class _TransportOrdersScreenState extends State<TransportOrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final Map<String, Future<dynamic>> _deliveryDetailsFutures = {};

  Future<dynamic> _getDeliveryDetails(String deliveryOrderId) {
    return _deliveryDetailsFutures.putIfAbsent(
      deliveryOrderId,
      () => Provider.of<DeliveryOrderProvider>(context, listen: false)
          .getDeliveryOrderById(deliveryOrderId),
    );
  }

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

  Future<void> _handleRefresh() async {
    final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
    await transportOrderProvider.loadTransporterTransportOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Custom Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade700,
                  Colors.deepPurple.shade500,
                  Colors.deepPurple.shade400,
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
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Transports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Accepted'),
                      Tab(text: 'In Transit'),
                      Tab(text: 'Delivered'),
                      Tab(text: 'Cancelled'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: _handleRefresh,
              color: Colors.deepPurple[300]!,
              backgroundColor: Colors.deepPurple[100]!,
              animSpeedFactor: 2,
              showChildOpacityTransition: true,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAcceptedTransportsTab(),
                  _buildInTransitTransportsTab(),
                  _buildDeliveredTransportsTab(),
                  _buildCancelledTransportsTab(),
                ],
              ),
            ),
          ),
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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'No accepted transports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Accepted transport orders will appear here',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_car_outlined, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'No in-transit transports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'In-transit transport orders will appear here',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'No delivered transports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Delivered transport orders will appear here',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cancel_outlined, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'No cancelled transports',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Cancelled transport orders will appear here',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransportOrderDetailScreen(transportOrder: transportOrder),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Transport Order ${transportOrder.transportOrderKey}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transportOrder.status),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getStatusText(transportOrder.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
              
              // Crop information with image
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Crop image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      transportOrder.cropImageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.image, color: Colors.grey[600], size: 24),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Crop details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transportOrder.cropName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.scale, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${transportOrder.quantity} kg',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            
                            const SizedBox(width: 4),
                            Text(
                              'LKR ${transportOrder.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (transportOrder.deliveryFee != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                '+ LKR ${transportOrder.deliveryFee!.toStringAsFixed(2)} delivery fee',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Route information with enhanced layout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[50]!, Colors.grey[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    // Pickup section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pickup Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                transportOrder.pickupLocation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              FutureBuilder(
                                future: _getDeliveryDetails(transportOrder.deliveryOrderId),
                                builder: (context, snapshot) {
                                  final farmerEmail = snapshot.hasData ? (snapshot.data?.farmerEmail ?? '') : '';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Farmer: ${transportOrder.farmerName}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (farmerEmail.isNotEmpty)
                                        Text(
                                          farmerEmail,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Arrow divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.arrow_downward, color: Colors.grey[400], size: 16),
                        ),
                        Expanded(child: Divider(color: Colors.grey[300])),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Delivery section
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.location_on, color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Location',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                transportOrder.distributorLocation,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              FutureBuilder(
                                future: _getDeliveryDetails(transportOrder.deliveryOrderId),
                                builder: (context, snapshot) {
                                  final distributorEmail = snapshot.hasData ? (snapshot.data?.distributorEmail ?? '') : '';
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Distributor: ${transportOrder.distributorName}',
                                        style: TextStyle(
                                          color: Colors.grey[800],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (distributorEmail.isNotEmpty)
                                        Text(
                                          distributorEmail,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Scheduling information (if available)
              if (transportOrder.scheduledDay != null || 
                  transportOrder.scheduledDate != null || 
                  transportOrder.scheduledTime != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.withValues(alpha: 0.1), Colors.purple.withValues(alpha: 0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.1),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(Icons.schedule, color: Colors.white, size: 14),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scheduled Delivery',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'PLANNED',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Scheduling details in a grid layout
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (transportOrder.scheduledDay != null) ...[
                            _buildScheduleDetail(
                              Icons.calendar_today,
                              'Day',
                              transportOrder.scheduledDay!,
                              Colors.blue,
                            ),
                          ],
                          if (transportOrder.scheduledDate != null) ...[
                            _buildScheduleDetail(
                              Icons.event,
                              'Date',
                              _formatDate(transportOrder.scheduledDate!),
                              Colors.green,
                            ),
                          ],
                          if (transportOrder.scheduledTime != null) ...[
                            _buildScheduleDetail(
                              Icons.access_time,
                              'Time',
                              transportOrder.scheduledTime!,
                              Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      
                      // Specific delivery location if different
                      if (transportOrder.deliveryLocation != null && 
                          transportOrder.deliveryLocation!.isNotEmpty &&
                          transportOrder.deliveryLocation != transportOrder.distributorLocation) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on, size: 16, color: Colors.amber[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Specific Delivery Location:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber[800],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      transportOrder.deliveryLocation!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              
              // Action buttons based on status
              if (transportOrder.canBeInTransit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showCancelDialog(transportOrder),
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _markInTransit(transportOrder),
                        icon: const Icon(Icons.local_shipping, size: 16),
                        label: const Text('Start Delivery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[300],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (transportOrder.canBeDelivered) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _markDelivered(transportOrder),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Mark as Delivered'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[300],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Provide feedback about distributor
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDistributorFeedback(transportOrder),
                    icon: const Icon(Icons.rate_review, size: 16),
                    label: const Text('Provide Feedback about Distributor'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.purple),
                      foregroundColor: Colors.purple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.purple[300]!;
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

  Widget _buildScheduleDetail(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _showDistributorFeedback(TransportOrderModel transportOrder) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DistributorFeedbackDialog(
        deliveryOrderId: transportOrder.deliveryOrderId,
        transporterId: transportOrder.transporterId,
        transporterName: transportOrder.transporterName,
        // We don't store distributorId in transport order; pass name for now
        distributorId: transportOrder.distributorName,
        distributorName: transportOrder.distributorName,
      ),
    );

    if ((result ?? false) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks for your feedback!'),
          backgroundColor: Colors.purple,
        ),
      );
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