import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../utils/logger.dart';

class PaymentSecurityHeaders {
  /// Add security headers to payment requests
  static Options addSecurityHeaders({
    Map<String, dynamic>? additionalHeaders,
    bool includeAuth = false,
    String? authToken,
  }) {
    final headers = <String, String>{
      // Standard security headers
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains; preload',
      'Referrer-Policy': 'strict-origin-when-cross-origin',
      'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
      
      // Custom security headers for payments
      'X-Payment-Request-ID': const Uuid().v4(),
      'X-Payment-Timestamp': DateTime.now().toIso8601String(),
      'X-Payment-Origin': 'mobile-app',
      
      // Content type for form data (typical for payment gateways)
      'Content-Type': 'application/x-www-form-urlencoded',
      
      // User agent to identify our app
      'User-Agent': 'NandyFood-Payments/1.0',
    };

    // Add authentication header if required
    if (includeAuth && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    // Add any additional headers provided
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders.cast<String, String>());
    }

    return Options(
      headers: headers,
      contentType: Headers.formUrlEncodedContentType,
      followRedirects: false,
      validateStatus: (status) => status != null && status < 500,
    );
  }

  /// Validate security headers in response
  static bool validateResponseSecurityHeaders(Response response) {
    try {
      final headers = response.headers;
      
      // Check for required security headers
      final hasContentTypeOptions = headers.value('x-content-type-options')?.toLowerCase() == 'nosniff';
      final hasFrameOptions = headers.value('x-frame-options') != null;
      final hasXssProtection = headers.value('x-xss-protection') != null;
      
      final isValid = hasContentTypeOptions && hasFrameOptions && hasXssProtection;
      
      if (!isValid) {
        AppLogger.w('Response missing security headers: ${response.realUri}');
      } else {
        AppLogger.d('Response security headers validated: ${response.realUri}');
      }
      
      return isValid;
    } catch (e) {
      AppLogger.e('Error validating response security headers: $e');
      return false;
    }
  }

  /// Create a Dio instance with security interceptors
  static Dio createSecureDioInstance() {
    final dio = Dio();

    // Add a request interceptor to add security headers
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add security headers to all requests
          options.headers.addAll(
            addSecurityHeaders().headers ?? {},
          );

          // Log security-relevant information
          AppLogger.i('Security headers added to request: ${options.path}');
          
          handler.next(options);
        },
        onResponse: (response, handler) async {
          // Validate security headers in response
          validateResponseSecurityHeaders(response);
          
          handler.next(response);
        },
        onError: (DioException err, handler) async {
          AppLogger.e('Request failed with security context: ${err.requestOptions.path}');
          
          handler.next(err);
        },
      ),
    );

    return dio;
  }

  /// Add CSRF protection headers
  static Map<String, String> addCsrfProtection({
    required String csrfToken,
  }) {
    return {
      'X-CSRF-Token': csrfToken,
      'X-Requested-With': 'XMLHttpRequest',
    };
  }

  /// Add request signing headers for additional security
  static Map<String, String> addRequestSigning({
    required String payload,
    required String secretKey,
    String? timestamp,
  }) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create a signature using the payload, timestamp, and secret
    // This is a simplified example - in production, use proper HMAC-SHA256
    final dataToSign = '$payload|$timestamp|$secretKey';
    // In a real implementation, you would use cryptographic signing here
    
    return {
      'X-Signature': 'SIGNATURE_PLACEHOLDER', // Would be actual signature in production
      'X-Timestamp': timestamp,
      'X-Nonce': const Uuid().v4(), // Prevent replay attacks
    };
  }
}