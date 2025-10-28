import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/routing/app_router.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/signup_screen.dart';
import 'package:food_delivery_app/features/home/presentation/screens/home_screen.dart';

void main() {
  group('Authentication Flow Integration Tests', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      container = ProviderContainer();
      router = AppRouter.createRouter(container);
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('Complete authentication flow should work', (WidgetTester tester) async {
      // Build app with router
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Verify we start at login screen (when not authenticated)
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);

      // Test sign up flow
      await tester.tap(find.text('Don\'t have an account? Sign Up'));
      await tester.pumpAndSettle();

      // Should be on signup screen
      expect(find.byType(SignupScreen), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);

      // Fill in signup form
      await tester.enterText(find.byKey(const Key('name_field')), 'Test User');
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('phone_field')), '+1234567890');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');
      await tester.enterText(find.byKey(const Key('confirm_password_field')), 'password123');

      // Attempt signup (this will fail in test environment, but we test UI flow)
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should remain on signup screen if signup fails (expected in test env)
      expect(find.byType(SignupScreen), findsOneWidget);
    });

    testWidgets('Login flow should navigate correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Should start at login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Fill in login form
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'password123');

      // Test forgot password navigation
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Should show forgot password dialog/screen
      expect(find.text('Reset Password'), findsOneWidget);

      // Close forgot password
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Back to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Auth state changes should trigger navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Initially on login screen
      expect(find.byType(LoginScreen), findsOneWidget);

      // Simulate successful authentication
      // Note: In real tests, you'd mock the auth service to return success
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'test_user_123',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpAndSettle();

      // Should navigate to home screen after successful auth
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Welcome, Test User!'), findsOneWidget);
    });

    testWidgets('Logout should return to login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Simulate authenticated state
      container.read(authStateProvider.notifier).setAuthenticatedUser(
        userId: 'test_user_123',
        email: 'test@example.com',
        name: 'Test User',
      );

      await tester.pumpAndSettle();

      // Should be on home screen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Find and tap profile/logout button
      await tester.tap(find.byIcon(Icons.account_circle));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Should return to login screen
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Error states should be handled gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Try to login with empty fields
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      // Fill email but leave password empty
      await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show password error only
      expect(find.text('Please enter your password'), findsOneWidget);
      expect(find.text('Please enter your email'), findsNothing);
    });
  });
}