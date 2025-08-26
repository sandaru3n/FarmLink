import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';

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
      appBar: AppBar(
        title: const Text('Crop Marketplace'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatDuration(timeLeft),
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
                  ),
                const SizedBox(height: 16),

                // Bid Button
                SizedBox(
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
              final bidAmount = double.tryParse(bidController.text);
              if (bidAmount == null || bidAmount < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bid placed successfully!'),
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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
}
