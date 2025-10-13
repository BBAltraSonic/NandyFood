import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  void _initializeAuthListener() {
    try {
      // Check if database is initialized before accessing client
      if (!DatabaseService().isInitialized) {
        print('INFO: Database not yet initialized, skipping auth listener setup');
        state = AuthState(user: null, isAuthenticated: false);
        return;
      }

      final auth = DatabaseService().client.auth;

      // Listen to auth state changes
      auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final user = session?.user;

        if (user != null) {
          // User is signed in - load roles
          await _loadUserRoles(user);
        } else {
          // User is signed out
          state = AuthState(user: null, isAuthenticated: false);
        }
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

      // If sign up is successful, create user profile in user_profiles table
      if (response.user != null) {
        await _createUserProfile(response.user!, fullName);
      }

      state = state.copyWith(isLoading: false);
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
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to switch role: ${e.toString()}',
      );
    }
  }
}
