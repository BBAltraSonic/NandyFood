import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/menu_item.dart';
import 'package:food_delivery_app/shared/models/order.dart';

/// Integration Test Helpers
///
/// Utility functions and mock data for integration tests
class IntegrationTestHelpers {
  // Mock Data
  static const mockUser = {
    'id': 'test_user_123',
    'email': 'test@example.com',
    'name': 'Test User',
    'phone': '+1234567890',
  };

  static const mockRestaurantOwner = {
    'id': 'owner_123',
    'email': 'owner@restaurant.com',
    'name': 'Restaurant Owner',
    'phone': '+0987654321',
  };

  static final mockRestaurant = Restaurant(
    id: 'restaurant_1',
    name: 'Test Restaurant',
    cuisine: 'Test Cuisine',
    rating: 4.5,
    deliveryTime: '30-40 min',
    deliveryFee: 2.99,
    minOrderAmount: 10.0,
    imageUrl: 'https://example.com/restaurant.jpg',
    address: '123 Test St, Test City',
    phone: '+1234567890',
    email: 'test@restaurant.com',
    isActive: true,
  );

  static final mockMenuItems = [
    MenuItem(
      id: 'item_1',
      name: 'Test Burger',
      description: 'Delicious test burger with all the fixings',
      price: 12.99,
      category: 'Main',
      imageUrl: 'https://example.com/burger.jpg',
      restaurantId: 'restaurant_1',
      isAvailable: true,
      preparationTime: 15,
      customizationOptions: [
        {
          'name': 'Extra Cheese',
          'price': 1.5,
          'type': 'checkbox',
        },
        {
          'name': 'Bacon',
          'price': 2.0,
          'type': 'checkbox',
        },
      ],
    ),
    MenuItem(
      id: 'item_2',
      name: 'Test Fries',
      description: 'Crispy golden fries with sea salt',
      price: 4.99,
      category: 'Side',
      imageUrl: 'https://example.com/fries.jpg',
      restaurantId: 'restaurant_1',
      isAvailable: true,
      preparationTime: 10,
    ),
    MenuItem(
      id: 'item_3',
      name: 'Test Drink',
      description: 'Refreshing test drink',
      price: 2.99,
      category: 'Beverage',
      imageUrl: 'https://example.com/drink.jpg',
      restaurantId: 'restaurant_1',
      isAvailable: true,
      preparationTime: 5,
    ),
  ];

  static final mockOrder = Order(
    id: 'order_123',
    userId: 'test_user_123',
    restaurantId: 'restaurant_1',
    restaurantName: 'Test Restaurant',
    deliveryAddress: {
      'street': '123 Test St',
      'city': 'Test City',
      'postalCode': '12345',
    },
    items: [
      {
        'id': 'item_1',
        'name': 'Test Burger',
        'price': 12.99,
        'quantity': 2,
        'customization': ['Extra Cheese'],
      },
      {
        'id': 'item_2',
        'name': 'Test Fries',
        'price': 4.99,
        'quantity': 1,
      },
    ],
    status: OrderStatus.placed,
    totalAmount: 33.47, // 2*12.99 + 1*4.99 + 1.5 (cheese) + 2.99 (delivery)
    deliveryFee: 2.99,
    taxAmount: 3.50,
    paymentMethod: 'cash',
    paymentStatus: PaymentStatus.pending,
    placedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Auth Helpers
  static void setupMockUser(ProviderContainer container, {
    String? userId,
    String? email,
    String? name,
    UserRoleType? role,
  }) {
    container.read(authStateProvider.notifier).setAuthenticatedUser(
      userId: userId ?? mockUser['id']!,
      email: email ?? mockUser['email']!,
      name: name ?? mockUser['name']!,
      role: role ?? UserRoleType.consumer,
    );
  }

  static void setupMockRestaurantOwner(ProviderContainer container) {
    container.read(authStateProvider.notifier).setAuthenticatedUser(
      userId: mockRestaurantOwner['id']!,
      email: mockRestaurantOwner['email']!,
      name: mockRestaurantOwner['name']!,
      role: UserRoleType.restaurantOwner,
    );
  }

  static void clearAuth(ProviderContainer container) {
    container.read(authStateProvider.notifier).logout();
  }

  // Widget Test Helpers
  static Future<void> pumpAppWithRoute(
    WidgetTester tester, {
    required Widget child,
    ProviderContainer? container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  static Future<void> pumpAppWithRouter(
    WidgetTester tester, {
    required Widget child,
    ProviderContainer? container,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container ?? ProviderContainer(),
        child: MaterialApp(
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Test Assertion Helpers
  static void expectTextExists(String text) {
    expect(find.text(text), findsOneWidget);
  }

  static void expectTextNotExists(String text) {
    expect(find.text(text), findsNothing);
  }

  static void expectWidgetExists<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  static void expectWidgetNotExists<T extends Widget>() {
    expect(find.byType(T), findsNothing);
  }

  static void expectButtonExists(String text) {
    expect(find.widgetWithText(ElevatedButton, text), findsOneWidget);
  }

  static void expectTextButtonExists(String text) {
    expect(find.widgetWithText(TextButton, text), findsOneWidget);
  }

  static Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(ElevatedButton, text));
    await tester.pumpAndSettle();
  }

  static Future<void> tapTextButton(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(TextButton, text));
    await tester.pumpAndSettle();
  }

  static Future<void> tapIcon(WidgetTester tester, IconData icon) async {
    await tester.tap(find.byIcon(icon));
    await tester.pumpAndSettle();
  }

  static Future<void> enterText(
    WidgetTester tester,
    String text, {
    Key? key,
  }) async {
    if (key != null) {
      await tester.enterText(find.byKey(key), text);
    } else {
      await tester.enterText(find.byType(TextField), text);
    }
    await tester.pump();
  }

  // Navigation Helpers
  static Future<void> waitForNavigation(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  // Data Validation Helpers
  static void expectNumericValue(String expectedValue) {
    expect(find.text(expectedValue), findsOneWidget);
  }

  static void expectPriceDisplayed(double price) {
    final formattedPrice = 'R${price.toStringAsFixed(2)}';
    expect(find.text(formattedPrice), findsOneWidget);
  }

  // Error Handling Helpers
  static void expectErrorState(String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  static void expectLoadingState() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  }

  // Performance Helpers
  static Future<void> waitForAsyncOperation(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  // Clean Up Helpers
  static void disposeContainer(ProviderContainer container) {
    container.dispose();
  }
}

/// Custom Test Matchers
class CustomMatchers {
  static Matcher containsText(String text) {
    return find.descendant(
      of: find.byType(Text),
      matching: find.text(text),
    );
  }

  static Matcher hasWidgetOfType<T extends Widget>() {
    return find.byType(T);
  }

  static Matcher hasKey(Key key) {
    return find.byKey(key);
  }
}

/// Test Scenarios
enum TestScenario {
  normal,
  slowNetwork,
  noNetwork,
  serverError,
  emptyData,
}

class TestScenarioHelper {
  static void applyScenario(TestScenario scenario) {
    switch (scenario) {
      case TestScenario.normal:
        // Normal operation
        break;
      case TestScenario.slowNetwork:
        // Simulate slow network (add delays)
        break;
      case TestScenario.noNetwork:
        // Simulate no network
        break;
      case TestScenario.serverError:
        // Simulate server errors
        break;
      case TestScenario.emptyData:
        // Simulate empty data responses
        break;
    }
  }
}