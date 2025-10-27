import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:food_delivery_app/core/results/result.dart';

/// Centralized mapper from arbitrary Exceptions into domain Failure types
class ErrorMapper {
  static Failure from(Object error, [StackTrace? stackTrace]) {
    // Already a Failure wrapped somewhere
    if (error is Failure) {
      return error;
    }

    // Supabase Auth
    if (error is AuthException) {
      final code = error.statusCode;
      if (code == '401' || code == '403') {
        return AuthFailure(message: error.message, code: code, exception: error, stackTrace: stackTrace);
      }
      return AuthFailure(message: error.message, code: code, exception: error, stackTrace: stackTrace);
    }

    // Supabase PostgREST/database layer
    if (error is PostgrestException) {
      final msg = error.message;
      final code = error.code;
      // Common PostgREST codes
      if (code == 'PGRST116' || code == '404' || msg.toLowerCase().contains('not found')) {
        return NotFoundFailure(message: msg, code: code, exception: error, stackTrace: stackTrace);
      }
      if (code == '23505' || msg.toLowerCase().contains('duplicate') || msg.toLowerCase().contains('unique constraint')) {
        return ValidationFailure(message: 'Duplicate data: $msg', code: code, exception: error, stackTrace: stackTrace);
      }
      if (code == '42501') {
        return PermissionDeniedFailure(message: 'Permission denied', code: code, exception: error, stackTrace: stackTrace);
      }
      return ServerFailure(message: msg, code: code, exception: error, stackTrace: stackTrace);
    }

    // Supabase Storage
    if (error is StorageException) {
      final msg = error.message;
      if (msg.toLowerCase().contains('not found')) {
        return NotFoundFailure(message: msg, exception: error, stackTrace: stackTrace);
      }
      return ServerFailure(message: msg, exception: error, stackTrace: stackTrace);
    }

    // Dio HTTP client
    if (error is DioException) {
      final type = error.type;
      switch (type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return TimeoutFailure(message: 'Request timed out', exception: error, stackTrace: stackTrace);
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode ?? 0;
          if (status == 400 || status == 422) {
            return ValidationFailure(message: _messageFromDio(error), code: status.toString(), exception: error, stackTrace: stackTrace);
          } else if (status == 401) {
            return AuthFailure(message: 'Authentication required', code: '401', exception: error, stackTrace: stackTrace);
          } else if (status == 403) {
            return PermissionDeniedFailure(message: 'Access forbidden', code: '403', exception: error, stackTrace: stackTrace);
          } else if (status == 404) {
            return NotFoundFailure(message: 'Resource not found', code: '404', exception: error, stackTrace: stackTrace);
          } else if (status >= 500) {
            return ServerFailure(message: 'Server error (${error.response?.statusCode})', code: status.toString(), exception: error, stackTrace: stackTrace);
          }
          return ServerFailure(message: _messageFromDio(error), code: status.toString(), exception: error, stackTrace: stackTrace);
        case DioExceptionType.connectionError:
          return NetworkFailure(message: 'Network error', exception: error, stackTrace: stackTrace);
        case DioExceptionType.cancel:
          return UnknownFailure(message: 'Request cancelled', exception: error, stackTrace: stackTrace);
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          final underlying = error.error;
          if (underlying is SocketException) {
            return NetworkFailure(message: 'No internet connection', exception: underlying, stackTrace: stackTrace);
          } else if (underlying is TimeoutException) {
            return TimeoutFailure(message: 'Request timed out', exception: underlying, stackTrace: stackTrace);
          }
          return UnknownFailure(message: _messageFromDio(error), exception: error, stackTrace: stackTrace);
      }
    }

    // Network/IO
    if (error is SocketException) {
      return NetworkFailure(message: 'No internet connection', exception: error, stackTrace: stackTrace);
    }
    if (error is TimeoutException) {
      return TimeoutFailure(message: 'Request timed out', exception: error, stackTrace: stackTrace);
    }
    if (error is HttpException) {
      return ServerFailure(message: error.message, exception: error, stackTrace: stackTrace);
    }

    // Validation/data
    if (error is FormatException || error is ArgumentError) {
      return ValidationFailure(message: error.toString(), exception: error, stackTrace: stackTrace);
    }

    // Generic strings used in app
    if (error is String && error.toLowerCase().contains('not authenticated')) {
      return AuthFailure(message: 'User not authenticated', exception: error, stackTrace: stackTrace);
    }

    // Fallback
    return UnknownFailure(message: error.toString(), exception: error, stackTrace: stackTrace);
  }

  static String _messageFromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (data is String) return data;
    if (status != null) return 'HTTP $status';
    return e.message ?? 'Network request failed';
  }
}

