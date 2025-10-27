import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    dotenv.testLoad(fileInput: [
      'DEFAULT_TAX_RATE=0.10',
      'DEFAULT_DELIVERY_FEE=5.00',
      'FREE_DELIVERY_THRESHOLD=25.00',
      'MIN_ORDER_AMOUNT=10.00',
    ].join('\n'));
  });

  MenuItem _menuItem({required String id, required double price}) {
    final now = DateTime.now();
    return MenuItem(
      id: id,
      restaurantId: 'r1',
      name: 'Item $id',
      price: price,
      category: 'Main',
      isAvailable: true,
      dietaryRestrictions: const [],
      preparationTime: 10,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('calculates tax and delivery fee per BusinessConfig (delivery below/above threshold)', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);

    // Ensure delivery mode
    notifier.setDeliveryMethod(DeliveryMethod.delivery);

    // Add one item at 20.00 -> below free threshold
    await notifier.addItem(_menuItem(id: 'm1', price: 20.0));

    var state = container.read(cartProvider);
    expect(state.subtotal, 20.0);
    expect(state.taxAmount, closeTo(2.0, 1e-6)); // 10%
    expect(state.deliveryFee, 5.0); // below 25 threshold

    // Add another item at 10.00 -> subtotal 30.00 -> free delivery
    await notifier.addItem(_menuItem(id: 'm2', price: 10.0));

    state = container.read(cartProvider);
    expect(state.subtotal, 30.0);
    expect(state.taxAmount, closeTo(3.0, 1e-6));
    expect(state.deliveryFee, 0.0);

    // Total = 30 + 3 + 0 + tip(0) - discount(0) = 33
    expect(state.totalAmount, closeTo(33.0, 1e-6));
  });

  test('sets delivery fee to 0 for pickup', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(cartProvider.notifier);

    await notifier.addItem(_menuItem(id: 'm3', price: 15.0));

    // Switch to pickup
    notifier.setDeliveryMethod(DeliveryMethod.pickup);

    final state = container.read(cartProvider);
    expect(state.deliveryFee, 0.0);
  });
}

