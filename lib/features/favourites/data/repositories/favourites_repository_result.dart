import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/features/favourites/data/repositories/favourites_repository.dart' as v1;
import 'package:food_delivery_app/shared/models/favourite.dart';

/// Result-returning wrapper around the legacy JSON-based repository
class FavouritesRepositoryR with RepositoryGuard {
  final v1.FavouritesRepository _inner;

  FavouritesRepositoryR({required v1.FavouritesRepository inner}) : _inner = inner;

  Future<Result<List<Favourite>>> fetchFavourites(String userId) async {
    return guard(() async {
      final rows = await _inner.fetchFavourites(userId);
      return rows.map(Favourite.fromJson).toList();
    });
  }

  Future<Result<Favourite>> addRestaurantFavourite(String userId, String restaurantId) async {
    return guard(() async {
      final row = await _inner.addRestaurantFavourite(userId, restaurantId);
      return Favourite.fromJson(row);
    });
  }

  Future<Result<Favourite>> addMenuItemFavourite(String userId, String menuItemId) async {
    return guard(() async {
      final row = await _inner.addMenuItemFavourite(userId, menuItemId);
      return Favourite.fromJson(row);
    });
  }

  Future<Result<bool>> removeRestaurantFavourite(String userId, String restaurantId) async {
    return guard(() async {
      await _inner.removeRestaurantFavourite(userId, restaurantId);
      return true;
    });
  }

  Future<Result<bool>> removeMenuItemFavourite(String userId, String menuItemId) async {
    return guard(() async {
      await _inner.removeMenuItemFavourite(userId, menuItemId);
      return true;
    });
  }

  Future<Result<bool>> clearUserFavourites(String userId) async {
    return guard(() async {
      await _inner.clearUserFavourites(userId);
      return true;
    });
  }
}

