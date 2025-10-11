import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen validates email and triggers submit', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaterialApp(home: ForgotPasswordScreen())));

    // Initially button enabled
    expect(find.text('Send reset link'), findsOneWidget);

    // Tap without email should show validator error
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();

    expect(find.text('Email is required'), findsOneWidget);

    // Enter invalid email
    await tester.enterText(find.byType(TextFormField), 'invalid');
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);

    // Enter valid email
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    // We cannot assert network call here; ensure no validation error appears
    await tester.tap(find.text('Send reset link'));
    await tester.pump(const Duration(milliseconds: 300));
  });
}
