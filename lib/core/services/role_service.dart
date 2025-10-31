import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/models/restaurant_owner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user roles and permissions
class RoleService {
  final SupabaseClient _supabase = DatabaseService().client;

  /// Get all roles for a user
  Future<List<UserRole>> getUserRoles(String userId) async {
    try {
      AppLogger.function('RoleService.getUserRoles', 'ENTER',
          params: {'userId': userId});

      final response = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', userId)
          .order('is_primary', ascending: false);

  
      final responseList = response as List;
      if (responseList.isEmpty) {
        AppLogger.function('RoleService.getUserRoles', 'EXIT',
            result: '0 roles (empty list)');
        return [];
      }

      final roles = responseList
          .map((json) => UserRole.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.function('RoleService.getUserRoles', 'EXIT',
          result: '${roles.length} roles');
      return roles;
    } catch (e, stack) {
      AppLogger.error('Failed to get user roles', error: e, stack: stack);
      // Return empty list instead of rethrowing to prevent crashes
      return [];
    }
  }

  /// Get the primary role for a user
  Future<UserRole?> getPrimaryRole(String userId) async {
    try {
      AppLogger.function('RoleService.getPrimaryRole', 'ENTER',
          params: {'userId': userId});

      final response = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', userId)
          .eq('is_primary', true)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('No primary role found for user');
        return null;
      }

      final role = UserRole.fromJson(response);
      AppLogger.function('RoleService.getPrimaryRole', 'EXIT',
          result: role.role.toString());
      return role;
    } catch (e, stack) {
      AppLogger.error('Failed to get primary role', error: e, stack: stack);
      // Return null instead of rethrowing to prevent crashes
      return null;
    }
  }

  /// Check if user has a specific role
  Future<bool> hasRole(String userId, UserRoleType roleType) async {
    try {
      final roles = await getUserRoles(userId);
      return roles.any((r) => r.role == roleType);
    } catch (e, stack) {
      AppLogger.error('Failed to check if user has role',
          error: e, stack: stack);
      return false;
    }
  }

  /// Assign a role to a user
  Future<void> assignRole(
    String userId,
    UserRoleType roleType, {
    bool isPrimary = false,
  }) async {
    try {
      AppLogger.function('RoleService.assignRole', 'ENTER', params: {
        'userId': userId,
        'roleType': roleType.toString(),
        'isPrimary': isPrimary,
      });

      // If setting as primary, unset all other primary roles first
      if (isPrimary) {
        await _supabase
            .from('user_roles')
            .update({'is_primary': false})
            .eq('user_id', userId);
      }

      // Insert or update the role
      await _supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': _roleTypeToString(roleType),
        'is_primary': isPrimary,
        'metadata': {},
      });

      AppLogger.success('Role assigned successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to assign role', error: e, stack: stack);
      rethrow;
    }
  }

  /// Set a role as primary (if user already has it)
  Future<void> setPrimaryRole(String userId, UserRoleType roleType) async {
    try {
      AppLogger.function('RoleService.setPrimaryRole', 'ENTER', params: {
        'userId': userId,
        'roleType': roleType.toString(),
      });

      // Check if user has this role
      final hasThisRole = await hasRole(userId, roleType);
      if (!hasThisRole) {
        throw Exception('User does not have role: $roleType');
      }

      // Unset all other primary roles
      await _supabase
          .from('user_roles')
          .update({'is_primary': false})
          .eq('user_id', userId);

      // Set this role as primary
      await _supabase
          .from('user_roles')
          .update({'is_primary': true})
          .eq('user_id', userId)
          .eq('role', _roleTypeToString(roleType));

      AppLogger.success('Primary role set successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to set primary role', error: e, stack: stack);
      rethrow;
    }
  }

  /// Switch primary role (if user has multiple roles)
  Future<void> switchPrimaryRole(String userId, UserRoleType newRole) async {
    try {
      AppLogger.function('RoleService.switchPrimaryRole', 'ENTER', params: {
        'userId': userId,
        'newRole': newRole.toString(),
      });

      // Find the role to make primary
      final response = await _supabase
          .from('user_roles')
          .select()
          .eq('user_id', userId)
          .eq('role', _roleTypeToString(newRole))
          .maybeSingle();

      if (response == null) {
        throw Exception('User does not have the role: $newRole');
      }

      // Update the role to be primary (trigger will handle setting others to false)
      await _supabase
          .from('user_roles')
          .update({'is_primary': true})
          .eq('id', response['id']);

      AppLogger.success('Primary role switched successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to switch primary role', error: e, stack: stack);
      rethrow;
    }
  }

  /// Request restaurant owner role
  /// This creates a pending role and restaurant ownership record
  Future<void> requestRestaurantOwnerRole({
    required String userId,
    required String restaurantId,
    Map<String, dynamic>? businessInfo,
  }) async {
    try {
      AppLogger.function('RoleService.requestRestaurantOwnerRole', 'ENTER',
          params: {
            'userId': userId,
            'restaurantId': restaurantId,
          });

      // Create restaurant owner role (if doesn't exist)
      await _supabase.from('user_roles').upsert({
        'user_id': userId,
        'role': 'restaurant_owner',
        'is_primary': false,
        'metadata': businessInfo ?? {},
      });

      // Create restaurant ownership record
      await _supabase.from('restaurant_owners').insert({
        'user_id': userId,
        'restaurant_id': restaurantId,
        'owner_type': 'primary',
        'status': 'pending',
        'verification_documents': businessInfo?['documents'] ?? [],
      });

      AppLogger.success('Restaurant owner role requested successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to request restaurant owner role',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get restaurants owned by user (returns restaurant IDs)
  Future<List<String>> getUserRestaurants(String userId) async {
    try {
      AppLogger.function('RoleService.getUserRestaurants', 'ENTER',
          params: {'userId': userId});

      final response = await _supabase
          .from('restaurant_owners')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final restaurantIds = (response as List)
          .map((json) => json['restaurant_id'] as String)
          .toList();

      AppLogger.function('RoleService.getUserRestaurants', 'EXIT',
          result: '${restaurantIds.length} restaurants');
      return restaurantIds;
    } catch (e, stack) {
      AppLogger.error('Failed to get user restaurants',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get user's restaurant owner records
  Future<List<RestaurantOwner>> getUserRestaurantOwners(String userId) async {
    try {
      AppLogger.function('RoleService.getUserRestaurantOwners', 'ENTER',
          params: {'userId': userId});

      final response = await _supabase
          .from('restaurant_owners')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final owners = (response as List)
          .map((json) => RestaurantOwner.fromJson(json as Map<String, dynamic>))
          .toList();

      AppLogger.function('RoleService.getUserRestaurantOwners', 'EXIT',
          result: '${owners.length} restaurant owners');
      return owners;
    } catch (e, stack) {
      AppLogger.error('Failed to get user restaurant owners',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Get user's primary restaurant (first active one)
  Future<RestaurantOwner?> getPrimaryRestaurant(String userId) async {
    try {
      final owners = await getUserRestaurantOwners(userId);
      if (owners.isEmpty) return null;

      // Return first primary owner, otherwise first restaurant
      return owners.firstWhere(
        (r) => r.isPrimary,
        orElse: () => owners.first,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get primary restaurant',
          error: e, stack: stack);
      return null;
    }
  }

  /// Check if user can access restaurant dashboard
  Future<bool> canAccessRestaurantDashboard(String userId) async {
    try {
      final role = await getPrimaryRole(userId);
      if (role == null) return false;

      return role.isRestaurantOwner || role.isRestaurantStaff;
    } catch (e) {
      AppLogger.error('Failed to check dashboard access', error: e);
      return false;
    }
  }

  /// Get initial route based on user's primary role
  Future<String> getInitialRoute(String userId) async {
    try {
      final role = await getPrimaryRole(userId);
      if (role == null) return '/home';

      switch (role.role) {
        case UserRoleType.restaurantOwner:
          return '/restaurant/dashboard';
        case UserRoleType.restaurantStaff:
          return '/restaurant/orders';
        case UserRoleType.admin:
          return '/admin/dashboard';
        case UserRoleType.deliveryDriver:
          return '/driver/dashboard';
        case UserRoleType.consumer:
          return '/home';
      }
    } catch (e) {
      AppLogger.error('Failed to get initial route', error: e);
      return '/home';
    }
  }

  /// Helper method to convert role type to string for database
  String _roleTypeToString(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return 'consumer';
      case UserRoleType.restaurantOwner:
        return 'restaurant_owner';
      case UserRoleType.restaurantStaff:
        return 'restaurant_staff';
      case UserRoleType.admin:
        return 'admin';
      case UserRoleType.deliveryDriver:
        return 'delivery_driver';
    }
  }
}
