import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('LoginScreen Widget Tests', () {
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

    testWidgets('displays login form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // Verify that the title is displayed
      expect(find.text('Welcome Back'), findsOneWidget);

      // Verify that email field is displayed
      expect(
        find.byType(TextField),
        findsNWidgets(2),
      ); // Email and password fields

      // Verify that login button is displayed
      expect(find.text('Sign In'), findsOneWidget);

      // Verify that sign up link is displayed
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows error message for invalid email', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextField).at(0), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      // Tap login button
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Verify that error message is displayed
      expect(find.text('Please enter a valid email'), findsWidgets);
    });

    testWidgets('shows error message for short password', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // Enter valid email and short password
      await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(1), '123');

      // Tap login button
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      // Verify that error message is displayed
      expect(find.text('Password must be at least 6 characters'), findsWidgets);
    });

    testWidgets('navigates to signup screen when sign up is tapped', (
      WidgetTester tester,
    ) async {
      bool navigatedToSignup = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/auth/signup') {
                navigatedToSignup = true;
                return MaterialPageRoute(
                  builder: (context) =>
                      Scaffold(appBar: AppBar(title: Text('Signup Screen'))),
                );
              }
              return null;
            },
          ),
        ),
      );

      // Tap sign up button
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToSignup, isTrue);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp(home: LoginScreen())),
      );

      // Find the password visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_outlined);

      // Initially should show visibility_off icon (password hidden)
      expect(visibilityButton, findsOneWidget);

      // Tap to show password
      await tester.tap(visibilityButton);
      await tester.pump();

      // Should now show visibility icon (password visible)
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}
