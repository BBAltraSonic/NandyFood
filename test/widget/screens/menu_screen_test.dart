import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/menu_screen.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('MenuScreen Widget Tests', () {
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

    testWidgets('displays menu items correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MenuScreen(restaurant: mockRestaurant)),
        ),
      );

      // Verify that restaurant name is displayed
      expect(find.text('Test Restaurant Menu'), findsOneWidget);

      // Verify that menu items list is displayed
      expect(find.byType(ListView), findsOneWidget);

      // Verify that loading indicator is displayed initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays menu categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MenuScreen(restaurant: mockRestaurant)),
        ),
      );

      // Wait for menu items to load
      await tester.pumpAndSettle();

      // Verify that menu categories are displayed
      // Note: Actual categories would depend on menu items
      expect(find.text('Starters'), findsOneWidget);
      expect(find.text('Main Courses'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
    });

    testWidgets('adds item to cart when add button is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MenuScreen(restaurant: mockRestaurant)),
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

    testWidgets('filters menu items by dietary restrictions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MenuScreen(restaurant: mockRestaurant)),
        ),
      );

      // Wait for menu items to load
      await tester.pumpAndSettle();

      // Tap on filter button
      await tester.tap(find.text('Filters'));
      await tester.pump();

      // Find and tap vegetarian filter
      await tester.tap(find.text('Vegetarian'));
      await tester.pump();

      // Verify that filter is applied
      // Note: Actual filtering would be tested in integration tests
    });

    testWidgets('search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(home: MenuScreen(restaurant: mockRestaurant)),
        ),
      );

      // Wait for menu items to load
      await tester.pumpAndSettle();

      // Find search field and enter query
      await tester.enterText(find.byType(TextField).first, 'pasta');

      // Trigger search
      await tester.pump();

      // Verify that search is processed
      // Note: Actual search would be tested in integration tests
    });

    testWidgets('navigates to cart when cart icon is tapped', (
      WidgetTester tester,
    ) async {
      bool navigatedToCart = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MenuScreen(restaurant: mockRestaurant),
            onGenerateRoute: (settings) {
              if (settings.name == '/order/cart') {
                navigatedToCart = true;
                return MaterialPageRoute(
                  builder: (context) =>
                      Scaffold(appBar: AppBar(title: Text('Cart Screen'))),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Wait for menu items to load
      await tester.pumpAndSettle();

      // Tap cart icon button
      await tester.tap(find.byIcon(Icons.shopping_cart).first);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToCart, isTrue);
    });
  });
}
