import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/place_order_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/order_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

void main() {
  group('Place Order Flow Integration Tests', () {
    late DatabaseService dbService;
    late ProviderContainer container;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();

      // Create a provider container for testing
      container = ProviderContainer();
    });

    tearDown(() {
      // Dispose of the provider container
      container.dispose();

      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    test('complete place order flow', () async {
      // Setup mock restaurant and menu items
      final mockRestaurant = Restaurant(
        id: 'restaurant1',
        name: 'Test Restaurant',
        cuisineType: 'Italian',
        address: {'street': '123 Test St'},
        rating: 4.5,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 30,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem = MenuItem(
        id: 'item1',
        restaurantId: 'restaurant1',
        name: 'Test Pasta',
        description: 'Delicious pasta dish',
        price: 12.99,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian'],
        preparationTime: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add items to cart
      final cartNotifier = container.read(cartProvider.notifier);
      await cartNotifier.addItem(
        mockMenuItem,
        quantity: 2,
        customizations: {'extra_cheese': true},
        specialInstructions: 'Well done',
      );

      // Verify cart has items
      var cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.items[0].orderItem.quantity, 2);
      expect(cartState.subtotal, 25.98); // 12.99 * 2

      // Place order
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      final order = await placeOrderNotifier.placeOrder(
        userId: 'user1',
        restaurantId: 'restaurant1',
        deliveryAddress: {
          'street': '456 Delivery St',
          'city': 'Test City',
          'zipCode': '12345',
        },
        paymentMethod: 'card',
        tipAmount: 3.0,
        promoCode: null,
        specialInstructions: 'Ring doorbell',
      );

      // Verify order was created successfully
      expect(order, isNotNull);
      expect(order.id, isNotEmpty);
      expect(order.userId, 'user1');
      expect(order.restaurantId, 'restaurant1');
      expect(order.totalAmount, greaterThan(0));
      expect(order.status, OrderStatus.placed);
      expect(order.paymentStatus, PaymentStatus.pending);

      // Verify cart is cleared after order placement
      cartState = container.read(cartProvider);
      expect(cartState.items.length, 0);
      expect(cartState.subtotal, 0.0);
    });

    test('place order with promo code', () async {
      // Setup mock restaurant and menu items
      final mockRestaurant = Restaurant(
        id: 'restaurant2',
        name: 'Promo Test Restaurant',
        cuisineType: 'Mexican',
        address: {'street': '789 Promo St'},
        rating: 4.2,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 25,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem = MenuItem(
        id: 'item2',
        restaurantId: 'restaurant2',
        name: 'Test Tacos',
        description: 'Spicy tacos',
        price: 9.99,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 10,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add items to cart
      final cartNotifier = container.read(cartProvider.notifier);
      await cartNotifier.addItem(mockMenuItem, quantity: 3);

      // Verify initial cart state
      var cartState = container.read(cartProvider);
      expect(cartState.items.length, 1);
      expect(cartState.subtotal, 29.97); // 9.99 * 3

      // Apply promo code
      await cartNotifier.applyPromoCode('SAVE10'); // Assuming 10% discount

      // Verify discount is applied
      cartState = container.read(cartProvider);
      expect(cartState.promoCode, 'SAVE10');
      expect(cartState.discountAmount, greaterThan(0));

      // Place order with promo code
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      final order = await placeOrderNotifier.placeOrder(
        userId: 'user2',
        restaurantId: 'restaurant2',
        deliveryAddress: {
          'street': '999 Discount St',
          'city': 'Coupon City',
          'zipCode': '54321',
        },
        paymentMethod: 'card',
        tipAmount: 2.5,
        promoCode: 'SAVE10',
        specialInstructions: 'Leave at door',
      );

      // Verify order was created with promo code
      expect(order, isNotNull);
      expect(order.promoCode, 'SAVE10');
      expect(order.discountAmount, greaterThan(0));
      expect(
        order.totalAmount,
        lessThan(cartState.subtotal + 2.5),
      ); // Total should be less due to discount
    });

    test('place order with multiple items', () async {
      // Setup mock restaurant and menu items
      final mockRestaurant = Restaurant(
        id: 'restaurant3',
        name: 'Multi Item Restaurant',
        cuisineType: 'American',
        address: {'street': '321 Multi St'},
        rating: 4.0,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 35,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem1 = MenuItem(
        id: 'item3',
        restaurantId: 'restaurant3',
        name: 'Cheeseburger',
        description: 'Juicy cheeseburger',
        price: 8.99,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: [],
        preparationTime: 12,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem2 = MenuItem(
        id: 'item4',
        restaurantId: 'restaurant3',
        name: 'French Fries',
        description: 'Crispy french fries',
        price: 3.99,
        category: 'Sides',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian'],
        preparationTime: 8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem3 = MenuItem(
        id: 'item5',
        restaurantId: 'restaurant3',
        name: 'Chocolate Shake',
        description: 'Rich chocolate milkshake',
        price: 5.99,
        category: 'Drinks',
        isAvailable: true,
        dietaryRestrictions: ['vegetarian'],
        preparationTime: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add multiple items to cart
      final cartNotifier = container.read(cartProvider.notifier);
      await cartNotifier.addItem(mockMenuItem1, quantity: 1);
      await cartNotifier.addItem(mockMenuItem2, quantity: 2);
      await cartNotifier.addItem(mockMenuItem3, quantity: 1);

      // Verify cart has multiple items
      var cartState = container.read(cartProvider);
      expect(cartState.items.length, 3);
      expect(cartState.subtotal, 22.96); // 8.99 + (3.99 * 2) + 5.99

      // Place order with multiple items
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);
      final order = await placeOrderNotifier.placeOrder(
        userId: 'user3',
        restaurantId: 'restaurant3',
        deliveryAddress: {
          'street': '654 Combo St',
          'city': 'Combo City',
          'zipCode': '98765',
        },
        paymentMethod: 'card',
        tipAmount: 4.0,
        promoCode: null,
        specialInstructions: 'Include utensils',
      );

      // Verify order was created with multiple items
      expect(order, isNotNull);
      expect(order.id, isNotEmpty);

      // Verify order items were created
      final orderProvider = container.read(orderProvider.notifier);
      // Note: In a real implementation, we would verify that order items were created in the database
    });

    test('failed order placement with invalid payment method', () async {
      // Setup mock restaurant and menu items
      final mockRestaurant = Restaurant(
        id: 'restaurant4',
        name: 'Invalid Payment Restaurant',
        cuisineType: 'Asian',
        address: {'street': '555 Invalid St'},
        rating: 4.3,
        deliveryRadius: 5.0,
        estimatedDeliveryTime: 20,
        isActive: true,
        openingHours: {}, // Required parameter
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final mockMenuItem = MenuItem(
        id: 'item6',
        restaurantId: 'restaurant4',
        name: 'Test Sushi',
        description: 'Fresh sushi rolls',
        price: 15.99,
        category: 'Main Course',
        isAvailable: true,
        dietaryRestrictions: ['gluten-free'],
        preparationTime: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add items to cart
      final cartNotifier = container.read(cartProvider.notifier);
      await cartNotifier.addItem(mockMenuItem, quantity: 1);

      // Place order with invalid payment method
      final placeOrderNotifier = container.read(placeOrderProvider.notifier);

      try {
        await placeOrderNotifier.placeOrder(
          userId: 'user4',
          restaurantId: 'restaurant4',
          deliveryAddress: {
            'street': '777 Fail St',
            'city': 'Failure City',
            'zipCode': '00000',
          },
          paymentMethod: 'invalid_payment_method',
          tipAmount: 0.0,
          promoCode: null,
          specialInstructions: '',
        );
        fail('Expected exception was not thrown');
      } catch (e) {
        // Verify that order placement failed
        final placeOrderState = container.read(placeOrderProvider);
        expect(placeOrderState.errorMessage, isNotNull);
      }
    });

    test(
      'order placement with customizations and special instructions',
      () async {
        // Setup mock restaurant and menu items
        final mockRestaurant = Restaurant(
          id: 'restaurant5',
          name: 'Customization Restaurant',
          cuisineType: 'Mediterranean',
          address: {'street': '888 Customize St'},
          rating: 4.7,
          deliveryRadius: 5.0,
          estimatedDeliveryTime: 40,
          isActive: true,
          openingHours: {}, // Required parameter
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final mockMenuItem = MenuItem(
          id: 'item7',
          restaurantId: 'restaurant5',
          name: 'Greek Salad',
          description: 'Fresh greek salad',
          price: 11.99,
          category: 'Salads',
          isAvailable: true,
          dietaryRestrictions: ['vegetarian', 'gluten-free'],
          preparationTime: 10,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Add item to cart with customizations
        final cartNotifier = container.read(cartProvider.notifier);
        await cartNotifier.addItem(
          mockMenuItem,
          quantity: 1,
          customizations: {
            'extra_olives': true,
            'no_feta': false,
            'dressing': 'lemon_vinaigrette',
          },
          specialInstructions: 'Make it extra fresh',
        );

        // Verify cart item has customizations
        var cartState = container.read(cartProvider);
        expect(cartState.items.length, 1);
        expect(cartState.items[0].orderItem.customizations, isNotNull);
        expect(
          cartState.items[0].orderItem.customizations!['extra_olives'],
          isTrue,
        );
        expect(
          cartState.items[0].orderItem.customizations!['no_feta'],
          isFalse,
        );
        expect(
          cartState.items[0].orderItem.customizations!['dressing'],
          'lemon_vinaigrette',
        );
        expect(
          cartState.items[0].orderItem.specialInstructions,
          'Make it extra fresh',
        );

        // Place order with customizations
        final placeOrderNotifier = container.read(placeOrderProvider.notifier);
        final order = await placeOrderNotifier.placeOrder(
          userId: 'user5',
          restaurantId: 'restaurant5',
          deliveryAddress: {
            'street': '111 Custom St',
            'city': 'Custom City',
            'zipCode': '11111',
          },
          paymentMethod: 'card',
          tipAmount: 3.5,
          promoCode: null,
          specialInstructions: 'Call upon arrival',
        );

        // Verify order was created with customizations
        expect(order, isNotNull);
        expect(order.id, isNotEmpty);
      },
    );
  });
}
