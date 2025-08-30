import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import '../payment/payment_screen.dart';
import '../../services/payment_service.dart'; // Added import for PaymentService

class CropMarketplaceScreen extends StatefulWidget {
  const CropMarketplaceScreen({super.key});

  @override
  State<CropMarketplaceScreen> createState() => _CropMarketplaceScreenState();
}

class _CropMarketplaceScreenState extends State<CropMarketplaceScreen> {
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
      body: Consumer<CropProvider>(
        builder: (context, cropProvider, child) {
          if (cropProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cropProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${cropProvider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      cropProvider.clearError();
                      cropProvider.loadAllActiveCrops();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (cropProvider.allActiveCrops.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No crops available for bidding',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cropProvider.allActiveCrops.length,
            itemBuilder: (context, index) {
              final crop = cropProvider.allActiveCrops[index];
              return _buildCropCard(crop);
            },
          );
        },
      ),
    );
  }

  Widget _buildCropCard(CropModel crop) {
    final timeLeft = crop.timeLeft;
    final highestBid = crop.highestBid;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.uid ?? '';
    final hasUserBid = crop.hasUserBid(currentUserId);
    final userBid = crop.getUserBid(currentUserId);
    final isUserHighestBidder = crop.isUserHighestBidder(currentUserId);

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
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
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
                  height: 200,
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
                // Crop Name and Time Left
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crop.cropName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: crop.isExpired ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        crop.isExpired ? 'EXPIRED' : _formatDuration(timeLeft),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quantity and Min Bid
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.scale,
                        'Quantity',
                        '${crop.quantity} kg',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Min Bid',
                        '₹${crop.minBidPrice}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                _buildInfoRow(
                  Icons.location_on,
                  'Pickup Location',
                  crop.pickupLocation,
                ),
                const SizedBox(height: 8),

                // Current Highest Bid
                if (highestBid != null)
                  _buildInfoRow(
                    Icons.trending_up,
                    'Current Highest',
                    '₹${highestBid.amount}',
                    valueColor: Colors.green,
                  ),
                const SizedBox(height: 8),

                // User's current bid (if any)
                if (hasUserBid && userBid != null)
                  _buildInfoRow(
                    Icons.person,
                    'Your Bid',
                    '₹${userBid.amount}',
                    valueColor: isUserHighestBidder ? Colors.green : Colors.blue,
                  ),
                const SizedBox(height: 16),

                // Bidding History Dropdown
                if (crop.bids.isNotEmpty)
                  _buildBiddingHistorySection(crop),
                const SizedBox(height: 16),

                // Action Buttons
                _buildActionButtons(crop, hasUserBid, isUserHighestBidder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBiddingHistorySection(CropModel crop) {
    return ExpansionTile(
      title: Row(
        children: [
          const Icon(Icons.history, size: 20),
          const SizedBox(width: 8),
          Text(
            'Bidding History (${crop.bids.length} bids)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crop.bids.length,
          itemBuilder: (context, index) {
            final bid = crop.bids[index];
            final isHighest = crop.highestBid?.id == bid.id;
            
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: isHighest ? Colors.green : Colors.blue,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                bid.distributorName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '₹${bid.amount} • ${_formatDateTime(bid.createdAt)}',
                style: TextStyle(
                  color: isHighest ? Colors.green : Colors.grey.shade600,
                  fontWeight: isHighest ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isHighest 
                ? const Icon(Icons.emoji_events, color: Colors.amber, size: 20)
                : null,
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(CropModel crop, bool hasUserBid, bool isUserHighestBidder) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.uid ?? '';
    final userBid = crop.getUserBid(currentUserId);

    if (crop.isSold) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sold to ${crop.order?.distributorName ?? 'Highest Bidder'}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (crop.isExpired) {
      if (crop.bids.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'No bids placed - Auction ended',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      if (isUserHighestBidder) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _placeOrder(crop),
            icon: const Icon(Icons.shopping_cart),
            label: const Text('Place Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Auction ended. ${crop.highestBid?.distributorName ?? 'Highest bidder'} won.',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }

    // Active auction buttons
    if (hasUserBid) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showUpdateBidDialog(crop, userBid!),
              icon: const Icon(Icons.edit),
              label: const Text('Update Bid'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showBiddingHistoryDialog(crop),
              icon: const Icon(Icons.history),
              label: const Text('History'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showBidDialog(crop),
          icon: const Icon(Icons.gavel),
          label: const Text('Place Bid'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showBidDialog(CropModel crop) {
    final bidController = TextEditingController();
    final highestBid = crop.highestBid;
    final minBid = highestBid != null 
        ? highestBid.amount + 1 
        : crop.minBidPrice;

    bidController.text = minBid.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bid on ${crop.cropName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quantity: ${crop.quantity} kg'),
            Text('Minimum bid: ₹${crop.minBidPrice}'),
            if (highestBid != null)
              Text('Current highest: ₹${highestBid.amount}'),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Your Bid Amount (₹)',
                border: OutlineInputBorder(),
              ),
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
               // Store ScaffoldMessenger reference early
               final scaffoldMessenger = ScaffoldMessenger.of(context);
               
               final bidAmount = double.tryParse(bidController.text);
               if (bidAmount == null || bidAmount < minBid) {
                 scaffoldMessenger.showSnackBar(
                   SnackBar(
                     content: Text('Bid must be at least ₹${minBid}'),
                   ),
                 );
                 return;
               }

               final cropProvider = Provider.of<CropProvider>(context, listen: false);
               final authProvider = Provider.of<AuthProvider>(context, listen: false);
               
               final bid = BidModel(
                 id: DateTime.now().millisecondsSinceEpoch.toString(),
                 distributorId: authProvider.userProfile?.uid ?? '',
                 distributorName: authProvider.userProfile?.displayName ?? 'Distributor',
                 amount: bidAmount,
                 createdAt: DateTime.now(),
               );

               final success = await cropProvider.addBid(crop.id, bid);
               
               if (success) {
                 if (mounted) {
                   Navigator.of(context).pop();
                   scaffoldMessenger.showSnackBar(
                     const SnackBar(
                       content: Text('Bid placed successfully!'),
                     ),
                   );
                 }
               } else {
                 if (mounted) {
                   scaffoldMessenger.showSnackBar(
                     SnackBar(
                       content: Text(cropProvider.error ?? 'Failed to place bid'),
                     ),
                   );
                 }
               }
             },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Bid'),
          ),
        ],
      ),
    );
  }

  void _showUpdateBidDialog(CropModel crop, BidModel currentBid) {
    final bidController = TextEditingController();
    final highestBid = crop.highestBid;
    final minBid = highestBid != null && highestBid.distributorId != currentBid.distributorId
        ? highestBid.amount + 1 
        : currentBid.amount + 1;

    bidController.text = minBid.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Bid on ${crop.cropName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your current bid: ₹${currentBid.amount}'),
            if (highestBid != null && highestBid.distributorId != currentBid.distributorId)
              Text('Current highest: ₹${highestBid.amount}'),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'New Bid Amount (₹)',
                border: OutlineInputBorder(),
              ),
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
               // Store ScaffoldMessenger reference early
               final scaffoldMessenger = ScaffoldMessenger.of(context);
               
               final bidAmount = double.tryParse(bidController.text);
               if (bidAmount == null || bidAmount <= currentBid.amount) {
                 scaffoldMessenger.showSnackBar(
                   SnackBar(
                     content: Text('New bid must be higher than ₹${currentBid.amount}'),
                   ),
                 );
                 return;
               }

               final cropProvider = Provider.of<CropProvider>(context, listen: false);
               final authProvider = Provider.of<AuthProvider>(context, listen: false);
               
               final success = await cropProvider.updateBid(
                 crop.id, 
                 authProvider.userProfile?.uid ?? '', 
                 bidAmount
               );
               
               if (success) {
                 if (mounted) {
                   Navigator.of(context).pop();
                   scaffoldMessenger.showSnackBar(
                     const SnackBar(
                       content: Text('Bid updated successfully!'),
                     ),
                   );
                 }
               } else {
                 if (mounted) {
                   scaffoldMessenger.showSnackBar(
                     SnackBar(
                       content: Text(cropProvider.error ?? 'Failed to update bid'),
                     ),
                   );
                 }
               }
             },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Update Bid'),
          ),
        ],
      ),
    );
  }

  void _showBiddingHistoryDialog(CropModel crop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bidding History - ${crop.cropName}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: crop.bids.length,
            itemBuilder: (context, index) {
              final bid = crop.bids[index];
              final isHighest = crop.highestBid?.id == bid.id;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isHighest ? Colors.green : Colors.blue,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  bid.distributorName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('₹${bid.amount} • ${_formatDateTime(bid.createdAt)}'),
                trailing: isHighest 
                  ? const Icon(Icons.emoji_events, color: Colors.amber)
                  : null,
              );
            },
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

  void _placeOrder(CropModel crop) async {
    // Store ScaffoldMessenger reference early
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Create order with a temporary location (will be updated after payment)
      final order = await cropProvider.placeOrder(
        crop.id, 
        authProvider.userProfile?.uid ?? '',
        'To be updated after payment' // Temporary location
      );
      
      if (order != null && mounted) {
        try {
          // Create payment intent for the order
          final paymentService = PaymentService();
          final orderWithPayment = await paymentService.createOrderWithPayment(order);
          
          // Check if still mounted before navigating
          if (mounted) {
            // Navigate to payment screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PaymentScreen(order: orderWithPayment),
              ),
            );
          }
        } catch (e) {
          // Check if still mounted before showing snackbar
          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('Failed to create payment: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else if (mounted) {
        // Check if still mounted before showing snackbar
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(cropProvider.error ?? 'Failed to place order'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
