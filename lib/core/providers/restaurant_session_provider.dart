import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/database_service.dart';
import '../utils/app_logger.dart';

/// Restaurant session state
class RestaurantSessionState {
  const RestaurantSessionState({
    this.restaurantId,
    this.restaurantName,
    this.ownerId,
    this.ownerType,
    this.permissions,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  final String? restaurantId;
  final String? restaurantName;
  final String? ownerId;
  final String? ownerType;
  final Map<String, dynamic>? permissions;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  bool get hasRestaurant => restaurantId != null && restaurantId!.isNotEmpty;

  bool get canManageMenu => permissions?['manage_menu'] == true;
  bool get canManageOrders => permissions?['manage_orders'] == true;
  bool get canManageStaff => permissions?['manage_staff'] == true;
  bool get canViewAnalytics => permissions?['view_analytics'] == true;
  bool get canManageSettings => permissions?['manage_settings'] == true;

  RestaurantSessionState copyWith({
    String? restaurantId,
    String? restaurantName,
    String? ownerId,
    String? ownerType,
    Map<String, dynamic>? permissions,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return RestaurantSessionState(
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      ownerId: ownerId ?? this.ownerId,
      ownerType: ownerType ?? this.ownerType,
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  String toString() {
    return 'RestaurantSessionState(restaurantId: $restaurantId, restaurantName: $restaurantName, hasRestaurant: $hasRestaurant)';
  }
}

/// Restaurant session notifier
class RestaurantSessionNotifier extends StateNotifier<RestaurantSessionState> {
  RestaurantSessionNotifier({
    required this.databaseService,
  }) : super(const RestaurantSessionState()) {
    _initialize();
  }

  final DatabaseService databaseService;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize restaurant session
  Future<void> _initialize() async {
    await loadRestaurantSession();
  }

  /// Load restaurant session for current user
  Future<void> loadRestaurantSession() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        AppLogger.debug('No user logged in, clearing restaurant session');
        state = const RestaurantSessionState(isLoading: false);
        return;
      }

      AppLogger.info('Loading restaurant session for user: $userId');

      // Get restaurant owner record
      final response = await _supabase
          .from('restaurant_owners')
          .select('''
            id,
            user_id,
            restaurant_id,
            owner_type,
            permissions,
            status,
            restaurant:restaurants(id, name, is_active)
          ''')
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      if (response == null) {
        AppLogger.info('No active restaurant found for user');
        state = state.copyWith(
          isLoading: false,
          lastUpdated: DateTime.now(),
        );
        return;
      }

      final restaurantData = response['restaurant'] as Map<String, dynamic>?;

      if (restaurantData == null) {
        AppLogger.warning('Restaurant data not found in response');
        state = state.copyWith(
          isLoading: false,
          error: 'Restaurant not found',
          lastUpdated: DateTime.now(),
        );
        return;
      }

      final restaurantId = restaurantData['id'] as String?;
      final restaurantName = restaurantData['name'] as String?;
      final isActive = restaurantData['is_active'] as bool? ?? false;

      if (!isActive) {
        AppLogger.warning('Restaurant is not active');
        state = state.copyWith(
          isLoading: false,
          error: 'Restaurant is not active',
          lastUpdated: DateTime.now(),
        );
        return;
      }

      final ownerType = response['owner_type'] as String?;
      final permissions = response['permissions'] as Map<String, dynamic>?;

      state = RestaurantSessionState(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        ownerId: userId,
        ownerType: ownerType,
        permissions: permissions,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );

      AppLogger.success(
        'Restaurant session loaded',
        details: 'Restaurant: $restaurantName (ID: $restaurantId)',
      );
    } catch (e, stack) {
      AppLogger.error('Failed to load restaurant session', error: e, stack: stack);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load restaurant: $e',
      );
    }
  }

  /// Set restaurant session manually (for testing or admin purposes)
  void setRestaurantSession({
    required String restaurantId,
    required String restaurantName,
    String? ownerType,
    Map<String, dynamic>? permissions,
  }) {
    state = RestaurantSessionState(
      restaurantId: restaurantId,
      restaurantName: restaurantName,
      ownerId: _supabase.auth.currentUser?.id,
      ownerType: ownerType,
      permissions: permissions,
      isLoading: false,
      lastUpdated: DateTime.now(),
    );

    AppLogger.info('Restaurant session set manually: $restaurantName');
  }

  /// Clear restaurant session
  void clearRestaurantSession() {
    state = const RestaurantSessionState();
    AppLogger.info('Restaurant session cleared');
  }

  /// Refresh restaurant session
  Future<void> refresh() async {
    await loadRestaurantSession();
  }

  /// Update permissions
  Future<void> updatePermissions(Map<String, dynamic> permissions) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null || state.restaurantId == null) {
        throw Exception('No active session');
      }

      await _supabase
          .from('restaurant_owners')
          .update({
            'permissions': permissions,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('restaurant_id', state.restaurantId!);

      state = state.copyWith(
        permissions: permissions,
        lastUpdated: DateTime.now(),
      );

      AppLogger.success('Permissions updated');
    } catch (e, stack) {
      AppLogger.error('Failed to update permissions', error: e, stack: stack);
      state = state.copyWith(error: 'Failed to update permissions: $e');
    }
  }

  /// Check if user has specific permission
  bool hasPermission(String permission) {
    return state.permissions?[permission] == true;
  }

  /// Get restaurant ID (throws if not available)
  String getRestaurantId() {
    final restaurantId = state.restaurantId;
    if (restaurantId == null || restaurantId.isEmpty) {
      throw Exception('No restaurant associated with current user');
    }
    return restaurantId;
  }

  /// Get restaurant ID safely (returns null if not available)
  String? getRestaurantIdSafe() {
    return state.restaurantId;
  }
}

/// Provider for restaurant session
final restaurantSessionProvider = StateNotifierProvider<RestaurantSessionNotifier, RestaurantSessionState>(
  (ref) {
    final databaseService = ref.watch(databaseServiceProvider);
    return RestaurantSessionNotifier(databaseService: databaseService);
  },
);

/// Provider to get current restaurant ID
final currentRestaurantIdProvider = Provider<String?>((ref) {
  final session = ref.watch(restaurantSessionProvider);
  return session.restaurantId;
});

/// Provider to check if user has a restaurant
final hasRestaurantProvider = Provider<bool>((ref) {
  final session = ref.watch(restaurantSessionProvider);
  return session.hasRestaurant;
});

/// Provider to get restaurant name
final restaurantNameProvider = Provider<String?>((ref) {
  final session = ref.watch(restaurantSessionProvider);
  return session.restaurantName;
});

/// Provider to check specific permission
final hasPermissionProvider = Provider.family<bool, String>((ref, permission) {
  final session = ref.watch(restaurantSessionProvider);
  return session.permissions?[permission] == true;
});
