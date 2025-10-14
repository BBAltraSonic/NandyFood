import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import '../constants/config.dart';

class PayFastService {
  final Dio _dio = Dio();

  /// Creates a payment request to PayFast
  /// Returns the URL to redirect the user for payment
  Future<String?> createPayment({
    required double amount,
    required String itemName,
    required String itemId,
    String? returnUrl,
    String? cancelUrl,
    String? notifyUrl,
    Map<String, dynamic>? customData,
  }) async {
    try {
      // Prepare payment parameters
      Map<String, dynamic> params = {
        'merchant_id': Config.payfastMerchantId,
        'merchant_key': Config.payfastMerchantKey,
        'return_url': returnUrl ?? '${Config.apiBaseUrl}/payment/success',
        'cancel_url': cancelUrl ?? '${Config.apiBaseUrl}/payment/cancel',
        'notify_url': notifyUrl ?? '${Config.apiBaseUrl}/payment/notify',
        'name_first': 'NandyFood',
        'email_address': 'test@example.com',  // This would come from user data in a real app
        'm_payment_id': itemId,  // Merchant's payment ID
        'amount': amount.toStringAsFixed(2),
        'item_name': itemName,
        'item_description': 'Food delivery order',
      };

      // Add custom data if provided
      if (customData != null) {
        params = {...params, ...customData};
      }

      // Create signature
      final signature = _generateSignature(params);
      params = {...params, 'signature': signature};

      // Send request to PayFast - convert params to form data string
      final formData = params.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
          
      final response = await _dio.post(
        Config.payfastProcessUrl,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,  // Don't follow redirects so we can get the payment page URL
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Return the redirect URL from PayFast
      final locationHeader = response.headers.value('location');
      return locationHeader;
    } catch (e) {
      print('Error creating PayFast payment: $e');
      return null;
    }
  }

  /// Validates payment parameters before sending to PayFast
  Future<bool> validatePayment({
    required Map<String, String> data,
  }) async {
    try {
      // Remove signature from data for validation
      final validateData = Map<String, String>.from(data);
      validateData.remove('signature');

      // Create signature from provided data
      final localSignature = _generateSignature(validateData);

      // Compare signatures
      final providedSignature = data['signature'];
      if (providedSignature != localSignature) {
        print('Signature mismatch in payment validation');
        return false;
      }

      // Validate against PayFast server
      validateData['action'] = 'validate';

      final response = await _dio.post(
        Config.payfastValidateUrl,
        data: validateData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final result = response.data.trim();
      return result == 'VALID';
    } catch (e) {
      print('Error validating PayFast payment: $e');
      return false;
    }
  }

  /// Generates the signature for PayFast API calls
  String _generateSignature(Map<String, dynamic> params) {
    // Sort parameters alphabetically by key
    final sortedKeys = params.keys.toList()..sort();

    // Build query string
    final queryString = sortedKeys
        .where((key) => params[key] != null)
        .map((key) => '$key=${_encodeValue(params[key])}')
        .join('&');

    // Add passphrase if available
    if (Config.payfastPassphrase.isNotEmpty) {
      return md5.convert(utf8.encode('$queryString&passphrase=${Config.payfastPassphrase}')).toString();
    }

    return md5.convert(utf8.encode(queryString)).toString();
  }

  /// Encodes a value for URL query string
  String _encodeValue(dynamic value) {
    if (value == null) return '';
    return Uri.encodeQueryComponent(value.toString());
  }

  /// Processes payment notification from PayFast (webhook)
  /// This would be called from your backend API
  Map<String, String> parseNotification(String notificationData) {
    final Map<String, String> params = {};

    // Parse the notification data (URL-encoded format)
    final pairs = notificationData.split('&');
    for (final pair in pairs) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        final key = Uri.decodeQueryComponent(parts[0]);
        final value = Uri.decodeQueryComponent(parts[1]);
        params[key] = value;
      }
    }

    return params;
  }
}