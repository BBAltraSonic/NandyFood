import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/notification_service.dart';

void main() {
  group('Deep Link Verification Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
    });

    test('validates order tracking payloads correctly', () {
      // Valid order payloads
      expect(notificationService.isValidDeepLinkPayload('order:123'), isTrue);
      expect(notificationService.isValidDeepLinkPayload('order:abc123'), isTrue);
      expect(notificationService.isValidDeepLinkPayload('order:test-order-1'), isTrue);

      // Invalid order payloads
      expect(notificationService.isValidDeepLinkPayload('order:'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('order:123#'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('order:order:123'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('order:123@'), isFalse);
    });

    test('validates restaurant payloads correctly', () {
      // Valid restaurant payloads
      expect(notificationService.isValidDeepLinkPayload('restaurant:123'), isTrue);
      expect(notificationService.isValidDeepLinkPayload('restaurant:rest-abc'), isTrue);

      // Invalid restaurant payloads
      expect(notificationService.isValidDeepLinkPayload('restaurant:'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('restaurant:123#'), isFalse);
    });

    test('validates promotion payloads correctly', () {
      // Valid promotion payloads
      expect(notificationService.isValidDeepLinkPayload('promotion:123'), isTrue);
      expect(notificationService.isValidDeepLinkPayload('promotion:sale-abc'), isTrue);

      // Invalid promotion payloads
      expect(notificationService.isValidDeepLinkPayload('promotion:'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('promotion:123#'), isFalse);
    });

    test('validates simple payloads correctly', () {
      // Valid simple payloads
      expect(notificationService.isValidDeepLinkPayload('profile'), isTrue);
      expect(notificationService.isValidDeepLinkPayload('orders'), isTrue);

      // Invalid simple payloads
      expect(notificationService.isValidDeepLinkPayload(''), isFalse);
      expect(notificationService.isValidDeepLinkPayload('invalid'), isFalse);
      expect(notificationService.isValidDeepLinkPayload(null), isFalse);
    });

    test('extracts route information from order payloads', () {
      final route = notificationService.extractRouteFromPayload('order:123');

      expect(route, isNotNull);
      expect(route!['route'], equals('/order/track/123'));
      expect(route['id'], equals('123'));
      expect(route['type'], equals('order'));
    });

    test('extracts route information from restaurant payloads', () {
      final route = notificationService.extractRouteFromPayload('restaurant:rest456');

      expect(route, isNotNull);
      expect(route!['route'], equals('/restaurant/rest456'));
      expect(route['id'], equals('rest456'));
      expect(route['type'], equals('restaurant'));
    });

    test('extracts route information from promotion payloads', () {
      final route = notificationService.extractRouteFromPayload('promotion:sale789');

      expect(route, isNotNull);
      expect(route!['route'], equals('/promotion/sale789'));
      expect(route['id'], equals('sale789'));
      expect(route['type'], equals('promotion'));
    });

    test('extracts route information from simple payloads', () {
      final profileRoute = notificationService.extractRouteFromPayload('profile');
      expect(profileRoute, isNotNull);
      expect(profileRoute!['route'], equals('/profile'));
      expect(profileRoute['type'], equals('profile'));

      final ordersRoute = notificationService.extractRouteFromPayload('orders');
      expect(ordersRoute, isNotNull);
      expect(ordersRoute!['route'], equals('/orders/history'));
      expect(ordersRoute['type'], equals('orders'));
    });

    test('returns null for invalid payloads', () {
      expect(notificationService.extractRouteFromPayload('invalid'), isNull);
      expect(notificationService.extractRouteFromPayload('order:'), isNull);
      expect(notificationService.extractRouteFromPayload(''), isNull);
      expect(notificationService.extractRouteFromPayload(null), isNull);
    });

    test('handles complex order IDs correctly', () {
      final complexOrderId = 'order:ORDER-123_456-abc';
      expect(notificationService.isValidDeepLinkPayload(complexOrderId), isTrue);

      final route = notificationService.extractRouteFromPayload(complexOrderId);
      expect(route, isNotNull);
      expect(route!['id'], equals('ORDER-123_456-abc'));
      expect(route['route'], equals('/order/track/ORDER-123_456-abc'));
    });

    test('handles edge cases in payload validation', () {
      // Very long payloads
      final longOrderId = 'order:${'a' * 100}';
      expect(notificationService.isValidDeepLinkPayload(longOrderId), isTrue);

      // Mixed case
      expect(notificationService.isValidDeepLinkPayload('Order:123'), isFalse); // Case sensitive

      // Special characters not allowed
      expect(notificationService.isValidDeepLinkPayload('order:123/456'), isFalse);
      expect(notificationService.isValidDeepLinkPayload('order:123?query=test'), isFalse);
    });
  });

  group('Deep Link Integration Tests', () {
    test('order deep link navigation paths are consistent', () {
      const orderId = 'test-order-123';
      const expectedPath = '/order/track/test-order-123';

      final service = NotificationService();
      final route = service.extractRouteFromPayload('order:$orderId');

      expect(route?['route'], equals(expectedPath));
    });

    test('restaurant deep link navigation paths are consistent', () {
      const restaurantId = 'rest-456';
      const expectedPath = '/restaurant/rest-456';

      final service = NotificationService();
      final route = service.extractRouteFromPayload('restaurant:$restaurantId');

      expect(route?['route'], equals(expectedPath));
    });

    test('promotion deep link navigation paths are consistent', () {
      const promotionId = 'promo-789';
      const expectedPath = '/promotion/promo-789';

      final service = NotificationService();
      final route = service.extractRouteFromPayload('promotion:$promotionId');

      expect(route?['route'], equals(expectedPath));
    });
  });
}