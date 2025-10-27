import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/restaurant/data/dtos/menu_item_dto.dart';

class MenuRepositoryR with RepositoryGuard {
  final DatabaseService _db;
  MenuRepositoryR({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<Result<MenuItemDTO>> fetchMenuItemWithModifiers(String menuItemId) async {
    return guard(() async {
      final row = await _db.getMenuItemById(menuItemId);
      if (row == null) {
        throw NotFoundFailure(message: 'Menu item not found', code: '404');
      }
      return MenuItemDTO.fromSupabaseRow(row);
    });
  }
}

