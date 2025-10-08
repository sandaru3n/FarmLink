import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '../../providers/delivery_order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transport_order_provider.dart';
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
  
  // Track scheduled deliveries for each day
  Map<String, List<DeliveryOrderModel>> _scheduledDeliveries = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    
    // Clean up any accepted deliveries from the scheduled map
    _cleanupAcceptedDeliveries();
  }

  void _cleanupAcceptedDeliveries() {
    setState(() {
      for (final day in _scheduledDeliveries.keys) {
        _scheduledDeliveries[day]!.removeWhere((delivery) => delivery.status != 'pending');
      }
    });
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

  Future<void> _handleRefresh() async {
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    await Future.wait([
      deliveryOrderProvider.loadPendingDeliveryOrders(),
      deliveryOrderProvider.loadTransporterDeliveryOrders(),
      deliveryOrderProvider.loadDeliveryStatistics(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
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
            Tab(text: 'Delivery Schedule'),
          ],
        ),
      ),
      body: LiquidPullToRefresh(
        onRefresh: _handleRefresh,
        color: Colors.deepPurple[300]!,
        backgroundColor: Colors.deepPurple[100]!,
        animSpeedFactor: 2,
        showChildOpacityTransition: true,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAvailableDeliveriesTab(),
            _buildDeliveryScheduleTab(),
          ],
        ),
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

  Widget _buildDeliveryScheduleTab() {
    return Consumer<DeliveryOrderProvider>(
      builder: (context, deliveryOrderProvider, child) {
        if (deliveryOrderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Timeline Card
              _buildTimelineCard(),
              const SizedBox(height: 20),
              
              // Available Deliveries Card
              _buildAvailableDeliveriesCard(deliveryOrderProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: Colors.purple, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Weekly Schedule',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimelineView(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineView() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return SizedBox(
      height: 400, // Fixed height to prevent overflow
      child: SingleChildScrollView(
        child: Column(
          children: weekdays.asMap().entries.map((entry) {
        final index = entry.key;
        final day = entry.value;
        final isToday = index == DateTime.now().weekday - 1;
        final scheduledCount = _scheduledDeliveries[day]?.where((delivery) => delivery.status == 'pending').length ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // Day label with count
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                decoration: BoxDecoration(
                  color: isToday ? Colors.purple : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  children: [
                    Text(
                      day,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (scheduledCount > 0) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isToday ? Colors.white : Colors.purple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$scheduledCount',
                          style: TextStyle(
                            color: isToday ? Colors.purple : Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Drop zone for deliveries
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 60),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: DragTarget<DeliveryOrderModel>(
                    onWillAccept: (data) => scheduledCount < 3, // Max 3 deliveries per day
                    onAccept: (deliveryOrder) {
                      _scheduleDelivery(deliveryOrder, day);
                    },
                    builder: (context, candidateData, rejectedData) {
                      final isDragOver = candidateData.isNotEmpty;
                      final isFull = scheduledCount >= 3;
                      
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 60),
                        decoration: BoxDecoration(
                          color: isDragOver 
                              ? Colors.purple.withOpacity(0.15)
                              : isFull 
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: isDragOver
                              ? Border.all(color: Colors.purple, width: 2)
                              : isFull
                                  ? Border.all(color: Colors.red.withOpacity(0.5), width: 1)
                                  : Border.all(color: Colors.grey[200]!, width: 1),
                        ),
                        child: Column(
                          children: [
                            // Scheduled deliveries display
                            if (scheduledCount > 0) ...[
                              ..._scheduledDeliveries[day]!
                                  .where((delivery) => delivery.status == 'pending')
                                  .map((delivery) {
                                final index = _scheduledDeliveries[day]!.indexOf(delivery);
                                return _buildScheduledDeliveryItem(delivery, day, index);
                              }),
                            ] else ...[
                              Container(
                                constraints: BoxConstraints(minHeight: 50),
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isDragOver ? Icons.add_circle : Icons.add_circle_outline,
                                        color: isDragOver ? Colors.purple : Colors.grey[400],
                                        size: 18,
                                      ),
                                      SizedBox(height: 2),
                                      Flexible(
                                        child: Text(
                                          isDragOver 
                                              ? 'Drop here to schedule!'
                                              : isFull 
                                                  ? 'Day is full (3/3)'
                                                  : 'Drop delivery here\n(Max 3 per day)',
                                          style: TextStyle(
                                            color: isDragOver 
                                                ? Colors.purple[700]
                                                : isFull 
                                                    ? Colors.red[600]
                                                    : Colors.grey[500],
                                            fontSize: 9,
                                            fontWeight: isDragOver ? FontWeight.bold : FontWeight.normal,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
        ),
      ),
    );
  }

  Widget _buildAvailableDeliveriesCard(DeliveryOrderProvider deliveryOrderProvider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Available Deliveries',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (deliveryOrderProvider.pendingDeliveryOrders.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No available deliveries',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 400, // Fixed height to prevent layout issues
                child: SingleChildScrollView(
                  child: Column(
                    children: deliveryOrderProvider.pendingDeliveryOrders
                        .where((deliveryOrder) => 
                            !_isDeliveryScheduled(deliveryOrder) && 
                            deliveryOrder.status == 'pending' &&
                            !_isDeliveryAccepted(deliveryOrder))
                        .map((deliveryOrder) {
                      return _buildDraggableDeliveryCard(deliveryOrder);
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableDeliveryCard(DeliveryOrderModel deliveryOrder) {
    return Draggable<DeliveryOrderModel>(
      data: deliveryOrder,
      feedback: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        shadowColor: Colors.purple.withOpacity(0.3),
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple, width: 2),
          ),
          child: _buildDeliveryCard(deliveryOrder, isAvailable: true),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Transform.scale(
          scale: 0.95,
          child: Opacity(
            opacity: 0.6,
            child: _buildDeliveryCard(deliveryOrder, isAvailable: true),
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: _buildDeliveryCard(deliveryOrder, isAvailable: true),
      ),
    );
  }

  Widget _buildScheduledDeliveryItem(DeliveryOrderModel deliveryOrder, String day, int index) {
    return Container(
      height: 70,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.1), Colors.purple.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withOpacity(0.4), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status indicator
          Container(
            width: 4,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 12, color: Colors.purple[600]),
                    SizedBox(width: 4),
                    Text(
                      deliveryOrder.cropName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.scale, size: 10, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${deliveryOrder.quantity}kg',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.location_on, size: 10, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        deliveryOrder.distributorLocation,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.grey[500],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Schedule button
              GestureDetector(
                onTap: () => _acceptScheduledDelivery(deliveryOrder, day),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green[600]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.3),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 10, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Schedule',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 4),
              // Remove button
              GestureDetector(
                onTap: () => _removeScheduledDelivery(deliveryOrder, day),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.close,
                    size: 10,
                    color: Colors.red[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _scheduleDelivery(DeliveryOrderModel deliveryOrder, String day) {
    setState(() {
      _scheduledDeliveries[day]!.add(deliveryOrder);
    });
    
    // Show success feedback with haptic feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delivery scheduled for $day! Tap to schedule details.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Schedule',
          textColor: Colors.white,
          onPressed: () => _acceptScheduledDelivery(deliveryOrder, day),
        ),
      ),
    );
  }

  void _removeScheduledDelivery(DeliveryOrderModel deliveryOrder, String day) {
    setState(() {
      _scheduledDeliveries[day]!.remove(deliveryOrder);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.remove_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Delivery removed from $day',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isDeliveryScheduled(DeliveryOrderModel deliveryOrder) {
    for (final dayDeliveries in _scheduledDeliveries.values) {
      if (dayDeliveries.any((scheduled) => scheduled.id == deliveryOrder.id)) {
        return true;
      }
    }
    return false;
  }

  bool _isDeliveryAccepted(DeliveryOrderModel deliveryOrder) {
    // Check if the delivery order status is accepted
    return deliveryOrder.status == 'accepted';
  }

  Future<Map<String, dynamic>?> _showSchedulingDialog(DeliveryOrderModel deliveryOrder, String day) async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final locationController = TextEditingController(text: deliveryOrder.distributorLocation);
    
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple, Colors.purple[700]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Schedule Delivery',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Plan your delivery for ${deliveryOrder.cropName}',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day selection with better styling
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.purple.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.purple, size: 20),
                              SizedBox(width: 12),
                              Text(
                                'Scheduled Day: ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                day,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Quick scheduling options
                        Text(
                          'Quick Schedule Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        
                        // Quick time buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildQuickTimeButton('Morning (9 AM)', '09:00', selectedTime, setDialogState),
                            _buildQuickTimeButton('Afternoon (2 PM)', '14:00', selectedTime, setDialogState),
                            _buildQuickTimeButton('Evening (6 PM)', '18:00', selectedTime, setDialogState),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Custom date picker with better styling
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.event, color: Colors.blue),
                            title: Text(
                              selectedDate != null 
                                ? 'Date: ${_formatDate(selectedDate!)}'
                                : 'Select specific date (optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedDate != null ? Colors.blue[700] : Colors.grey[600],
                                fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(Duration(days: 1)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(Duration(days: 30)),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.purple,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setDialogState(() {
                                  selectedDate = date;
                                });
                              }
                            },
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Custom time picker with better styling
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.access_time, color: Colors.orange),
                            title: Text(
                              selectedTime != null 
                                ? 'Time: ${selectedTime!.format(context)}'
                                : 'Select specific time (optional)',
                              style: TextStyle(
                                fontSize: 14,
                                color: selectedTime != null ? Colors.orange[700] : Colors.grey[600],
                                fontWeight: selectedTime != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.purple,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (time != null) {
                                setDialogState(() {
                                  selectedTime = time;
                                });
                              }
                            },
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Delivery location with better styling
                        Text(
                          'Delivery Location',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        TextField(
                          controller: locationController,
                          decoration: InputDecoration(
                            hintText: 'Enter specific delivery address',
                            prefixIcon: Icon(Icons.location_on, color: Colors.green),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.purple, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          maxLines: 2,
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Info card with better styling
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[50]!, Colors.blue[100]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '💡 Tip: Specific scheduling helps with route planning and ensures timely deliveries!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Action buttons with better styling
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop({
                              'scheduledDate': selectedDate,
                              'scheduledTime': selectedTime?.format(context),
                              'deliveryLocation': locationController.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            elevation: 2,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.schedule, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Schedule & Accept',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  Widget _buildQuickTimeButton(String label, String time, TimeOfDay? selectedTime, StateSetter setDialogState) {
    final isSelected = selectedTime?.format(context) == time;
    return GestureDetector(
      onTap: () {
        setDialogState(() {
          final hour = int.parse(time.split(':')[0]);
          final minute = int.parse(time.split(':')[1]);
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
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

  void _acceptScheduledDelivery(DeliveryOrderModel deliveryOrder, String day) async {
    print('Accept button tapped for delivery: ${deliveryOrder.id} on day: $day');
    
    // Show scheduling dialog first
    final schedulingDetails = await _showSchedulingDialog(deliveryOrder, day);
    if (schedulingDetails == null) return; // User cancelled
    
    try {
      // Get current user info
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      
      print('User: ${user?.uid}, Display name: ${user?.displayName}');
      
      if (user == null) {
        print('User is null - not authenticated');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if delivery is already accepted - if so, just remove from UI
      if (deliveryOrder.status == 'accepted') {
        setState(() {
          _scheduledDeliveries[day]!.remove(deliveryOrder);
          // Clean up all accepted deliveries from the entire scheduled map
          for (final dayKey in _scheduledDeliveries.keys) {
            _scheduledDeliveries[dayKey]!.removeWhere((delivery) => delivery.status != 'pending');
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery already accepted and removed from schedule'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      // Remove from scheduled deliveries
      print('Removing delivery from scheduled deliveries for day: $day');
      setState(() {
        _scheduledDeliveries[day]!.remove(deliveryOrder);
        // Also clean up any other accepted deliveries from the map
        _scheduledDeliveries[day]!.removeWhere((delivery) => delivery.status != 'pending');
      });
      print('Delivery removed from scheduled deliveries');

      // Create delivery order document first if it doesn't exist
      print('Creating delivery order document for: ${deliveryOrder.id}');
      final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
      try {
        // Use the acceptDeliveryOrder method which creates both delivery order and transport order
        final success = await deliveryOrderProvider.acceptDeliveryOrder(
          deliveryOrder.orderId, 
          user.displayName ?? 'Transporter',
          scheduledDay: day,
        );
        
        if (success) {
          print('Delivery order accepted successfully');
          
          // Update scheduling details if provided
          if (schedulingDetails['scheduledDate'] != null || schedulingDetails['scheduledTime'] != null) {
            // Find the transport order and update scheduling
            final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
            await transportOrderProvider.updateTransportOrderScheduling(
              'transport_delivery_${deliveryOrder.orderId}',
              scheduledDate: schedulingDetails['scheduledDate'],
              scheduledTime: schedulingDetails['scheduledTime'],
              deliveryLocation: schedulingDetails['deliveryLocation'],
            );
          }
        } else {
          print('Failed to accept delivery order: ${deliveryOrderProvider.error}');
        }
      } catch (e) {
        print('Error accepting delivery order: $e');
        // Continue with UI updates even if backend fails
      }

      // Refresh both transport orders and delivery orders
      final transportOrderProvider = Provider.of<TransportOrderProvider>(context, listen: false);
      transportOrderProvider.loadTransporterTransportOrders();
      deliveryOrderProvider.loadPendingDeliveryOrders();

      // Clean up all accepted deliveries from the entire scheduled map
      setState(() {
        for (final day in _scheduledDeliveries.keys) {
          _scheduledDeliveries[day]!.removeWhere((delivery) => delivery.status != 'pending');
        }
      });

      // Show success message and navigate to My Transport Orders
      print('Showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery accepted and scheduled for ${schedulingDetails['scheduledDate'] != null ? 'specific date' : day}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Navigate to transporter dashboard with My Transports tab selected
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => TransporterDashboard(initialTabIndex: 2), // Index 2 is My Transports
            ),
          );
        }
      });
    } catch (e) {
      // Show error message
      print('Error in _acceptScheduledDelivery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting delivery: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
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