import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../../providers/delivery_order_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transport_order_provider.dart';
import '../../models/delivery_order_model.dart';
import '../../services/directions_service.dart';
import 'delivery_order_detail_screen.dart';
import '../dashboards/transporter/transporter_dashboard.dart';

// Top-level container for resolved coordinates used by geocoding fallback
class _ResolvedCoords {
  final LatLng origin;
  final LatLng destination;
  const _ResolvedCoords({required this.origin, required this.destination});
}

class _CityPair {
  final String startCity;
  final String endCity;
  const _CityPair(this.startCity, this.endCity);
}

class DeliveryOrdersScreen extends StatefulWidget {
  const DeliveryOrdersScreen({super.key});

  @override
  State<DeliveryOrdersScreen> createState() => _DeliveryOrdersScreenState();
}

class _DeliveryOrdersScreenState extends State<DeliveryOrdersScreen> {
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

  // Cache computed road distances in kilometers per delivery order id
  final Map<String, double> _distanceKmCache = {};
  // Cache resolved city names to avoid repeated geocoding
  final Map<String, String> _cityCache = {};

  @override
  void initState() {
    super.initState();
    
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

  // Resolve coordinates if missing by geocoding the textual addresses.
  Future<_ResolvedCoords?> _resolveCoordsIfMissing(DeliveryOrderModel order) async {
    LatLng? origin;
    LatLng? destination;

    if (order.pickupLatitude != null && order.pickupLongitude != null) {
      origin = LatLng(order.pickupLatitude!, order.pickupLongitude!);
    } else if (order.pickupLocation.isNotEmpty) {
      try {
        final results = await geocoding.locationFromAddress(order.pickupLocation);
        if (results.isNotEmpty) {
          origin = LatLng(results.first.latitude, results.first.longitude);
        }
      } catch (_) {}
    }

    if (order.distributorLatitude != null && order.distributorLongitude != null) {
      destination = LatLng(order.distributorLatitude!, order.distributorLongitude!);
    } else if (order.distributorLocation.isNotEmpty) {
      try {
        final results = await geocoding.locationFromAddress(order.distributorLocation);
        if (results.isNotEmpty) {
          destination = LatLng(results.first.latitude, results.first.longitude);
        }
      } catch (_) {}
    }

    if (origin != null && destination != null) {
      return _ResolvedCoords(origin: origin, destination: destination);
    }
    return null;
  }

  // Get or compute road distance in kilometers (cached) using Google Directions
  Future<double?> _getDistanceKm(DeliveryOrderModel order) async {
    // Use order.id as cache key; fallback to order.orderId if needed
    final String cacheKey = order.id.isNotEmpty ? order.id : order.orderId;
    if (_distanceKmCache.containsKey(cacheKey)) {
      return _distanceKmCache[cacheKey];
    }

    LatLng? origin;
    LatLng? destination;

    // Prefer existing coordinates
    if (order.pickupLatitude != null && order.pickupLongitude != null) {
      origin = LatLng(order.pickupLatitude!, order.pickupLongitude!);
    }
    if (order.distributorLatitude != null && order.distributorLongitude != null) {
      destination = LatLng(order.distributorLatitude!, order.distributorLongitude!);
    }

    // If any coordinate missing, try geocoding addresses
    if (origin == null || destination == null) {
      final resolved = await _resolveCoordsIfMissing(order);
      if (resolved != null) {
        origin = resolved.origin;
        destination = resolved.destination;
      }
    }

    if (origin == null || destination == null) {
      return null;
    }

    final result = await DirectionsService().getDirections(
      origin: origin,
      destination: destination,
    );

    if (result == null) {
      return null;
    }

    final double km = result.distanceInKm;
    _distanceKmCache[cacheKey] = km;
    return km;
  }

  // Resolve a human-friendly nearest city using reverse geocoding with caching
  Future<String> _resolveCity({double? lat, double? lng, String? address, required String cacheKey}) async {
    // Return from cache if available
    final String? cached = _cityCache[cacheKey];
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      if (lat != null && lng != null) {
        final placemarks = await geocoding.placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final String city = (p.locality?.trim().isNotEmpty == true)
              ? p.locality!.trim()
              : (p.subAdministrativeArea?.trim().isNotEmpty == true)
                  ? p.subAdministrativeArea!.trim()
                  : (p.administrativeArea?.trim().isNotEmpty == true)
                      ? p.administrativeArea!.trim()
                      : (p.country?.trim().isNotEmpty == true)
                          ? p.country!.trim()
                          : 'Unknown';
          _cityCache[cacheKey] = city;
          return city;
        }
      }

      // If we don't have coordinates, try geocoding address -> coords -> placemark
      if (address != null && address.trim().isNotEmpty) {
        final results = await geocoding.locationFromAddress(address);
        if (results.isNotEmpty) {
          final coords = results.first;
          final placemarks = await geocoding.placemarkFromCoordinates(coords.latitude, coords.longitude);
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            final String city = (p.locality?.trim().isNotEmpty == true)
                ? p.locality!.trim()
                : (p.subAdministrativeArea?.trim().isNotEmpty == true)
                    ? p.subAdministrativeArea!.trim()
                    : (p.administrativeArea?.trim().isNotEmpty == true)
                        ? p.administrativeArea!.trim()
                        : (p.country?.trim().isNotEmpty == true)
                            ? p.country!.trim()
                            : _extractCity(address);
            _cityCache[cacheKey] = city;
            return city;
          }
        }
      }
    } catch (_) {
      // Fall through to string-based extraction
    }

    final String fallback = _extractCity(address ?? '');
    _cityCache[cacheKey] = fallback;
    return fallback;
  }

  Future<_CityPair> _getStartEndCities(DeliveryOrderModel order) async {
    final String idKey = order.id.isNotEmpty ? order.id : order.orderId;
    final String pickupKey = 'pickup:$idKey:${order.pickupLocation}';
    final String dropoffKey = 'dropoff:$idKey:${order.distributorLocation}';

    final Future<String> startFuture = _resolveCity(
      lat: order.pickupLatitude,
      lng: order.pickupLongitude,
      address: order.pickupLocation,
      cacheKey: pickupKey,
    );

    final Future<String> endFuture = _resolveCity(
      lat: order.distributorLatitude,
      lng: order.distributorLongitude,
      address: order.distributorLocation,
      cacheKey: dropoffKey,
    );

    final results = await Future.wait([startFuture, endFuture]);
    return _CityPair(results[0], results[1]);
  }

  String _extractCity(String address) {
    if (address.isEmpty) return 'Unknown';
    final parts = address.split(',');
    final List<String> candidates = parts
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (candidates.isEmpty) return address.trim();
    for (final p in candidates.reversed) {
      if (!p.contains(RegExp(r'\d')) && p.length <= 30) {
        return p;
      }
    }
    return candidates.first;
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
                          'Delivery',
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentTabIndex = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _currentTabIndex == 0 
                                      ? Colors.white 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Available',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _currentTabIndex == 0 
                                        ? Colors.deepPurple.shade700 
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentTabIndex = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _currentTabIndex == 1 
                                      ? Colors.white 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Schedule',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _currentTabIndex == 1 
                                        ? Colors.deepPurple.shade700 
                                        : Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: LiquidPullToRefresh(
              onRefresh: _handleRefresh,
              color: Colors.deepPurple[300]!,
              backgroundColor: Colors.deepPurple[100]!,
              animSpeedFactor: 2,
              showChildOpacityTransition: true,
              child: _currentTabIndex == 0
                  ? _buildAvailableDeliveriesTab()
                  : _buildDeliveryScheduleTab(),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
        child: FloatingActionButton(
          onPressed: () {
            setState(() {
              _currentTabIndex = _currentTabIndex == 0 ? 1 : 0;
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          child: Icon(_currentTabIndex == 0 ? Icons.calendar_today : Icons.list, size: 28),
        ),
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
                  'Error: ${deliveryOrderProvider.error}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      deliveryOrderProvider.clearError();
                      deliveryOrderProvider.loadPendingDeliveryOrders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Retry', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
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
                  child: const Icon(Icons.local_shipping_outlined, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'No available deliveries',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'New delivery orders will appear here',
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
            await deliveryOrderProvider.loadPendingDeliveryOrders();
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
    // Check if we have coordinates for map display
    final hasCoordinates = deliveryOrder.pickupLatitude != null &&
        deliveryOrder.pickupLongitude != null &&
        deliveryOrder.distributorLatitude != null &&
        deliveryOrder.distributorLongitude != null;

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
                builder: (context) => DeliveryOrderDetailScreen(deliveryOrder: deliveryOrder),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map and Details Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 180,
                  child: Row(
                    children: [
                      // Left: Map preview
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade200,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildMapSection(deliveryOrder),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Right: Compact crop details with image
                      Expanded(
                        child: _buildCompactDetails(deliveryOrder),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Details Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uber-Style Price Display
                    _buildPriceDisplay(deliveryOrder, hasCoordinates),
                    
                    const SizedBox(height: 16),
                    Divider(height: 1, color: Colors.grey.shade300),
                    
                    // Action buttons for available deliveries
                    if (isAvailable) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade400, width: 2),
                              ),
                              child: OutlinedButton(
                                onPressed: () => _showRejectDialog(deliveryOrder),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.close, color: Colors.red.shade600, size: 20),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Reject',
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade600, Colors.green.shade800],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => _acceptDelivery(deliveryOrder),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    SizedBox(width: 6),
                                    Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade600, Colors.blue.shade800],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => _markInTransit(deliveryOrder),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.local_shipping, color: Colors.white, size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        'Start Delivery',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ] else if (deliveryOrder.status == 'in_transit') ...[
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.green.shade600, Colors.green.shade800],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.4),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () => _markDelivered(deliveryOrder),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                                      SizedBox(width: 6),
                                      Text(
                                        'Mark Delivered',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactDetails(DeliveryOrderModel deliveryOrder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    deliveryOrder.cropImageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.image, color: Colors.grey, size: 24),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deliveryOrder.cropName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${deliveryOrder.quantity} kg',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Start and End cities row (resolved via reverse geocoding)
        FutureBuilder<_CityPair>(
          future: _getStartEndCities(deliveryOrder),
          builder: (context, snapshot) {
            final bool loading = snapshot.connectionState == ConnectionState.waiting;
            final String startCity = snapshot.hasData ? snapshot.data!.startCity : _extractCity(deliveryOrder.pickupLocation);
            final String endCity = snapshot.hasData ? snapshot.data!.endCity : _extractCity(deliveryOrder.distributorLocation);
            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$startCity → $endCity',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (loading) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 10, 
                      height: 10, 
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const Spacer(),
        Align(
          alignment: Alignment.bottomLeft,
          child: Container(
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
        ),
      ],
    );
  }

  Widget _buildMapPreview(DeliveryOrderModel deliveryOrder) {
    final origin = LatLng(
      deliveryOrder.pickupLatitude!,
      deliveryOrder.pickupLongitude!,
    );
    final destination = LatLng(
      deliveryOrder.distributorLatitude!,
      deliveryOrder.distributorLongitude!,
    );

    return FutureBuilder<DirectionsResult?>(
      future: DirectionsService().getDirections(
        origin: origin,
        destination: destination,
      ),
      builder: (context, snapshot) {
        Set<Polyline> polylines = {};
        
        if (snapshot.hasData && snapshot.data != null) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: snapshot.data!.polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        }

        final bounds = LatLngBounds(
          southwest: LatLng(
            math.min(origin.latitude, destination.latitude),
            math.min(origin.longitude, destination.longitude),
          ),
          northeast: LatLng(
            math.max(origin.latitude, destination.latitude),
            math.max(origin.longitude, destination.longitude),
          ),
        );

        return Container(
          height: 180,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    (origin.latitude + destination.latitude) / 2,
                    (origin.longitude + destination.longitude) / 2,
                  ),
                  zoom: 12,
                ),
                onMapCreated: (c) {
                  c.animateCamera(
                    CameraUpdate.newLatLngBounds(bounds, 40),
                  );
                },
                markers: const {},
                polylines: polylines,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
              ),
              
              // Map overlay with pickup and delivery info
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Pickup info
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                  const Text(
                              'Pickup',
                              style: TextStyle(
                                      color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        Text(
                                    deliveryOrder.farmerName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                          overflow: TextOverflow.ellipsis,
                        ),
                                ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                      // Arrow icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      
                      // Delivery info
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                  const Text(
                              'Delivery',
                              style: TextStyle(
                                      color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                                  Text(
                                    deliveryOrder.distributorName,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Wrapper that either shows map (using known or resolved coords) or placeholder
  Widget _buildMapSection(DeliveryOrderModel deliveryOrder) {
    final hasCoords = deliveryOrder.pickupLatitude != null &&
        deliveryOrder.pickupLongitude != null &&
        deliveryOrder.distributorLatitude != null &&
        deliveryOrder.distributorLongitude != null;

    if (hasCoords) {
      return _buildMapPreview(deliveryOrder);
    }

    // Try to resolve from addresses
    return FutureBuilder<_ResolvedCoords?>(
      future: _resolveCoordsIfMissing(deliveryOrder),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                        Text(
                  'Loading map...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final resolved = snapshot.data!;
          return FutureBuilder<DirectionsResult?>(
            future: DirectionsService().getDirections(
              origin: resolved.origin,
              destination: resolved.destination,
            ),
            builder: (context, dirSnap) {
              final Set<Marker> markers = {
                Marker(
                  markerId: const MarkerId('pickup'),
                  position: resolved.origin,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                ),
                Marker(
                  markerId: const MarkerId('delivery'),
                  position: resolved.destination,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                ),
              };

              final Set<Polyline> polylines = {};
              if (dirSnap.hasData && dirSnap.data != null) {
                polylines.add(Polyline(
                  polylineId: const PolylineId('route'),
                  points: dirSnap.data!.polylinePoints,
                  color: Colors.blue,
                  width: 5,
                ));
              }

              final bounds = LatLngBounds(
                southwest: LatLng(
                  math.min(resolved.origin.latitude, resolved.destination.latitude),
                  math.min(resolved.origin.longitude, resolved.destination.longitude),
                ),
                northeast: LatLng(
                  math.max(resolved.origin.latitude, resolved.destination.latitude),
                  math.max(resolved.origin.longitude, resolved.destination.longitude),
                ),
              );

              return Container(
                height: 180,
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          (resolved.origin.latitude + resolved.destination.latitude) / 2,
                          (resolved.origin.longitude + resolved.destination.longitude) / 2,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (c) {
                        c.animateCamera(CameraUpdate.newLatLngBounds(bounds, 40));
                      },
                      markers: const {},
                      polylines: polylines,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: true,
                      zoomGesturesEnabled: true,
                      tiltGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                    ),
                    // Overlay removed
                  ],
                ),
              );
            },
          );
        }

        // If we couldn't resolve, show placeholder with correct names
        return _buildNoMapPlaceholder();
      },
    );
  }

  Widget _buildNoMapPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 48, color: Colors.grey[600]),
                const SizedBox(height: 8),
                Text(
                  'Map not available',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location coordinates needed',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
          ),
          
          // Placeholder pickup and delivery info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
              ),
              child: Row(
                  children: [
                  // Pickup placeholder
                    Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                        child: Text(
                            'Pickup location not set',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_forward,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                  ),
                  
                  // Delivery placeholder
                    Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Delivery location not set',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
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
        ],
      ),
    );
  }

  Widget _buildPriceDisplay(DeliveryOrderModel deliveryOrder, bool hasCoordinates) {
    return FutureBuilder<double?>(
      future: _getDistanceKm(deliveryOrder),
      builder: (context, snapshot) {
        final double? distanceKm = snapshot.data;
        final double displayPrice = distanceKm != null
            ? (distanceKm * 100) // price per km = 100
            : deliveryOrder.price;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Uber-style price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                Text(
                  'LKR ${displayPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Delivery Fee',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            if (distanceKm != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.straighten, size: 14, color: Colors.green[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${distanceKm.toStringAsFixed(1)} km • LKR 100/km',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ],
          ),
        ),
            ] else if (snapshot.connectionState == ConnectionState.waiting) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Calculating distance...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
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