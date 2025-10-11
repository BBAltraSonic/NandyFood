import 'dart:async';
import 'package:food_delivery_app/shared/models/delivery.dart';
import 'package:food_delivery_app/shared/models/order.dart';

class DeliveryTrackingService {
  static final DeliveryTrackingService _instance =
      DeliveryTrackingService._internal();
  factory DeliveryTrackingService() => _instance;
  DeliveryTrackingService._internal();

  StreamController<Delivery>? _deliveryStreamController;
  Timer? _deliveryUpdateTimer;

  /// Start tracking a delivery
  void startTrackingDelivery(String orderId) {
    // In a real app, this would connect to a real-time service
    // For this mock implementation, we'll simulate delivery updates

    _deliveryStreamController = StreamController<Delivery>();

    // Simulate delivery updates at intervals
    _deliveryUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _simulateDeliveryUpdate(orderId);
    });
  }

  /// Get the delivery updates stream
  Stream<Delivery>? getDeliveryStream(String orderId) {
    return _deliveryStreamController?.stream;
  }

  /// Stop tracking delivery
  void stopTrackingDelivery() {
    _deliveryUpdateTimer?.cancel();
    _deliveryStreamController?.close();
    _deliveryUpdateTimer = null;
    _deliveryStreamController = null;
  }

  /// Simulate delivery updates
  void _simulateDeliveryUpdate(String orderId) {
    // In a real implementation, this would fetch real-time delivery data
    // For the mock, we'll simulate progression through delivery states

    final mockDelivery = Delivery(
      id: 'del_$orderId',
      orderId: orderId,
      driverId: 'driver_123',
      estimatedArrival: DateTime.now().add(const Duration(minutes: 20)),
      actualArrival: null,
      currentLocation: {
        'lat': -33.8688 + (DateTime.now().millisecond % 100) * 0.001,
        'lng': 151.2093 + (DateTime.now().millisecond % 100) * 0.001,
      },
      status: _getNextDeliveryStatus(orderId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _deliveryStreamController?.add(mockDelivery);
  }

  /// Get the next delivery status based on the current state
  DeliveryStatus _getNextDeliveryStatus(String orderId) {
    // For simplicity, we'll cycle through statuses
    // In a real app, this would be determined by the actual delivery state
    final currentTime = DateTime.now().millisecond;
    final statusIndex = (currentTime ~/ 3000) % 4; // Cycle every 3 seconds

    switch (statusIndex) {
      case 0:
        return DeliveryStatus.assigned;
      case 1:
        return DeliveryStatus.pickedUp;
      case 2:
        return DeliveryStatus.inTransit;
      case 3:
        return DeliveryStatus.delivered;
      default:
        return DeliveryStatus.assigned;
    }
  }

  /// Get current delivery status for an order
  Future<Delivery> getDeliveryStatus(String orderId) async {
    // In a real app, this would fetch from the backend
    // For the mock, we'll return a simulated delivery object
    return Delivery(
      id: 'del_$orderId',
      orderId: orderId,
      driverId: 'driver_123',
      estimatedArrival: DateTime.now().add(const Duration(minutes: 20)),
      actualArrival: null,
      currentLocation: {
        'lat': -33.8688 + (DateTime.now().millisecond % 100) * 0.001,
        'lng': 151.2093 + (DateTime.now().millisecond % 100) * 0.001,
      },
      status: DeliveryStatus.inTransit,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Get delivery driver information
  Map<String, dynamic> getDriverInfo(String orderId) {
    return {
      'id': 'driver_123',
      'name': 'John Driver',
      'phone': '+1234567890',
      'vehicle': 'Toyota Camry',
      'vehiclePlate': 'ABC-123',
      'rating': 4.8,
      'photoUrl': 'https://example.com/driver-photo.jpg',
    };
  }

  /// Get estimated arrival time
  DateTime getEstimatedArrivalTime(String orderId) {
    return DateTime.now().add(const Duration(minutes: 20));
  }

  /// Get delivery progress percentage
  int getDeliveryProgress(String orderId) {
    // Calculate progress based on elapsed time
    final elapsed = DateTime.now().minute % 30; // Mock elapsed time
    final progress = (elapsed / 30 * 10).round();
    return progress > 100 ? 100 : progress;
  }
}
