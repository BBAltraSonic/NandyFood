import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../constants/config.dart';
import '../utils/logger.dart';

class PayFastSecurity {
  /// Validates a PayFast payment notification using the signature
  static bool validateNotificationSignature(Map<String, dynamic> data) {
    try {
      // Extract signature from data
      final signature = data['signature'] as String?;
      if (signature == null) {
        AppLogger.e('PayFast validation failed: No signature provided');
        return false;
      }

      // Remove signature from data for validation
      final validationData = Map<String, dynamic>.from(data);
      validationData.remove('signature');

      // Build the signature string according to PayFast specification
      final signatureString = buildSignatureString(validationData);

      // Add passphrase to signature string
      final passphrase = Config.payfastPassphrase;
      final fullSignatureString = '$signatureString&PAYFAST_PASSPHRASE=$passphrase';

      // Calculate expected signature
      final expectedSignature = md5.convert(utf8.encode(fullSignatureString)).toString();

      // Compare signatures
      final isValid = expectedSignature == signature;
      
      AppLogger.payment(
        'Payment validation ${isValid ? 'PASSED' : 'FAILED'}',
        validationData['m_payment_id']?.toString() ?? 'unknown',
        isValid ? 'VALID' : 'INVALID',
      );

      return isValid;
    } catch (e) {
      AppLogger.e('Error validating PayFast notification signature: $e');
      return false;
    }
  }

  /// Builds the signature string according to PayFast specification
  static String buildSignatureString(Map<String, dynamic> data) {
    // Sort parameters by key name (alphabetically)
    final sortedKeys = data.keys.toList()..sort();

    // Build the signature string
    final signatureParts = <String>[];
    for (final key in sortedKeys) {
      final value = data[key];
      
      // Skip signature field
      if (key == 'signature') continue;
      
      // Include only non-null values
      if (value != null) {
        signatureParts.add('$key=${_encodeValue(value)}');
      }
    }

    return signatureParts.join('&');
  }

  /// Encodes a value for signature calculation
  static String _encodeValue(dynamic value) {
    // URL encode the value
    final stringValue = value.toString();
    return Uri.encodeQueryComponent(stringValue);
  }

  /// Validates payment parameters for security issues
  static bool validatePaymentParameters({
    required double amount,
    required String itemName,
    String? returnUrl,
    String? cancelUrl,
    String? notifyUrl,
    String? email,
  }) {
    try {
      // Validate amount is positive
      if (amount <= 0) {
        AppLogger.e('Payment validation failed: Invalid amount $amount');
        return false;
      }

      // Validate item name is not empty
      if (itemName.isEmpty) {
        AppLogger.e('Payment validation failed: Empty item name');
        return false;
      }

      // Validate URLs contain expected domain
      final expectedDomain = Uri.parse(Config.payfastBaseUrl).host;
      
      if (returnUrl != null && !returnUrl.contains(expectedDomain)) {
        AppLogger.e('Payment validation failed: Invalid return URL $returnUrl');
        return false;
      }

      if (cancelUrl != null && !cancelUrl.contains(expectedDomain)) {
        AppLogger.e('Payment validation failed: Invalid cancel URL $cancelUrl');
        return false;
      }

      if (notifyUrl != null && !notifyUrl.contains(expectedDomain)) {
        AppLogger.e('Payment validation failed: Invalid notify URL $notifyUrl');
        return false;
      }

      // Validate email format if provided
      if (email != null && email.isNotEmpty) {
        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
        if (!emailRegex.hasMatch(email)) {
          AppLogger.e('Payment validation failed: Invalid email format $email');
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.e('Error validating payment parameters: $e');
      return false;
    }
  }

  /// Sanitizes payment data to prevent injection attacks
  static Map<String, dynamic> sanitizePaymentData(Map<String, dynamic> data) {
    final sanitizedData = <String, dynamic>{};

    for (final entry in data.entries) {
      // Sanitize the key
      final sanitizedKey = _sanitizeString(entry.key);

      // Sanitize the value based on type
      dynamic sanitizedValue;
      if (entry.value is String) {
        sanitizedValue = _sanitizeString(entry.value);
      } else {
        sanitizedValue = entry.value; // Pass through non-string values
      }

      sanitizedData[sanitizedKey] = sanitizedValue;
    }

    return sanitizedData;
  }

  /// Sanitizes a string to prevent injection attacks
  static String _sanitizeString(String input) {
    // Remove potentially dangerous characters
    return input
        .replaceAll(RegExp(r'[<>"\']'), '')  // Remove HTML/JS injection characters
        .replaceAll(RegExp(r'[;()&|]'), '')  // Remove SQL injection characters
        .trim();  // Remove leading/trailing whitespace
  }

  /// Checks if an amount matches expected pattern (to prevent tampering)
  static bool isValidAmount(double amount, double expectedAmount, {double tolerance = 0.01}) {
    return (amount - expectedAmount).abs() <= tolerance;
  }

  /// Generates a secure ID for the payment
  static String generateSecurePaymentId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    final rawId = '$timestamp$random';
    return sha256.convert(utf8.encode(rawId)).toString().substring(0, 16);
  }
}