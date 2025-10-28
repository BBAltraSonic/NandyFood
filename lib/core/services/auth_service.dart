import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/config/environment_config.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  GoogleSignIn? _googleSignIn;

  SupabaseClient get _client => Supabase.instance.client;
  GoTrueClient get auth => _client.auth;

  Future<void> initialize() async {
    // Listen to auth state changes
    auth.onAuthStateChange.listen((data) {
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
    final response = await auth.signUp(
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
    final response = await auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    try {
      // Get Google Sign-In configuration from environment
      // For now, use environment variable directly
      final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID'];
      if (serverClientId == null || serverClientId.isEmpty) {
        throw AuthException(
          'Google Sign-In is not properly configured. Please contact support.',
          statusCode: 'config_error',
        );
      }

      // Initialize Google Sign-In if not already done
      _googleSignIn ??= GoogleSignIn(
        serverClientId: serverClientId,
        scopes: ['email', 'profile'],
      );

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw AuthException(
          'Google sign-in was canceled by user',
          statusCode: 'user_cancelled',
        );
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw AuthException(
          'Failed to retrieve Google credentials. Please try again.',
          statusCode: 'credential_error',
        );
      }

      // Sign in to Supabase with Google credentials
      final response = await auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Create user profile if first time sign-in
      if (response.user != null) {
        await _ensureUserProfileExists(
          response.user!,
          googleUser.displayName ?? googleUser.email,
        );
      }

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('network')) {
        throw AuthException(
          'Network error. Please check your internet connection and try again.',
          statusCode: 'network_error',
        );
      } else if (e.toString().contains('PlatformException')) {
        throw AuthException(
          'Google sign-in is not properly configured. Please contact support.',
          statusCode: 'config_error',
        );
      } else if (e.toString().contains('User already exists')) {
        throw AuthException(
          'An account with this email already exists. Please sign in with your password.',
          statusCode: 'duplicate_account',
        );
      }
      throw AuthException(
        'Google sign-in failed: ${e.toString()}',
        statusCode: 'unknown_error',
      );
    }
  }

  // Sign in with Apple
  Future<AuthResponse> signInWithApple() async {
    try {
      // Check if Apple Sign-In is available (iOS 13+)
      if (!Platform.isIOS) {
        throw AuthException(
          'Apple Sign-In is only available on iOS devices.',
          statusCode: 'platform_error',
        );
      }

      // Check if Apple Sign-In is available on device
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw AuthException(
          'Apple Sign-In is not available on this device. Please use iOS 13 or later.',
          statusCode: 'unavailable',
        );
      }

      // Trigger Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw AuthException(
          'Failed to retrieve Apple ID token. Please try again.',
          statusCode: 'credential_error',
        );
      }

      // Sign in to Supabase with Apple credentials
      final response = await auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      // Create/update user profile with name if available
      if (response.user != null) {
        final fullName =
            '${credential.givenName ?? ''} ${credential.familyName ?? ''}'
                .trim();
        await _ensureUserProfileExists(
          response.user!,
          fullName.isNotEmpty ? fullName : response.user!.email ?? 'Apple User',
        );
      }

      return response;
    } on AuthException {
      rethrow;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AuthException(
          'Apple sign-in was canceled by user',
          statusCode: 'user_cancelled',
        );
      } else if (e.code == AuthorizationErrorCode.failed) {
        throw AuthException(
          'Apple sign-in failed. Please try again.',
          statusCode: 'sign_in_failed',
        );
      } else if (e.code == AuthorizationErrorCode.notHandled) {
        throw AuthException(
          'Apple sign-in could not be completed. Please try again.',
          statusCode: 'not_handled',
        );
      }
      throw AuthException(
        'Apple sign-in error: ${e.message}',
        statusCode: e.code.toString(),
      );
    } catch (e) {
      if (e.toString().contains('network')) {
        throw AuthException(
          'Network error. Please check your internet connection and try again.',
          statusCode: 'network_error',
        );
      } else if (e.toString().contains('User already exists')) {
        throw AuthException(
          'An account with this email already exists. Please sign in with your password.',
          statusCode: 'duplicate_account',
        );
      }
      throw AuthException(
        'Apple sign-in failed: ${e.toString()}',
        statusCode: 'unknown_error',
      );
    }
  }

  // Get current user
  User? getCurrentUser() {
    return auth.currentUser;
  }

  // Get current session
  Session? getCurrentSession() {
    return auth.currentSession;
  }

  // Update user profile
  Future<User> updateUser({
    String? email,
    String? password,
    Map<String, dynamic>? data,
  }) async {
    final response = await auth.updateUser(
      UserAttributes(email: email, password: password, data: data),
    );
    return response.user!;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.resetPasswordForEmail(email);
  }

  // Refresh session
  Future<Session?> refreshSession() async {
    try {
      final response = await auth.refreshSession();
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

  // Ensure user profile exists (for social sign-in)
  Future<void> _ensureUserProfileExists(User user, String fullName) async {
    try {
      // Check if profile already exists
      final existingProfile = await _client
          .from('user_profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Create new profile
        await _createUserProfile(user, fullName);
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
    }
  }

  /// Get Google Server Client ID from environment configuration
  String? get _googleServerClientId {
    return EnvironmentConfig.googleServerClientId;
  }

  /// Validate Google Sign-In configuration
  bool get isGoogleSignInConfigured {
    return EnvironmentConfig.isGoogleSignInEnabled;
  }

  /// Get supported authentication methods
  List<AuthMethod> get supportedAuthMethods {
    final methods = <AuthMethod>[AuthMethod.email];

    if (isGoogleSignInConfigured) {
      methods.add(AuthMethod.google);
    }

    // Note: Apple Sign-In can be added here when configured
    // if (_isAppleSignInConfigured) {
    //   methods.add(AuthMethod.apple);
    // }

    return methods;
  }

  /// Enhanced sign out with cleanup
  Future<void> signOut() async {
    try {
      await auth.signOut();

      // Sign out from Google if signed in
      if (_googleSignIn != null && await _googleSignIn!.isSignedIn()) {
        await _googleSignIn!.signOut();
      }

      // Note: Apple Sign-In sign out can be added here when implemented

      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
      // Still try to clear local session even if provider sign out fails
      await auth.signOut();
      rethrow;
    }
  }

  /// Check if user is currently signed in with any provider
  Future<bool> isSignedIn() async {
    return auth.currentUser != null;
  }

  /// Get current user with enhanced error handling
  User? get currentUser {
    try {
      return auth.currentUser;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}

/// Supported authentication methods
enum AuthMethod {
  email,
  google,
  apple,
}
