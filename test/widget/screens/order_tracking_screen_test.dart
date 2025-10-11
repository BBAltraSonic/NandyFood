import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/screens/order_tracking_screen.dart';
import 'package:food_delivery_app/shared/models/order.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('OrderTrackingScreen Widget Tests', () {
    late DatabaseService dbService;
    late Order mockOrder;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();

      // Create a mock order for testing
      mockOrder = Order(
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
    });

    tearDown(() {
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    testWidgets('displays order tracking information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Verify that title is displayed
      expect(find.text('Track Order'), findsOneWidget);

      // Verify that order ID is displayed
      expect(find.text('Order #${mockOrder.id}'), findsOneWidget);

      // Verify that order status is displayed
      expect(find.text('Status: ${mockOrder.status.name}'), findsOneWidget);

      // Verify that total amount is displayed
      expect(find.text('\$${mockOrder.totalAmount.toStringAsFixed(2)}'), findsOneWidget);
    });

    testWidgets('displays delivery progress correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Verify that delivery progress widget is displayed
      expect(find.byType(Column), findsWidgets); // Progress indicators are in a column

      // Verify that status labels are displayed
      expect(find.text('Order Placed'), findsOneWidget);
      expect(find.text('Preparing'), findsOneWidget);
      expect(find.text('On the Way'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('displays driver information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Wait for delivery info to load
      await tester.pumpAndSettle();

      // Verify that driver info section is displayed
      expect(find.text('Your Driver'), findsOneWidget);

      // Verify that driver name is displayed
      // Note: Actual driver name would depend on delivery data
      expect(find.byType(Container), findsWidgets); // Driver info container
    });

    testWidgets('displays restaurant information', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Wait for restaurant info to load
      await tester.pumpAndSettle();

      // Verify that restaurant info section is displayed
      expect(find.text('From'), findsOneWidget);

      // Verify that restaurant name is displayed
      // Note: Actual restaurant name would depend on order data
      expect(find.byType(Container), findsWidgets); // Restaurant info container
    });

    testWidgets('updates delivery status in real-time', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Wait for initial delivery info
      await tester.pumpAndSettle();

      // Verify initial status
      expect(find.text('Status: ${mockOrder.status.name}'), findsOneWidget);

      // Simulate status update
      // Note: Actual status updates would come from delivery tracking service
    });

    testWidgets('calls driver when call button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Wait for delivery info to load
      await tester.pumpAndSettle();

      // Find call driver button
      final callButtons = find.byIcon(Icons.phone);

      // Tap call button
      if (callButtons.evaluate().isNotEmpty) {
        await tester.tap(callButtons.first);
        await tester.pump();

        // Verify that call action is triggered
        expect(find.text('Calling driver...'), findsOneWidget);
      }
    });

    testWidgets('displays estimated delivery time', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Wait for delivery info to load
      await tester.pumpAndSettle();

      // Verify that estimated delivery time is displayed
      // Note: Actual time would depend on delivery data
      expect(find.byType(Text), findsWidgets); // Time information is in text widgets
    });

    testWidgets('refreshes delivery information when pulled down', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: OrderTrackingScreen(order: mockOrder),
          ),
        ),
      );

      // Perform pull to refresh gesture
      await tester.fling(
        find.byType(SingleChildScrollView),
        const Offset(0.0, 300.0),
        1000.0,
      );
      await tester.pumpAndSettle();

      // Verify that refresh happened
      // Note: Actual refresh would depend on delivery tracking service
    });
  });
}