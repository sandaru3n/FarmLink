import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../models/rating_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/delivery_order_service.dart';
import '../../services/transport_order_service.dart';
import '../../services/rating_service.dart';
import 'transporter_details_screen.dart';
import 'rating_dialog.dart';

class DistributorOrdersScreen extends StatefulWidget {
  const DistributorOrdersScreen({super.key});

  @override
  State<DistributorOrdersScreen> createState() => _DistributorOrdersScreenState();
}

class _DistributorOrdersScreenState extends State<DistributorOrdersScreen> {
  final OrderService _orderService = OrderService();
  final DeliveryOrderService _deliveryOrderService = DeliveryOrderService();
  final TransportOrderService _transportOrderService = TransportOrderService();
  final RatingService _ratingService = RatingService();
  String _selectedStatus = 'All';
  
  // Track expanded state for each order
  final Map<String, bool> _expandedOrders = {};

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Confirmed',
    'Completed',
    'Cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.uid ?? '';

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const Text(
                'Filter by status:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                onSelected: (String status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
                itemBuilder: (BuildContext context) {
                  return _statusFilters.map((String status) {
                    return PopupMenuItem<String>(
                      value: status,
                      child: Row(
                        children: [
                          Icon(
                            _selectedStatus == status ? Icons.check : Icons.radio_button_unchecked,
                            color: _selectedStatus == status ? Colors.orange : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(status),
                        ],
                      ),
                    );
                  }).toList();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_selectedStatus),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Orders list
        Expanded(
          child: StreamBuilder<List<OrderModel>>(
        stream: _selectedStatus == 'All'
            ? _orderService.getDistributorOrders(currentUserId)
            : _orderService.getOrdersByOrderStatus(currentUserId, _selectedStatus.toLowerCase()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading orders: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedStatus == 'All' ? Icons.shopping_bag : Icons.filter_list,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                                      Text(
                      _selectedStatus == 'All' 
                          ? 'No orders placed yet'
                          : 'No ${_selectedStatus.toLowerCase()} orders',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedStatus == 'All'
                        ? 'Place bids on crops and win auctions to see your orders here'
                        : 'Try selecting a different status filter',
                    style: const TextStyle(
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
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          );
        },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header with Image and Status
          Container(
            height: 140,
             decoration: const BoxDecoration(
               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
               color: Colors.white,
             ),
            child: Row(
              children: [
                // Crop Image
                Container(
                  margin: const EdgeInsets.all(12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 100,
                      height: 116,
                      child: order.cropImageUrl.isNotEmpty
                          ? Image.network(
                              order.cropImageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.grey.shade200, Colors.grey.shade100],
                                    ),
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.orange,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_not_supported,
                                        size: 32,
                                        color: Colors.grey.shade500,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'No Image',
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.grey.shade300, Colors.grey.shade200],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 32,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No Image',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                
                // Order Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Crop Name and Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.cropName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusChip(order.orderStatus),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Quantity and Price
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.scale, size: 14, color: Colors.purple.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${order.quantity} kg',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'LKR ${order.finalPrice}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Order Date
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              'Ordered: ${_formatDate(order.createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
           // Order Details
           Padding(
             padding: const EdgeInsets.all(20),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 // Order Details Section Header with Expand/Collapse
                 InkWell(
                   onTap: () {
                     setState(() {
                       _expandedOrders[order.id] = !(_expandedOrders[order.id] ?? false);
                     });
                   },
                   borderRadius: BorderRadius.circular(12),
                   child: Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: Colors.orange.shade50,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: Colors.orange.shade200),
                     ),
                     child: Row(
                       children: [
                         Container(
                           padding: const EdgeInsets.all(8),
                           decoration: BoxDecoration(
                             gradient: LinearGradient(
                               colors: [Colors.orange.shade400, Colors.orange.shade600],
                             ),
                             borderRadius: BorderRadius.circular(8),
                           ),
                           child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                         ),
                         const SizedBox(width: 12),
                         const Expanded(
                           child: Text(
                             'Order Details',
                             style: TextStyle(
                               fontSize: 18,
                               fontWeight: FontWeight.bold,
                               color: Colors.black87,
                             ),
                           ),
                         ),
                         Icon(
                           _expandedOrders[order.id] == true 
                               ? Icons.expand_less 
                               : Icons.expand_more,
                           color: Colors.orange.shade700,
                           size: 24,
                         ),
                       ],
                     ),
                   ),
                 ),
                 
                 // Expandable Order Details Content
                 ClipRect(
                   child: AnimatedSize(
                     duration: const Duration(milliseconds: 300),
                     curve: Curves.easeInOut,
                     child: (_expandedOrders[order.id] ?? false)
                         ? Column(
                             children: [
                               const SizedBox(height: 16),
                               _buildModernDetailRow('Order ID', order.id, Icons.tag),
                               _buildModernDetailRow('Pickup Location', order.pickupLocation, Icons.location_on),
                               _buildModernDetailRow('Shipping Address', order.distributorLocation.isNotEmpty 
                                   ? order.distributorLocation 
                                   : 'Not specified', Icons.local_shipping),
                               _buildModernDetailRow('Payment Status', order.paymentStatus.toUpperCase(), Icons.payment),
                               
                               // Transporter information if available
                               FutureBuilder<Map<String, dynamic>?>(
                                 future: _getDeliveryOrderInfo(order.id),
                                 builder: (context, snapshot) {
                                   if (snapshot.hasData && snapshot.data != null) {
                                     final deliveryInfo = snapshot.data!;
                                     if (deliveryInfo['transporterId'] != null && deliveryInfo['transporterName'] != null) {
                                       return Column(
                                         children: [
                                           const SizedBox(height: 12),
                                           _buildTransporterInfoWithLiveUpdates(deliveryInfo),
                                         ],
                                       );
                                     }
                                   }
                                   return const SizedBox.shrink();
                                 },
                               ),
                               
                               // Status-specific dates
                               if (order.confirmedAt != null)
                                 _buildModernDetailRow('Confirmed Date', _formatDateTime(order.confirmedAt!), Icons.check_circle),
                               if (order.completedAt != null)
                                 _buildModernDetailRow('Completed Date', _formatDateTime(order.completedAt!), Icons.done_all),
                               if (order.paymentCompletedAt != null)
                                 _buildModernDetailRow('Payment Date', _formatDateTime(order.paymentCompletedAt!), Icons.payment),
                               
                               const SizedBox(height: 20),
                               
                               // Action Buttons
                               _buildActionButtons(order),
                             ],
                           )
                         : const SizedBox.shrink(),
                   ),
                 ),
               ],
             ),
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

  Widget _buildModernDetailRow(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.orange.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
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
        chipColor = Colors.purple;
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
    switch (order.orderStatus.toLowerCase()) {
      case 'pending':
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.shade50,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _contactFarmer(order),
                  icon: Icon(Icons.message, size: 18, color: Colors.orange.shade700),
                  label: Text('Contact Farmer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'confirmed':
        return Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orange.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.orange.shade50,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => _contactFarmer(order),
                  icon: Icon(Icons.message, size: 18, color: Colors.orange.shade700),
                  label: Text('Contact Farmer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.orange.shade700)),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade500, Colors.green.shade700],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _markAsCompleted(order),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('Mark Complete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'completed':
        return const SizedBox.shrink(); // No buttons for completed orders
      default:
        return const SizedBox.shrink(); // No buttons for other statuses
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 20,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.orange.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          order.cropName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Order Image and Key Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.orange.shade200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Crop Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: order.cropImageUrl.isNotEmpty
                            ? Image.network(
                                order.cropImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.grey.shade300, Colors.grey.shade200],
                                      ),
                                    ),
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                  );
                                },
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.grey.shade300, Colors.grey.shade200],
                                  ),
                                ),
                                child: const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order.quantity} kg',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${order.finalPrice}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatusChip(order.orderStatus),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Order Details Section
              Text(
                'Order Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              
              // Scrollable Details
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildModernDetailRow('Order ID', order.id, Icons.tag),
                      _buildModernDetailRow('Pickup Location', order.pickupLocation, Icons.location_on),
                      _buildModernDetailRow('Shipping Address', order.distributorLocation.isNotEmpty 
                          ? order.distributorLocation 
                          : 'Not specified', Icons.local_shipping),
                      _buildModernDetailRow('Payment Status', order.paymentStatus.toUpperCase(), Icons.payment),
                      _buildModernDetailRow('Order Date', _formatDateTime(order.createdAt), Icons.calendar_today),
                      if (order.confirmedAt != null)
                        _buildModernDetailRow('Confirmed Date', _formatDateTime(order.confirmedAt!), Icons.check_circle),
                      if (order.completedAt != null)
                        _buildModernDetailRow('Completed Date', _formatDateTime(order.completedAt!), Icons.done_all),
                      if (order.paymentCompletedAt != null)
                        _buildModernDetailRow('Payment Date', _formatDateTime(order.paymentCompletedAt!), Icons.payment),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Close Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade500, Colors.orange.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            onPressed: () async {
              try {
                await _orderService.updateOrderStatus(order.id, 'completed');
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order marked as completed!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to update order: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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

  Future<Map<String, dynamic>?> _getDeliveryOrderInfo(String orderId) async {
    try {
      final deliveryOrderId = 'delivery_$orderId';
      final deliveryOrder = await _deliveryOrderService.getDeliveryOrderById(deliveryOrderId);
      if (deliveryOrder != null) {
        return {
          'transporterId': deliveryOrder.transporterId,
          'transporterName': deliveryOrder.transporterName,
          'deliveryOrderId': deliveryOrder.id,
          'status': deliveryOrder.status,
        };
      }
      return null;
    } catch (e) {
      print('Error getting delivery order info: $e');
      return null;
    }
  }

  Widget _buildTransporterInfoWithLiveUpdates(Map<String, dynamic> deliveryInfo) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade50,
            Colors.purple.shade100,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.local_shipping, color: Colors.purple.shade700, size: 18),
              ),
              const SizedBox(width: 8),
              const Text(
                'Assigned Transporter',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            deliveryInfo['transporterName'] ?? 'Unknown',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Live delivery status tracking
          StreamBuilder<Map<String, dynamic>?>(
            stream: _getLiveDeliveryStatus(deliveryInfo['deliveryOrderId']),
            builder: (context, statusSnapshot) {
              if (statusSnapshot.hasData && statusSnapshot.data != null) {
                final statusData = statusSnapshot.data!;
                return _buildDeliveryStatusCard(statusData);
              }
              
              // Fallback to basic status
              return _buildBasicStatusCard(deliveryInfo);
            },
          ),
          
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _viewTransporterDetails(deliveryInfo),
              icon: const Icon(Icons.person, size: 16),
              label: const Text('View Transporter Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
                shadowColor: Colors.purple.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<Map<String, dynamic>?> _getLiveDeliveryStatus(String deliveryOrderId) {
    return _deliveryOrderService.listenToDeliveryOrder(deliveryOrderId).map((deliveryOrder) {
      if (deliveryOrder != null) {
        return {
          'deliveryOrderId': deliveryOrderId,
          'status': deliveryOrder.status,
          'transporterId': deliveryOrder.transporterId,
          'transporterName': deliveryOrder.transporterName,
          'acceptedAt': deliveryOrder.acceptedAt,
          'inTransitAt': deliveryOrder.inTransitAt,
          'deliveredAt': deliveryOrder.deliveredAt,
          'estimatedDeliveryTime': deliveryOrder.estimatedDeliveryTime,
          'actualDeliveryTime': deliveryOrder.actualDeliveryTime,
        };
      }
      return null;
    });
  }

  Widget _buildDeliveryStatusCard(Map<String, dynamic> statusData) {
    final status = statusData['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Text(
                'Delivery Status: $statusText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (statusData['acceptedAt'] != null) ...[
            Text(
              'Accepted: ${_formatDateTime(statusData['acceptedAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            // ETA shows only after accepted status
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: Colors.purple.shade600, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Delivery Within 2-3 days',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (statusData['inTransitAt'] != null)
            Text(
              'In Transit: ${_formatDateTime(statusData['inTransitAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          if (statusData['deliveredAt'] != null)
            Text(
              'Delivered: ${_formatDateTime(statusData['deliveredAt'])}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          
          // Rating button for delivered orders
          if (status == 'delivered') ...[
            const SizedBox(height: 8),
            _buildRatingButton(statusData),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicStatusCard(Map<String, dynamic> deliveryInfo) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info, color: Colors.grey, size: 16),
          const SizedBox(width: 6),
          Text(
            'Status: ${deliveryInfo['status']?.toUpperCase() ?? 'UNKNOWN'}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.purple;
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'accepted':
        return Icons.check_circle;
      case 'in_transit':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'in_transit':
        return 'IN TRANSIT';
      case 'delivered':
        return 'DELIVERED';
      case 'rejected':
        return 'REJECTED';
      default:
        return 'UNKNOWN';
    }
  }

  Widget _buildRatingButton(Map<String, dynamic> statusData) {
    return FutureBuilder<bool>(
      future: _ratingService.hasBeenRated(statusData['deliveryOrderId']),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        final hasBeenRated = snapshot.data ?? false;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showRatingDialog(statusData, hasBeenRated),
            icon: Icon(hasBeenRated ? Icons.edit : Icons.star, size: 16),
            label: Text(hasBeenRated ? 'Update Rating' : 'Rate Transporter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasBeenRated ? Colors.orange : Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRatingDialog(Map<String, dynamic> statusData, bool hasBeenRated) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final distributorId = authProvider.userProfile?.uid ?? '';
    final distributorName = authProvider.userProfile?.displayName ?? 'Distributor';

    // Get existing rating if available
    RatingModel? existingRating;
    if (hasBeenRated) {
      existingRating = await _ratingService.getRatingByDeliveryOrder(statusData['deliveryOrderId']);
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RatingDialog(
        deliveryOrderId: statusData['deliveryOrderId'],
        transporterId: statusData['transporterId'],
        transporterName: statusData['transporterName'],
        distributorId: distributorId,
        distributorName: distributorName,
        existingRating: existingRating,
      ),
    );

    if (result == true) {
      // Refresh the UI to show updated rating status
      setState(() {});
    }
  }

  void _viewTransporterDetails(Map<String, dynamic> deliveryInfo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TransporterDetailsScreen(
          transporterId: deliveryInfo['transporterId'],
          transporterName: deliveryInfo['transporterName'],
          deliveryOrderId: deliveryInfo['deliveryOrderId'],
        ),
      ),
    );
  }
}
