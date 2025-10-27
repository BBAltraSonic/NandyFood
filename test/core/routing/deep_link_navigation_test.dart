import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/main.dart' as app_main;

Widget _buildAppWithRouter({required GoRouter router}) {
  return MaterialApp.router(routerConfig: router);
}

void main() {
  testWidgets('navigateForPayload routes order:<id> to /order/track/:id', (tester) async {
    late GoRouter router;
    router = GoRouter(
      navigatorKey: app_main.rootNavigatorKey,
      initialLocation: '/dummy',
      routes: [
        GoRoute(path: '/dummy', builder: (_, __) => const Placeholder()),
        GoRoute(
          path: RoutePaths.orderTrackByIdPattern,
          builder: (_, state) => Text('Track ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(_buildAppWithRouter(router: router));
    await tester.pumpAndSettle();

    app_main.navigateForPayload('order:abc123');
    await tester.pumpAndSettle();

    expect(find.text('Track abc123'), findsOneWidget);
  });

  testWidgets('navigateForPayload routes /promotions to /promotions', (tester) async {
    late GoRouter router;
    router = GoRouter(
      navigatorKey: app_main.rootNavigatorKey,
      initialLocation: '/dummy',
      routes: [
        GoRoute(path: '/dummy', builder: (_, __) => const Placeholder()),
        GoRoute(path: RoutePaths.promotions, builder: (_, __) => const Text('Promotions')),
      ],
    );

    await tester.pumpWidget(_buildAppWithRouter(router: router));
    await tester.pumpAndSettle();

    app_main.navigateForPayload(RoutePaths.promotions);
    await tester.pumpAndSettle();

    expect(find.text('Promotions'), findsOneWidget);
  });

  testWidgets('navigateForPayload routes promo:<id> to /promo/:id', (tester) async {
    late GoRouter router;
    router = GoRouter(
      navigatorKey: app_main.rootNavigatorKey,
      initialLocation: '/dummy',
      routes: [
        GoRoute(path: '/dummy', builder: (_, __) => const Placeholder()),
        GoRoute(
          path: RoutePaths.promoByIdPattern,
          builder: (_, state) => Text('Promo ${state.pathParameters['id']}'),
        ),
      ],
    );

    await tester.pumpWidget(_buildAppWithRouter(router: router));
    await tester.pumpAndSettle();

    app_main.navigateForPayload('promo:ZX9');
    await tester.pumpAndSettle();

    expect(find.text('Promo ZX9'), findsOneWidget);
  });
}

