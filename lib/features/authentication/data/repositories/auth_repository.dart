import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:food_delivery_app/core/data/repository_guard.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/core/services/auth_service.dart';

class AuthRepository with RepositoryGuard {
  final AuthService _auth;

  AuthRepository({AuthService? auth}) : _auth = auth ?? AuthService();

  Future<Result<AuthResponse>> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return guard(() => _auth.signUp(email: email, password: password, fullName: fullName));
  }

  Future<Result<AuthResponse>> signIn({
    required String email,
    required String password,
  }) async {
    return guard(() => _auth.signIn(email: email, password: password));
  }

  Future<Result<AuthResponse>> signInWithGoogle() async {
    return guard(() => _auth.signInWithGoogle());
  }

  Future<Result<AuthResponse>> signInWithApple() async {
    return guard(() => _auth.signInWithApple());
  }

  Future<Result<bool>> signOut() async {
    return guard(() async {
      await _auth.signOut();
      return true;
    });
  }

  Future<Result<User>> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    return guard(() => _auth.updateUser(email: email, password: password, data: data));
  }

  Future<Result<bool>> sendPasswordResetEmail(String email) async {
    return guard(() async {
      await _auth.sendPasswordResetEmail(email);
      return true;
    });
  }

  Future<Result<Session?>> refreshSession() async {
    return guard(() => _auth.refreshSession());
  }

  User? get currentUser => _auth.getCurrentUser();
  Session? get currentSession => _auth.getCurrentSession();
}

