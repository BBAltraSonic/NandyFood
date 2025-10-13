import 'package:food_delivery_app/core/services/database_service.dart';

class PermissionService {
  final _supabase = DatabaseService().client;

  /// Check if user can manage menu for a restaurant
  Future<bool> canManageMenu(String userId, String restaurantId) async {
    return await _checkPermission(userId, restaurantId, 'manage_menu');
  }

  /// Check if user can manage orders for a restaurant
  Future<bool> canManageOrders(String userId, String restaurantId) async {
    return await _checkPermission(userId, restaurantId, 'manage_orders');
  }

  /// Check if user can manage staff for a restaurant
  Future<bool> canManageStaff(String userId, String restaurantId) async {
    return await _checkPermission(userId, restaurantId, 'manage_staff');
  }

  /// Check if user can view analytics for a restaurant
  Future<bool> canViewAnalytics(String userId, String restaurantId) async {
    return await _checkPermission(userId, restaurantId, 'view_analytics');
  }

  /// Check if user can manage settings for a restaurant
  Future<bool> canManageSettings(String userId, String restaurantId) async {
    return await _checkPermission(userId, restaurantId, 'manage_settings');
  }

  /// Get all permissions for a user at a restaurant
  Future<Map<String, bool>> getAllPermissions(
    String userId,
    String restaurantId,
  ) async {
    try {
      // Try to use the database function first
      final response = await _supabase.rpc(
        'get_user_restaurant_permissions',
        params: {
          'p_user_id': userId,
          'p_restaurant_id': restaurantId,
        },
      );

      if (response != null && response is Map<String, dynamic>) {
        return {
          'manage_menu': response['manage_menu'] == true,
          'manage_orders': response['manage_orders'] == true,
          'manage_staff': response['manage_staff'] == true,
          'view_analytics': response['view_analytics'] == true,
          'manage_settings': response['manage_settings'] == true,
        };
      }

      // Fallback: query restaurant_owners table directly
      final data = await _supabase
          .from('restaurant_owners')
          .select('permissions')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .maybeSingle();

      if (data != null && data['permissions'] != null) {
        final permissions = data['permissions'] as Map<String, dynamic>;
        return {
          'manage_menu': permissions['manage_menu'] == true,
          'manage_orders': permissions['manage_orders'] == true,
          'manage_staff': permissions['manage_staff'] == true,
          'view_analytics': permissions['view_analytics'] == true,
          'manage_settings': permissions['manage_settings'] == true,
        };
      }

      return {
        'manage_menu': false,
        'manage_orders': false,
        'manage_staff': false,
        'view_analytics': false,
        'manage_settings': false,
      };
    } catch (e) {
      return {
        'manage_menu': false,
        'manage_orders': false,
        'manage_staff': false,
        'view_analytics': false,
        'manage_settings': false,
      };
    }
  }

  /// Helper method to check a specific permission
  Future<bool> _checkPermission(
    String userId,
    String restaurantId,
    String permission,
  ) async {
    try {
      // Try to use the database function first
      final response = await _supabase.rpc(
        'user_has_permission',
        params: {
          'p_user_id': userId,
          'p_restaurant_id': restaurantId,
          'p_permission': permission,
        },
      );

      if (response != null) {
        return response == true;
      }

      // Fallback: query restaurant_owners table directly
      final data = await _supabase
          .from('restaurant_owners')
          .select('permissions')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .maybeSingle();

      if (data != null && data['permissions'] != null) {
        final permissions = data['permissions'] as Map<String, dynamic>;
        return permissions[permission] == true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if user has any permission at a restaurant
  Future<bool> hasAnyPermission(String userId, String restaurantId) async {
    try {
      final data = await _supabase
          .from('restaurant_owners')
          .select('id')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .maybeSingle();

      return data != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is primary owner of a restaurant
  Future<bool> isPrimaryOwner(String userId, String restaurantId) async {
    try {
      final data = await _supabase
          .from('restaurant_owners')
          .select('owner_type')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .maybeSingle();

      return data != null && data['owner_type'] == 'primary';
    } catch (e) {
      return false;
    }
  }

  /// Get user's permission level (primary, co-owner, manager, or null)
  Future<String?> getUserPermissionLevel(
    String userId,
    String restaurantId,
  ) async {
    try {
      final data = await _supabase
          .from('restaurant_owners')
          .select('owner_type')
          .eq('user_id', userId)
          .eq('restaurant_id', restaurantId)
          .eq('status', 'active')
          .maybeSingle();

      return data?['owner_type'] as String?;
    } catch (e) {
      return null;
    }
  }
}
