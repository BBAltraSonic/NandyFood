import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/providers/user_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

void main() {
  group('User Authentication Flow Integration Tests', () {
    late DatabaseService dbService;
    late ProviderContainer container;

    setUp(() {
      // Enable test mode for DatabaseService to avoid pending timers
      DatabaseService.enableTestMode();
      dbService = DatabaseService();
      
      // Create a provider container for testing
      container = ProviderContainer();
    });

    tearDown(() {
      // Dispose of the provider container
      container.dispose();
      
      // Disable test mode after tests
      DatabaseService.disableTestMode();
    });

    test('successful user signup flow', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // Perform signup
      await userNotifier.signUp(
        email: 'test@example.com',
        password: 'password123',
        fullName: 'Test User',
      );
      
      // Verify that user is authenticated
      final userState = container.read(userProvider);
      expect(userState.isAuthenticated, isTrue);
      expect(userState.userProfile, isNotNull);
      expect(userState.userProfile?.email, 'test@example.com');
      expect(userState.userProfile?.fullName, 'Test User');
    });

    test('successful user login flow', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // First signup a user
      await userNotifier.signUp(
        email: 'login_test@example.com',
        password: 'password123',
        fullName: 'Login Test User',
      );
      
      // Sign out
      await userNotifier.signOut();
      
      // Verify user is signed out
      var userState = container.read(userProvider);
      expect(userState.isAuthenticated, isFalse);
      
      // Login with the same credentials
      await userNotifier.signIn(
        email: 'login_test@example.com',
        password: 'password123',
      );
      
      // Verify that user is authenticated
      userState = container.read(userProvider);
      expect(userState.isAuthenticated, isTrue);
      expect(userState.userProfile?.email, 'login_test@example.com');
    });

    test('failed login with invalid credentials', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // Attempt login with invalid credentials
      try {
        await userNotifier.signIn(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        );
        fail('Expected exception was not thrown');
      } catch (e) {
        // Verify that login failed
        final userState = container.read(userProvider);
        expect(userState.isAuthenticated, isFalse);
        expect(userState.errorMessage, isNotNull);
      }
    });

    test('failed signup with existing email', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // First signup a user
      await userNotifier.signUp(
        email: 'duplicate@example.com',
        password: 'password123',
        fullName: 'Duplicate Test User',
      );
      
      // Sign out
      await userNotifier.signOut();
      
      // Try to signup with the same email
      try {
        await userNotifier.signUp(
          email: 'duplicate@example.com',
          password: 'differentpassword',
          fullName: 'Another User',
        );
        fail('Expected exception was not thrown');
      } catch (e) {
        // Verify that signup failed
        final userState = container.read(userProvider);
        expect(userState.isAuthenticated, isFalse);
        expect(userState.errorMessage, isNotNull);
      }
    });

    test('user profile update flow', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // First signup a user
      await userNotifier.signUp(
        email: 'profile_update@example.com',
        password: 'password123',
        fullName: 'Profile Update User',
      );
      
      // Verify initial profile
      var userState = container.read(userProvider);
      expect(userState.userProfile?.fullName, 'Profile Update User');
      
      // Update user profile
      final updatedProfile = userState.userProfile!.copyWith(
        fullName: 'Updated Name',
        phoneNumber: '+1234567890',
      );
      
      await userNotifier.updateUserProfile(updatedProfile);
      
      // Verify that profile was updated
      userState = container.read(userProvider);
      expect(userState.userProfile?.fullName, 'Updated Name');
      expect(userState.userProfile?.phoneNumber, '+1234567890');
    });

    test('user logout flow', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // First signup a user
      await userNotifier.signUp(
        email: 'logout_test@example.com',
        password: 'password123',
        fullName: 'Logout Test User',
      );
      
      // Verify user is authenticated
      var userState = container.read(userProvider);
      expect(userState.isAuthenticated, isTrue);
      
      // Logout
      await userNotifier.signOut();
      
      // Verify user is logged out
      userState = container.read(userProvider);
      expect(userState.isAuthenticated, isFalse);
      expect(userState.userProfile, isNull);
    });

    test('persistent user session after app restart', () async {
      final userNotifier = container.read(userProvider.notifier);
      
      // First signup a user
      await userNotifier.signUp(
        email: 'session_test@example.com',
        password: 'password123',
        fullName: 'Session Test User',
      );
      
      // Verify user is authenticated
      var userState = container.read(userProvider);
      expect(userState.isAuthenticated, isTrue);
      
      // Create a new provider container to simulate app restart
      final newContainer = ProviderContainer();
      final newUserNotifier = newContainer.read(userProvider.notifier);
      
      // Load user profile (simulating app startup)
      await newUserNotifier.loadUserProfile(userState.userProfile!.id);
      
      // Verify that user session persists
      final newUserState = newContainer.read(userProvider);
      expect(newUserState.isAuthenticated, isTrue);
      expect(newUserState.userProfile?.email, 'session_test@example.com');
      
      // Clean up
      newContainer.dispose();
    });
  });
}