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
      return rows.map((r) => Restaurant.fromJson(r)).toList();
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
      return rows.map((r) => Restaurant.fromJson(r)).toList();
    });
  }

  Future<Result<List<Restaurant>>> fetchByCategory(String category) async {
    return guard(() async {
      final rows = await _db.getRestaurantsByCategory(category);
      return rows.map((r) => Restaurant.fromJson(r)).toList();
    });
  }
}

