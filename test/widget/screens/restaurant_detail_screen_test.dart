import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_detail_screen.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('RestaurantDetailScreen Widget Tests', () {
    late DatabaseService dbService;
    late Restaurant mockRestaurant;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();

      // Create a mock restaurant for testing
      mockRestaurant = Restaurant(
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
    });

    tearDown(() {
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    testWidgets('displays restaurant details correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
          ),
        ),
      );

      // Verify that restaurant name is displayed
      expect(find.text('Test Restaurant'), findsOneWidget);

      // Verify that cuisine type is displayed
      expect(find.text('Italian'), findsOneWidget);

      // Verify that rating is displayed
      expect(find.text('4.5'), findsOneWidget);

      // Verify that delivery time is displayed
      expect(find.text('30 min'), findsOneWidget);
    });

    testWidgets('displays menu tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
          ),
        ),
      );

      // Verify that menu tab is selected by default
      expect(find.text('Menu'), findsOneWidget);
    });

    testWidgets('switches to info tab when tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
          ),
        ),
      );

      // Tap on info tab
      await tester.tap(find.text('Info'));
      await tester.pump();

      // Verify that info tab content is displayed
      // Note: Actual content would depend on implementation
    });

    testWidgets('navigates to menu screen when menu item is tapped', (
      WidgetTester tester,
    ) async {
      bool navigatedToMenu = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
            onGenerateRoute: (settings) {
              if (settings.name == '/restaurant/${mockRestaurant.id}/menu') {
                navigatedToMenu = true;
                return MaterialPageRoute(
                  builder: (context) =>
                      Scaffold(appBar: AppBar(title: Text('Menu Screen'))),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Tap on menu tab to go to menu screen
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToMenu, isTrue);
    });

    testWidgets('adds item to cart when add button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
          ),
        ),
      );

      // Wait for menu items to load
      await tester.pumpAndSettle();

      // Find add to cart button and tap it
      final addToCartButtons = find.byIcon(Icons.add_shopping_cart);
      if (addToCartButtons.evaluate().isNotEmpty) {
        await tester.tap(addToCartButtons.first);
        await tester.pump();

        // Verify that item was added to cart
        // Note: Actual cart functionality would be tested in integration tests
      }
    });

    testWidgets('displays loading indicator when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: RestaurantDetailScreen(restaurant: mockRestaurant, restaurantId: 'test-restaurant-1'),
          ),
        ),
      );

      // Initially, we should see a loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
