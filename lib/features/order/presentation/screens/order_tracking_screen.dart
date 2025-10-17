import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/delivery_tracking_service.dart';
import 'package:food_delivery_app/shared/models/delivery.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/delivery_tracking_widget.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final Order? order;
  final String? orderId;

  const OrderTrackingScreen({Key? key, this.order, this.orderId}) : super(key: key);

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  late DeliveryTrackingService _deliveryService;
  Stream<Delivery>? _deliveryStream;
  Delivery? _currentDelivery;

  @override
  void initState() {
    super.initState();
    _deliveryService = DeliveryTrackingService();

    // Start tracking the delivery
    final id = widget.order?.id ?? widget.orderId;
    if (id != null) {
      _deliveryService.startTrackingDelivery(id);
      _deliveryStream = _deliveryService.getDeliveryStream(id);

      _deliveryService.getDeliveryStatus(id).then((delivery) {
        if (mounted) {
          setState(() {
            _currentDelivery = delivery;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _deliveryService.stopTrackingDelivery();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Order'), centerTitle: true),
      body: (widget.order == null && widget.orderId == null)
          ? const Center(child: Text('No order to track'))
          : _buildOrderTrackingContent(context),
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
                          widget.order!.id,
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
                          '\$${widget.order!.totalAmount.toStringAsFixed(2)}',
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

            // Delivery progress
            if (_currentDelivery != null)
              DeliveryTrackingWidget(
                delivery: _currentDelivery!,
                progress: _deliveryService.getDeliveryProgress(
                  widget.order!.id,
                ),
              )
            else
              const Center(child: LoadingIndicator()),

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
    final driverInfo = _deliveryService.getDriverInfo(widget.order!.id);

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
                  child: const Icon(Icons.person, size: 30, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverInfo['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            driverInfo['rating'].toString(),
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
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          const Text('4.5', style: TextStyle(fontSize: 14)),
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
