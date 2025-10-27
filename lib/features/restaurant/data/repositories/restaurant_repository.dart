import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

class RestaurantRepository {
  final DatabaseService _db;

  RestaurantRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<List<Restaurant>> fetchFeatured({int limit = 5}) async {
    final rows = await _db.getFeaturedRestaurants(limit: limit);
    return rows.map((r) => Restaurant.fromJson(r)).toList();
  }

  Future<List<Restaurant>> fetchList({
    required int page,
    required int limit,
    String? cuisineType,
    double? minRating,
    int? maxDeliveryTime,
  }) async {
    final rows = await _db.getRestaurantsPaginated(
      page: page,
      limit: limit,
      cuisineType: cuisineType,
      minRating: minRating,
      maxDeliveryTime: maxDeliveryTime,
    );
    return rows.map((r) => Restaurant.fromJson(r)).toList();
  }

  Future<List<Restaurant>> fetchByCategory(String category) async {
    final rows = await _db.getRestaurantsByCategory(category);
    return rows.map((r) => Restaurant.fromJson(r)).toList();
  }
}

