import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/delivery_tracking_service.dart';
import 'package:food_delivery_app/shared/models/delivery.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/widgets/delivery_tracking_map_widget.dart';


class OrderTrackingScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.order, this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  late DeliveryTrackingService _deliveryService;
  Stream<Delivery>? _deliveryStream;
  StreamSubscription<Delivery>? _deliverySub;
  Order? _order;
  String? _loadError;

  Delivery? _currentDelivery;

  @override
  void initState() {
    super.initState();
    _deliveryService = DeliveryTrackingService();

    // Determine the order and begin tracking
    _order = widget.order;
    final orderId = widget.order?.id ?? widget.orderId;

    if (orderId != null && orderId.isNotEmpty) {
      _deliveryService.startTrackingDelivery(orderId);
      _deliveryStream = _deliveryService.getDeliveryStream(orderId);

      // Listen to the delivery stream for real-time updates
      _deliverySub = _deliveryStream?.listen((delivery) {
        if (!mounted) return;
        setState(() {
          _currentDelivery = delivery;
        });
      });

      // Get initial delivery status
      _deliveryService.getDeliveryStatus(orderId).then((delivery) {
        if (!mounted) return;
        setState(() {
          _currentDelivery = delivery;
        });
      });

      // If only an ID was provided, fetch the full order details
      if (_order == null) {
        _loadOrderById(orderId);
      }
    }
  }

  Future<void> _loadOrderById(String id) async {
    try {
      setState(() {
        _loadError = null;
      });
      final data = await DatabaseService().getOrder(id);
      if (!mounted) return;
      if (data != null) {
        setState(() {
          _order = Order.fromJson(data);
          _loadError = null;
        });
      } else {
        setState(() {
          _loadError = 'We couldn\'t find this order.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load order. Please check your connection and try again.';
      });
    }
  }


  @override
  void dispose() {
    _deliverySub?.cancel();
    _deliveryService.stopTrackingDelivery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
        centerTitle: true,
      ),
      body: _order == null
          ? (_loadError != null
              ? _buildLoadError(context)
              : const Center(child: CircularProgressIndicator()))
          : _buildOrderTrackingContent(context),
    );
  }

  Widget _buildLoadError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(_loadError ?? 'An error occurred', textAlign: TextAlign.center),
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
    );
  }

  Widget _buildOrderTrackingContent(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order info header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order #',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          _order!.id,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          '\$${_order!.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Status',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          _currentDelivery?.status.name ?? 'Preparing',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(_currentDelivery?.status),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Delivery map
            DeliveryTrackingMapWidget(
              order: _order!,
              delivery: _currentDelivery,
            ),

            const SizedBox(height: 16),

            // Delivery progress
            _buildDeliveryProgress(),

            const SizedBox(height: 24),

            // Driver info
            _buildDriverInfo(),

            const SizedBox(height: 24),

            // Restaurant info
            _buildRestaurantInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfo() {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.value(_deliveryService.getDriverInfo(_order!.id)),
      builder: (context, snapshot) {
        final driverInfo = snapshot.data ?? {};

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Driver',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade300,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driverInfo['name'] ?? 'Driver',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (driverInfo['rating'] ?? 0.0).toString(),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // In a real app, this would initiate a call
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Calling driver...')),
                        );
                      },
                      child: const Icon(Icons.phone),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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
                  child: const Icon(
                    Icons.restaurant,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delicious Bistro',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '4.5',
                            style: TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on,
                            color: Colors.grey,
                            size: 16,
                          ),
                          const Text(
                            '1.2 km away',
                            style: TextStyle(fontSize: 14),
                          ),
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

  Widget _buildDeliveryProgress() {
    return FutureBuilder<int>(
      future: Future.value(_deliveryService.getDeliveryProgress(_order!.id)),
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0;

        // Placeholder for DeliveryTrackingWidget until we create or update it
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                ),
                const SizedBox(height: 8),
                Text(
                  _getProgressText(progress),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getProgressText(int progress) {
    if (progress < 25) {
      return 'Preparing your order';
    } else if (progress < 50) {
      return 'Order ready, waiting for driver';
    } else if (progress < 75) {
      return 'Driver is on the way';
    } else if (progress < 100) {
      return 'Driver is almost there!';
    } else {
      return 'Delivered!';
    }
  }

  Color _getStatusColor(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.assigned:
        return Colors.blue;
      case DeliveryStatus.pickedUp:
        return Colors.orange;
      case DeliveryStatus.inTransit:
        return Colors.deepOrange;
      case DeliveryStatus.delivered:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}