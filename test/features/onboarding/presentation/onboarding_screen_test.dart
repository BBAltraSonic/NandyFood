import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:food_delivery_app/features/onboarding/models/onboarding_page_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingScreen', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('should display first onboarding page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      // Wait for animations
      await tester.pumpAndSettle();

      // Check if first page content is displayed
      expect(find.text('Discover Great Food'), findsOneWidget);
      expect(
        find.text(
          'Browse through hundreds of restaurants and find your favorite dishes with our interactive map view',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should show Skip button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('should show Next button on first page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('should show page indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have page indicators equal to number of onboarding pages
      final pageIndicators = find.byType(AnimatedContainer);
      expect(
        pageIndicators,
        findsNWidgets(OnboardingPages.pages.length),
      );
    });

    testWidgets('should navigate to next page when Next is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify we're on first page
      expect(find.text('Discover Great Food'), findsOneWidget);

      // Tap Next button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on second page now
      expect(find.text('Order with Ease'), findsOneWidget);
    });

    testWidgets('should navigate back when back button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to second page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Order with Ease'), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should be back on first page
      expect(find.text('Discover Great Food'), findsOneWidget);
    });

    testWidgets('should show Get Started on last page', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < OnboardingPages.pages.length - 1; i++) {
        await tester.tap(find.text(i == OnboardingPages.pages.length - 2 ? 'Next' : 'Next'));
        await tester.pumpAndSettle();
      }

      // Last page should show "Get Started" instead of "Next"
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });

    testWidgets('should allow swiping between pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Discover Great Food'), findsOneWidget);

      // Swipe left to go to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Order with Ease'), findsOneWidget);
    });
  });
}
