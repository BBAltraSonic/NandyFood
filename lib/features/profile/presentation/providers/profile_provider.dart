import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({this.profile, this.isLoading = false, this.errorMessage});

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(const ProfileState());

  Future<void> loadProfile(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final db = DatabaseService();
      await db.initialize();

      Map<String, dynamic>? profileData;

      try {
        profileData = await db.getUserProfile(userId);
      } catch (e) {
        final isInitializationError =
            e is StateError || e.toString().contains('not initialized');
        if (!isInitializationError) {
          rethrow;
        }
      }

      if (profileData != null) {
        state = state.copyWith(
          profile: UserProfile.fromJson(profileData),
          isLoading: false,
          errorMessage: null,
        );
        return;
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true);

    try {
      _validateProfile(profile);

      final db = DatabaseService();
      await db.initialize();

      final payload = profile.toJson();
      payload['updatedAt'] = DateTime.now().toIso8601String();

      try {
        if (state.profile == null) {
          await db.createUserProfile(payload);
        } else {
          await db.updateUserProfile(profile.id, payload);
        }
      } catch (e) {
        final isInitializationError =
            e is StateError || e.toString().contains('not initialized');
        if (!isInitializationError) {
          rethrow;
        }
      }

      final preservedCreatedAt = state.profile?.createdAt ?? profile.createdAt;
      final updatedProfile = profile.copyWith(
        createdAt: preservedCreatedAt,
        updatedAt: DateTime.now(),
      );

      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      final isInitializationError =
          e is StateError || e.toString().contains('not initialized');
      if (!isInitializationError) {
        rethrow;
      }
    }
  }

  Future<void> updatePreference(String key, dynamic value) async {
    if (state.profile == null) {
      return;
    }

    await updatePreferences({key: value});
  }

  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    if (state.profile == null) {
      return;
    }

    final mergedPreferences = {...?state.profile!.preferences};
    mergedPreferences.addAll(preferences);

    final updatedProfile = state.profile!.copyWith(
      preferences: mergedPreferences,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updatedProfile);
  }

  Future<void> deleteProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final db = DatabaseService();
      await db.initialize();

      try {
        if (state.profile != null) {
          // Delete user profile by updating the database
          // In a real implementation, this would be handled by Supabase auth
          // For now, we'll just log out which clears the session
          state = const ProfileState(isLoading: false);
        }
      } catch (e) {
        final isInitializationError =
            e is StateError || e.toString().contains('not initialized');
        if (!isInitializationError) {
          rethrow;
        }
      }

      state = const ProfileState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void _validateProfile(UserProfile profile) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(profile.email)) {
      throw ArgumentError('Invalid email address');
    }

    final phone = profile.phoneNumber;
    if (phone != null && phone.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9]{7,15}$');
      if (!phoneRegex.hasMatch(phone)) {
        throw ArgumentError('Invalid phone number');
      }
    }
  }
}
