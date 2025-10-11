import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

// Auth state class to represent the authentication state
class AuthState {
  final User? user;
 final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Auth provider to manage authentication state
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>(
  (ref) => AuthStateNotifier(),
);

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState()) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    try {
      final auth = DatabaseService().client.auth;
      
      // Listen to auth state changes
      auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final user = session?.user;
        
        if (user != null) {
          // User is signed in
          state = AuthState(
            user: user,
            isAuthenticated: true,
          );
        } else {
          // User is signed out
          state = AuthState(
            user: null,
            isAuthenticated: false,
          );
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

 // Sign out method
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await DatabaseService().client.auth.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  // Clear error message
  void clearErrorMessage() {
    state = state.copyWith(errorMessage: null);
  }
}