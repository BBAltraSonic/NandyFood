import 'dart:io';
import 'package:dio/dio.dart';
import 'package:food_delivery_app/core/utils/security/certificate_pinning_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class SecureHttpService {
  static SecureHttpService? _instance;
  static SecureHttpService get instance {
    _instance ??= SecureHttpService._internal();
    return _instance!;
  }

  SecureHttpService._internal();

  final Dio _dio = Dio();

  // Initialize the HTTP client with security settings
  Future<void> initialize() async {
    AppLogger.function('SecureHttpService.initialize', 'ENTER');
    
    // Configure Dio with security settings
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'NandyFood/1.0',
      },
    );
    
    AppLogger.function('SecureHttpService.initialize', 'EXIT');
  }

  // Method to make secure HTTP requests with certificate pinning validation
  Future<Response> getSecureRequest({
    required String url,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    String? expectedSha256Fingerprint, // Certificate fingerprint to validate
  }) async {
    AppLogger.function('SecureHttpService.getSecureRequest', 'ENTER',
        params: {'url': url});

    // If certificate fingerprint is provided, validate it first
    if (expectedSha256Fingerprint != null) {
      final isValid = await CertificatePinningService.instance
          .validateCertificate(
              url: url, sha256Fingerprint: expectedSha256Fingerprint);
      
      if (!isValid) {
        throw const SocketException('Certificate pinning validation failed');
      }
    }

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          receiveTimeout: const Duration(seconds: 15),
        ),
        queryParameters: queryParameters,
      );
      
      AppLogger.function('SecureHttpService.getSecureRequest', 'EXIT',
          result: 'Success ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Dio error in secure request', error: e);
      AppLogger.function('SecureHttpService.getSecureRequest', 'EXIT',
          result: 'Error: $e');
      rethrow;
    } catch (e) {
      AppLogger.error('Error in secure request', error: e);
      AppLogger.function('SecureHttpService.getSecureRequest', 'EXIT',
          result: 'Error: $e');
      rethrow;
    }
  }

  Future<Response> postSecureRequest({
    required String url,
    required Map<String, dynamic> data,
    Map<String, dynamic>? headers,
    String? expectedSha256Fingerprint, // Certificate fingerprint to validate
  }) async {
    AppLogger.function('SecureHttpService.postSecureRequest', 'ENTER',
        params: {'url': url});

    // If certificate fingerprint is provided, validate it first
    if (expectedSha256Fingerprint != null) {
      final isValid = await CertificatePinningService.instance
          .validateCertificate(
              url: url, sha256Fingerprint: expectedSha256Fingerprint);
      
      if (!isValid) {
        throw const SocketException('Certificate pinning validation failed');
      }
    }

    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      
      AppLogger.function('SecureHttpService.postSecureRequest', 'EXIT',
          result: 'Success ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      AppLogger.error('Dio error in secure post request', error: e);
      AppLogger.function('SecureHttpService.postSecureRequest', 'EXIT',
          result: 'Error: $e');
      rethrow;
    } catch (e) {
      AppLogger.error('Error in secure post request', error: e);
      AppLogger.function('SecureHttpService.postSecureRequest', 'EXIT',
          result: 'Error: $e');
      rethrow;
    }
  }

  // Wrapper method that validates Supabase connection using certificate pinning
  Future<bool> validateSupabaseConnection() async {
    AppLogger.function('SecureHttpService.validateSupabaseConnection', 'ENTER');
    
    try {
      // This will validate the certificate using our pinning service
      final isValid = await CertificatePinningService.instance
          .validateSupabaseCertificate();
      
      AppLogger.function('SecureHttpService.validateSupabaseConnection', 'EXIT',
          result: isValid ? 'VALID' : 'INVALID');
      return isValid;
    } catch (e) {
      AppLogger.error('Error validating Supabase connection', error: e);
      AppLogger.function('SecureHttpService.validateSupabaseConnection', 'EXIT',
          result: 'ERROR');
      return false;
    }
  }
}