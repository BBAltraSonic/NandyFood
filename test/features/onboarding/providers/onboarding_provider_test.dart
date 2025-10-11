import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/onboarding/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingProvider', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state should be loading', () {
      final container = ProviderContainer();
      final state = container.read(onboardingCompletedProvider);

      expect(state, isA<AsyncLoading>());
      container.dispose();
    });

    test('completeOnboarding should set state to true', () async {
      final container = ProviderContainer();
      final notifier = container.read(onboardingCompletedProvider.notifier);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      // Complete onboarding
      await notifier.completeOnboarding();

      final state = container.read(onboardingCompletedProvider);
      expect(state.value, true);

      container.dispose();
    });

    test('resetOnboarding should set state to false', () async {
      final container = ProviderContainer();
      final notifier = container.read(onboardingCompletedProvider.notifier);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      // Complete then reset onboarding
      await notifier.completeOnboarding();
      await notifier.resetOnboarding();

      final state = container.read(onboardingCompletedProvider);
      expect(state.value, false);

      container.dispose();
    });

    test('onboarding status should persist across sessions', () async {
      // First session - complete onboarding
      var container = ProviderContainer();
      var notifier = container.read(onboardingCompletedProvider.notifier);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.completeOnboarding();
      container.dispose();

      // Second session - should remember completion
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));
      final state = container.read(onboardingCompletedProvider);
      expect(state.value, true);

      container.dispose();
    });

    test('onboardingPageIndexProvider should start at 0', () {
      final container = ProviderContainer();
      final index = container.read(onboardingPageIndexProvider);

      expect(index, 0);
      container.dispose();
    });

    test('onboardingPageIndexProvider should update correctly', () {
      final container = ProviderContainer();

      container.read(onboardingPageIndexProvider.notifier).state = 2;
      final index = container.read(onboardingPageIndexProvider);

      expect(index, 2);
      container.dispose();
    });
  });
}
