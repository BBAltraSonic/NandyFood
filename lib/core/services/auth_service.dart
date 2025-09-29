import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:food_delivery_app/core/services/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late GoTrueClient _auth;
  late SupabaseClient _client;

  GoTrueClient get auth => _auth;

  Future<void> initialize() async {
    _client = DatabaseService().client;
    _auth = _client.auth;
    
    // Listen to auth state changes
    _auth.onAuthStateChange.listen((data) {
      final session = data.session;
      final user = session?.user;
      
      // Handle auth state changes
      if (user != null) {
        // User is signed in
        print('User signed in: ${user.email}');
      } else {
        // User is signed out
        print('User signed out');
      }
    });
  }

  // Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
      },
    );
    
    // If sign up is successful, create user profile
    if (response.user != null) {
      await _createUserProfile(response.user!, fullName);
    }
    
    return response;
  }

  // Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutterdemo://login-callback/',
    );
  }

  // Sign in with Apple
  Future<void> signInWithApple() async {
    await _auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutterdemo://login-callback/',
    );
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Get current session
  Session? getCurrentSession() {
    return _auth.currentSession;
  }

  // Update user profile
  Future<User> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    final response = await _auth.updateUser(
      UserAttributes(
        email: email,
        password: password,
        data: data,
      ),
    );
    return response.user!;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // Refresh session
  Future<Session?> refreshSession() async {
    try {
      final response = await _auth.refreshSession();
      return response.session;
    } catch (e) {
      print('Error refreshing session: $e');
      return null;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(User user, String fullName) async {
    try {
      await _client.from('user_profiles').insert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }
}