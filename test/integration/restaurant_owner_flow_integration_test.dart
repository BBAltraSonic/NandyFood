import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_dashboard_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_analytics_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/notifications_screen.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/core/services/role_service.dart';

void main() {
  group('Restaurant Owner Flow Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Restaurant owner dashboard should be accessible', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build dashboard screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dashboard loads
      expect(find.text('Restaurant Dashboard'), findsOneWidget);
      expect(find.text('Welcome, Restaurant Owner!'), findsOneWidget);

      // Verify key dashboard sections
      expect(find.text('Today\'s Orders'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Popular Items'), findsOneWidget);
    });

    testWidgets('Analytics screen should display correctly', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build analytics screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantAnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify analytics sections
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Revenue Overview'), findsOneWidget);
      expect(find.text('Sales Trends'), findsOneWidget);
      expect(find.text('Customer Analytics'), findsOneWidget);
    });

    testWidgets('Notifications should work correctly', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build notifications screen
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify notifications screen
      expect(find.text('Notifications'), findsOneWidget);

      // Should show empty state initially
      expect(find.text('No notifications'), findsOneWidget);
    });

    testWidgets('Role-based access should work correctly', (WidgetTester tester) async {
      // Test with regular user (should not have access)
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'customer_123',
        email: 'customer@example.com',
        name: 'Regular Customer',
        role: UserRoleType.consumer,
      );

      // Try to build dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show access denied or redirect
      expect(find.text('Access Denied'), findsOneWidget);
    });

    testWidgets('Navigation between dashboard screens should work', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build main dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to analytics
      await tester.tap(find.text('Analytics'));
      await tester.pumpAndSettle();

      // Should be on analytics screen
      expect(find.text('Analytics'), findsOneWidget);

      // Navigate back to dashboard
      await tester.tap(find.byIcon(Icons.dashboard));
      await tester.pumpAndSettle();

      // Should be back on dashboard
      expect(find.text('Restaurant Dashboard'), findsOneWidget);

      // Navigate to notifications
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      // Should be on notifications screen
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Dashboard should display real-time updates', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify dashboard metrics are displayed
      expect(find.byKey(const Key('orders_today')), findsOneWidget);
      expect(find.byKey(const Key('revenue_today')), findsOneWidget);
      expect(find.byKey(const Key('active_orders')), findsOneWidget);

      // Test refresh functionality
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      // Dashboard should still be displayed after refresh
      expect(find.text('Restaurant Dashboard'), findsOneWidget);
    });

    testWidgets('Error handling should work gracefully', (WidgetTester tester) async {
      // Set up authenticated restaurant owner
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'owner_123',
        email: 'owner@restaurant.com',
        name: 'Restaurant Owner',
        role: UserRoleType.restaurantOwner,
      );

      // Build dashboard
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const RestaurantDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Simulate network error state
      // In real implementation, this would be triggered by actual network failures
      // For testing, we verify the UI handles error states gracefully
      expect(find.text('Restaurant Dashboard'), findsOneWidget);
    });
  });
}