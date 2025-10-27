import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

class ProfileRepository with RepositoryGuard {
  final DatabaseService _db;
  ProfileRepository({DatabaseService? db}) : _db = db ?? DatabaseService();

  Future<Result<UserProfile>> getUserProfile(String userId) async {
    return guard(() async {
      final row = await _db.getUserProfile(userId);
      if (row == null) {
        throw NotFoundFailure(message: 'User profile not found', code: '404');
      }
      return UserProfile.fromJson(row);
    });
  }

  Future<Result<UserProfile>> createUserProfile(UserProfile profile) async {
    return guard(() async {
      final inserted = await _db.createUserProfile(profile.toJson());
      return UserProfile.fromJson(inserted);
    });
  }

  Future<Result<bool>> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    return guard(() async {
      await _db.updateUserProfile(userId, updates);
      return true;
    });
  }
}

