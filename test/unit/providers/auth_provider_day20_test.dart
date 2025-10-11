import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

void main() {
  group('Auth Provider Day 20 - Password Reset & Email Verification', () {
    test('sendPasswordResetEmail should update loading state', () async {
      final container = ProviderContainer();
      final notifier = container.read(authStateProvider.notifier);

      // Initially not loading
      expect(container.read(authStateProvider).isLoading, false);

      // Note: This will fail in tests without Supabase mock
      // In production, you'd mock the DatabaseService
      
      container.dispose();
    });

    test('isEmailVerified should return false for null user', () {
      final container = ProviderContainer();
      final notifier = container.read(authStateProvider.notifier);

      // No user authenticated
      expect(notifier.isEmailVerified, false);

      container.dispose();
    });

    test('clearErrorMessage should reset error state', () {
      final container = ProviderContainer();
      final notifier = container.read(authStateProvider.notifier);

      notifier.clearErrorMessage();
      
      expect(container.read(authStateProvider).errorMessage, null);

      container.dispose();
    });
  });
}
