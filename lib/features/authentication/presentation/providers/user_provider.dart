import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

/// State class for user data
class UserState {
  final UserProfile? userProfile;
  final bool isAuthenticated;
  final bool isLoading;
  final String? errorMessage;

  UserState({
    this.userProfile,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.errorMessage,
  });

  UserState copyWith({
    UserProfile? userProfile,
    bool? isAuthenticated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserState(
      userProfile: userProfile ?? this.userProfile,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for user state management
final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState());

  /// Load user profile from the database
  Future<void> loadUserProfile(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Sample data - in a real app, this would come from the database
      final userProfile = UserProfile(
        id: userId,
        email: 'user@example.com',
        fullName: 'John Doe',
        phoneNumber: '+1234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
        preferences: {'notifications': true},
        defaultAddress: {
          'street': '123 Main St',
          'city': 'New York',
          'zipCode': '10001',
        },
      );

      state = state.copyWith(
        userProfile: userProfile,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      // In a real app, this would update the database
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());

      state = state.copyWith(userProfile: updatedProfile, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Sign in user
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Sample data - in a real app, this would come from authentication
      final userProfile = UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: 'John Doe',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        userProfile: userProfile,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid email or password',
      );
    }
  }

  /// Sign up user
  Future<void> signUp(String email, String password, String fullName) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Sample data - in a real app, this would create a new user
      final userProfile = UserProfile(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        userProfile: userProfile,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create account',
      );
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        userProfile: null,
        isAuthenticated: false,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
