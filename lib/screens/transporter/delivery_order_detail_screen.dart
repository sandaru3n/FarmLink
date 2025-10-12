import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/delivery_order_model.dart';
import '../../providers/delivery_order_provider.dart';
import '../../services/directions_service.dart';
import '../../utils/app_localizations.dart';
import 'dart:async';

class DeliveryOrderDetailScreen extends StatefulWidget {
  final DeliveryOrderModel deliveryOrder;

  const DeliveryOrderDetailScreen({
    super.key,
    required this.deliveryOrder,
  });

  @override
  State<DeliveryOrderDetailScreen> createState() => _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState extends State<DeliveryOrderDetailScreen> {
  DirectionsResult? _directionsResult;
  bool _isLoadingDirections = true;

  @override
  void initState() {
    super.initState();
    _loadDirections();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDirections() async {
    print('DEBUG: Loading directions...');
    print('DEBUG: Pickup Lat: ${widget.deliveryOrder.pickupLatitude}');
    print('DEBUG: Pickup Lng: ${widget.deliveryOrder.pickupLongitude}');
    print('DEBUG: Distributor Lat: ${widget.deliveryOrder.distributorLatitude}');
    print('DEBUG: Distributor Lng: ${widget.deliveryOrder.distributorLongitude}');
    
    // Check if we have coordinates
    if (widget.deliveryOrder.pickupLatitude == null ||
        widget.deliveryOrder.pickupLongitude == null ||
        widget.deliveryOrder.distributorLatitude == null ||
        widget.deliveryOrder.distributorLongitude == null) {
      print('DEBUG: Missing coordinates, cannot load directions');
      setState(() {
        _isLoadingDirections = false;
      });
      return;
    }

    final origin = LatLng(
      widget.deliveryOrder.pickupLatitude!,
      widget.deliveryOrder.pickupLongitude!,
    );

    final destination = LatLng(
      widget.deliveryOrder.distributorLatitude!,
      widget.deliveryOrder.distributorLongitude!,
    );
    
    print('DEBUG: Origin: ${origin.latitude}, ${origin.longitude}');
    print('DEBUG: Destination: ${destination.latitude}, ${destination.longitude}');

    // Fetch directions (no map display, only distance calculation)
    final directionsService = DirectionsService();
    print('DEBUG: Calling Directions API...');
    final result = await directionsService.getDirections(
      origin: origin,
      destination: destination,
    );

    if (result != null && mounted) {
      print('DEBUG: Directions API success!');
      print('DEBUG: Distance: ${result.distance}');
      print('DEBUG: Distance in km: ${result.distanceInKm}');
      print('DEBUG: Duration: ${result.duration}');
      print('DEBUG: Polyline points: ${result.polylinePoints.length}');
      
      setState(() {
        _directionsResult = result;
        _isLoadingDirections = false;
      });
    } else {
      print('DEBUG: Directions API failed or returned null');
      setState(() {
        _isLoadingDirections = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Modern Purple Header
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
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
                    Text(
                      l10n.get('view_details'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Details Section (Map section removed)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Pricing Card with LKR 100 per km
                    _buildPricingCard(),
                    
                    // Crop Information
                    _buildCropSection(),
                    
                    // Route Details
                    _buildRouteDetails(),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  


  Widget _buildPricingCard() {
    final l10n = AppLocalizations.of(context);
    // Calculate delivery fee based on real distance: LKR 100 per km
    final double distanceInKm = _directionsResult?.distanceInKm ?? 0;
    final double calculatedDeliveryFee = distanceInKm * 100; // LKR 100 per km
    
    // Use calculated fee if available, otherwise show estimated minimum
    final double deliveryFee = calculatedDeliveryFee > 0 ? calculatedDeliveryFee : 500; // Minimum LKR 500
    
    print('DEBUG: Distance in km: $distanceInKm');
    print('DEBUG: Calculated delivery fee: $calculatedDeliveryFee');
    print('DEBUG: Final delivery fee: $deliveryFee');
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade600,
            Colors.deepPurple.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Uber-style price display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LKR ',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                  height: 2,
                ),
              ),
              Text(
                deliveryFee.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              l10n.get('delivery_fee'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          if (_directionsResult != null) ...[
            const SizedBox(height: 20),
            Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
            const SizedBox(height: 20),
            
            // Distance and Duration
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoPill(
                  icon: Icons.straighten,
                  label: l10n.get('distance'),
                  value: _directionsResult!.distance,
                  color: Colors.white,
                ),
                _buildInfoPill(
                  icon: Icons.access_time,
                  label: 'Duration',
                  value: _directionsResult!.duration,
                  color: Colors.white,
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Price calculation info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'LKR 100 per km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_directionsResult!.distanceInKm.toStringAsFixed(2)} km × 100 = LKR ${calculatedDeliveryFee.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCropSection() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade400,
                        Colors.green.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.agriculture, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  'Crop Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.deliveryOrder.cropImageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.image, color: Colors.grey[600]),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.deliveryOrder.cropName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${AppLocalizations.of(context).get('quantity')}: ${widget.deliveryOrder.quantity} kg',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails() {
    final l10n = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Text(
                  'Route Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Pickup
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).get('pickup'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deliveryOrder.pickupLocation,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deliveryOrder.farmerName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Delivery
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).get('delivery'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deliveryOrder.distributorLocation,
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.deliveryOrder.distributorName,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.deliveryOrder.status == 'accepted') ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade500,
                    Colors.blue.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _markInTransit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.play_circle_filled, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      l10n.get('started_delivery'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (widget.deliveryOrder.status == 'in_transit') ...[
            Container(
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
                    color: Colors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _markDelivered(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      l10n.get('mark_delivered'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Open in Google Maps button
          if (widget.deliveryOrder.pickupLatitude != null &&
              widget.deliveryOrder.pickupLongitude != null &&
              widget.deliveryOrder.distributorLatitude != null &&
              widget.deliveryOrder.distributorLongitude != null) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade500,
                    Colors.deepPurple.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _openInGoogleMaps,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.map, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      l10n.get('get_directions'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Back button
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              side: BorderSide(color: Colors.deepPurple.shade600, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, color: Colors.deepPurple.shade600),
                const SizedBox(width: 8),
                Text(
                  l10n.get('back'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markInTransit() async {
    final l10n = AppLocalizations.of(context);
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    final success = await deliveryOrderProvider.markDeliveryInTransit(widget.deliveryOrder.id);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('started_delivery')),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markDelivered() async {
    final l10n = AppLocalizations.of(context);
    final deliveryOrderProvider = Provider.of<DeliveryOrderProvider>(context, listen: false);
    
    // Calculate delivery fee based on real distance: LKR 100 per km
    final double distanceInKm = _directionsResult?.distanceInKm ?? 0;
    final double calculatedDeliveryFee = distanceInKm * 100; // LKR 100 per km
    
    print('DEBUG _markDelivered: Distance in km: $distanceInKm');
    print('DEBUG _markDelivered: Calculated fee: $calculatedDeliveryFee');
    
    final success = await deliveryOrderProvider.markDeliveryCompleted(
      widget.deliveryOrder.id,
      deliveryFee: calculatedDeliveryFee > 0 ? calculatedDeliveryFee : 500, // Minimum LKR 500
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.get('order_delivered')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.get('failed_update_status')}: ${deliveryOrderProvider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openInGoogleMaps() async {
    if (widget.deliveryOrder.pickupLatitude == null ||
        widget.deliveryOrder.pickupLongitude == null ||
        widget.deliveryOrder.distributorLatitude == null ||
        widget.deliveryOrder.distributorLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final origin = '${widget.deliveryOrder.pickupLatitude},${widget.deliveryOrder.pickupLongitude}';
    final destination = '${widget.deliveryOrder.distributorLatitude},${widget.deliveryOrder.distributorLongitude}';
    
    // Google Maps URL with directions
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';
    
    final Uri uri = Uri.parse(googleMapsUrl);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Google Maps: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}


