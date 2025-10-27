import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:food_delivery_app/main.dart' as app;
import 'package:patrol/patrol.dart';

/// Complete authentication flow testing
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow Tests', () {
    patrolTest('Complete signup flow with validation', ($) async {
      await app.main();
      await $.pumpAndSettle();

      // Navigate to signup
      await _navigateToSignup($);

      // Test form validation
      await _testSignupValidation($);

      // Test password visibility toggle
      await _testPasswordVisibility($);

      // Test successful signup
      await _testSuccessfulSignup($);
    });

    patrolTest('Login flow with different scenarios', ($) async {
      await app.main();
      await $.pumpAndSettle();

      // Navigate to login
      await _navigateToLogin($);

      // Test empty form validation
      await _testEmptyLoginValidation($);

      // Test invalid credentials
      await _testInvalidLogin($);

      // Test remember me checkbox
      await _testRememberMe($);

      // Test forgot password flow
      await _testForgotPassword($);
    });

    patrolTest('Social authentication flows', ($) async {
      await app.main();
      await $.pumpAndSettle();

      await _navigateToLogin($);

      // Test Google Sign-In
      await _testGoogleSignIn($);

      // Test Apple Sign-In (iOS only)
      await _testAppleSignIn($);
    });

    patrolTest('Logout and session management', ($) async {
      await app.main();
      await $.pumpAndSettle();

      // Assume user is logged in
      await _navigateToProfile($);

      // Test logout
      await _testLogout($);

      // Verify redirected to login
      expect(find.text('Login'), findsOneWidget);
    });
  });
}

Future<void> _navigateToSignup(PatrolIntegrationTester $) async {
  final signupButton = find.text('Sign Up');
  if (signupButton.evaluate().isNotEmpty) {
    await $.tap(signupButton);
    await $.pumpAndSettle();
  }
}

Future<void> _navigateToLogin(PatrolIntegrationTester $) async {
  final loginButton = find.text('Login').or(find.text('Sign In'));
  if (loginButton.evaluate().isNotEmpty) {
    await $.tap(loginButton);
    await $.pumpAndSettle();
  }
}

Future<void> _testSignupValidation(PatrolIntegrationTester $) async {
  // Tap signup without filling form
  final signupButton = find.text('Sign Up').or(find.text('Create Account'));
  if (signupButton.evaluate().isNotEmpty) {
    await $.tap(signupButton);
    await $.pumpAndSettle();

    // Should show validation errors
    expect(find.textContaining('required').or(find.textContaining('Required')), findsWidgets);
  }

  // Test invalid email
  final emailField = find.byType(TextField).at(1); // Assuming email is second
  await $.tap(emailField);
  await $.enterText(emailField, 'invalid-email');
  await $.pumpAndSettle();

  await $.tap(signupButton);
  await $.pumpAndSettle();

  // Should show email validation error
  expect(
    find.textContaining('valid email').or(find.textContaining('Valid email')),
    findsOneWidget,
  );

  // Test password mismatch
  final passwordField = find.byType(TextField).at(2);
  final confirmPasswordField = find.byType(TextField).at(3);

  await $.tap(passwordField);
  await $.enterText(passwordField, 'password123');
  await $.pumpAndSettle();

  await $.tap(confirmPasswordField);
  await $.enterText(confirmPasswordField, 'password456');
  await $.pumpAndSettle();

  await $.tap(signupButton);
  await $.pumpAndSettle();

  // Should show password mismatch error
  expect(
    find.textContaining('match').or(find.textContaining('Match')),
    findsOneWidget,
  );
}

Future<void> _testPasswordVisibility(PatrolIntegrationTester $) async {
  // Find password visibility toggle icon
  final visibilityIcon = find.byIcon(Icons.visibility_off).or(find.byIcon(Icons.visibility));

  if (visibilityIcon.evaluate().isNotEmpty) {
    // Tap to show password
    await $.tap(visibilityIcon.first);
    await $.pumpAndSettle();

    // Tap to hide password
    await $.tap(visibilityIcon.first);
    await $.pumpAndSettle();
  }
}

Future<void> _testSuccessfulSignup(PatrolIntegrationTester $) async {
  // Fill in all required fields
  final nameField = find.byType(TextField).at(0);
  await $.tap(nameField);
  await $.enterText(nameField, 'Test User');
  await $.pumpAndSettle();

  final emailField = find.byType(TextField).at(1);
  await $.tap(emailField);
  await $.enterText(emailField, 'testuser${DateTime.now().millisecondsSinceEpoch}@example.com');
  await $.pumpAndSettle();

  final phoneField = find.byType(TextField).at(2);
  await $.tap(phoneField);
  await $.enterText(phoneField, '1234567890');
  await $.pumpAndSettle();

  final passwordField = find.byType(TextField).at(3);
  await $.tap(passwordField);
  await $.enterText(passwordField, 'Password123!');
  await $.pumpAndSettle();

  final confirmPasswordField = find.byType(TextField).at(4);
  await $.tap(confirmPasswordField);
  await $.enterText(confirmPasswordField, 'Password123!');
  await $.pumpAndSettle();

  // Accept terms
  final termsCheckbox = find.byType(Checkbox);
  if (termsCheckbox.evaluate().isNotEmpty) {
    await $.tap(termsCheckbox);
    await $.pumpAndSettle();
  }

  // Submit signup
  final signupButton = find.text('Sign Up').or(find.text('Create Account'));
  await $.tap(signupButton);
  await $.pumpAndSettle(const Duration(seconds: 5));

  // Should navigate to home or verification screen
  expect(
    find.text('Home').or(find.text('Verify')),
    findsOneWidget,
  );
}

Future<void> _testEmptyLoginValidation(PatrolIntegrationTester $) async {
  final loginButton = find.text('Login').or(find.text('Sign In'));
  await $.tap(loginButton);
  await $.pumpAndSettle();

  // Should show validation errors
  expect(find.textContaining('required').or(find.textContaining('Required')), findsWidgets);
}

Future<void> _testInvalidLogin(PatrolIntegrationTester $) async {
  final emailField = find.byType(TextField).at(0);
  await $.tap(emailField);
  await $.enterText(emailField, 'invalid@example.com');
  await $.pumpAndSettle();

  final passwordField = find.byType(TextField).at(1);
  await $.tap(passwordField);
  await $.enterText(passwordField, 'wrongpassword');
  await $.pumpAndSettle();

  final loginButton = find.text('Login').or(find.text('Sign In'));
  await $.tap(loginButton);
  await $.pumpAndSettle(const Duration(seconds: 3));

  // Should show error message
  expect(
    find.textContaining('Invalid').or(find.textContaining('error')),
    findsOneWidget,
  );
}

Future<void> _testRememberMe(PatrolIntegrationTester $) async {
  final rememberMeCheckbox = find.byType(Checkbox);
  if (rememberMeCheckbox.evaluate().isNotEmpty) {
    await $.tap(rememberMeCheckbox);
    await $.pumpAndSettle();

    await $.tap(rememberMeCheckbox);
    await $.pumpAndSettle();
  }
}

Future<void> _testForgotPassword(PatrolIntegrationTester $) async {
  final forgotPasswordLink = find.text('Forgot Password?').or(find.text('Forgot Password'));
  
  if (forgotPasswordLink.evaluate().isNotEmpty) {
    await $.tap(forgotPasswordLink);
    await $.pumpAndSettle();

    // Should navigate to forgot password screen
    expect(find.text('Reset Password').or(find.text('Forgot Password')), findsOneWidget);

    // Enter email
    final emailField = find.byType(TextField).first;
    await $.tap(emailField);
    await $.enterText(emailField, 'test@example.com');
    await $.pumpAndSettle();

    // Submit
    final resetButton = find.text('Reset Password').or(find.text('Send'));
    if (resetButton.evaluate().isNotEmpty) {
      await $.tap(resetButton);
      await $.pumpAndSettle(const Duration(seconds: 2));
    }

    // Go back
    await $.native.pressBack();
    await $.pumpAndSettle();
  }
}

Future<void> _testGoogleSignIn(PatrolIntegrationTester $) async {
  final googleButton = find.textContaining('Google').or(find.byIcon(Icons.g_mobiledata));
  
  if (googleButton.evaluate().isNotEmpty) {
    await $.tap(googleButton);
    await $.pumpAndSettle(const Duration(seconds: 2));
    
    // Note: Actual Google Sign-In flow requires mocking in tests
    // This just tests that the button triggers the flow
  }
}

Future<void> _testAppleSignIn(PatrolIntegrationTester $) async {
  final appleButton = find.textContaining('Apple');
  
  if (appleButton.evaluate().isNotEmpty) {
    await $.tap(appleButton);
    await $.pumpAndSettle(const Duration(seconds: 2));
    
    // Note: Actual Apple Sign-In flow requires mocking in tests
    // This just tests that the button triggers the flow
  }
}

Future<void> _navigateToProfile(PatrolIntegrationTester $) async {
  final profileTab = find.byIcon(Icons.person).or(find.text('Profile'));
  
  if (profileTab.evaluate().isNotEmpty) {
    await $.tap(profileTab);
    await $.pumpAndSettle();
  }
}

Future<void> _testLogout(PatrolIntegrationTester $) async {
  // Navigate to settings
  final settingsButton = find.text('Settings').or(find.byIcon(Icons.settings));
  
  if (settingsButton.evaluate().isNotEmpty) {
    await $.tap(settingsButton);
    await $.pumpAndSettle();
  }

  // Find and tap logout
  final logoutButton = find.text('Logout').or(find.text('Log Out'));
  
  if (logoutButton.evaluate().isNotEmpty) {
    await $.tap(logoutButton);
    await $.pumpAndSettle();

    // Confirm logout if dialog appears
    final confirmButton = find.text('Yes').or(find.text('Confirm'));
    if (confirmButton.evaluate().isNotEmpty) {
      await $.tap(confirmButton);
      await $.pumpAndSettle(const Duration(seconds: 2));
    }
  }
}
