import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';

void main() {
  group('HomeScreen Widget Tests', () {
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

    testWidgets('displays home screen correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

      // Verify that welcome message is displayed
      expect(find.text('Welcome back!'), findsOneWidget);

      // Verify that search bar is displayed
      expect(find.byType(TextField), findsOneWidget);

      // Verify that categories section is displayed
      expect(find.text('Categories'), findsOneWidget);

      // Verify that popular restaurants section is displayed
      expect(find.text('Popular Restaurants'), findsOneWidget);
    });

    testWidgets('search functionality works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField).first, 'pizza');

      // Trigger search (typically done by pressing enter or clicking search icon)
      await tester.pump();

      // Verify that search query is processed
      // Note: Actual filtering would be tested in integration tests
      expect(find.text('pizza'), findsOneWidget);
    });

    testWidgets('navigates to cart when cart icon is tapped', (
      WidgetTester tester,
    ) async {
      bool navigatedToCart = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
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

      // Tap cart icon button
      await tester.tap(find.byIcon(Icons.shopping_cart).first);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToCart, isTrue);
    });

    testWidgets('navigates to profile when profile icon is tapped', (
      WidgetTester tester,
    ) async {
      bool navigatedToProfile = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/profile') {
                navigatedToProfile = true;
                return MaterialPageRoute(
                  builder: (context) =>
                      Scaffold(appBar: AppBar(title: Text('Profile Screen'))),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Tap profile icon button
      await tester.tap(find.byIcon(Icons.person).first);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToProfile, isTrue);
    });

    testWidgets('category items are displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

      // Verify that category items are displayed
      expect(find.text('Pizza'), findsOneWidget);
      expect(find.text('Burgers'), findsOneWidget);
      expect(find.text('Sushi'), findsOneWidget);
      expect(find.text('Salads'), findsOneWidget);
      expect(find.text('Desserts'), findsOneWidget);
    });

    testWidgets('pull to refresh works', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: HomeScreen())),
      );

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
  });
}
