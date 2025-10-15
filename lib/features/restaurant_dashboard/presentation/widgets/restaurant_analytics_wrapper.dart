import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_analytics_screen.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';

/// Wrapper widget that fetches the restaurant ID for the authenticated user
/// and displays the analytics screen
class RestaurantAnalyticsWrapper extends ConsumerStatefulWidget {
  const RestaurantAnalyticsWrapper({
    super.key,
    this.queryRestaurantId,
  });

  /// Optional restaurant ID from query parameters (for testing or direct access)
  final String? queryRestaurantId;

  @override
  ConsumerState<RestaurantAnalyticsWrapper> createState() =>
      _RestaurantAnalyticsWrapperState();
}

class _RestaurantAnalyticsWrapperState
    extends ConsumerState<RestaurantAnalyticsWrapper> {
  String? _restaurantId;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantId();
  }

  Future<void> _fetchRestaurantId() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Use query parameter if provided (for testing/development)
      if (widget.queryRestaurantId != null &&
          widget.queryRestaurantId!.isNotEmpty) {
        setState(() {
          _restaurantId = widget.queryRestaurantId;
          _isLoading = false;
        });
        return;
      }

      // Get current user ID
      final userId = DatabaseService().client.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      AppLogger.debug('Fetching restaurants for user: $userId');

      // Call the Supabase function to get user's restaurants
      final response = await DatabaseService()
          .client
          .rpc('get_user_restaurants', params: {'p_user_id': userId});

      AppLogger.debug('Restaurants response: $response');

      if (response == null || (response as List).isEmpty) {
        throw Exception(
            'No restaurant found for this user. Please register a restaurant first.');
      }

      // Get the first restaurant (primary owner's restaurant)
      final restaurants = response;
      final primaryRestaurant = restaurants.first;

      setState(() {
        _restaurantId = primaryRestaurant['restaurant_id'] as String;
        _isLoading = false;
      });

      AppLogger.success(
          'Restaurant ID fetched successfully: $_restaurantId');
    } catch (e, stack) {
      AppLogger.error('Failed to fetch restaurant ID',
          error: e, stack: stack);

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: LoadingIndicator(message: 'Loading restaurant data...'),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant Analytics'),
        ),
        body: Center(
          child: ErrorMessageWidget(
            message: _errorMessage!,
            onRetry: _fetchRestaurantId,
          ),
        ),
      );
    }

    if (_restaurantId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant Analytics'),
        ),
        body: Center(
          child: ErrorMessageWidget(
            message:
                'No restaurant found. Please register a restaurant to access analytics.',
          ),
        ),
      );
    }

    return RestaurantAnalyticsScreen(restaurantId: _restaurantId!);
  }
}
