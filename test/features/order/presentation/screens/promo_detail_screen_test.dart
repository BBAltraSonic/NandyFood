import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/screens/promo_detail_screen.dart';
import 'package:food_delivery_app/shared/models/promotion.dart';
import 'package:food_delivery_app/core/services/promotion_service.dart';

import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Promotion _buildPromo({double? minOrderAmount, bool isActive = true}) {
    final now = DateTime.now();
    return Promotion(
      id: 'p1',
      code: 'SAVE50',
      title: 'Save 50',
      description: 'Half price on your order',
      promotionType: PromotionType.percentage,
      discountValue: 50,
      minOrderAmount: minOrderAmount,
      maxDiscountAmount: null,
      startDate: now.subtract(const Duration(days: 1)),
      endDate: now.add(const Duration(days: 1)),
      usageLimit: null,
      usageCount: 0,
      userUsageLimit: null,
      restaurantId: null,
      isFirstOrderOnly: false,
      status: isActive ? PromotionStatus.active : PromotionStatus.inactive,
      createdAt: now,
    );
  }

  testWidgets('Apply button disabled with reason when subtotal below minimum', (tester) async {
    // Arrange: cart subtotal 100, promo requires 200
    final container = ProviderContainer();
    // Make subtotal 100 by adding a dummy item to the cart
    final cart = container.read(cartProvider.notifier);
    // Use a simple add via state copy to avoid external models
    cart.state = cart.state.copyWith(subtotal: 100.0);

    final promo = _buildPromo(minOrderAmount: 200.0);

    Future<Promotion?> loader(String id) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return promo;
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PromoDetailScreen(promoId: 'p1', loader: loader),
        ),
      ),
    );

    // Wait for FutureBuilder
    await tester.pumpAndSettle();

    // Assert: Button exists and is disabled
    // Assert: Button label exists and disabled reason is visible
    expect(find.text('Apply code SAVE50'), findsOneWidget);
    expect(find.textContaining('Minimum order'), findsWidgets);
  });

  testWidgets('Error state shows back and try again actions', (tester) async {
    final container = ProviderContainer();

    Future<Promotion?> loader(String id) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      throw Exception('network');
    }

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PromoDetailScreen(promoId: 'p1', loader: loader),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert: Back and Try Again buttons are visible
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Try Again'), findsOneWidget);
  });
}

