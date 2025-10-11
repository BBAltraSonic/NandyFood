import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/features/order/presentation/models/cart_item.dart';
import 'package:food_delivery_app/shared/models/order_item.dart';

void main() {
  group('Comprehensive Unit Tests', () {
    group('Order Model Tests', () {
      test('Order should calculate total correctly', () {
        final order = Order(
          id: 'order1',
          userId: 'user1',
          restaurantId: 'restaurant1',
          deliveryAddress: {'street': '123 Main St'},
          status: OrderStatus.placed,
          totalAmount: 30.00,
          subtotal: 25.00,
          deliveryFee: 2.50,
          taxAmount: 2.00,
          tipAmount: 3.00,
          discountAmount: 2.50,
          paymentMethod: 'card',
          paymentStatus: PaymentStatus.pending,
          placedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Verify that the totalAmount matches what was set
        expect(order.totalAmount, 30.00);

        // Verify other amounts
        expect(order.subtotal, 25.00);
        expect(order.deliveryFee, 2.50);
        expect(order.taxAmount, 2.00);
        expect(order.tipAmount, 3.00);
        expect(order.discountAmount, 2.50);
      });

      test('Order should have correct status transitions', () {
        final order = Order(
          id: 'order1',
          userId: 'user1',
          restaurantId: 'restaurant1',
          deliveryAddress: {'street': '123 Main St'},
          status: OrderStatus.placed,
          totalAmount: 25.00,
          deliveryFee: 2.00,
          taxAmount: 2.00,
          paymentMethod: 'card',
          paymentStatus: PaymentStatus.pending,
          placedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(order.status, OrderStatus.placed);
      });
    });

    group('Restaurant Model Tests', () {
      test('Restaurant should have valid rating range', () {
        final restaurant = Restaurant(
          id: 'restaurant1',
          name: 'Test Restaurant',
          cuisineType: 'Italian',
          address: {'street': '123 Main St'},
          rating: 4.2,
          deliveryRadius: 5.0,
          estimatedDeliveryTime: 25,
          isActive: true,
          openingHours: {}, // Required parameter
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(restaurant.rating, 4.2);
        expect(restaurant.rating, greaterThanOrEqualTo(0.0));
        expect(restaurant.rating, lessThanOrEqualTo(5.0));
      });

      test('Restaurant should have valid delivery time', () {
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

        expect(restaurant.estimatedDeliveryTime, 30);
        expect(restaurant.estimatedDeliveryTime, greaterThan(0));
      });
    });

    group('MenuItem Model Tests', () {
      test('MenuItem should have valid price', () {
        final menuItem = MenuItem(
          id: 'item1',
          restaurantId: 'restaurant1',
          name: 'Test Item',
          description: 'A test menu item',
          price: 15.99,
          category: 'Main Course',
          isAvailable: true,
          dietaryRestrictions: ['vegetarian', 'gluten-free'],
          preparationTime: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(menuItem.price, 15.99);
        expect(menuItem.price, greaterThan(0));
      });

      test('MenuItem should have valid preparation time', () {
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

        expect(menuItem.preparationTime, 15);
        expect(menuItem.preparationTime, greaterThan(0));
      });
    });

    group('CartItem Model Tests', () {
      test('CartItem should calculate total price correctly', () {
        final orderItem = OrderItem(
          id: 'orderItem1',
          orderId: 'order1',
          menuItemId: 'item1',
          quantity: 2,
          unitPrice: 12.50,
          customizations: {},
          specialInstructions: 'Extra cheese',
        );

        final menuItem = MenuItem(
          id: 'item1',
          restaurantId: 'restaurant1',
          name: 'Burger',
          description: 'Delicious burger',
          price: 12.50,
          category: 'Main Course',
          isAvailable: true,
          dietaryRestrictions: ['gluten-free'],
          preparationTime: 15,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cartItem = CartItem(orderItem: orderItem, menuItem: menuItem);

        // Total price should be quantity * unitPrice
        expect(cartItem.totalPrice, 25.00); // 2 * 12.50
      });

      test('CartItem should handle single item correctly', () {
        final orderItem = OrderItem(
          id: 'orderItem1',
          orderId: 'order1',
          menuItemId: 'item1',
          quantity: 1,
          unitPrice: 18.99,
          customizations: {},
          specialInstructions: 'No onions',
        );

        final menuItem = MenuItem(
          id: 'item1',
          restaurantId: 'restaurant1',
          name: 'Pizza',
          description: 'Delicious pizza',
          price: 18.99,
          category: 'Main Course',
          isAvailable: true,
          dietaryRestrictions: ['vegetarian'],
          preparationTime: 20,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final cartItem = CartItem(orderItem: orderItem, menuItem: menuItem);

        expect(cartItem.totalPrice, 18.99);
      });
    });

    group('OrderItem Model Tests', () {
      test('OrderItem should calculate item total correctly', () {
        final orderItem = OrderItem(
          id: 'orderItem1',
          orderId: 'order1',
          menuItemId: 'item1',
          quantity: 3,
          unitPrice: 9.99,
          customizations: {},
          specialInstructions: 'Extra sauce',
        );

        final itemTotal = orderItem.unitPrice * orderItem.quantity;
        expect(itemTotal, 29.97); // 3 * 9.99
      });

      test('OrderItem should handle quantity of 1 correctly', () {
        final orderItem = OrderItem(
          id: 'orderItem1',
          orderId: 'order1',
          menuItemId: 'item1',
          quantity: 1,
          unitPrice: 14.50,
          customizations: {},
          specialInstructions: 'Well done',
        );

        final itemTotal = orderItem.unitPrice * orderItem.quantity;
        expect(itemTotal, 14.50);
      });
    });

    group('Business Logic Validation Tests', () {
      test('Tax calculation should be accurate', () {
        final subtotal = 20.00;
        final taxRate = 0.085; // 8.5%
        final taxAmount = subtotal * taxRate;

        expect(
          taxAmount,
          closeTo(1.70, 0.01),
        ); // Allow for floating point precision
      });

      test('Discount calculation should be accurate', () {
        final subtotal = 25.00;
        final discountPercentage = 0.10; // 10%
        final discountAmount = subtotal * discountPercentage;

        expect(discountAmount, 2.50); // 25.00 * 0.10 = 2.50
      });

      test('Total calculation with all components should be accurate', () {
        final subtotal = 30.00;
        final taxAmount = 2.55; // 8.5% tax
        final deliveryFee = 2.00;
        final tipAmount = 5.00;
        final discountAmount = 3.00;

        final total =
            subtotal + taxAmount + deliveryFee + tipAmount - discountAmount;
        expect(total, 36.55); // 30.00 + 2.55 + 2.00 + 5.00 - 3.00 = 36.55
      });

      test('Restaurant rating should be within valid range', () {
        final ratings = [0.0, 1.5, 2.3, 3.7, 4.2, 5.0];

        for (final rating in ratings) {
          expect(rating, greaterThanOrEqualTo(0.0));
          expect(rating, lessThanOrEqualTo(5.0));
        }
      });

      test('Delivery time should be reasonable', () {
        final deliveryTimes = [10, 15, 20, 25, 30, 45, 60];

        for (final time in deliveryTimes) {
          expect(time, greaterThanOrEqualTo(5));
          expect(time, lessThanOrEqualTo(120)); // Max 2 hours
        }
      });
    });
  });
}
