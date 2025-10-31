import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/order/presentation/providers/driver_location_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_tracking_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/driver_info_card.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/live_tracking_map.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/order_status_timeline.dart';
import 'package:food_delivery_app/shared/models/order.dart';

/// Unified order tracking screen that supports both basic and advanced tracking
class UnifiedOrderTrackingScreen extends ConsumerStatefulWidget {
  final String? orderId;
  final Order? order;
  final String? deliveryAddress;
  final LatLng? deliveryLatLng;

  const UnifiedOrderTrackingScreen({
    Key? key,
    this.orderId,
    this.order,
    this.deliveryAddress,
    this.deliveryLatLng,
  }) : super(key: key);

  @override
  ConsumerState<UnifiedOrderTrackingScreen> createState() =>
      _UnifiedOrderTrackingScreenState();
}

class _UnifiedOrderTrackingScreenState
    extends ConsumerState<UnifiedOrderTrackingScreen>
    with WidgetsBindingObserver {
  Order? _order;
  String? _loadError;
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasNetworkError = false;
  Timer? _refreshTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeTracking();
    _setupConnectivityListener();

    // Set up periodic refresh for real-time updates (only when app is in foreground)
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setupPeriodicRefresh();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _refreshTimer?.cancel();
        _refreshTimer = null;
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> _initializeTracking() async {
    // Determine the order and begin tracking
    _order = widget.order;
    final orderId = widget.order?.id ?? widget.orderId;

    if (orderId != null && orderId.isNotEmpty) {
      if (_order == null) {
        await _loadOrderById(orderId);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _loadError = 'No order ID provided';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadOrderById(String id) async {
    try {
      final authState = ref.read(authStateProvider);
      final orderProvider = ref.read(orderTrackingProvider(id).notifier);

      setState(() {
        _loadError = null;
      });

      // Load order details
      await orderProvider.loadOrderDetails(id);

      if (!mounted) return;

      final orderState = ref.read(orderTrackingProvider(id));
      if (orderState.error != null) {
        setState(() {
          _loadError = orderState.error!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _order = orderState.order;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to load order', error: e);
      if (mounted) {
        setState(() {
          _loadError = 'Failed to load order. Please check your connection and try again.';
          _isLoading = false;
        });
      }
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      setState(() {
        _hasNetworkError = !hasConnection;
        if (hasConnection && _order != null) {
          // Network restored, refresh data
          _refreshOrderData(showLoading: false);
        }
      });
    });
  }

  void _setupPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_order != null && !_hasNetworkError) {
        _refreshOrderData(showLoading: false);
      }
    });
  }

  Future<void> _refreshOrderData({bool showLoading = true}) async {
    if (_order == null || widget.orderId == null || _isRefreshing) return;

    try {
      if (showLoading) {
        setState(() {
          _isRefreshing = true;
        });
      }

      final orderProvider = ref.read(orderTrackingProvider(widget.orderId!).notifier);
      await orderProvider.refreshOrderData();

      AppLogger.info('Order data refreshed successfully for order: ${widget.orderId}');
    } catch (e) {
      AppLogger.error('Failed to refresh order data', error: e);
      if (mounted) {
        setState(() {
          _loadError = 'Failed to update order status. Please check your connection.';
        });
      }
    } finally {
      if (showLoading) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _retryLoading() async {
    setState(() {
      _loadError = null;
      _hasNetworkError = false;
      _isLoading = true;
    });

    await _initializeTracking();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return _buildLoadError(context);
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(
          child: Text('Order not found'),
        ),
      );
    }

    // Use enhanced tracking if we have the required data
    final hasAdvancedTracking = widget.deliveryAddress != null && widget.deliveryLatLng != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: true,
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshOrderData,
            ),
        ],
      ),
      body: _hasNetworkError
          ? _buildNetworkError()
          : (hasAdvancedTracking
              ? _buildEnhancedTracking()
              : _buildBasicTracking()),
    );
  }

  Widget _buildNetworkError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Icon(
                Icons.wifi_off,
                size: 48,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Internet Connection',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _retryLoading,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRefreshing ? 'Retrying...' : 'Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _loadError ?? 'An error occurred',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      final id = widget.order?.id ?? widget.orderId;
                      if (id != null) {
                        _loadOrderById(id);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicTracking() {
    return RefreshIndicator(
      onRefresh: _refreshOrderData,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderHeader(),
              const SizedBox(height: 16),
              _buildBasicMap(),
              const SizedBox(height: 16),
              _buildBasicProgress(),
              const SizedBox(height: 24),
              _buildRestaurantInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedTracking() {
    final orderId = _order!.id;
    final orderState = ref.watch(orderTrackingProvider(orderId));

    if (orderState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderState.error != null) {
      return _buildLoadError(context);
    }

    return RefreshIndicator(
      onRefresh: _refreshOrderData,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderHeader(),
            _buildEnhancedMap(orderState),
            _buildETABanner(orderState),
            _buildDriverInfo(orderState),
            const SizedBox(height: 16),
            OrderStatusTimeline(
              currentStatus: orderState.status,
              statusHistory: orderState.statusHistory,
            ),
            _buildDeliveryAddress(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${_order!.id.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  'R${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    Color backgroundColor;
    Color textColor;

    switch (_order!.status.name.toLowerCase()) {
      case 'placed':
      case 'confirmed':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case 'preparing':
      case 'ready':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case 'picked_up':
      case 'on_the_way':
      case 'nearby':
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[900]!;
        break;
      case 'delivered':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case 'cancelled':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
      default:
        backgroundColor = Colors.grey[100]!;
        textColor = Colors.grey[900]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _order!.status.name,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBasicMap() {
    return Card(
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text('Basic order tracking'),
              Text('Enhanced tracking available with delivery address'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getBasicProgress(),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
            ),
            const SizedBox(height: 8),
            Text(
              _getBasicProgressText(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMap(OrderTrackingState orderState) {
    // Check if driver is assigned and order is in delivery
    final showDriverTracking = orderState.driverId != null &&
        (orderState.status.name == 'picked_up' ||
            orderState.status.name == 'on_the_way' ||
            orderState.status.name == 'nearby');

    if (!showDriverTracking || orderState.driverId == null) {
      return _buildBasicMap();
    }

    final driverLocationState = ref.watch(
      driverLocationProvider(
        DriverLocationParams(
          destinationLocation: widget.deliveryLatLng!,
          driverId: orderState.driverId!,
        ),
      ),
    );

    if (driverLocationState.currentLocation == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading driver location...'),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LiveTrackingMap(
        driverLocation: driverLocationState.currentLocation!,
        destinationLocation: widget.deliveryLatLng!,
        driverHeading: driverLocationState.heading,
      ),
    );
  }

  Widget _buildETABanner(OrderTrackingState orderState) {
    if (orderState.estimatedDeliveryTime == null) {
      return const SizedBox.shrink();
    }

    final eta = orderState.estimatedDeliveryTime!;
    final now = DateTime.now();
    final difference = eta.difference(now);
    final minutes = difference.inMinutes;

    Color bannerColor;
    String message;

    if (minutes <= 5) {
      bannerColor = Colors.green;
      message = 'Arriving very soon!';
    } else if (minutes <= 15) {
      bannerColor = Colors.orange;
      message = 'Almost there!';
    } else {
      bannerColor = Colors.blue;
      message = 'On the way';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bannerColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Estimated arrival: ${DateFormat('h:mm a').format(eta)} ($minutes min)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfo(OrderTrackingState orderState) {
    if (orderState.driverId == null ||
        orderState.driverName == null ||
        orderState.vehicleType == null ||
        orderState.vehicleNumber == null) {
      return const SizedBox.shrink();
    }

    // Get distance from driver location provider if available
    double? distanceAway;
    if (widget.deliveryLatLng != null) {
      final driverLocationState = ref.watch(
        driverLocationProvider(
          DriverLocationParams(
            destinationLocation: widget.deliveryLatLng!,
            driverId: orderState.driverId!,
          ),
        ),
      );
      distanceAway = driverLocationState.distanceToDestination;
    }

    return DriverInfoCard(
      driverName: orderState.driverName!,
      vehicleType: orderState.vehicleType!,
      vehicleNumber: orderState.vehicleNumber!,
      driverRating: orderState.driverRating,
      driverPhone: orderState.driverPhone,
      distanceAway: distanceAway,
    );
  }

  Widget _buildDeliveryAddress() {
    if (widget.deliveryAddress == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.deliveryAddress!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'From',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade300,
                  ),
                  child: const Icon(Icons.restaurant, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _order!.restaurantName ?? 'Restaurant',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text('4.5', style: TextStyle(fontSize: 14)),
                        ],
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

  double _getBasicProgress() {
    switch (_order!.status.name.toLowerCase()) {
      case 'placed':
        return 0.2;
      case 'confirmed':
        return 0.3;
      case 'preparing':
        return 0.5;
      case 'ready':
        return 0.6;
      case 'picked_up':
        return 0.7;
      case 'on_the_way':
        return 0.85;
      case 'delivered':
        return 1.0;
      default:
        return 0.1;
    }
  }

  String _getBasicProgressText() {
    switch (_order!.status.name.toLowerCase()) {
      case 'placed':
        return 'Order placed';
      case 'confirmed':
        return 'Order confirmed';
      case 'preparing':
        return 'Preparing your order';
      case 'ready':
        return 'Order ready, waiting for driver';
      case 'picked_up':
        return 'Driver picked up order';
      case 'on_the_way':
        return 'Driver is on the way';
      case 'delivered':
        return 'Delivered!';
      default:
        return 'Processing order';
    }
  }
}