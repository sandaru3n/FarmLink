import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/crop_model.dart';
import '../../providers/crop_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_localizations.dart';
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
      _loadCrops();
    });
  }

  void _loadCrops() {
    final cropProvider = Provider.of<CropProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final distributorId = authProvider.userProfile?.uid;
    if (distributorId != null) {
      cropProvider.loadDistributorCrops(distributorId);
    } else {
      cropProvider.loadAllActiveCrops();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.orange.shade700,
                  Colors.orange.shade500,
                  Colors.orange.shade400,
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
                  color: Colors.orange.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.amber.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).get('marketplace'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Consumer<CropProvider>(
              builder: (context, cropProvider, child) {
                if (cropProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (cropProvider.error != null) {
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
                          child: const Icon(Icons.error_outline, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Error: ${cropProvider.error}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade600, Colors.orange.shade800],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              cropProvider.clearError();
                              _loadCrops();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.refresh, color: Colors.white),
                                const SizedBox(width: 8),
                                Text(l10n.get('retry'), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (cropProvider.allActiveCrops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade400, Colors.orange.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.store, size: 64, color: Colors.white),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.get('no_crops_available'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.get('no_active_auctions'),
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
                    _loadCrops();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: cropProvider.allActiveCrops.length,
                    itemBuilder: (context, index) {
                      final crop = cropProvider.allActiveCrops[index];
                      return _buildCropCard(crop);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(CropModel crop) {
    final l10n = AppLocalizations.of(context);
    final timeLeft = crop.timeLeft;
    final highestBid = crop.highestBid;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.uid ?? '';
    final hasUserBid = crop.hasUserBid(currentUserId);
    final userBid = crop.getUserBid(currentUserId);
    final isUserHighestBidder = crop.isUserHighestBidder(currentUserId);
    final isExpired = crop.isExpired || crop.status == 'expired';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isExpired
              ? [
                  Colors.grey.shade100,
                  Colors.grey.shade200.withOpacity(0.5),
                ]
              : [
                  Colors.white,
                  Colors.orange.shade50.withOpacity(0.3),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isExpired ? Colors.red.shade300 : Colors.orange.shade100,
          width: isExpired ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpired 
                ? Colors.red.withOpacity(0.15)
                : Colors.orange.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: isExpired
                ? Colors.red.withOpacity(0.08)
                : Colors.orange.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Image with Expired Overlay
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                    Image.network(
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
                                l10n.get('image_not_available'),
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
                  ],
                ),
              ),
              // Top Right Badge
              if (isExpired)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade800],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cancel_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AUCTION ENDED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
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
                // Crop Name and Time Left
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        crop.cropName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isExpired ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: isExpired
                            ? LinearGradient(
                                colors: [Colors.red.shade600, Colors.red.shade700],
                              )
                            : null,
                        color: isExpired ? null : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isExpired ? [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ] : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isExpired)
                            Icon(
                              Icons.event_busy,
                              color: Colors.white,
                              size: 14,
                            ),
                          if (isExpired) const SizedBox(width: 4),
                          Text(
                            _getStatusText(crop.status, timeLeft),
                            style: TextStyle(
                              color: isExpired ? Colors.white : Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
                        Icons.inventory_2,
                        'Quantity',
                        '${crop.quantity} kg',
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.attach_money,
                        l10n.get('min_bid'),
                        'LKR ${crop.minBidPrice}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                _buildInfoRow(
                  Icons.location_on,
                  l10n.get('pickup_location'),
                  crop.pickupLocation,
                ),
                const SizedBox(height: 8),

                // Current Highest Bid
                if (highestBid != null)
                  _buildInfoRow(
                    Icons.trending_up,
                    l10n.get('current_highest'),
                    'LKR ${highestBid.amount}',
                    valueColor: Colors.green,
                  ),
                const SizedBox(height: 8),

                // User's current bid (if any)
                if (hasUserBid && userBid != null)
                  _buildInfoRow(
                    Icons.person,
                    l10n.get('your_bid'),
                    'LKR ${userBid.amount}',
                    valueColor: isUserHighestBidder ? Colors.green : Colors.blue,
                  ),
                const SizedBox(height: 16),

                // Bidding History Dropdown
                if (crop.bids.isNotEmpty)
                  _buildBiddingHistorySection(crop),
                const SizedBox(height: 16),

                // Action Buttons
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildActionButtons(crop, hasUserBid, isUserHighestBidder),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor, Color? iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 44), // Align with text after icon
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBiddingHistorySection(CropModel crop) {
    final l10n = AppLocalizations.of(context);
    return ExpansionTile(
      title: Row(
        children: [
          const Icon(Icons.history, size: 20),
          const SizedBox(width: 8),
          Text(
            '${l10n.get('bidding_history_count')} (${crop.bids.length} ${l10n.get('bids')})',
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
                 'LKR ${bid.amount} • ${_formatDateTime(bid.createdAt)}',
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
    final l10n = AppLocalizations.of(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.userProfile?.uid ?? '';
    final userBid = crop.getUserBid(currentUserId);

    if (crop.isSold) {
      // Check if current user is the one who won this crop
      final isWinningDistributor = crop.order?.distributorId == currentUserId;
      
      if (isWinningDistributor) {
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
              const Icon(Icons.emoji_events, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                   '${l10n.get('you_won_auction')}: LKR ${crop.order?.finalPrice ?? crop.highestBid?.amount ?? 0}',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Text(
                '${l10n.get('sold_to_bidder')} ${crop.order?.distributorName ?? l10n.get('highest_bidder')}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }
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
              Text(
                l10n.get('no_bids_placed'),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }

      if (isUserHighestBidder) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
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
            onPressed: () => _placeOrder(crop),
            icon: const Icon(Icons.shopping_cart, size: 20),
            label: Text(l10n.get('place_order'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                  '${l10n.get('auction_ended')} ${crop.highestBid?.distributorName ?? l10n.get('highest_bidder')} ${l10n.get('won')}.',
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
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade500, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
        child: ElevatedButton.icon(
          onPressed: () => _showUpdateBidDialog(crop, userBid!),
          icon: const Icon(Icons.edit, size: 18),
          label: Text(l10n.get('update_bid'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showBidDialog(crop),
          icon: const Icon(Icons.gavel, size: 20),
          label: Text(l10n.get('place_bid'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

  String _getStatusText(String status, Duration timeLeft) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'active':
        return _formatDuration(timeLeft);
      case 'expired':
        return 'EXPIRED';
      case 'sold':
        return 'SOLD';
      default:
        return 'UNKNOWN';
    }
  }

  void _showBidDialog(CropModel crop) {
    final l10n = AppLocalizations.of(context);
    final bidController = TextEditingController();
    final highestBid = crop.highestBid;
    final minBid = highestBid != null 
        ? highestBid.amount + 1 
        : crop.minBidPrice;

    bidController.text = minBid.toString();

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
                    child: const Icon(Icons.gavel, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('place_your_bid'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          crop.cropName,
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
              const SizedBox(height: 24),
              
              // Crop Info Cards
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      Icons.inventory_2,
                      'Quantity',
                      '${crop.quantity} kg',
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      Icons.attach_money,
                      l10n.get('min_bid'),
                      'LKR ${crop.minBidPrice}',
                      Colors.green,
                    ),
                  ),
                ],
              ),
              
              if (highestBid != null) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  Icons.trending_up,
                  'Current Highest',
                  'LKR ${highestBid.amount}',
                  Colors.purple,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // Bid Input
              Text(
                l10n.get('your_bid_amount'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: l10n.get('enter_amount_lkr'),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LKR',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
                        onPressed: () async {
                          // Store ScaffoldMessenger reference early
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          final bidAmount = double.tryParse(bidController.text);
                          if (bidAmount == null || bidAmount < minBid) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${l10n.get('bid_must_be_at_least')} LKR ${minBid}'),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                SnackBar(
                                  content: Text(l10n.get('bid_placed_success')),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(cropProvider.error ?? l10n.get('failed_place_bid')),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.get('place_bid'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateBidDialog(CropModel crop, BidModel currentBid) {
    final l10n = AppLocalizations.of(context);
    final bidController = TextEditingController();
    final highestBid = crop.highestBid;
    final minBid = highestBid != null && highestBid.distributorId != currentBid.distributorId
        ? highestBid.amount + 1 
        : currentBid.amount + 1;

    bidController.text = minBid.toString();

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
                    child: const Icon(Icons.edit, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.get('update_your_bid'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          crop.cropName,
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
              const SizedBox(height: 24),
              
              // Current Bid Info Card - Wide Rectangle
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.2), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.person, color: Colors.blue, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.get('your_current_bid'),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LKR ${currentBid.amount}',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              if (highestBid != null && highestBid.distributorId != currentBid.distributorId) ...[
                const SizedBox(height: 12),
                _buildInfoCard(
                  Icons.trending_up,
                  'Current Highest',
                  'LKR ${highestBid.amount}',
                  Colors.purple,
                ),
              ],
              
              const SizedBox(height: 24),
              
              // New Bid Input
              Text(
                'New Bid Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300, width: 2),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: bidController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: l10n.get('enter_new_amount'),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LKR',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
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
                        onPressed: () async {
                          // Store ScaffoldMessenger reference early
                          final scaffoldMessenger = ScaffoldMessenger.of(context);
                          
                          final bidAmount = double.tryParse(bidController.text);
                          if (bidAmount == null || bidAmount <= currentBid.amount) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('${l10n.get('new_bid_must_be_higher')} LKR ${currentBid.amount}'),
                                backgroundColor: Colors.red.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                SnackBar(
                                  content: Text(l10n.get('bid_updated_success')),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          } else {
                            if (mounted) {
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(cropProvider.error ?? l10n.get('failed_update_bid')),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          l10n.get('update_bid'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBiddingHistoryDialog(CropModel crop) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${l10n.get('bidding_history_count')} - ${crop.cropName}'),
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
                 subtitle: Text('LKR ${bid.amount} • ${_formatDateTime(bid.createdAt)}'),
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
            child: Text(l10n.get('close')),
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
          
          // Refresh the crop list to show the updated status
          final distributorId = authProvider.userProfile?.uid;
          if (distributorId != null) {
            cropProvider.loadDistributorCrops(distributorId);
          }
          
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
