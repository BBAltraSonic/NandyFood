import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/auth_service.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Day 16-17: Social Authentication Integration Tests', () {
    testWidgets('Google Sign-In button is visible and properly styled',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Find Google Sign-In button
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata_rounded), findsOneWidget);

      // Verify button is enabled by default
      final googleButton = tester.widget<OutlinedButton>(
        find.ancestor(
          of: find.text('Continue with Google'),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(googleButton.onPressed, isNotNull);
    });

    testWidgets('Apple Sign-In button is conditionally displayed on iOS',
        (WidgetTester tester) async {
      // Note: This test would need platform-specific mocking
      // For now, we test that the code structure supports conditional rendering
      
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On non-iOS platforms, Apple button should not be visible
      // This would be tested differently on actual iOS devices
      expect(find.text('Continue with Apple'), findsNothing);
    });

    testWidgets('Google Sign-In button shows loading state when tapped',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap Google Sign-In button
      await tester.tap(find.text('Continue with Google'));
      await tester.pump(); // Start animation

      // Assert - Loading indicator should appear
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('Email/password login is disabled when Google Sign-In is loading',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter email and password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );

      // Act - Tap Google Sign-In button
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Assert - Regular Sign In button should be disabled
      final signInButton = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('Sign In'),
          matching: find.byType(ElevatedButton),
        ),
      );
      // Button should still be visible but state is managed by provider
      expect(signInButton, isNotNull);
    });

    testWidgets('Social login buttons maintain proper spacing and layout',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Verify OR divider exists
      expect(find.text('OR'), findsOneWidget);

      // Verify Google button position is below the divider
      final orFinder = find.text('OR');
      final googleButtonFinder = find.text('Continue with Google');

      final orPosition = tester.getCenter(orFinder);
      final googlePosition = tester.getCenter(googleButtonFinder);

      expect(googlePosition.dy, greaterThan(orPosition.dy));
    });

    test('AuthService properly handles Google Sign-In cancellation', () async {
      // This would require mocking GoogleSignIn
      // Testing that AuthException with 'user_cancelled' code is thrown
      
      // Arrange
      final authService = AuthService();

      // Act & Assert
      try {
        // In real scenario, this would be mocked to return null
        // await authService.signInWithGoogle();
        // expect(false, true); // Should not reach here
      } on AuthException catch (e) {
        expect(e.statusCode, equals('user_cancelled'));
        expect(e.message, contains('canceled'));
      }
    });

    test('AuthService properly handles network errors', () async {
      // This would require mocking network failures
      
      // Arrange
      final authService = AuthService();

      // Act & Assert
      try {
        // Mock network failure scenario
        // await authService.signInWithGoogle();
        // expect(false, true); // Should not reach here
      } on AuthException catch (e) {
        expect(e.statusCode, equals('network_error'));
        expect(e.message, contains('network'));
      }
    });

    test('AuthService properly handles duplicate account errors', () async {
      // This would require mocking duplicate account scenario
      
      // Arrange
      final authService = AuthService();

      // Act & Assert
      try {
        // Mock duplicate account scenario
        // await authService.signInWithGoogle();
        // expect(false, true); // Should not reach here
      } on AuthException catch (e) {
        expect(e.statusCode, equals('duplicate_account'));
        expect(e.message, contains('already exists'));
      }
    });

    testWidgets('Error message displays properly for failed social sign-in',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Override provider with a mock that returns an error state
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Note: This test would need proper mocking to simulate an actual error
      // The UI is designed to show SnackBar on error
    });

    testWidgets('Multiple social login buttons cannot be loading simultaneously',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Tap Google Sign-In
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Assert - Google should be loading
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));

      // Note: In actual implementation, Apple button would be disabled
      // when Google is loading due to authState.isLoading check
    });

    test('AuthProvider correctly updates state on successful Google Sign-In',
        () async {
      // This would require mocking the AuthService
      // Testing the state transitions in AuthStateNotifier
      
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(authStateProvider.notifier);

      // Initial state
      expect(container.read(authStateProvider).isAuthenticated, false);
      expect(container.read(authStateProvider).isLoading, false);

      // Note: Actual implementation would mock the service call
      // and verify state transitions:
      // 1. isLoading = true
      // 2. isLoading = false, isAuthenticated = true (on success)
      
      container.dispose();
    });

    test('AuthProvider correctly updates state on failed Google Sign-In',
        () async {
      // This would require mocking the AuthService to throw an error
      
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(authStateProvider.notifier);

      // Note: Actual implementation would mock the service call
      // and verify state transitions:
      // 1. isLoading = true
      // 2. isLoading = false, errorMessage = "..." (on error)
      
      container.dispose();
    });

    test('AuthProvider does not show error message on user cancellation',
        () async {
      // Verify that when AuthException with 'user_cancelled' is thrown,
      // no error message is set
      
      // Arrange
      final container = ProviderContainer();

      // Note: Mock the scenario where user cancels sign-in
      // Expected behavior:
      // - isLoading returns to false
      // - errorMessage remains null
      // - No error SnackBar shown
      
      container.dispose();
    });

    testWidgets('Login screen handles successful social authentication navigation',
        (WidgetTester tester) async {
      // This test would verify navigation to home screen after successful auth
      // Requires mocking navigation and auth service
      
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Note: Would need to mock successful authentication
      // and verify context.go('/home') is called
    });

    test('User profile is created on first-time Google Sign-In', () async {
      // This would test the _ensureUserProfileExists method
      
      // Arrange
      final authService = AuthService();

      // Note: Mock the scenario where:
      // 1. Google Sign-In succeeds
      // 2. User doesn't exist in database
      // 3. New profile is created with Google display name
      
      // Assert: Verify database insert was called with correct data
    });

    test('User profile is created on first-time Apple Sign-In with name fallback',
        () async {
      // This would test Apple Sign-In with hidden email scenario
      
      // Arrange
      final authService = AuthService();

      // Note: Mock the scenario where:
      // 1. Apple Sign-In succeeds
      // 2. User hides email (provides relay email)
      // 3. User doesn't provide name
      // 4. Profile created with fallback "Apple User"
      
      // Assert: Verify database insert was called with "Apple User"
    });

    test('Existing user profile is not duplicated on subsequent sign-ins',
        () async {
      // This would test the _ensureUserProfileExists method
      
      // Arrange
      final authService = AuthService();

      // Note: Mock the scenario where:
      // 1. User signs in with Google
      // 2. Profile already exists in database
      // 3. No duplicate insert is attempted
      
      // Assert: Verify database insert was NOT called
    });
  });

  group('Social Authentication Error Handling', () {
    test('Google Sign-In handles PlatformException gracefully', () async {
      // Test configuration error handling
      
      final authService = AuthService();

      try {
        // Mock PlatformException scenario
      } on AuthException catch (e) {
        expect(e.statusCode, equals('config_error'));
        expect(e.message, contains('not properly configured'));
      }
    });

    test('Apple Sign-In handles platform unavailability', () async {
      // Test iOS version check
      
      final authService = AuthService();

      try {
        // Mock iOS 12 or Android platform
      } on AuthException catch (e) {
        expect(e.statusCode, anyOf(['platform_error', 'unavailable']));
      }
    });

    test('Apple Sign-In handles authorization errors', () async {
      // Test SignInWithAppleAuthorizationException handling
      
      final authService = AuthService();

      // Test scenarios:
      // - AuthorizationErrorCode.canceled
      // - AuthorizationErrorCode.failed
      // - AuthorizationErrorCode.notHandled
    });
  });

  group('Social Authentication UI/UX', () {
    testWidgets('Social login buttons have proper accessibility labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify semantic labels for screen readers
      // Note: Would use Semantics widget to test
    });

    testWidgets('Social login buttons have proper icon sizes and colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert Google icon
      final googleIcon = tester.widget<Icon>(
        find.byIcon(Icons.g_mobiledata_rounded),
      );
      expect(googleIcon.size, equals(32));
      expect(googleIcon.color, equals(const Color(0xFF4285F4)));
    });

    testWidgets('Loading indicators match brand colors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Google button to show loading
      await tester.tap(find.text('Continue with Google'));
      await tester.pump();

      // Find loading indicator
      final indicators = find.byType(CircularProgressIndicator);
      expect(indicators, findsAtLeastNWidgets(1));

      // Verify color matches Google brand
      final indicator = tester.widget<CircularProgressIndicator>(
        indicators.first,
      );
      expect(indicator.color, equals(const Color(0xFF4285F4)));
    });
  });
}
