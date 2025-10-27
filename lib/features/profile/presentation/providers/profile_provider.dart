import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/data/repositories/profile_repository.dart';
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
      final repo = ProfileRepository();
      final res = await repo.getUserProfile(userId);

      res.when(
        success: (profile) {
          state = state.copyWith(
            profile: profile,
            isLoading: false,
            errorMessage: null,
          );
        },
        failure: (f) {
          state = state.copyWith(isLoading: false, errorMessage: f.message);
        },
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = state.copyWith(isLoading: true);

    try {
      _validateProfile(profile);

      final repo = ProfileRepository();

      if (state.profile == null) {
        final res = await repo.createUserProfile(profile);
        res.when(
          success: (created) {
            state = state.copyWith(
              profile: created,
              isLoading: false,
              errorMessage: null,
            );
          },
          failure: (f) {
            state = state.copyWith(isLoading: false, errorMessage: f.message);
          },
        );
      } else {
        final payload = profile.toJson();
        payload['updatedAt'] = DateTime.now().toIso8601String();
        final res = await repo.updateUserProfile(profile.id, payload);
        res.when(
          success: (_) {
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
          },
          failure: (f) {
            state = state.copyWith(isLoading: false, errorMessage: f.message);
          },
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
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
      // For now, just clear local state; actual deletion handled by auth backend
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
