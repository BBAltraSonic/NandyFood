import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class RestaurantRepositoryR with RepositoryGuard {
  final DatabaseService _db;
  RestaurantRepositoryR({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<Result<List<Restaurant>>> fetchFeatured({int limit = 5}) async {
    return guard(() async {
      final rows = await _db.getFeaturedRestaurants(limit: limit);
      return rows
          .where((r) => _isValidRestaurantData(r))
          .map((r) => Restaurant.fromJson(r))
          .toList();
    });
  }

  Future<Result<List<Restaurant>>> fetchList({
    required int page,
    required int limit,
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
  }) async {
    return guard(() async {
      final rows = await _db.getRestaurantsPaginated(
        page: page,
        limit: limit,
        cuisineType: cuisineType,
        minRating: minRating,
        maxDeliveryTime: maxDeliveryTime,
      );
      return rows
          .where((r) => _isValidRestaurantData(r))
          .map((r) => Restaurant.fromJson(r))
          .toList();
    });
  }

  Future<Result<List<Restaurant>>> fetchByCategory(String category) async {
    return guard(() async {
      final rows = await _db.getRestaurantsByCategory(category);
      return rows
          .where((r) => _isValidRestaurantData(r))
          .map((r) => Restaurant.fromJson(r))
          .toList();
    });
  }

  /// Validates that restaurant data contains all required fields
  bool _isValidRestaurantData(Map<String, dynamic> data) {
    try {
      // Check required string fields
      final requiredFields = ['id', 'name', 'cuisine_type'];
      for (final field in requiredFields) {
        final value = data[field];
        if (value == null || value is! String || (value as String).isEmpty) {
          return false;
        }
      }

      // Check required timestamp fields
      final timestampFields = ['created_at', 'updated_at'];
      for (final field in timestampFields) {
        final value = data[field];
        if (value == null || value is! String) {
          return false;
        }
        // Try to parse the timestamp to ensure it's valid
        try {
          DateTime.parse(value as String);
        } catch (e) {
          return false;
        }
      }

      // Check required numeric fields
      final numericFields = ['rating', 'delivery_radius', 'estimated_delivery_time'];
      for (final field in numericFields) {
        final value = data[field];
        if (value == null) return false;
        if (value is! num && value is! int && value is! double) {
          return false;
        }
      }

      // Check required boolean field
      if (data['is_active'] == null || data['is_active'] is! bool) {
        return false;
      }

      // Check required address field
      if (data['address'] == null || data['address'] is! Map<String, dynamic>) {
        return false;
      }

      // Check required opening_hours field
      if (data['opening_hours'] == null || data['opening_hours'] is! Map<String, dynamic>) {
        return false;
      }

      return true;
    } catch (e) {
      // If any error occurs during validation, consider the data invalid
      return false;
    }
  }
}

