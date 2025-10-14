import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  static SecureStorageService get instance {
    _instance ??= SecureStorageService._internal();
    return _instance!;
  }

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accountName: 'nandyfood_secure_storage',
    ),
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  SecureStorageService._internal();

  // Store authentication token securely
  Future<void> storeAuthToken(String token) async {
    AppLogger.function('SecureStorageService.storeAuthToken', 'ENTER');
    
    try {
      await _storage.write(
        key: 'auth_token',
        value: token,
      );
      
      AppLogger.success('Auth token stored securely');
      AppLogger.function('SecureStorageService.storeAuthToken', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to store auth token', error: e);
      AppLogger.function('SecureStorageService.storeAuthToken', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Read authentication token
  Future<String?> getAuthToken() async {
    AppLogger.function('SecureStorageService.getAuthToken', 'ENTER');
    
    try {
      final token = await _storage.read(key: 'auth_token');
      
      AppLogger.function('SecureStorageService.getAuthToken', 'EXIT', 
          result: token != null ? 'TOKEN_FOUND' : 'NO_TOKEN');
      return token;
    } catch (e) {
      AppLogger.error('Failed to read auth token', error: e);
      AppLogger.function('SecureStorageService.getAuthToken', 'EXIT', result: 'Error');
      return null;
    }
  }

  // Delete authentication token
  Future<void> deleteAuthToken() async {
    AppLogger.function('SecureStorageService.deleteAuthToken', 'ENTER');
    
    try {
      await _storage.delete(key: 'auth_token');
      
      AppLogger.success('Auth token deleted');
      AppLogger.function('SecureStorageService.deleteAuthToken', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to delete auth token', error: e);
      AppLogger.function('SecureStorageService.deleteAuthToken', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    AppLogger.function('SecureStorageService.storeRefreshToken', 'ENTER');
    
    try {
      await _storage.write(
        key: 'refresh_token',
        value: token,
      );
      
      AppLogger.success('Refresh token stored securely');
      AppLogger.function('SecureStorageService.storeRefreshToken', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to store refresh token', error: e);
      AppLogger.function('SecureStorageService.storeRefreshToken', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Read refresh token
  Future<String?> getRefreshToken() async {
    AppLogger.function('SecureStorageService.getRefreshToken', 'ENTER');
    
    try {
      final token = await _storage.read(key: 'refresh_token');
      
      AppLogger.function('SecureStorageService.getRefreshToken', 'EXIT', 
          result: token != null ? 'TOKEN_FOUND' : 'NO_TOKEN');
      return token;
    } catch (e) {
      AppLogger.error('Failed to read refresh token', error: e);
      AppLogger.function('SecureStorageService.getRefreshToken', 'EXIT', result: 'Error');
      return null;
    }
  }

  // Store user preferences securely
  Future<void> storeUserPreference(String key, String value) async {
    AppLogger.function('SecureStorageService.storeUserPreference', 'ENTER',
        params: {'key': key});
    
    try {
      await _storage.write(
        key: 'user_pref_$key',
        value: value,
      );
      
      AppLogger.success('User preference stored: $key');
      AppLogger.function('SecureStorageService.storeUserPreference', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to store user preference: $key', error: e);
      AppLogger.function('SecureStorageService.storeUserPreference', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Read user preferences
  Future<String?> getUserPreference(String key) async {
    AppLogger.function('SecureStorageService.getUserPreference', 'ENTER',
        params: {'key': key});
    
    try {
      final value = await _storage.read(key: 'user_pref_$key');
      
      AppLogger.function('SecureStorageService.getUserPreference', 'EXIT', 
          result: value != null ? 'VALUE_FOUND' : 'NO_VALUE');
      return value;
    } catch (e) {
      AppLogger.error('Failed to read user preference: $key', error: e);
      AppLogger.function('SecureStorageService.getUserPreference', 'EXIT', result: 'Error');
      return null;
    }
  }

  // Store payment method tokens securely (only tokens, never sensitive data)
  Future<void> storePaymentToken(String key, String token) async {
    AppLogger.function('SecureStorageService.storePaymentToken', 'ENTER',
        params: {'key': key});
    
    try {
      await _storage.write(
        key: 'payment_token_$key',
        value: token,
      );
      
      AppLogger.success('Payment token stored: $key');
      AppLogger.function('SecureStorageService.storePaymentToken', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to store payment token: $key', error: e);
      AppLogger.function('SecureStorageService.storePaymentToken', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Read payment method tokens
  Future<String?> getPaymentToken(String key) async {
    AppLogger.function('SecureStorageService.getPaymentToken', 'ENTER',
        params: {'key': key});
    
    try {
      final token = await _storage.read(key: 'payment_token_$key');
      
      AppLogger.function('SecureStorageService.getPaymentToken', 'EXIT', 
          result: token != null ? 'TOKEN_FOUND' : 'NO_TOKEN');
      return token;
    } catch (e) {
      AppLogger.error('Failed to read payment token: $key', error: e);
      AppLogger.function('SecureStorageService.getPaymentToken', 'EXIT', result: 'Error');
      return null;
    }
  }

  // Delete all stored data (for logout)
  Future<void> deleteAll() async {
    AppLogger.function('SecureStorageService.deleteAll', 'ENTER');
    
    try {
      await _storage.deleteAll();
      
      AppLogger.success('All secure storage cleared');
      AppLogger.function('SecureStorageService.deleteAll', 'EXIT');
    } catch (e) {
      AppLogger.error('Failed to clear secure storage', error: e);
      AppLogger.function('SecureStorageService.deleteAll', 'EXIT', result: 'Error');
      rethrow;
    }
  }

  // Check if storage contains a key
  Future<bool> containsKey(String key) async {
    AppLogger.function('SecureStorageService.containsKey', 'ENTER',
        params: {'key': key});
    
    try {
      final value = await _storage.read(key: key);
      final result = value != null;
      
      AppLogger.function('SecureStorageService.containsKey', 'EXIT', 
          result: result.toString());
      return result;
    } catch (e) {
      AppLogger.error('Failed to check key existence: $key', error: e);
      AppLogger.function('SecureStorageService.containsKey', 'EXIT', result: 'Error');
      return false;
    }
  }

  // Test storage functionality
  Future<bool> testStorage() async {
    AppLogger.function('SecureStorageService.testStorage', 'ENTER');
    
    try {
      const testKey = 'storage_test';
      const testValue = 'test_data_123';
      
      // Write test value
      await _storage.write(key: testKey, value: testValue);
      
      // Read test value
      final readValue = await _storage.read(key: testKey);
      
      // Delete test value
      await _storage.delete(key: testKey);
      
      final success = readValue == testValue;
      
      AppLogger.function('SecureStorageService.testStorage', 'EXIT', 
          result: success ? 'SUCCESS' : 'FAILURE');
      return success;
    } catch (e) {
      AppLogger.error('Storage test failed', error: e);
      AppLogger.function('SecureStorageService.testStorage', 'EXIT', result: 'ERROR');
      return false;
    }
  }
}