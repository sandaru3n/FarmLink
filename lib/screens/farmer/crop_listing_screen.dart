import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../utils/app_localizations.dart';
import 'add_crop_screen.dart';
import 'edit_crop_screen.dart';

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
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(140),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade600,
                Colors.green.shade700,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.agriculture,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).get('my_crops'),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.green.shade700,
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
                    tabs: const [
                      Tab(text: 'Pending'),
                      Tab(text: 'Active'),
                      Tab(text: 'Expired'),
                      Tab(text: 'All'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
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
              _buildCropList(cropProvider.pendingFarmerCrops, AppLocalizations.of(context).get('no_pending_crops')),
              _buildCropList(cropProvider.activeFarmerCrops, AppLocalizations.of(context).get('no_active_crops')),
              _buildCropList(cropProvider.expiredFarmerCrops, AppLocalizations.of(context).get('no_expired_crops')),
              _buildCropList(cropProvider.farmerCrops, AppLocalizations.of(context).get('no_crops_found')),
            ],
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade500,
              Colors.green.shade700,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddCropScreen(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildCropList(List<CropModel> crops, String emptyMessage) {
    if (crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade100,
                    Colors.green.shade50,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.agriculture,
                size: 64,
                color: Colors.green.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding crops to see them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: crops.length,
        itemBuilder: (context, index) {
          final crop = crops[index];
          return _buildCropCard(crop);
        },
      ),
    );
  }

  Widget _buildCropCard(CropModel crop) {
    final timeLeft = crop.timeLeft;
    final timeUntilStart = crop.timeUntilStart;
    final isExpired = crop.isExpired;
    final isPending = crop.isPending;
    final isActive = crop.isActive;
    final highestBid = crop.highestBid;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Image with overlay gradient
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: Colors.green,
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
              // Gradient overlay at bottom of image
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Name and Status
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crop.cropName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getStatusGradient(crop.status),
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor(crop.status).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(crop.status),
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(crop.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        'Min Bid',
                        'LKR ${crop.minBidPrice}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Location
                _buildInfoRow(
                  Icons.location_on,
                  'Pickup Location',
                  crop.pickupLocation,
                ),
                const SizedBox(height: 10),

                // Time information based on status
                if (isPending) ...[
                  _buildInfoRow(
                    Icons.schedule,
                    'Bidding Starts',
                    _formatDateTime(crop.startDate),
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.access_time,
                    'Time Until Start',
                    _formatDuration(timeUntilStart),
                  ),
                  const SizedBox(height: 10),
                ] else if (isActive && !isExpired) ...[
                  _buildInfoRow(
                    Icons.access_time,
                    'Time Left',
                    _formatDuration(timeLeft),
                  ),
                  const SizedBox(height: 10),
                ],

                // Bidding Info (only for active/expired crops)
                if (!isPending) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          Icons.gavel,
                          'Total Bids',
                          '${crop.bids.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (highestBid != null)
                        Expanded(
                          child: _buildInfoRow(
                            Icons.trending_up,
                            'Highest Bid',
                            'LKR ${highestBid.amount}',
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                _buildActionButtons(crop),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'sold':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'active':
        return 'Active';
      case 'expired':
        return 'Expired';
      case 'sold':
        return 'Sold';
      default:
        return 'Unknown';
    }
  }

  List<Color> _getStatusGradient(String status) {
    switch (status) {
      case 'pending':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'active':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'expired':
        return [Colors.red.shade400, Colors.red.shade600];
      case 'sold':
        return [Colors.purple.shade400, Colors.purple.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'active':
        return Icons.timer;
      case 'expired':
        return Icons.timer_off;
      case 'sold':
        return Icons.check_circle;
      default:
        return Icons.help;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade400,
                  Colors.green.shade600,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey.shade900,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(CropModel crop) {
    if (crop.isPending) {
      // Pending crops can be edited and deleted
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _editCrop(crop),
              icon: const Icon(Icons.edit),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _deleteCrop(crop),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      );
    } else if (crop.isActive) {
      // Active crops can only view bidding history
      return Row(
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
        ],
      );
    } else if (crop.isExpired) {
      // Expired crops can view bidding history and confirm winning distributor
      if (crop.bids.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                'No bids received',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      } else {
        return Column(
          children: [
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
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmWinningDistributor(crop),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (crop.highestBid != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Winner: ${crop.highestBid!.distributorName} - LKR ${crop.highestBid!.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }
    } else {
      // Sold crops - no actions needed
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sold to ${crop.order?.distributorName ?? 'Highest Bidder'}',
              style: const TextStyle(
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _editCrop(CropModel crop) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditCropScreen(crop: crop),
      ),
    );
  }

  void _deleteCrop(CropModel crop) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Crop'),
        content: Text('Are you sure you want to delete "${crop.cropName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final cropProvider = Provider.of<CropProvider>(context, listen: false);
              final success = await cropProvider.deleteCrop(crop.id);
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Crop deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(cropProvider.error ?? 'Failed to delete crop'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showBiddingHistory(CropModel crop) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bidding History - ${crop.cropName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // Bidding Summary
              if (crop.bids.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: Colors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Bidding Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Total Bids: ${crop.bids.length}'),
                          ),
                          if (crop.highestBid != null) ...[
                            Expanded(
                              child: Text(
                                'Highest: LKR ${crop.highestBid!.amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (crop.highestBid != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Winner: ${crop.highestBid!.distributorName}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Bids List
              Expanded(
                child: crop.bids.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.gavel,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No bids received',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: crop.bids.length,
                        itemBuilder: (context, index) {
                          final bid = crop.bids[index];
                          final isHighest = crop.highestBid?.id == bid.id;
                          final isExpired = crop.isExpired;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: isHighest && isExpired ? Colors.green.shade50 : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isHighest && isExpired 
                                    ? Colors.green 
                                    : Colors.green.shade100,
                                child: Text(
                                  'LKR ${bid.amount.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: isHighest && isExpired 
                                        ? Colors.white 
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isHighest && isExpired ? 12 : 14,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(child: Text(bid.distributorName)),
                                  if (isHighest && isExpired) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'WINNER',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bid on ${_formatDate(bid.createdAt)}'),
                                  if (isHighest && isExpired)
                                    Text(
                                      'Ready for confirmation',
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Text(
                                'LKR ${bid.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isHighest && isExpired 
                                      ? Colors.green.shade700 
                                      : null,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // Action button for expired crops with bids
              if (crop.isExpired && crop.bids.isNotEmpty && crop.highestBid != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _confirmWinningDistributor(crop);
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _confirmWinningDistributor(CropModel crop) {
    final highestBid = crop.highestBid;
    if (highestBid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No bids to confirm'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Winning Distributor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to confirm ${highestBid.distributorName} as the winner?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Winner Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Distributor: ${highestBid.distributorName}'),
                  Text('Winning Bid: LKR ${highestBid.amount.toStringAsFixed(0)}'),
                  Text('Crop: ${crop.cropName}'),
                  Text('Quantity: ${crop.quantity} kg'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This action will finalize the sale and create an order for the winning distributor.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
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
              Navigator.of(context).pop();
              await _processWinnerConfirmation(crop, highestBid);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _processWinnerConfirmation(CropModel crop, BidModel winningBid) async {
    final cropProvider = Provider.of<CropProvider>(context, listen: false);
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Create order for the winning distributor
      final orderService = OrderService();
      final order = await orderService.createOrderFromCrop(
        crop: crop,
        distributorId: winningBid.distributorId,
        distributorLocation: '', // Will be filled by distributor
      );

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully confirmed ${winningBid.distributorName} as winner! Order created.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Refresh the crop list
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.userProfile?.uid != null) {
          cropProvider.loadFarmerCrops(authProvider.userProfile!.uid);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm winner: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
