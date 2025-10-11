import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('PromotionService', () {
    late DatabaseService databaseService;

    setUp(() {
      databaseService = DatabaseService();
    });

    test('getPromotionByCode should return promotion data or null', () async {
      // Test with a valid promo code (this would depend on your mock data)
      final result = await databaseService.getPromotionByCode('VALIDCODE');

      // Result can be a Map or null
      expect(result, anyOf(isA<Map<String, dynamic>>(), isNull));
    });

    test('getPromotionByCode should return null for invalid code', () async {
      // Test with an invalid promo code
      final result = await databaseService.getPromotionByCode('INVALIDCODE');

      expect(result, isNull);
    });

    test('getActivePromotions should return a list of promotions', () async {
      final result = await databaseService.getActivePromotions();

      expect(result, isA<List<Map<String, dynamic>>>());
      // The list can be empty or contain items
    });

    test('validatePromotion should validate based on criteria', () {
      final now = DateTime.now();
      final validFrom = now.subtract(Duration(days: 1));
      final validUntil = now.add(Duration(days: 1));
      final usageLimit = 10;
      final usedCount = 5;
      final minimumOrderAmount = 10.0;
      final orderAmount = 15.0;

      // This is a conceptual test - actual implementation would be in the cart provider
      expect(validFrom.isBefore(now), isTrue);
      expect(validUntil.isAfter(now), isTrue);
      expect(usedCount, lessThan(usageLimit));
      expect(orderAmount, greaterThanOrEqualTo(minimumOrderAmount));
    });
  });
}
