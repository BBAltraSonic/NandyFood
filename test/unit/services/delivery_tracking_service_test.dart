import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/delivery_tracking_service.dart';
import 'package:food_delivery_app/shared/models/delivery.dart';

void main() {
  group('DeliveryTrackingService', () {
    late DeliveryTrackingService deliveryService;

    setUp(() {
      deliveryService = DeliveryTrackingService();
    });

    test('getDeliveryStatus should return a Delivery object', () async {
      final result = await deliveryService.getDeliveryStatus('order123');
      
      expect(result, isA<Delivery>());
      expect(result.orderId, 'order123');
    });

    test('getDriverInfo should return a Map with driver information', () async {
      final result = await deliveryService.getDriverInfo('order123');
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result['id'], isA<String>());
      expect(result['name'], isA<String>());
    });

    test('getEstimatedArrivalTime should return a DateTime or null', () async {
      final result = await deliveryService.getEstimatedArrivalTime('order123');
      
      // Result can be DateTime or null
      expect(result, anyOf(isA<DateTime>(), isNull));
    });

    test('getDeliveryProgress should return an integer percentage', () async {
      final result = await deliveryService.getDeliveryProgress('order123');
      
      expect(result, isA<int>());
      expect(result, greaterThanOrEqualTo(0));
      expect(result, lessThanOrEqualTo(100));
    });

    test('startTrackingDelivery should begin tracking without error', () {
      expect(() => deliveryService.startTrackingDelivery('order123'), 
             returnsNormally);
    });

    test('stopTrackingDelivery should stop tracking without error', () {
      deliveryService.startTrackingDelivery('order123');
      expect(() => deliveryService.stopTrackingDelivery(), 
             returnsNormally);
    });

    test('getDeliveryStream should return a Stream', () {
      deliveryService.startTrackingDelivery('order123');
      final stream = deliveryService.getDeliveryStream('order123');
      
      expect(stream, isA<Stream<Delivery>>());
    });
  });
}