import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/location_service.dart';
import 'package:food_delivery_app/core/utils/location_utils.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'dart:async';

// Location-aware restaurant state
class HomeRestaurantState {
  final List<Restaurant> popularRestaurants;
  final List<Restaurant> featuredRestaurants;
  final List<Restaurant> nearbyRestaurants;
  final Position? userLocation;
  final bool isLoading;
  final bool isLocationLoading;
  final String? errorMessage;
  final String? locationError;
  final bool hasLocationPermission;
  final Map<String, dynamic> userPreferences;
  final DateTime? lastUpdated;
  final int popularRestaurantsCount;
  final int featuredRestaurantsCount;
  final int nearbyRestaurantsCount;

  const HomeRestaurantState({
    this.popularRestaurants = const [],
    this.featuredRestaurants = const [],
    this.nearbyRestaurants = const [],
    this.userLocation,
    this.isLoading = false,
    this.isLocationLoading = false,
    this.errorMessage,
    this.locationError,
    this.hasLocationPermission = false,
    this.userPreferences = const {},
    this.lastUpdated,
    this.popularRestaurantsCount = 0,
    this.featuredRestaurantsCount = 0,
    this.nearbyRestaurantsCount = 0,
  });

  HomeRestaurantState copyWith({
    List<Restaurant>? popularRestaurants,
    List<Restaurant>? featuredRestaurants,
    List<Restaurant>? nearbyRestaurants,
    Position? userLocation,
    bool? isLoading,
    bool? isLocationLoading,
    String? errorMessage,
    String? locationError,
    bool? hasLocationPermission,
    Map<String, dynamic>? userPreferences,
    DateTime? lastUpdated,
    int? popularRestaurantsCount,
    int? featuredRestaurantsCount,
    int? nearbyRestaurantsCount,
  }) {
    return HomeRestaurantState(
      popularRestaurants: popularRestaurants ?? this.popularRestaurants,
      featuredRestaurants: featuredRestaurants ?? this.featuredRestaurants,
      nearbyRestaurants: nearbyRestaurants ?? this.nearbyRestaurants,
      userLocation: userLocation ?? this.userLocation,
      isLoading: isLoading ?? this.isLoading,
      isLocationLoading: isLocationLoading ?? this.isLocationLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      locationError: locationError ?? this.locationError,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      userPreferences: userPreferences ?? this.userPreferences,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      popularRestaurantsCount: popularRestaurantsCount ?? this.popularRestaurantsCount,
      featuredRestaurantsCount: featuredRestaurantsCount ?? this.featuredRestaurantsCount,
      nearbyRestaurantsCount: nearbyRestaurantsCount ?? this.nearbyRestaurantsCount,
    );
  }
}

class HomeRestaurantNotifier extends StateNotifier<HomeRestaurantState> {
  final DatabaseService _dbService = DatabaseService();
  final LocationService _locationService = LocationService();
  StreamSubscription<Position>? _locationSubscription;
  RealtimeChannel? _restaurantSubscription;
  Timer? _refreshTimer;

  bool _isDisposed = false;
  bool _isInitializing = false;

  HomeRestaurantNotifier() : super(const HomeRestaurantState()) {
    _initializePeriodicRefresh();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupResources();
    super.dispose();
  }

  // Enhanced resource cleanup with error handling
  void _cleanupResources() {
    try {
      _locationSubscription?.cancel();
      _locationSubscription = null;
    } catch (e) {
      // Log error but don't throw in dispose
      AppLogger.error('Error cancelling location subscription', error: e);
    }

    try {
      _restaurantSubscription?.unsubscribe();
      _restaurantSubscription = null;
    } catch (e) {
      AppLogger.error('Error cancelling restaurant subscription', error: e);
    }

    try {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } catch (e) {
      AppLogger.error('Error cancelling refresh timer', error: e);
    }
  }

  // Safe state update with disposal check
  void _safeUpdateState(HomeRestaurantState Function(HomeRestaurantState) updateFn) {
    if (!_isDisposed && mounted) {
      state = updateFn(state);
    }
  }

  // Initialize the provider with concurrency protection
  Future<void> initialize() async {
    AppLogger.function('HomeRestaurantNotifier', 'ENTER', params: {'action': 'initialize'});

    if (_isDisposed || _isInitializing) return;

    _isInitializing = true;
    _safeUpdateState((state) => state.copyWith(isLoading: true, errorMessage: null));

    try {
      await Future.wait([
        _loadUserPreferences(),
        _requestLocationPermission(),
        _loadRestaurants(),
      ]);

      _safeUpdateState((state) => state.copyWith(
        isLoading: false,
        lastUpdated: DateTime.now(),
      ));

      AppLogger.function('HomeRestaurantNotifier', 'EXIT', result: 'Successfully initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize home restaurant provider', error: e);
      _safeUpdateState((state) => state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    } finally {
      _isInitializing = false;
    }
  }

  // Load user preferences for personalization
  Future<void> _loadUserPreferences() async {
    try {
      final response = await _dbService.client
          .from('user_profiles')
          .select('preferences')
          .maybeSingle();

      if (response != null) {
        state = state.copyWith(
          userPreferences: response['preferences'] as Map<String, dynamic>? ?? {},
        );
      }
    } catch (e) {
      // Continue with empty preferences if error occurs
      print('Error loading user preferences: $e');
    }
  }

  // Request location permission and get current location
  Future<void> _requestLocationPermission() async {
    state = state.copyWith(isLocationLoading: true, locationError: null);

    try {
      final permission = await _locationService.checkPermission();

      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          final position = await _locationService.getCurrentPosition();
          state = state.copyWith(
            hasLocationPermission: true,
            userLocation: position,
            isLocationLoading: false,
          );
          _startLocationTracking();
          break;

        case LocationPermission.denied:
          state = state.copyWith(
            hasLocationPermission: false,
            isLocationLoading: false,
            locationError: 'Location permission denied',
          );
          break;

        case LocationPermission.deniedForever:
          state = state.copyWith(
            hasLocationPermission: false,
            isLocationLoading: false,
            locationError: 'Location permission permanently denied',
          );
          break;

        case LocationPermission.unableToDetermine:
          state = state.copyWith(
            hasLocationPermission: false,
            isLocationLoading: false,
            locationError: 'Unable to determine location permission',
          );
          break;
      }
    } catch (e) {
      state = state.copyWith(
        isLocationLoading: false,
        locationError: e.toString(),
      );
    }
  }

  // Start real-time location tracking
  void _startLocationTracking() {
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update every 100 meters
      ),
    ).listen(
      (Position position) {
        if (mounted) {
          state = state.copyWith(userLocation: position);
          _refreshNearbyRestaurants();
        }
      },
      onError: (error) {
        if (mounted) {
          state = state.copyWith(locationError: error.toString());
        }
      },
    );
  }

  // Load restaurants from database with personalization
  Future<void> _loadRestaurants() async {
    try {
      final response = await _dbService.client
          .from('restaurants')
          .select('''
            id,
            name,
            description,
            cuisine_type,
            rating,
            total_reviews,
            delivery_radius,
            estimated_delivery_time,
            delivery_fee,
            minimum_order_amount,
            is_active,
            is_featured,
            logo_url,
            cover_image_url,
            latitude,
            longitude,
            opening_hours,
            dietary_options,
            features,
            city,
            state
          ''')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final List<Restaurant> restaurants = (response as List)
          .map((json) => _parseRestaurantFromJson(json as Map<String, dynamic>))
          .where((restaurant) => restaurant.latitude != null && restaurant.longitude != null)
          .toList();

      await Future.wait([
        _calculatePopularRestaurants(restaurants),
        _calculateFeaturedRestaurants(restaurants),
        _calculateNearbyRestaurants(restaurants),
      ]);

    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  // Parse restaurant from JSON response with proper timestamp handling
  Restaurant _parseRestaurantFromJson(Map<String, dynamic> json) {
    // Parse timestamps from database or fallback to current time
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return DateTime.now();
      if (timestamp is String) {
        try {
          return DateTime.parse(timestamp);
        } catch (e) {
          AppLogger.warning('Error parsing timestamp: $timestamp');
          return DateTime.now();
        }
      }
      if (timestamp is int) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return DateTime.now();
    }

    return Restaurant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Restaurant',
      description: json['description'] as String?,
      cuisineType: json['cuisine_type'] as String? ?? 'Other',
      address: {
        'city': json['city'] ?? '',
        'state': json['state'] ?? '',
        'latitude': json['latitude'],
        'longitude': json['longitude'],
      },
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      websiteUrl: json['website_url'] as String?,
      addressLine1: json['address_line1'] as String?,
      addressLine2: json['address_line2'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      openingHours: json['opening_hours'] as Map<String, dynamic>? ?? {},
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['total_reviews'] as num?)?.toInt(),
      deliveryRadius: (json['delivery_radius'] as num?)?.toDouble() ?? 5.0,
      estimatedDeliveryTime: json['estimated_delivery_time'] as int? ?? 30,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble(),
      minimumOrderAmount: (json['minimum_order_amount'] as num?)?.toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      dietaryOptions: (json['dietary_options'] as List<dynamic>?)?.cast<String>(),
      features: (json['features'] as List<dynamic>?)?.cast<String>(),
      logoUrl: json['logo_url'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      createdAt: parseTimestamp(json['created_at']),
      updatedAt: parseTimestamp(json['updated_at']),
    );
  }

  // Calculate popular restaurants based on user personalization with input validation
  Future<void> _calculatePopularRestaurants(List<Restaurant> restaurants) async {
    // Validate user ID with proper checks
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || currentUser.id.isEmpty) {
      AppLogger.info('No authenticated user found, using general popularity');
      _safeUpdateState((state) => state.copyWith(
        popularRestaurants: _getGeneralPopularRestaurants(restaurants),
        popularRestaurantsCount: _getGeneralPopularRestaurants(restaurants).length,
      ));
      return;
    }

    final String userId = currentUser.id;

    // Validate UUID format
    if (!_isValidUUID(userId)) {
      AppLogger.warning('Invalid user ID format: $userId');
      _safeUpdateState((state) => state.copyWith(
        popularRestaurants: _getGeneralPopularRestaurants(restaurants),
        popularRestaurantsCount: _getGeneralPopularRestaurants(restaurants).length,
      ));
      return;
    }

    try {
      final orderHistory = await _dbService.client
          .from('orders')
          .select('restaurant_id, placed_at, rating')
          .eq('user_id', userId)
          .eq('status', 'delivered')
          .order('placed_at', ascending: false)
          .limit(50);

      final userCuisinePreferences = _extractCuisinePreferences(orderHistory);
      final userPricePreferences = _extractPricePreferences(orderHistory);

      // Personalized popularity scoring
      final scoredRestaurants = restaurants.map((restaurant) {
        double score = 0.0;

        // Base score from rating and review count
        score += restaurant.rating * 20;
        score += (restaurant.totalReviews ?? 0) * 0.1;

        // User preference bonus
        if (userCuisinePreferences.contains(restaurant.cuisineType)) {
          score += 30; // Strong preference for user's favorite cuisines
        }

        // Price preference alignment
        final avgDeliveryFee = userPricePreferences['avg_delivery_fee'] ?? 2.99;
        if (restaurant.deliveryFee != null) {
          final priceDiff = (restaurant.deliveryFee! - avgDeliveryFee).abs();
          score -= priceDiff * 5; // Penalty for price difference
        }

        // Recent order bonus
        final recentOrders = orderHistory.where((order) =>
            order['restaurant_id'] == restaurant.id &&
            DateTime.parse(order['placed_at']).isAfter(DateTime.now().subtract(const Duration(days: 30)))
        ).length;
        score += recentOrders * 10;

        return MapEntry(restaurant, score);
      }).toList();

      // Sort by score and take top 5
      scoredRestaurants.sort((a, b) => b.value.compareTo(a.value));
      final popularRestaurants = scoredRestaurants
          .take(5)
          .map((entry) => entry.key)
          .toList();

      state = state.copyWith(
        popularRestaurants: popularRestaurants,
        popularRestaurantsCount: popularRestaurants.length,
      );

    } catch (e) {
      // Fallback to general popularity on error
      final popularRestaurants = restaurants
          .where((r) => r.rating >= 4.0 && (r.totalReviews ?? 0) >= 3)
          .take(5)
          .toList();

      state = state.copyWith(
        popularRestaurants: popularRestaurants,
        popularRestaurantsCount: popularRestaurants.length,
      );
    }
  }

  // Calculate featured restaurants based on admin flags and user preferences
  Future<void> _calculateFeaturedRestaurants(List<Restaurant> restaurants) async {
    final featuredRestaurants = restaurants
        .where((r) => r.isFeatured)
        .take(4)
        .toList();

    state = state.copyWith(
      featuredRestaurants: featuredRestaurants,
      featuredRestaurantsCount: featuredRestaurants.length,
    );
  }

  // Calculate nearby restaurants based on user location
  Future<void> _calculateNearbyRestaurants(List<Restaurant> restaurants) async {
    if (state.userLocation == null) {
      // If no location, return empty list
      state = state.copyWith(
        nearbyRestaurants: [],
        nearbyRestaurantsCount: 0,
      );
      return;
    }

    final userLat = state.userLocation!.latitude;
    final userLng = state.userLocation!.longitude;

    // Calculate distances and sort using LocationUtils
    final restaurantsWithDistance = restaurants.map((restaurant) {
      final restaurantLat = restaurant.latitude ?? 0.0;
      final restaurantLng = restaurant.longitude ?? 0.0;

      // Validate coordinates before calculating distance
      if (!LocationUtils.isValidCoordinate(restaurantLat, restaurantLng)) {
        return MapEntry(restaurant, double.infinity);
      }

      final distance = LocationUtils.calculateDistance(
        userLat,
        userLng,
        restaurantLat,
        restaurantLng,
      );
      return MapEntry(restaurant, distance);
    }).where((entry) => entry.value <= 50.0 && entry.value != double.infinity) // Within 50km
      .toList();

    restaurantsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    final nearbyRestaurants = restaurantsWithDistance
        .take(4)
        .map((entry) => entry.key)
        .toList();

    state = state.copyWith(
      nearbyRestaurants: nearbyRestaurants,
      nearbyRestaurantsCount: nearbyRestaurants.length,
    );
  }

  // Refresh only nearby restaurants (for location updates)
  Future<void> _refreshNearbyRestaurants() async {
    if (state.userLocation == null) return;

    try {
      final response = await _dbService.client
          .from('restaurants')
          .select('''
            id,
            name,
            description,
            cuisine_type,
            rating,
            total_reviews,
            delivery_radius,
            estimated_delivery_time,
            delivery_fee,
            minimum_order_amount,
            is_active,
            is_featured,
            logo_url,
            cover_image_url,
            latitude,
            longitude,
            opening_hours,
            dietary_options,
            features,
            city,
            state
          ''')
          .eq('is_active', true)
          .order('rating', ascending: false);

      final List<Restaurant> restaurants = (response as List)
          .map((json) => _parseRestaurantFromJson(json as Map<String, dynamic>))
          .where((restaurant) => restaurant.latitude != null && restaurant.longitude != null)
          .toList();

      await _calculateNearbyRestaurants(restaurants);
    } catch (e) {
      print('Error refreshing nearby restaurants: $e');
    }
  }

  // Extract user cuisine preferences from order history
  List<String> _extractCuisinePreferences(List<Map<String, dynamic>> orderHistory) {
    final cuisineCount = <String, int>{};

    for (final order in orderHistory) {
      // This would need to be enhanced to get cuisine type from restaurant
      // For now, return empty list
    }

    return [];
  }

  // Extract user price preferences from order history
  Map<String, double> _extractPricePreferences(List<Map<String, dynamic>> orderHistory) {
    // For now, return default preferences
    return {'avg_delivery_fee': 2.99};
  }

  
  // Initialize periodic refresh for real-time updates
  void _initializePeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _loadRestaurants();
      }
    });

    // Listen to real-time database changes
    _restaurantSubscription = _dbService.client
        .channel('restaurants_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'restaurants',
          callback: (payload) {},
        )
        .subscribe();
  }

  // Retry location permission
  Future<void> retryLocationPermission() async {
    await _requestLocationPermission();
    if (state.hasLocationPermission) {
      await _loadRestaurants();
    }
  }

  // Refresh all restaurant data
  Future<void> refresh() async {
    if (_isDisposed || _isInitializing) return;

    _safeUpdateState((state) => state.copyWith(isLoading: true, errorMessage: null));
    await _loadRestaurants();
    _safeUpdateState((state) => state.copyWith(isLoading: false, lastUpdated: DateTime.now()));
  }

  // Helper method to get general popular restaurants (fallback when no user)
  List<Restaurant> _getGeneralPopularRestaurants(List<Restaurant> restaurants) {
    return restaurants
        .where((r) => r.rating >= 4.0 && (r.totalReviews ?? 0) >= 5)
        .take(5)
        .toList();
  }

  // Validate UUID format
  bool _isValidUUID(String uuid) {
    if (uuid.isEmpty) return false;

    // Basic UUID validation (version 4 format)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );

    return uuidRegex.hasMatch(uuid);
  }
}

// Provider for home restaurants with advanced personalization
final homeRestaurantProvider =
    StateNotifierProvider<HomeRestaurantNotifier, HomeRestaurantState>(
      (ref) => HomeRestaurantNotifier(),
    );

// Computed providers for UI
final popularRestaurantsProvider = Provider<List<Restaurant>>(
  (ref) => ref.watch(homeRestaurantProvider).popularRestaurants,
);

final featuredRestaurantsProvider = Provider<List<Restaurant>>(
  (ref) => ref.watch(homeRestaurantProvider).featuredRestaurants,
);

final nearbyRestaurantsProvider = Provider<List<Restaurant>>(
  (ref) => ref.watch(homeRestaurantProvider).nearbyRestaurants,
);

final isLoadingRestaurantsProvider = Provider<bool>(
  (ref) => ref.watch(homeRestaurantProvider).isLoading,
);

final hasLocationPermissionProvider = Provider<bool>(
  (ref) => ref.watch(homeRestaurantProvider).hasLocationPermission,
);