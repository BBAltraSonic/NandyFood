import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/features/order/presentation/screens/payment_result_screen.dart';

Widget _buildAppWithRouter({required GoRouter router}) {
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('PaymentResultScreen - success flow', () {
    testWidgets('shows success actions and navigates correctly', (tester) async {
      const orderId = '123';
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/result',
            builder: (context, state) => const PaymentResultScreen(
              orderId: orderId,
              success: true,
              paymentReference: 'ref-1',
            ),
          ),
          GoRoute(path: RoutePaths.home, builder: (_, __) => const Text('Home')),
          GoRoute(
            path: RoutePaths.orderTrackByIdPattern,
            builder: (_, state) => Text('Track ${state.pathParameters['id']}'),
          ),
        ],
      );

      await tester.pumpWidget(_buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Track Order button navigates to /order/track/:id
      await tester.tap(find.text('Track Order'));
      await tester.pumpAndSettle();
      expect(find.text('Track $orderId'), findsOneWidget);

      // Navigate back to result to test second CTA
      router.go('/result');
      await tester.pumpAndSettle();

      // Back to Home navigates to /home
      await tester.tap(find.text('Back to Home'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });

  group('PaymentResultScreen - failure flow', () {
    testWidgets('shows failure actions and navigates correctly', (tester) async {
      late GoRouter router;
      router = GoRouter(
        initialLocation: '/result',
        routes: [
          GoRoute(
            path: '/result',
            builder: (context, state) => const PaymentResultScreen(
              orderId: 'o-1',
              success: false,
              errorMessage: 'Payment verification failed',
            ),
          ),
          GoRoute(path: RoutePaths.home, builder: (_, __) => const Text('Home')),
          GoRoute(path: RoutePaths.orderCart, builder: (_, __) => const Text('Cart')),
        ],
      );

      await tester.pumpWidget(_buildAppWithRouter(router: router));
      await tester.pumpAndSettle();

      // Try Again -> /order/cart
      await tester.tap(find.text('Try Again'));
      await tester.pumpAndSettle();
      expect(find.text('Cart'), findsOneWidget);

      // Back to result to test other actions
      router.go('/result');
      await tester.pumpAndSettle();

      // Use Different Method -> /order/cart
      await tester.tap(find.text('Use Different Method'));
      await tester.pumpAndSettle();
      expect(find.text('Cart'), findsOneWidget);

      // Back to result again
      router.go('/result');
      await tester.pumpAndSettle();

      // Cancel -> /home
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}

