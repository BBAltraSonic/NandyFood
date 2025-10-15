import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../providers/driver_location_provider.dart';
import '../providers/order_tracking_provider.dart';
import '../widgets/driver_info_card.dart';
import '../widgets/live_tracking_map.dart';
import '../widgets/order_status_timeline.dart';

/// Enhanced order tracking screen with live driver location
class EnhancedOrderTrackingScreen extends ConsumerWidget {
  const EnhancedOrderTrackingScreen({
    required this.orderId,
    required this.deliveryAddress,
    required this.deliveryLatLng,
    super.key,
  });

  final String orderId;
  final String deliveryAddress;
  final LatLng deliveryLatLng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(orderTrackingProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: true,
        elevation: 0,
      ),
      body: orderState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderState.error != null
              ? _buildErrorState(context, orderState.error!)
              : _buildTrackingContent(context, ref, orderState),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent(
    BuildContext context,
    WidgetRef ref,
    OrderTrackingState orderState,
  ) {
    // Check if driver is assigned and order is in delivery
    final showDriverTracking = orderState.driverId != null &&
        (orderState.status == OrderStatus.pickedUp ||
            orderState.status == OrderStatus.onTheWay ||
            orderState.status == OrderStatus.nearby);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header card
          _buildOrderHeader(context, orderState),

          // Live map tracking (only when driver is on the way)
          if (showDriverTracking && orderState.driverId != null)
            _buildLiveMap(context, ref, orderState.driverId!),

          // ETA Banner
          if (showDriverTracking && orderState.estimatedDeliveryTime != null)
            _buildETABanner(context, orderState.estimatedDeliveryTime!),

          // Driver info card (only when driver is assigned)
          if (orderState.driverId != null)
            _buildDriverInfo(context, ref, orderState),

          // Order status timeline
          const SizedBox(height: 16),
          OrderStatusTimeline(
            currentStatus: orderState.status,
            statusHistory: orderState.statusHistory,
          ),

          // Delivery address
          _buildDeliveryAddress(context),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, OrderTrackingState state) {
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
                  'Order #${orderId.substring(0, 8)}...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusChip(context, state.status),
              ],
            ),
            if (state.lastUpdated != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Last updated: ${_formatTime(state.lastUpdated!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, OrderStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[900]!;
        break;
      case OrderStatus.preparing:
      case OrderStatus.ready:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        break;
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
      case OrderStatus.nearby:
        backgroundColor = Colors.purple[100]!;
        textColor = Colors.purple[900]!;
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLiveMap(
    BuildContext context,
    WidgetRef ref,
    String driverId,
  ) {
    final driverLocationState = ref.watch(
      driverLocationProvider(
        DriverLocationParams(
          destinationLocation: deliveryLatLng,
          driverId: driverId,
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
        destinationLocation: deliveryLatLng,
        driverHeading: driverLocationState.heading,
      ),
    );
  }

  Widget _buildETABanner(BuildContext context, DateTime eta) {
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
          const Icon(
            Icons.schedule,
            color: Colors.white,
            size: 32,
          ),
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

  Widget _buildDriverInfo(
    BuildContext context,
    WidgetRef ref,
    OrderTrackingState orderState,
  ) {
    if (orderState.driverName == null ||
        orderState.vehicleType == null ||
        orderState.vehicleNumber == null) {
      return const SizedBox.shrink();
    }

    // Get distance from driver location provider if available
    double? distanceAway;
    if (orderState.driverId != null) {
      final driverLocationState = ref.watch(
        driverLocationProvider(
          DriverLocationParams(
            destinationLocation: deliveryLatLng,
            driverId: orderState.driverId,
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

  Widget _buildDeliveryAddress(BuildContext context) {
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
              deliveryAddress,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}
