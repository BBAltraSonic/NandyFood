import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/restaurant/data/dtos/menu_item_dto.dart';

class MenuRepository {
  final DatabaseService _db;

  MenuRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  /// Fetch a single menu item row (including customization_options) and parse DTO
  Future<MenuItemDTO?> fetchMenuItemWithModifiers(String menuItemId) async {
    final row = await _db.getMenuItemById(menuItemId);
    if (row == null) return null;
    try {
      return MenuItemDTO.fromSupabaseRow(row);
    } catch (_) {
      return null;
    }
  }
}

