import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/restaurant_session_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../screens/restaurant_analytics_screen.dart';

/// Wrapper widget for RestaurantAnalyticsScreen that uses session-based restaurant ID
class RestaurantAnalyticsSessionWrapper extends ConsumerWidget {
  const RestaurantAnalyticsSessionWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(restaurantSessionProvider);

    // Show loading state
    if (sessionState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error state
    if (sessionState.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.black87,
              ),
              const SizedBox(height: 16),
              Text(
                'Error Loading Restaurant',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  sessionState.error!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(restaurantSessionProvider.notifier).refresh();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/restaurant/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if restaurant session exists
    if (!sessionState.hasRestaurant || sessionState.restaurantId == null) {
      AppLogger.warning('No restaurant session found, redirecting to registration');

      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.store_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                'No Restaurant Found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You need to register a restaurant before accessing analytics.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/restaurant/register'),
                icon: const Icon(Icons.add_business),
                label: const Text('Register Restaurant'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user has analytics permission
    if (!sessionState.canViewAnalytics) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 64,
                color: Colors.black87,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'You do not have permission to view analytics.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/restaurant/dashboard'),
                child: const Text('Back to Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    // All checks passed, show analytics screen
    AppLogger.info('Loading analytics for restaurant: ${sessionState.restaurantId}');

    return RestaurantAnalyticsScreen(
      restaurantId: sessionState.restaurantId!,
    );
  }
}
