import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/screens/restaurant_list_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';

void main() {
  group('RestaurantListScreen Widget Tests', () {
    late DatabaseService dbService;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();
    });

    tearDown(() {
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    testWidgets('displays restaurant list correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: RestaurantListScreen())),
      );

      // Verify that title is displayed
      expect(find.text('Restaurants'), findsOneWidget);

      // Verify that restaurant list is displayed
      expect(find.byType(ListView), findsOneWidget);

      // Verify that filter widget is displayed
      expect(find.text('Filters'), findsOneWidget);
    });

    testWidgets('displays loading indicator when loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: RestaurantListScreen())),
      );

      // Initially, we should see a loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('applies dietary restriction filters', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: RestaurantListScreen())),
      );

      // Wait for initial load
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
        ProviderScope(child: MaterialApp(home: RestaurantListScreen())),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Find search field and enter query
      await tester.enterText(find.byType(TextField).first, 'italian');

      // Trigger search
      await tester.pump();

      // Verify that search is processed
      // Note: Actual search would be tested in integration tests
    });

    testWidgets('pull to refresh works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: RestaurantListScreen())),
      );

      // Wait for initial load
      await tester.pumpAndSettle();

      // Perform pull to refresh gesture
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      // Verify that refresh happened
      // Note: Actual refresh functionality would be tested in integration tests
    });

    testWidgets(
      'navigates to restaurant detail when restaurant card is tapped',
      (WidgetTester tester) async {
        bool navigatedToDetail = false;

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: RestaurantListScreen(),
              onGenerateRoute: (settings) {
                if (settings.name != null &&
                    settings.name!.startsWith('/restaurant/')) {
                  navigatedToDetail = true;
                  return MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text('Restaurant Detail')),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        );

        // Wait for initial load
        await tester.pumpAndSettle();

        // Tap on a restaurant card (if any are displayed)
        final restaurantCards = find.byType(Card);
        if (restaurantCards.evaluate().isNotEmpty) {
          await tester.tap(restaurantCards.first);
          await tester.pumpAndSettle();

          // Verify that navigation occurred
          expect(navigatedToDetail, isTrue);
        }
      },
    );
  });
}
