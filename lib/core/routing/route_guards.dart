import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

/// Route guards for role-based access control
class RouteGuards {
  static final _roleService = RoleService();

  /// Check if user is authenticated
  static bool isAuthenticated() {
    if (!DatabaseService().isInitialized) {
      return false;
    }
    return DatabaseService().client.auth.currentSession != null;
  }

  /// Get current user ID
  static String? getCurrentUserId() {
    if (!isAuthenticated()) return null;
    return DatabaseService().client.auth.currentUser?.id;
  }

  /// Get user's primary role
  static Future<UserRole?> getPrimaryRole() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;

    try {
      return await _roleService.getPrimaryRole(userId);
    } catch (e) {
      return null;
    }
  }

  /// Guard for restaurant dashboard routes
  static Future<String?> requireRestaurantRole(
    GoRouterState state,
  ) async {
    final location = state.uri.toString();

    // Check authentication first
    if (!isAuthenticated()) {
      return '/auth/login?redirect=$location';
    }

    // Check role
    final primaryRole = await getPrimaryRole();
    if (primaryRole == null) {
      return '/home'; // No role, go to consumer home
    }

    // Allow access for restaurant owners and staff
    if (primaryRole.role == UserRoleType.restaurantOwner ||
        primaryRole.role == UserRoleType.restaurantStaff) {
      return null; // Allow access
    }

    // Not authorized - redirect to home
    return '/home';
  }

  /// Guard for admin routes
  static Future<String?> requireAdminRole(
    GoRouterState state,
  ) async {
    final location = state.uri.toString();

    // Check authentication first
    if (!isAuthenticated()) {
      return '/auth/login?redirect=$location';
    }

    // Check role
    final primaryRole = await getPrimaryRole();
    if (primaryRole?.role == UserRoleType.admin) {
      return null; // Allow access
    }

    // Not authorized - redirect to home
    return '/home';
  }

  /// Guard for consumer-only routes (optional, for future use)
  static Future<String?> requireConsumerRole(
    GoRouterState state,
  ) async {
    final location = state.uri.toString();

    // Check authentication first
    if (!isAuthenticated()) {
      return '/auth/login?redirect=$location';
    }

    return null; // Allow access for all authenticated users
  }

  /// Guard for authenticated routes (any role)
  static String? requireAuthentication(
    GoRouterState state,
  ) {
    final location = state.uri.toString();

    if (!isAuthenticated()) {
      return '/auth/login?redirect=$location';
    }

    return null; // Allow access
  }

  /// Check if user has specific role
  static Future<bool> hasRole(UserRoleType roleType) async {
    final userId = getCurrentUserId();
    if (userId == null) return false;

    try {
      return await _roleService.hasRole(userId, roleType);
    } catch (e) {
      return false;
    }
  }

  /// Get all user roles
  static Future<List<UserRole>> getUserRoles() async {
    final userId = getCurrentUserId();
    if (userId == null) return [];

    try {
      return await _roleService.getUserRoles(userId);
    } catch (e) {
      return [];
    }
  }
}
