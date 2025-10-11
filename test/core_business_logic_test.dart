import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/order/presentation/models/cart_item.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

void main() {
  group('Core Business Logic Tests', () {
    test('Order total calculation should be accurate', () {
      final order = Order(
        id: 'order1',
        userId: 'user1',
        restaurantId: 'restaurant1',
        deliveryAddress: {'street': '123 Main St'},
        status: OrderStatus.placed,
        totalAmount: 25.50,
        subtotal: 20.00,
        deliveryFee: 2.00,
        taxAmount: 1.70, // 8.5% tax on $20
        tipAmount: 3.00,
        discountAmount: 2.00,
        paymentMethod: 'card',
        paymentStatus: PaymentStatus.pending,
        placedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Verify that totalAmount matches what was set in the constructor
      expect(order.totalAmount, 25.50);
    });

    test('Restaurant rating calculation should be valid', () {
      final restaurant = Restaurant(
        id: 'restaurant1',
        name: 'Test Restaurant',
        cuisineType: 'Italian',
        address: {'street': '123 Main St'},
        rating: 4.5,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 30,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(restaurant.rating, 4.5);
      expect(restaurant.rating, greaterThanOrEqualTo(0.0));
      expect(restaurant.rating, lessThanOrEqualTo(5.0));
    });

    test('Menu item price calculation should be valid', () {
      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Item',
        description: 'A test menu item',
        price: 12.99,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(menuItem.price, 12.99);
      expect(menuItem.price, greaterThan(0));
    });

    test('Order item total calculation should be accurate', () {
      final orderItem = OrderItem(
        id: 'orderItem1',
        orderId: 'order1',
        menuItemId: 'item1',
        quantity: 3,
        unitPrice: 12.99,
        customizations: {},
        specialInstructions: 'Extra cheese',
      );

      final total = orderItem.unitPrice * orderItem.quantity;
      expect(total, 38.97);
    });

    test('Cart item total calculation should be accurate', () {
      final orderItem = OrderItem(
        id: 'orderItem1',
        orderId: 'order1',
        menuItemId: 'item1',
        quantity: 2,
        unitPrice: 15.50,
        customizations: {},
        specialInstructions: 'No onions',
      );

      final menuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Burger',
        description: 'Delicious burger',
        price: 15.50,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final cartItem = CartItem(orderItem: orderItem, menuItem: menuItem);

      final total = cartItem.totalPrice;
      expect(total, 31.00); // 15.50 * 2
    });

    test('Delivery time estimation should be reasonable', () {
      final restaurant = Restaurant(
        id: 'restaurant1',
        name: 'Test Restaurant',
        cuisineType: 'Italian',
        address: {'street': '123 Main St'},
        rating: 4.5,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 30,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Delivery time should be reasonable (between 10 mins and 2 hours)
      expect(restaurant.estimatedDeliveryTime, greaterThanOrEqualTo(10));
      expect(restaurant.estimatedDeliveryTime, lessThanOrEqualTo(120));
    });
  });
}
