import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/auth_service.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

// Auth state class to represent the authentication state
class AuthState {
  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;
  final UserRole? primaryRole;
  final List<UserRole> allRoles;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
    this.primaryRole,
    this.allRoles = const [],
  });

  // Role-based helper getters
  bool get canAccessRestaurantDashboard =>
      primaryRole?.role == UserRoleType.restaurantOwner ||
      primaryRole?.role == UserRoleType.restaurantStaff;

  bool get canAccessAdminDashboard => primaryRole?.role == UserRoleType.admin;

  bool get isConsumer =>
      primaryRole?.role == UserRoleType.consumer || primaryRole == null;

  bool get isRestaurantOwner =>
      primaryRole?.role == UserRoleType.restaurantOwner;

  bool get hasMultipleRoles => allRoles.length > 1;

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
    UserRole? primaryRole,
    List<UserRole>? allRoles,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      primaryRole: primaryRole ?? this.primaryRole,
      allRoles: allRoles ?? this.allRoles,
    );
  }
}

// Auth provider to manage authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(),
);

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState()) {
    _roleService = RoleService();
    _initializeAuthListener();
  }

  late final RoleService _roleService;
  StreamSubscription<String>? _fcmTokenSub;
  Timer? _authDebounceTimer;
  String? _subscribedRestaurantTopic;

  @override
  void dispose() {
    _cancelFcmTokenRefreshListener();
    _authDebounceTimer?.cancel();
    super.dispose();
  }


  void _initializeAuthListener() {
    try {
      // Check if database is initialized before accessing client
      if (!DatabaseService().isInitialized) {
        print('INFO: Database not yet initialized, skipping auth listener setup');
        state = AuthState(user: null, isAuthenticated: false);
        return;
      }

      final auth = DatabaseService().client.auth;

      // Listen to auth state changes with debouncing
      auth.onAuthStateChange.listen((data) {
        // Debounce rapid auth state changes to prevent unnecessary rebuilds
        _authDebounceTimer?.cancel();
        _authDebounceTimer = Timer(const Duration(milliseconds: 300), () async {
          final session = data.session;
          final user = session?.user;

          if (user != null) {
            // User is signed in - load roles
            await _loadUserRoles(user);
            // Upsert FCM token and listen for refreshes
            await _upsertDeviceTokenIfAvailable();
            await _ensureFcmTokenRefreshListener();
            // Subscribe to restaurant topic if applicable
            await _subscribeToRestaurantTopicIfApplicable();
          } else {
            // User is signed out: clean up listener and remove device token
            await _cancelFcmTokenRefreshListener();
            await _deleteDeviceTokenIfAvailable();
            await _unsubscribeFromRestaurantTopic();
            state = AuthState(user: null, isAuthenticated: false);
          }
        });
      });
    } catch (e) {
      print('Error initializing auth listener: $e');
      // Set default state if initialization fails
      state = AuthState(
        user: null,
        isAuthenticated: false,
        errorMessage: 'Failed to initialize auth: $e',
      );
    }
  }

  /// Load user roles after authentication
  Future<void> _loadUserRoles(User user) async {
    try {
      final roles = await _roleService.getUserRoles(user.id);
      final primaryRole = await _roleService.getPrimaryRole(user.id);

      state = AuthState(
        user: user,
        isAuthenticated: true,
        primaryRole: primaryRole,
        allRoles: roles,
      );
    } catch (e) {
      print('Error loading user roles: $e');
      // Set authenticated but without roles (default to consumer)
      state = AuthState(
        user: user,
        isAuthenticated: true,
        errorMessage: 'Failed to load user roles',
      );
    }
  }

  // Sign up method
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    UserRoleType initialRole = UserRoleType.consumer,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await DatabaseService().client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      // If sign up is successful, assign role
      // Note: User profile is automatically created by database trigger
      if (response.user != null) {
        // Assign role (default consumer role is also assigned by trigger, but we can override here)
        if (initialRole != UserRoleType.consumer) {
          await _roleService.assignRole(
            response.user!.id,
            initialRole,
            isPrimary: true,
          );
        }

        // Fetch the created role from database to get complete data
        final primaryRole = await _roleService.getPrimaryRole(response.user!.id);
        final allRoles = await _roleService.getUserRoles(response.user!.id);

        state = state.copyWith(
          isLoading: false,
          primaryRole: primaryRole,
          allRoles: allRoles,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, String fullName) async {
    try {
      await DatabaseService().client.from('user_profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Log error but don't throw as this shouldn't prevent sign up
      print('Error creating user profile: $e');
    }
  }

  // Sign in method
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await DatabaseService().client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await AuthService().signInWithGoogle();

      // Update state with authenticated user
      if (response.user != null) {
        state = AuthState(
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return response;
    } on AuthException catch (e) {
      // Handle user cancellation gracefully (no error message)
      if (e.statusCode == 'user_cancelled') {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        );
      }
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Google sign-in failed. Please try again.',
      );
      rethrow;
    }
  }

  // Sign in with Apple
  Future<AuthResponse> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await AuthService().signInWithApple();

      // Update state with authenticated user
      if (response.user != null) {
        state = AuthState(
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return response;
    } on AuthException catch (e) {
      // Handle user cancellation gracefully (no error message)
      if (e.statusCode == 'user_cancelled') {
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.message,
        );
      }
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Apple sign-in failed. Please try again.',
      );
      rethrow;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      // Best-effort: delete current device token before signing out (RLS requires auth)
      await _unsubscribeFromRestaurantTopic();
      await _deleteDeviceTokenIfAvailable();
      await _cancelFcmTokenRefreshListener();

      await AuthService().signOut();
      // Clear all state including roles
      state = AuthState(user: null, isAuthenticated: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // Clear error message
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }

  // DAY 20: Password reset
  Future<void> sendPasswordResetEmail({
    required String email,
    String? redirectTo,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await DatabaseService().client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // DAY 20: Email verification resend
  Future<void> resendVerificationEmail({
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await DatabaseService().client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      rethrow;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  bool get isEmailVerified => state.user?.emailConfirmedAt != null;

  /// Get initial route based on user role
  Future<String> getInitialRoute() async {
    if (!state.isAuthenticated || state.user == null) {
      return '/auth/login';
    }

    // Use RoleService for consistent routing logic
    return _roleService.getInitialRoute(state.user!.id);
  }

  /// Refresh user roles
  Future<void> refreshRoles() async {
    if (state.user != null) {
      await _loadUserRoles(state.user!);
    }
  }

  /// Switch primary role
  Future<void> switchRole(UserRoleType roleType) async {
    if (state.user == null) return;

    try {
      state = state.copyWith(isLoading: true);
      await _roleService.switchPrimaryRole(state.user!.id, roleType);
      await _loadUserRoles(state.user!);
      await _subscribeToRestaurantTopicIfApplicable();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch role: ${e.toString()}',
      );
    }
  }

  // --- FCM device token management ---
  Future<void> _ensureFcmTokenRefreshListener() async {
    if (!DatabaseService().isInitialized) return;
    // Avoid duplicate listeners
    await _cancelFcmTokenRefreshListener();
    try {
      // Attempt initial upsert (safe if already done)
      final initialToken = await FirebaseMessaging.instance.getToken();
      if (initialToken != null && state.user != null) {
        await _upsertDeviceTokenIfAvailable(initialToken);
      }
    } catch (e) {
      // Non-fatal
      print('FCM initial token upsert failed: $e');
    }
    _fcmTokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        if (state.user != null) {
          await _upsertDeviceTokenIfAvailable(newToken);
        }
      } catch (e) {
        print('FCM onTokenRefresh upsert failed: $e');
      }
    });
  }

  Future<void> _cancelFcmTokenRefreshListener() async {
    try {
      await _fcmTokenSub?.cancel();
    } catch (_) {}
    _fcmTokenSub = null;
  }

  Future<void> _upsertDeviceTokenIfAvailable([String? tokenOverride]) async {
    try {
      if (!DatabaseService().isInitialized) return;
      final userId = state.user?.id ?? DatabaseService().client.auth.currentUser?.id;
      if (userId == null) return;

      final token = tokenOverride ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      String platform;
      try {
        if (Platform.isIOS) {
          platform = 'ios';
        } else if (Platform.isAndroid) {
          platform = 'android';
        } else {
          platform = 'web';
        }
      } catch (_) {
        platform = 'android';
      }

      await DatabaseService().client.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': platform,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
    } catch (e) {
      // Non-fatal: do not block auth flow
      print('Warning: failed to upsert device token: $e');
    }
  }

  Future<void> _deleteDeviceTokenIfAvailable() async {
    try {
      if (!DatabaseService().isInitialized) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await DatabaseService().client.from('user_devices').delete().eq('fcm_token', token);
    } catch (e) {
      // Non-fatal cleanup
      print('Warning: failed to delete device token: $e');
    }
  }

  Future<void> _subscribeToRestaurantTopicIfApplicable() async {
    try {
      if (state.user == null) return;
      if (!state.canAccessRestaurantDashboard) {
        await _unsubscribeFromRestaurantTopic();
        return;
      }
      final primaryRestaurant = await _roleService.getPrimaryRestaurant(state.user!.id);
      final restaurantId = primaryRestaurant?.restaurantId;
      if (restaurantId == null || restaurantId.isEmpty) return;
      final topic = 'restaurant_$restaurantId';

      // If already subscribed to same topic, skip
      if (_subscribedRestaurantTopic == topic) return;

      // If subscribed to a different topic, unsubscribe first
      if (_subscribedRestaurantTopic != null && _subscribedRestaurantTopic != topic) {
        try {
          await FirebaseMessaging.instance.unsubscribeFromTopic(_subscribedRestaurantTopic!);
        } catch (_) {}
      }

      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _subscribedRestaurantTopic = topic;
    } catch (e) {
      // Non-fatal: do not block auth/role flow
      print('Warning: failed to subscribe to restaurant topic: $e');
    }
  }

  Future<void> _unsubscribeFromRestaurantTopic() async {
    try {
      if (_subscribedRestaurantTopic != null) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(_subscribedRestaurantTopic!);
      }
    } catch (e) {
      // Non-fatal
      print('Warning: failed to unsubscribe from restaurant topic: $e');
    } finally {
      _subscribedRestaurantTopic = null;
    }
  }
}

