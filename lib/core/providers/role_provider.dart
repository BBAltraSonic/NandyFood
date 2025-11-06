import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/core/services/staff_service.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

/// Role state class
class RoleState {
  final UserRole? primaryRole;
  final List<UserRole> allRoles;
  final bool isLoading;
  final String? error;

  RoleState({
    this.primaryRole,
    this.allRoles = const [],
    this.isLoading = false,
    this.error,
  });

  /// Helper getters for role checks
  bool get isConsumer =>
      primaryRole?.role == UserRoleType.consumer || primaryRole == null;
  bool get isRestaurantOwner =>
      primaryRole?.role == UserRoleType.restaurantOwner;
  bool get isRestaurantStaff =>
      primaryRole?.role == UserRoleType.restaurantStaff;
  bool get isAdmin => primaryRole?.role == UserRoleType.admin;
  bool get isDeliveryDriver =>
      primaryRole?.role == UserRoleType.deliveryDriver;
  bool get hasMultipleRoles => allRoles.length > 1;

  bool get canAccessRestaurantDashboard =>
      isRestaurantOwner || isRestaurantStaff;
  bool get canAccessAdminDashboard => isAdmin;

  RoleState copyWith({
    UserRole? primaryRole,
    List<UserRole>? allRoles,
    bool? isLoading,
    String? error,
  }) {
    return RoleState(
      primaryRole: primaryRole ?? this.primaryRole,
      allRoles: allRoles ?? this.allRoles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Role notifier
class RoleNotifier extends StateNotifier<RoleState> {
  RoleNotifier() : super(RoleState()) {
    _roleService = RoleService();
  }

  late final RoleService _roleService;

  /// Load user roles
  Future<void> loadUserRoles(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final roles = await _roleService.getUserRoles(userId);
      final primary = await _roleService.getPrimaryRole(userId);

      state = RoleState(
        primaryRole: primary,
        allRoles: roles,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load roles: ${e.toString()}',
      );
    }
  }

  /// Switch primary role
  Future<bool> switchRole(String userId, UserRoleType roleType) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _roleService.switchPrimaryRole(userId, roleType);
      await loadUserRoles(userId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to switch role: ${e.toString()}',
      );
      return false;
    }
  }

  /// Request restaurant owner role
  Future<bool> requestRestaurantRole(
    String userId,
    String restaurantId,
    Map<String, dynamic>? businessInfo,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _roleService.requestRestaurantOwnerRole(
        userId: userId,
        restaurantId: restaurantId,
        businessInfo: businessInfo,
      );
      await loadUserRoles(userId);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request restaurant role: ${e.toString()}',
      );
      return false;
    }
  }

  /// Clear roles (on logout)
  void clearRoles() {
    state = RoleState();
  }

  /// Refresh roles
  Future<void> refreshRoles(String userId) async {
    await loadUserRoles(userId);
  }
}

/// Role provider
final roleProvider = StateNotifierProvider<RoleNotifier, RoleState>(
  (ref) => RoleNotifier(),
);

/// Helper provider to get primary role type
final primaryRoleTypeProvider = Provider<UserRoleType?>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.primaryRole?.role;
});

/// Provider to get primary role type directly (alias for compatibility)
final primaryRoleProvider = primaryRoleTypeProvider;

/// Provider to get all user roles
final userRolesProvider = Provider<List<UserRole>>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.allRoles;
});

/// Provider to get staff data (placeholder for now)
final staffDataProvider = Provider<Map<String, dynamic>?>((ref) {
  // This would typically come from a staff service
  // For now, return null as placeholder
  return null;
});

/// Provider to get restaurant data (placeholder for now)
final restaurantDataProvider = Provider<Map<String, dynamic>?>((ref) {
  // This would typically come from a restaurant service
  // For now, return null as placeholder
  return null;
});

/// Helper provider to check if user is restaurant owner
final isRestaurantOwnerProvider = Provider<bool>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.isRestaurantOwner;
});

/// Helper provider to check if user is restaurant staff
final isRestaurantStaffProvider = Provider<bool>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.isRestaurantStaff;
});

/// Helper provider to check if user can access restaurant dashboard
final canAccessRestaurantDashboardProvider = Provider<bool>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.canAccessRestaurantDashboard;
});

/// Helper provider to check if user has multiple roles
final hasMultipleRolesProvider = Provider<bool>((ref) {
  final roleState = ref.watch(roleProvider);
  return roleState.hasMultipleRoles;
});

/// Role service provider
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService();
});

/// Staff service provider
final staffServiceProvider = Provider<StaffService>((ref) {
  return StaffService();
});
