import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:food_delivery_app/core/constants/config.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Security utilities for PayFast payment processing
class PaymentSecurity {
  /// Generate MD5 signature for PayFast payment request
  /// Required for validating payment data integrity
  static String generatePaymentSignature(Map<String, String> data) {
    AppLogger.function('PaymentSecurity.generatePaymentSignature', 'ENTER');

    try {
      // Remove signature if it exists
      final cleanData = Map<String, String>.from(data);
      cleanData.remove('signature');

      // Sort parameters alphabetically
      final sortedKeys = cleanData.keys.toList()..sort();

      // Build parameter string
      final paramString = sortedKeys
          .map((key) => '$key=${Uri.encodeComponent(cleanData[key]!)}')
          .join('&');

      // Add passphrase if configured
      final passphrase = Config.payfastPassphrase;
      final stringToHash = passphrase.isNotEmpty
          ? '$paramString&passphrase=${Uri.encodeComponent(passphrase)}'
          : paramString;

      // Generate MD5 hash
      final bytes = utf8.encode(stringToHash);
      final digest = md5.convert(bytes);
      final signature = digest.toString();

      AppLogger.success('Payment signature generated', details: signature);
      return signature;
    } catch (e, stack) {
      AppLogger.error('Failed to generate payment signature',
          error: e, stack: stack);
      rethrow;
    }
  }

  /// Verify PayFast ITN (Instant Transaction Notification) signature
  static bool verifyPaymentSignature(
    Map<String, String> data,
    String receivedSignature,
  ) {
    AppLogger.function('PaymentSecurity.verifyPaymentSignature', 'ENTER');

    try {
      final generatedSignature = generatePaymentSignature(data);
      final isValid = generatedSignature == receivedSignature;

      if (isValid) {
        AppLogger.success('Payment signature verified');
      } else {
        AppLogger.warning('Payment signature verification failed');
        AppLogger.debug('Generated vs Received: $generatedSignature vs $receivedSignature');
      }

      return isValid;
    } catch (e, stack) {
      AppLogger.error('Failed to verify payment signature',
          error: e, stack: stack);
      return false;
    }
  }

  /// Sanitize payment input to prevent injection attacks
  static String sanitizeInput(String input) {
    // Remove potentially dangerous characters
    var sanitized = input.trim();
    
    // Remove control characters
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
    
    // Remove SQL injection patterns (basic protection)
    sanitized = sanitized.replaceAll(RegExp(r'[;<>]'), '');
    
    return sanitized;
  }

  /// Validate payment amount to prevent manipulation
  static bool validateAmount(double amount) {
    // Must be positive
    if (amount <= 0) {
      AppLogger.warning('Invalid amount: must be positive');
      return false;
    }

    // Check for reasonable maximum (R 100,000)
    if (amount > 100000) {
      AppLogger.warning('Invalid amount: exceeds maximum');
      return false;
    }

    // Check decimal places (max 2)
    final decimalPlaces = amount.toString().split('.').last.length;
    if (decimalPlaces > 2) {
      AppLogger.warning('Invalid amount: too many decimal places');
      return false;
    }

    return true;
  }

  /// Validate merchant credentials
  static bool validateMerchantConfig() {
    final merchantId = Config.payfastMerchantId;
    final merchantKey = Config.payfastMerchantKey;

    if (merchantId.isEmpty || merchantKey.isEmpty) {
      AppLogger.error('Invalid PayFast configuration: Missing credentials');
      return false;
    }

    // Validate format (basic check)
    if (merchantId.length < 8 || merchantKey.length < 8) {
      AppLogger.error('Invalid PayFast configuration: Credentials too short');
      return false;
    }

    return true;
  }

  /// Generate unique payment reference
  static String generatePaymentReference(String userId, String orderId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'PAY-$userId-$orderId-$timestamp';
  }

  /// Mask card number for display
  static String maskCardNumber(String cardNumber) {
    if (cardNumber.length < 4) return '****';
    final lastFour = cardNumber.substring(cardNumber.length - 4);
    return '**** **** **** $lastFour';
  }

  /// Validate webhook IP (PayFast uses specific IPs)
  static bool validateWebhookIP(String ipAddress) {
    // PayFast valid IPs (as of documentation)
    const validIPs = [
      '197.97.145.144',
      '41.74.179.194',
      '41.74.179.195',
      '41.74.179.196',
      '41.74.179.197',
      '41.74.179.198',
      '41.74.179.199',
      // Sandbox IPs
      '41.74.179.210',
      '41.74.179.211',
    ];

    final isValid = validIPs.contains(ipAddress) || 
                    Config.isSandbox; // Allow all IPs in sandbox

    if (!isValid) {
      AppLogger.warning('Invalid webhook IP: $ipAddress');
    }

    return isValid;
  }

  /// Hash sensitive data for logging
  static String hashForLogging(String sensitiveData) {
    final bytes = utf8.encode(sensitiveData);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // First 16 chars
  }
}
