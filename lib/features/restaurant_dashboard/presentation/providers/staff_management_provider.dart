import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/staff_service.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Staff management state
class StaffManagementState {
  final List<RestaurantStaff> staffList;
  final bool isLoading;
  final String? error;
  final String? searchQuery;
  final StaffRoleType? roleFilter;
  final StaffStatus? statusFilter;

  const StaffManagementState({
    this.staffList = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
    this.roleFilter,
    this.statusFilter,
  });

  StaffManagementState copyWith({
    List<RestaurantStaff>? staffList,
    bool? isLoading,
    String? error,
    String? searchQuery,
    StaffRoleType? roleFilter,
    StaffStatus? statusFilter,
  }) {
    return StaffManagementState(
      staffList: staffList ?? this.staffList,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      roleFilter: roleFilter ?? this.roleFilter,
      statusFilter: statusFilter ?? this.statusFilter,
    );
  }

  /// Get filtered staff list
  List<RestaurantStaff> get filteredStaff {
    var filtered = staffList;

    // Filter by search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((staff) {
        final name = staff.userProfile?.fullName?.toLowerCase() ?? '';
        final email = staff.userProfile?.email?.toLowerCase() ?? '';
        final role = staff.roleDisplayName.toLowerCase();

        return name.contains(query) ||
            email.contains(query) ||
            role.contains(query);
      }).toList();
    }

    // Filter by role
    if (roleFilter != null) {
      filtered = filtered.where((staff) => staff.role == roleFilter).toList();
    }

    // Filter by status
    if (statusFilter != null) {
      filtered = filtered.where((staff) => staff.status == statusFilter).toList();
    }

    // Sort by role priority and then by name
    filtered.sort((a, b) {
      final rolePriority = {
        StaffRoleType.manager: 1,
        StaffRoleType.chef: 2,
        StaffRoleType.cashier: 3,
        StaffRoleType.server: 4,
        StaffRoleType.deliveryCoordinator: 5,
        StaffRoleType.basicStaff: 6,
      };

      final priorityA = rolePriority[a.role] ?? 999;
      final priorityB = rolePriority[b.role] ?? 999;

      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // Sort by name if same role
      final nameA = a.userProfile?.fullName?.toLowerCase() ?? '';
      final nameB = b.userProfile?.fullName?.toLowerCase() ?? '';
      return nameA.compareTo(nameB);
    });

    return filtered;
  }

  /// Get staff counts by role
  Map<StaffRoleType, int> get staffCountByRole {
    final counts = <StaffRoleType, int>{};
    for (final staff in staffList) {
      counts[staff.role] = (counts[staff.role] ?? 0) + 1;
    }
    return counts;
  }

  /// Get staff counts by status
  Map<StaffStatus, int> get staffCountByStatus {
    final counts = <StaffStatus, int>{};
    for (final staff in staffList) {
      counts[staff.status] = (counts[staff.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Get active staff count
  int get activeStaffCount {
    return staffList.where((staff) => staff.isActive).length;
  }

  /// Get total staff count
  int get totalStaffCount {
    return staffList.length;
  }
}

/// Staff management notifier
class StaffManagementNotifier extends StateNotifier<StaffManagementState> {
  StaffManagementNotifier(this._restaurantId) : super(const StaffManagementState()) {
    _staffService = StaffService();
    loadStaff();
  }

  final String _restaurantId;
  late final StaffService _staffService;

  /// Load all staff members
  Future<void> loadStaff() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final staffList = await _staffService.getRestaurantStaff(_restaurantId);
      state = state.copyWith(
        staffList: staffList,
        isLoading: false,
      );
      AppLogger.success('Loaded ${staffList.length} staff members');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load staff: ${e.toString()}',
      );
      AppLogger.error('Failed to load staff: $e');
    }
  }

  /// Add new staff member
  Future<RestaurantStaff?> addStaffMember(CreateStaffRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newStaff = await _staffService.createStaffMember(_restaurantId, request);

      // Add to local state
      final updatedStaffList = [...state.staffList, newStaff];
      state = state.copyWith(
        staffList: updatedStaffList,
        isLoading: false,
      );

      AppLogger.success('Added new staff member: ${newStaff.id}');
      return newStaff;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add staff member: ${e.toString()}',
      );
      AppLogger.error('Failed to add staff member: $e');
      return null;
    }
  }

  /// Update staff member
  Future<bool> updateStaffMember(String staffId, UpdateStaffRequest request) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedStaff = await _staffService.updateStaffMember(staffId, request);

      // Update local state
      final updatedStaffList = state.staffList.map((staff) {
        return staff.id == staffId ? updatedStaff : staff;
      }).toList();

      state = state.copyWith(
        staffList: updatedStaffList,
        isLoading: false,
      );

      AppLogger.success('Updated staff member: $staffId');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update staff member: ${e.toString()}',
      );
      AppLogger.error('Failed to update staff member: $e');
      return false;
    }
  }

  /// Update staff status
  Future<bool> updateStaffStatus(String staffId, StaffStatus status) async {
    try {
      await _staffService.updateStaffStatus(staffId, status);

      // Update local state
      final updatedStaffList = state.staffList.map((staff) {
        if (staff.id == staffId) {
          return staff.copyWith(status: status);
        }
        return staff;
      }).toList();

      state = state.copyWith(staffList: updatedStaffList);

      AppLogger.success('Updated staff status: $staffId to $status');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to update staff status: ${e.toString()}');
      AppLogger.error('Failed to update staff status: $e');
      return false;
    }
  }

  /// Remove staff member
  Future<bool> removeStaffMember(String staffId, {String? reason}) async {
    try {
      await _staffService.removeStaffMember(staffId, reason: reason);

      // Remove from local state
      final updatedStaffList = state.staffList.where((staff) => staff.id != staffId).toList();
      state = state.copyWith(staffList: updatedStaffList);

      AppLogger.success('Removed staff member: $staffId');
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Failed to remove staff member: ${e.toString()}');
      AppLogger.error('Failed to remove staff member: $e');
      return false;
    }
  }

  /// Set search query
  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Set role filter
  void setRoleFilter(StaffRoleType? role) {
    state = state.copyWith(roleFilter: role);
  }

  /// Set status filter
  void setStatusFilter(StaffStatus? status) {
    state = state.copyWith(statusFilter: status);
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      searchQuery: null,
      roleFilter: null,
      statusFilter: null,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh staff list
  Future<void> refresh() async {
    await loadStaff();
  }
}

/// Staff management provider
final staffManagementProvider = StateNotifierProvider.family<
    StaffManagementNotifier,
    StaffManagementState,
    String>(
  (ref, restaurantId) => StaffManagementNotifier(restaurantId),
);

/// Provider for filtered staff list
final filteredStaffProvider = Provider.family<List<RestaurantStaff>, String>(
  (ref, restaurantId) {
    final state = ref.watch(staffManagementProvider(restaurantId));
    return state.filteredStaff;
  },
);

/// Provider for staff statistics
final staffStatsProvider = Provider.family<Map<String, int>, String>(
  (ref, restaurantId) {
    final state = ref.watch(staffManagementProvider(restaurantId));

    return {
      'total': state.totalStaffCount,
      'active': state.activeStaffCount,
      'managers': state.staffCountByRole[StaffRoleType.manager] ?? 0,
      'chefs': state.staffCountByRole[StaffRoleType.chef] ?? 0,
      'cashiers': state.staffCountByRole[StaffRoleType.cashier] ?? 0,
      'servers': state.staffCountByRole[StaffRoleType.server] ?? 0,
      'delivery_coordinators': state.staffCountByRole[StaffRoleType.deliveryCoordinator] ?? 0,
      'basic_staff': state.staffCountByRole[StaffRoleType.basicStaff] ?? 0,
      'on_leave': state.staffCountByStatus[StaffStatus.onLeave] ?? 0,
      'suspended': state.staffCountByStatus[StaffStatus.suspended] ?? 0,
    };
  },
);

/// Provider for current user's staff record
final currentUserStaffProvider = FutureProvider.family<RestaurantStaff?, String>(
  (ref, restaurantId) async {
    final staffService = ref.watch(staffServiceProvider);
    return await staffService.getCurrentUserStaff(restaurantId);
  },
);