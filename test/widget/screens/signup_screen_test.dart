import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

void main() {
  group('SignupScreen Widget Tests', () {
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

    testWidgets('displays signup form correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Verify that the title is displayed
      expect(find.text('Create Account'), findsOneWidget);

      // Verify that form fields are displayed
      expect(find.byType(TextField), findsNWidgets(4)); // Name, email, password, confirm password

      // Verify that signup button is displayed
      expect(find.text('Sign Up'), findsOneWidget);

      // Verify that sign in link is displayed
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('shows error message for invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Enter invalid email
      await tester.enterText(find.byType(TextField).at(1), 'invalid-email');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'password123');

      // Tap signup button
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Verify that error message is displayed
      expect(find.text('Please enter a valid email'), findsWidgets);
    });

    testWidgets('shows error message for short password', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Enter valid info with short password
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(2), '123');
      await tester.enterText(find.byType(TextField).at(3), '123');

      // Tap signup button
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Verify that error message is displayed
      expect(find.text('Password must be at least 6 characters'), findsWidgets);
    });

    testWidgets('shows error message for password mismatch', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Enter passwords that don't match
      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'differentpassword');

      // Tap signup button
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      // Verify that error message is displayed
      expect(find.text('Passwords do not match'), findsWidgets);
    });

    testWidgets('navigates to login screen when sign in is tapped', (WidgetTester tester) async {
      bool navigatedToLogin = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/auth/login') {
                navigatedToLogin = true;
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

      // Tap sign in button
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      // Verify that navigation occurred
      expect(navigatedToLogin, isTrue);
    });

    testWidgets('toggles password visibility', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );

      // Find the password visibility toggle buttons
      final visibilityButtons = find.byIcon(Icons.visibility_outlined);
      
      // Should have two visibility buttons (for password and confirm password)
      expect(visibilityButtons, findsNWidgets(2));

      // Tap first visibility button to show password
      await tester.tap(visibilityButtons.at(0));
      await tester.pump();

      // Should now show visibility_off icon for first password field
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });
  });
}