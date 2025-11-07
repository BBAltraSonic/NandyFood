import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;
import '../services/database_service.dart';
import '../../shared/models/restaurant.dart';

class RestaurantService {
  final DatabaseService _dbService;
  final SupabaseClient _client;

  RestaurantService(this._dbService) : _client = _dbService.client;

  /// Get active restaurants with optional filtering
  Future<List<Restaurant>> getRestaurants({
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final List<Map<String, dynamic>> response;

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        response = await _searchRestaurants(
          searchQuery,
          cuisineType: cuisineType,
          minRating: minRating,
          maxDeliveryTime: maxDeliveryTime,
          limit: limit,
          offset: offset,
        );
      } else {
        response = await _getFilteredRestaurants(
          cuisineType: cuisineType,
          minRating: minRating,
          maxDeliveryTime: maxDeliveryTime,
          limit: limit,
          offset: offset,
        );
      }

      return response.map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      print('Error getting restaurants: $e');
      return [];
    }
  }

  /// Search restaurants by name or cuisine type
  Future<List<Map<String, dynamic>>> _searchRestaurants(
    String query, {
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
    int limit = 50,
    int offset = 0,
  }) async {
    final searchQuery = query.trim().toLowerCase();
    var dbQuery = _client
        .from('restaurants')
        .select()
        .eq('is_active', true)
        .or('name.ilike.%$searchQuery%,cuisine_type.ilike.%$searchQuery%');

    return _applyFiltersAndPagination(
      dbQuery,
      cuisineType: cuisineType,
      minRating: minRating,
      maxDeliveryTime: maxDeliveryTime,
      limit: limit,
      offset: offset,
    );
  }

  /// Get restaurants with filters applied
  Future<List<Map<String, dynamic>>> _getFilteredRestaurants({
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
    int limit = 50,
    int offset = 0,
  }) async {
    var query = _client.from('restaurants').select().eq('is_active', true);

    return _applyFiltersAndPagination(
      query,
      cuisineType: cuisineType,
      minRating: minRating,
      maxDeliveryTime: maxDeliveryTime,
      limit: limit,
      offset: offset,
    );
  }

  /// Apply common filters and pagination to restaurant queries
  Future<List<Map<String, dynamic>>> _applyFiltersAndPagination(
    var query, {
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
    int limit = 50,
    int offset = 0,
  }) async {
    if (cuisineType != null && cuisineType.trim().isNotEmpty) {
      query = query.ilike('cuisine_type', '%$cuisineType%');
    }
    if (minRating != null) {
      query = query.gte('rating', minRating);
    }
    if (maxDeliveryTime != null) {
      query = query.lte('estimated_delivery_time', maxDeliveryTime);
    }

    final end = offset + limit - 1;
    final response = await query
        .order('rating', ascending: false)
        .range(offset, end);

    return response;
  }

  /// Get a single restaurant by ID
  Future<Restaurant?> getRestaurant(String restaurantId) async {
    try {
      final response = await _dbService.getRestaurant(restaurantId);
      return response != null ? Restaurant.fromJson(response) : null;
    } catch (e) {
      print('Error getting restaurant: $e');
      return null;
    }
  }

  /// Get featured restaurants (highly rated and active)
  Future<List<Restaurant>> getFeaturedRestaurants({int limit = 10}) async {
    try {
      final response = await _dbService.getFeaturedRestaurants(limit: limit);
      return response.map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      print('Error getting featured restaurants: $e');
      return [];
    }
  }

  /// Get restaurants by category/cuisine type
  Future<List<Restaurant>> getRestaurantsByCategory(
    String category, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      if (category == 'all') {
        return getRestaurants(limit: limit, offset: offset);
      }

      final response = await _client
          .from('restaurants')
          .select()
          .eq('is_active', true)
          .ilike('cuisine_type', '%$category%')
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      print('Error getting restaurants by category: $e');
      return [];
    }
  }

  /// Get restaurants the user has ordered from recently
  Future<List<Restaurant>> getUserRecentRestaurants(String userId) async {
    try {
      final response = await _dbService.getUserRecentRestaurants(userId);
      return response.map((json) => Restaurant.fromJson(json)).toList();
    } catch (e) {
      print('Error getting user recent restaurants: $e');
      return [];
    }
  }

  /// Get restaurants near a specific location
  Future<List<Restaurant>> getNearbyRestaurants(
    double userLat,
    double userLng, {
    double radiusKm = 10.0,
    int limit = 20,
  }) async {
    try {
      // Use PostGIS function to find restaurants within radius
      final response = await _client.rpc('get_restaurants_within_radius', params: {
        'user_lat': userLat,
        'user_lng': userLng,
        'radius_km': radiusKm,
        'limit_param': limit,
      });

      if (response is List) {
        return response.map((json) => Restaurant.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting nearby restaurants: $e');
      // Fallback to simple distance calculation if PostGIS not available
      return await _getNearbyRestaurantsFallback(userLat, userLng, radiusKm, limit);
    }
  }

  /// Fallback method for nearby restaurants using client-side distance calculation
  Future<List<Restaurant>> _getNearbyRestaurantsFallback(
    double userLat,
    double userLng,
    double radiusKm,
    int limit,
  ) async {
    try {
      final restaurants = await getRestaurants(limit: limit * 2); // Get more to filter
      final nearbyRestaurants = <Restaurant>[];

      for (final restaurant in restaurants) {
        if (restaurant.latitude != null && restaurant.longitude != null) {
          final distance = _calculateDistance(
            userLat,
            userLng,
            restaurant.latitude!,
            restaurant.longitude!,
          );

          if (distance <= radiusKm) {
            nearbyRestaurants.add(restaurant);
          }
        }
      }

      // Sort by distance and limit
      nearbyRestaurants.sort((a, b) {
        final distA = _calculateDistance(userLat, userLng, a.latitude!, a.longitude!);
        final distB = _calculateDistance(userLat, userLng, b.latitude!, b.longitude!);
        return distA.compareTo(distB);
      });

      return nearbyRestaurants.take(limit).toList();
    } catch (e) {
      print('Error in fallback nearby restaurants: $e');
      return [];
    }
  }

  /// Convert degrees to radians
  double _toRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLng = _toRadians(lng2 - lng1);

    final double a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
        math.pow(math.sin(dLng / 2), 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get restaurant statistics (total count, average rating, etc.)
  Future<Map<String, dynamic>> getRestaurantStatistics() async {
    try {
      final response = await _client
          .from('restaurants')
          .select('is_active, rating')
          .eq('is_active', true);

      final totalRestaurants = response.length;
      double totalRating = 0;
      int ratedRestaurants = 0;

      for (final restaurant in response) {
        if (restaurant['rating'] != null) {
          totalRating += restaurant['rating'];
          ratedRestaurants++;
        }
      }

      final averageRating = ratedRestaurants > 0 ? totalRating / ratedRestaurants : 0.0;

      return {
        'total_restaurants': totalRestaurants,
        'rated_restaurants': ratedRestaurants,
        'average_rating': averageRating.toStringAsFixed(1),
      };
    } catch (e) {
      print('Error getting restaurant statistics: $e');
      return {
        'total_restaurants': 0,
        'rated_restaurants': 0,
        'average_rating': '0.0',
      };
    }
  }

  /// Watch restaurant changes in real-time
  Stream<List<Restaurant>> watchRestaurants({
    String? cuisineType,
    double? minRating,
  }) {
    var query = _client
        .from('restaurants')
        .select('*')
        .eq('is_active', true);

    if (cuisineType != null) {
      query = query.ilike('cuisine_type', '%$cuisineType%');
    }
    if (minRating != null) {
      query = query.gte('rating', minRating);
    }

    return query
        .order('rating', ascending: false)
        .asStream()
        .map((event) => (event as List)
            .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
            .toList());
  }
}

// Extension method for double to radians
extension on double {
  double toRadians() => this * (3.14159265359 / 180);
}

// Extension for math operations on double
extension MathExtension on double {
  double sin() => math.sin(this);
  double cos() => math.cos(this);
  double atan2(double other) => math.atan2(this, other);
  double sqrt() => math.sqrt(this);
}

/// Provider for RestaurantService
final restaurantServiceProvider = Provider<RestaurantService>((ref) {
  final dbService = ref.watch(databaseServiceProvider);
  return RestaurantService(dbService);
});