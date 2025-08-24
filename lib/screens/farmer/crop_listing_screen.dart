import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import 'add_crop_screen.dart';

class CropListingScreen extends StatefulWidget {
  const CropListingScreen({super.key});

  @override
  State<CropListingScreen> createState() => _CropListingScreenState();
}

class _CropListingScreenState extends State<CropListingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cropProvider = Provider.of<CropProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.userProfile?.uid != null) {
        cropProvider.loadFarmerCrops(authProvider.userProfile!.uid);
      }
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
        title: const Text('My Crops'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Expired'),
            Tab(text: 'All'),
          ],
        ),
      ),
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
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      if (authProvider.userProfile?.uid != null) {
                        cropProvider.loadFarmerCrops(authProvider.userProfile!.uid);
                      }
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCropList(cropProvider.activeFarmerCrops, 'No active crops'),
              _buildCropList(cropProvider.expiredFarmerCrops, 'No expired crops'),
              _buildCropList(cropProvider.farmerCrops, 'No crops found'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddCropScreen(),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCropList(List<CropModel> crops, String emptyMessage) {
    if (crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.agriculture,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        return _buildCropCard(crop);
      },
    );
  }

  Widget _buildCropCard(CropModel crop) {
    final timeLeft = crop.timeLeft;
    final isExpired = crop.isExpired;
    final highestBid = crop.highestBid;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 64,
                    color: Colors.grey,
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
                // Crop Name and Status
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
                        color: isExpired ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isExpired ? 'Expired' : 'Active',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quantity and Price
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

                // Time Left
                if (!isExpired) ...[
                  _buildInfoRow(
                    Icons.access_time,
                    'Time Left',
                    _formatDuration(timeLeft),
                  ),
                  const SizedBox(height: 8),
                ],

                // Bidding Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.gavel,
                        'Total Bids',
                        '${crop.bids.length}',
                      ),
                    ),
                    if (highestBid != null)
                      Expanded(
                        child: _buildInfoRow(
                          Icons.trending_up,
                          'Highest Bid',
                          '₹${highestBid.amount}',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showBiddingHistory(crop),
                        icon: const Icon(Icons.history),
                        label: const Text('Bid History'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (isExpired && highestBid != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showOrderDialog(crop, highestBid!),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Place Order'),
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

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  void _showBiddingHistory(CropModel crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Bidding History - ${crop.cropName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: crop.bids.isEmpty
                    ? const Center(
                        child: Text('No bids yet'),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: crop.bids.length,
                        itemBuilder: (context, index) {
                          final bid = crop.bids[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  '₹${bid.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(bid.distributorName),
                              subtitle: Text(
                                'Bid on ${_formatDate(bid.createdAt)}',
                              ),
                              trailing: Text(
                                '₹${bid.amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDialog(CropModel crop, BidModel highestBid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Place Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Crop: ${crop.cropName}'),
            Text('Quantity: ${crop.quantity} kg'),
            Text('Winning Bid: ₹${highestBid.amount}'),
            Text('Distributor: ${highestBid.distributorName}'),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to place an order with the highest bidder?',
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
              // Here you would implement the order placement logic
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Order placed successfully!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
