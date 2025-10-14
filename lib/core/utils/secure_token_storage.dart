import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class SecurePaymentTokenStorage {
  static final SecurePaymentTokenStorage _instance = SecurePaymentTokenStorage._internal();
  factory SecurePaymentTokenStorage() => _instance;
  SecurePaymentTokenStorage._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for secure storage
  static const String _paymentTokensKey = 'payment_tokens';
  static const String _activePaymentSessionKey = 'active_payment_session';

  /// Store a payment token securely
  static Future<void> storePaymentToken({
    required String userId,
    required String token,
    String? tokenId,
    DateTime? expiry,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Generate a unique ID for this token if not provided
      tokenId ??= const Uuid().v4();
      
      // Create a payment token object
      final paymentToken = _PaymentToken(
        id: tokenId,
        userId: userId,
        encryptedToken: _encryptToken(token),
        createdAt: DateTime.now(),
        expiry: expiry,
        metadata: metadata,
      );

      // Get existing tokens
      final existingTokens = await _getPaymentTokens(userId);
      
      // Add the new token
      existingTokens.add(paymentToken);
      
      // Store back to secure storage
      final tokensJson = jsonEncode(existingTokens.map((t) => t.toJson()).toList());
      await _storage.write(key: '$_paymentTokensKey:$userId', value: tokensJson);
      
      AppLogger.i('Payment token stored securely for user: $userId');
    } catch (e) {
      AppLogger.e('Error storing payment token: $e');
      rethrow;
    }
  }

  /// Retrieve payment tokens for a user
  static Future<List<_PaymentToken>> getPaymentTokens(String userId) async {
    try {
      final tokensJson = await _storage.read(key: '$_paymentTokensKey:$userId');
      
      if (tokensJson == null) {
        return [];
      }
      
      final List<dynamic> tokensList = jsonDecode(tokensJson);
      final tokens = tokensList.map((json) => _PaymentToken.fromJson(json)).toList();
      
      // Filter out expired tokens
      final validTokens = tokens.where((token) {
        if (token.expiry != null) {
          return DateTime.now().isBefore(token.expiry!);
        }
        return true; // No expiry set, treat as valid
      }).toList();
      
      // Update storage with non-expired tokens
      if (validTokens.length != tokens.length) {
        final tokensJson = jsonEncode(validTokens.map((t) => t.toJson()).toList());
        await _storage.write(key: '$_paymentTokensKey:$userId', value: tokensJson);
      }
      
      AppLogger.i('Retrieved ${validTokens.length} payment tokens for user: $userId');
      return validTokens;
    } catch (e) {
      AppLogger.e('Error retrieving payment tokens: $e');
      return [];
    }
  }

  /// Get a specific payment token
  static Future<String?> getPaymentToken(String userId, String tokenId) async {
    try {
      final tokens = await getPaymentTokens(userId);
      final token = tokens.firstWhere(
        (t) => t.id == tokenId,
        orElse: () => throw Exception('Token not found'),
      );
      
      if (token.expiry != null && DateTime.now().isAfter(token.expiry!)) {
        // Token is expired
        AppLogger.w('Payment token expired: $tokenId');
        return null;
      }
      
      AppLogger.i('Retrieved payment token for user: $userId');
      return _decryptToken(token.encryptedToken);
    } catch (e) {
      AppLogger.e('Error getting payment token: $e');
      return null;
    }
  }

  /// Remove a payment token
  static Future<void> removePaymentToken(String userId, String tokenId) async {
    try {
      final tokens = await _getPaymentTokens(userId);
      final filteredTokens = tokens.where((token) => token.id != tokenId).toList();
      
      // Store back to secure storage
      final tokensJson = jsonEncode(filteredTokens.map((t) => t.toJson()).toList());
      await _storage.write(key: '$_paymentTokensKey:$userId', value: tokensJson);
      
      AppLogger.i('Payment token removed for user: $userId');
    } catch (e) {
      AppLogger.e('Error removing payment token: $e');
      rethrow;
    }
  }

  /// Clear all payment tokens for a user
  static Future<void> clearPaymentTokens(String userId) async {
    try {
      await _storage.delete(key: '$_paymentTokensKey:$userId');
      AppLogger.i('Cleared all payment tokens for user: $userId');
    } catch (e) {
      AppLogger.e('Error clearing payment tokens: $e');
      rethrow;
    }
  }

  /// Store the active payment session
  static Future<void> storeActivePaymentSession(String sessionId) async {
    try {
      await _storage.write(key: _activePaymentSessionKey, value: sessionId);
      AppLogger.i('Active payment session stored: $sessionId');
    } catch (e) {
      AppLogger.e('Error storing active payment session: $e');
      rethrow;
    }
  }

  /// Get the active payment session
  static Future<String?> getActivePaymentSession() async {
    try {
      final sessionId = await _storage.read(key: _activePaymentSessionKey);
      if (sessionId != null) {
        AppLogger.i('Retrieved active payment session: $sessionId');
      }
      return sessionId;
    } catch (e) {
      AppLogger.e('Error getting active payment session: $e');
      return null;
    }
  }

  /// Remove the active payment session
  static Future<void> removeActivePaymentSession() async {
    try {
      await _storage.delete(key: _activePaymentSessionKey);
      AppLogger.i('Removed active payment session');
    } catch (e) {
      AppLogger.e('Error removing active payment session: $e');
      rethrow;
    }
  }

  /// Encrypt a token before storing
  static String _encryptToken(String token) {
    // In a real implementation, you would use proper encryption
    // For now, we'll use a simple hash as an example
    final salt = const Uuid().v4(); // Generate a random salt
    final combined = '$token$salt';
    final hash = sha256.convert(utf8.encode(combined)).toString();
    return '$hash|$salt';
  }

  /// Decrypt a token
  static String _decryptToken(String encryptedToken) {
    // In a real implementation, you would decrypt the token
    // For this example, we'll just return an empty string since actual decryption 
    // is not possible with a one-way hash
    // In a real app, you'd use proper encryption instead of hashing
    throw Exception('Cannot decrypt token encrypted with hash function. Use proper encryption in production.');
  }
  
  /// Internal method to get payment tokens without checking expiration
  static Future<List<_PaymentToken>> _getPaymentTokens(String userId) async {
    final tokensJson = await _storage.read(key: '$_paymentTokensKey:$userId');
    
    if (tokensJson == null) {
      return [];
    }
    
    final List<dynamic> tokensList = jsonDecode(tokensJson);
    return tokensList.map((json) => _PaymentToken.fromJson(json)).toList();
  }
}

/// Internal class to represent a payment token
class _PaymentToken {
  final String id;
  final String userId;
  final String encryptedToken;
  final DateTime createdAt;
  final DateTime? expiry;
  final Map<String, dynamic>? metadata;

  _PaymentToken({
    required this.id,
    required this.userId,
    required this.encryptedToken,
    required this.createdAt,
    this.expiry,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'encryptedToken': encryptedToken,
      'createdAt': createdAt.toIso8601String(),
      'expiry': expiry?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory _PaymentToken.fromJson(Map<String, dynamic> json) {
    return _PaymentToken(
      id: json['id'],
      userId: json['userId'],
      encryptedToken: json['encryptedToken'],
      createdAt: DateTime.parse(json['createdAt']),
      expiry: json['expiry'] != null ? DateTime.parse(json['expiry']) : null,
      metadata: json['metadata'],
    );
  }
}