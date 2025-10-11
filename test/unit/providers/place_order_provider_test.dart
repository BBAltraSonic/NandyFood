import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';

void main() {
  group('PlaceOrderProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have default values', () {
      final state = container.read(placeOrderProvider);
      expect(state.isLoading, false);
      expect(state.errorMessage, isNull);
      expect(state.placedOrder, isNull);
      expect(state.totalAmount, 0.0);
      expect(state.deliveryFee, 0.0);
      expect(state.taxAmount, 0.0);
      expect(state.tipAmount, 0.0);
      expect(state.discountAmount, 0.0);
      expect(state.promoCode, isNull);
    });

    test('updateDeliveryFee should update delivery fee', () {
      final notifier = container.read(placeOrderProvider.notifier);
      notifier.updateDeliveryFee(5.0);

      final state = container.read(placeOrderProvider);
      expect(state.deliveryFee, 5.0);
    });

    test('updateTipAmount should update tip amount', () {
      final notifier = container.read(placeOrderProvider.notifier);
      notifier.updateTipAmount(3.0);

      final state = container.read(placeOrderProvider);
      expect(state.tipAmount, 3.0);
    });

    test('clearError should clear error message', () {
      final notifier = container.read(placeOrderProvider.notifier);
      // Simulate an error state
      container.read(placeOrderProvider.notifier).state = container
          .read(placeOrderProvider.notifier)
          .state
          .copyWith(errorMessage: 'Test error');

      notifier.clearError();

      final state = container.read(placeOrderProvider);
      expect(state.errorMessage, isNull);
    });

    test('reset should reset to initial state', () {
      final notifier = container.read(placeOrderProvider.notifier);
      // Set some values to non-initial state
      container.read(placeOrderProvider.notifier).state = container
          .read(placeOrderProvider.notifier)
          .state
          .copyWith(deliveryFee: 5.0, tipAmount: 3.0, promoCode: 'TEST');

      notifier.reset();

      final state = container.read(placeOrderProvider);
      expect(state.deliveryFee, 0.0);
      expect(state.tipAmount, 0.0);
      expect(state.promoCode, isNull);
    });
  });
}
