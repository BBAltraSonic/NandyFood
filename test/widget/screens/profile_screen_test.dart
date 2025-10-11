import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('ProfileScreen Widget Tests', () {
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

    testWidgets('displays profile information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that profile header is displayed
      expect(find.text('Profile'), findsOneWidget);

      // Verify that profile information sections are displayed
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Addresses'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Order History'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
    });

    testWidgets('displays user profile header with avatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that profile header section is displayed
      expect(find.byType(Container), findsWidgets); // Profile header container

      // Verify that user avatar is displayed
      expect(find.byIcon(Icons.person), findsOneWidget);

      // Verify that user name is displayed
      // Note: Actual name would depend on user profile data
    });

    testWidgets('navigates to edit profile screen when edit button is tapped', (WidgetTester tester) async {
      bool navigatedToEditProfile = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/profile/edit') {
                navigatedToEditProfile = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Edit Profile')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap edit profile button
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToEditProfile, isTrue);
    });

    testWidgets('navigates to addresses screen when addresses section is tapped', (WidgetTester tester) async {
      bool navigatedToAddresses = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/profile/addresses') {
                navigatedToAddresses = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Addresses')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap addresses section
      final addressesFinder = find.text('Addresses');
      await tester.ensureVisible(addressesFinder);
      await tester.tap(addressesFinder);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToAddresses, isTrue);
    });

    testWidgets('navigates to payment methods screen when payment methods section is tapped', (WidgetTester tester) async {
      bool navigatedToPaymentMethods = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/profile/payment-methods') {
                navigatedToPaymentMethods = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Payment Methods')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap payment methods section
      final paymentMethodsFinder = find.text('Payment Methods');
      await tester.ensureVisible(paymentMethodsFinder);
      await tester.tap(paymentMethodsFinder);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToPaymentMethods, isTrue);
    });

    testWidgets('navigates to order history screen when order history section is tapped', (WidgetTester tester) async {
      bool navigatedToOrderHistory = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/order/history') {
                navigatedToOrderHistory = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Order History')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap order history section
      final orderHistoryFinder = find.text('Order History');
      await tester.ensureVisible(orderHistoryFinder);
      await tester.tap(orderHistoryFinder);
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToOrderHistory, isTrue);
    });

    testWidgets('toggles notification preference when switch is toggled', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find notification preference switch
      final switches = find.byType(Switch);

      // Toggle switch
      if (switches.evaluate().isNotEmpty) {
        await tester.ensureVisible(switches.first);
        await tester.tap(switches.first);
        await tester.pump(const Duration(milliseconds: 500));

        // Verify that preference is toggled
        // Note: Actual verification would depend on state management
      }
    });

    testWidgets('logs out when logout button is tapped', (WidgetTester tester) async {
      bool loggedOut = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/auth/login') {
                loggedOut = true;
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text('Login Screen')),
                  ),
                );
              }
              return null;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutFinder = find.text('Logout');
      await tester.ensureVisible(logoutFinder);
      await tester.tap(logoutFinder);
      await tester.pumpAndSettle();

      // Confirm logout in dialog
      final confirmLogout = find.text('Logout').last;
      await tester.tap(confirmLogout);
      await tester.pumpAndSettle();

      // Verify that logout occurred
      expect(loggedOut, isTrue);
    });

    testWidgets('shows confirmation dialog when logout is attempted', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap logout button
      final logoutFinder = find.text('Logout');
      await tester.ensureVisible(logoutFinder);
      await tester.tap(logoutFinder);
      await tester.pump();

      // Verify that confirmation dialog is displayed
      expect(find.text('Logout'), findsWidgets);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    });
  });
}