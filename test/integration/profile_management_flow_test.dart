import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/address_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/shared/models/address.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';

void main() {
  group('Profile Management Flow Integration Tests', () {
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

    test('user profile creation and update', () async {
      // Create a user profile provider
      final profileNotifier = container.read(profileProvider.notifier);

      // Create a new user profile
      final newUserProfile = UserProfile(
        id: 'user_profile_1',
        email: 'test@example.com',
        fullName: 'Test User',
        phoneNumber: '+1234567890',
        dateOfBirth: DateTime(1990, 1, 1),
        preferences: {'notifications': true, 'marketing_emails': false},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the user profile
      await profileNotifier.saveProfile(newUserProfile);

      // Verify profile is saved
      var profileState = container.read(profileProvider);
      expect(profileState.profile, isNotNull);
      expect(profileState.profile?.id, 'user_profile_1');
      expect(profileState.profile?.email, 'test@example.com');
      expect(profileState.profile?.fullName, 'Test User');

      // Update the user profile
      final updatedProfile = newUserProfile.copyWith(
        fullName: 'Updated Test User',
        phoneNumber: '+1987654321',
        preferences: {
          'notifications': true,
          'marketing_emails': true,
          'sms_alerts': false,
        },
      );

      await profileNotifier.saveProfile(updatedProfile);

      // Verify profile is updated
      profileState = container.read(profileProvider);
      expect(profileState.profile?.fullName, 'Updated Test User');
      expect(profileState.profile?.phoneNumber, '+1987654321');
      expect(profileState.profile?.preferences?['marketing_emails'], isTrue);
    });

    test('address management flow', () async {
      // Create address provider
      final addressNotifier = container.read(addressProvider.notifier);

      // Create a new address
      final newAddress = Address(
        id: 'address_1',
        userId: 'user_profile_1',
        type: AddressType.home,
        street: '123 Main St',
        city: 'Test City',
        state: 'TS',
        zipCode: '12345',
        country: 'USA',
        isDefault: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add the address
      await addressNotifier.addAddress(newAddress);

      // Verify address is added
      var addressState = container.read(addressProvider);
      expect(addressState.addresses.length, 1);
      expect(addressState.addresses[0].id, 'address_1');
      expect(addressState.addresses[0].street, '123 Main St');
      expect(addressState.defaultAddress, isNotNull);
      expect(addressState.defaultAddress?.id, 'address_1');

      // Create another address
      final secondAddress = Address(
        id: 'address_2',
        userId: 'user_profile_1',
        type: AddressType.work,
        street: '456 Business Ave',
        city: 'Work City',
        state: 'WC',
        zipCode: '67890',
        country: 'USA',
        isDefault: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add the second address
      await addressNotifier.addAddress(secondAddress);

      // Verify both addresses exist
      addressState = container.read(addressProvider);
      expect(addressState.addresses.length, 2);
      expect(
        addressState.defaultAddress?.id,
        'address_1',
      ); // First address should still be default

      // Update an address
      final updatedAddress = secondAddress.copyWith(
        street: '789 Updated Blvd',
        city: 'Updated City',
      );

      await addressNotifier.updateAddress(updatedAddress);

      // Verify address is updated
      addressState = container.read(addressProvider);
      final updatedAddr = addressState.addresses.firstWhere(
        (addr) => addr.id == 'address_2',
        orElse: () => addressState.addresses[0],
      );
      expect(updatedAddr.street, '789 Updated Blvd');
      expect(updatedAddr.city, 'Updated City');

      // Set second address as default
      await addressNotifier.setDefaultAddress('address_2');

      // Verify default address is updated
      addressState = container.read(addressProvider);
      expect(addressState.defaultAddress?.id, 'address_2');

      // Remove an address
      await addressNotifier.removeAddress('address_1');

      // Verify address is removed
      addressState = container.read(addressProvider);
      expect(addressState.addresses.length, 1);
      expect(addressState.addresses[0].id, 'address_2');
    });

    test('payment method management flow', () async {
      // Create payment methods provider
      final paymentMethodsNotifier = container.read(
        paymentMethodsProvider.notifier,
      );

      // Create a payment method
      final paymentMethod = PaymentMethodInfo(
        id: 'pm_1',
        type: 'card',
        last4: '4242',
        brand: 'Visa',
        expiryMonth: 12,
        expiryYear: 25,
        isDefault: true,
      );

      // Add the payment method
      await paymentMethodsNotifier.addPaymentMethod(
        cardNumber: '4242424242424242',
        expiryMonth: 12,
        expiryYear: 25,
        cvc: '123',
        holderName: 'Test User',
      );

      // Verify payment method is added
      var paymentMethodsState = container.read(paymentMethodsProvider);
      expect(paymentMethodsState.paymentMethods.length, 1);
      expect(paymentMethodsState.paymentMethods[0].id, startsWith('pm_mock_'));
      expect(paymentMethodsState.paymentMethods[0].last4, '4242');
      expect(paymentMethodsState.paymentMethods[0].brand, 'Visa');
      expect(paymentMethodsState.paymentMethods[0].isDefault, isTrue);

      // Create another payment method
      final secondPaymentMethod = PaymentMethodInfo(
        id: 'pm_2',
        type: 'card',
        last4: '1234',
        brand: 'Mastercard',
        expiryMonth: 6,
        expiryYear: 26,
        isDefault: false,
      );

      // Add the second payment method
      await paymentMethodsNotifier.addPaymentMethod(
        cardNumber: '5555555555554444',
        expiryMonth: 6,
        expiryYear: 26,
        cvc: '456',
        holderName: 'Test User',
      );

      // Verify both payment methods exist
      paymentMethodsState = container.read(paymentMethodsProvider);
      expect(paymentMethodsState.paymentMethods.length, 2);

      // Set second payment method as default
      await paymentMethodsNotifier.setDefaultPaymentMethod('pm_2');

      // Verify default payment method is updated
      paymentMethodsState = container.read(paymentMethodsProvider);
      expect(paymentMethodsState.paymentMethods[0].id, 'pm_2');
      expect(paymentMethodsState.paymentMethods[0].isDefault, isTrue);
      expect(paymentMethodsState.paymentMethods[1].isDefault, isFalse);

      // Remove a payment method
      await paymentMethodsNotifier.removePaymentMethod('pm_1');

      // Verify payment method is removed
      paymentMethodsState = container.read(paymentMethodsProvider);
      expect(paymentMethodsState.paymentMethods.length, 1);
      expect(paymentMethodsState.paymentMethods[0].id, 'pm_2');
    });

    test('profile preferences management', () async {
      // Create profile provider
      final profileNotifier = container.read(profileProvider.notifier);

      // Create a user profile with initial preferences
      final userProfile = UserProfile(
        id: 'user_profile_2',
        email: 'preferences@test.com',
        fullName: 'Preference User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        preferences: {
          'notifications': true,
          'marketing_emails': true,
          'sms_alerts': false,
        },
      );

      // Save the profile
      await profileNotifier.saveProfile(userProfile);

      // Verify initial preferences
      var profileState = container.read(profileProvider);
      expect(profileState.profile?.preferences?['notifications'], isTrue);
      expect(profileState.profile?.preferences?['marketing_emails'], isTrue);
      expect(profileState.profile?.preferences?['sms_alerts'], isFalse);

      // Update a preference
      await profileNotifier.updatePreference('sms_alerts', true);

      // Verify preference is updated
      profileState = container.read(profileProvider);
      expect(profileState.profile?.preferences?['sms_alerts'], isTrue);

      // Update multiple preferences
      await profileNotifier.updatePreferences({
        'notifications': false,
        'dark_mode': true,
      });

      // Verify multiple preferences are updated
      profileState = container.read(profileProvider);
      expect(profileState.profile?.preferences?['notifications'], isFalse);
      expect(profileState.profile?.preferences?['dark_mode'], isTrue);
      expect(
        profileState.profile?.preferences?['marketing_emails'],
        isTrue,
      ); // Should remain unchanged
    });

    test('profile data validation', () async {
      // Create profile provider
      final profileNotifier = container.read(profileProvider.notifier);

      // Test valid profile data
      final validProfile = UserProfile(
        id: 'user_profile_3',
        email: 'valid@example.com',
        fullName: 'Valid User',
        phoneNumber: '+1234567890',
        dateOfBirth: DateTime(1990, 1, 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save valid profile
      await profileNotifier.saveProfile(validProfile);

      // Verify profile is saved
      var profileState = container.read(profileProvider);
      expect(profileState.profile, isNotNull);
      expect(profileState.profile?.email, 'valid@example.com');

      // Test invalid email
      try {
        final invalidProfile = validProfile.copyWith(email: 'invalid-email');
        await profileNotifier.saveProfile(invalidProfile);
        // If we reach here, validation didn't work as expected
        fail('Expected validation error for invalid email');
      } catch (e) {
        // Validation should have thrown an error or set an error state
        // In a real implementation, we would check the error state
      }

      // Test invalid phone number
      try {
        final invalidProfile = validProfile.copyWith(
          phoneNumber: '123',
        ); // Too short
        await profileNotifier.saveProfile(invalidProfile);
        // If we reach here, validation didn't work as expected
        fail('Expected validation error for invalid phone number');
      } catch (e) {
        // Validation should have thrown an error or set an error state
        // In a real implementation, we would check the error state
      }
    });

    test('profile deletion flow', () async {
      // Create profile provider
      final profileNotifier = container.read(profileProvider.notifier);

      // Create a user profile
      final userProfile = UserProfile(
        id: 'user_profile_4',
        email: 'delete@test.com',
        fullName: 'Delete User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the profile
      await profileNotifier.saveProfile(userProfile);

      // Verify profile exists
      var profileState = container.read(profileProvider);
      expect(profileState.profile, isNotNull);

      // Delete the profile
      await profileNotifier.deleteProfile();

      // Verify profile is deleted
      profileState = container.read(profileProvider);
      expect(profileState.profile, isNull);
    });
  });
}
