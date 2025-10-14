import 'app_error.dart';

/// A wrapper class that represents either a success or failure result
class Result<T> {
  final T? _data;
  final AppError? _error;

  const Result._internal(this._data, this._error);

  /// Creates a success result with data
  factory Result.success(T data) => Result._internal(data, null);

  /// Creates an error result with an AppError
  factory Result.error(AppError error) => Result._internal(null, error);

  /// Creates an error result with a message (converts to GeneralError)
  factory Result.failure(String message) => Result._internal(null, GeneralError(message: message));

  /// Whether this result represents a success
  bool get isSuccess => _error == null;

  /// Whether this result represents a failure
  bool get isFailure => _error != null;

  /// The data if successful, otherwise null
  T? get data => _data;

  /// The error if failed, otherwise null
  AppError? get error => _error;

  /// Maps the result to another type
  Result<R> map<R>(R Function(T data) success, AppError Function(AppError error) failure) {
    if (isSuccess) {
      try {
        return Result.success(success(_data as T));
      } catch (e) {
        return Result.error(AppErrorTypeConverter.fromDynamic(e));
      }
    } else {
      return Result.error(failure(_error!));
    }
  }

  /// Performs a side effect based on success or failure
  void fold(void Function(T data) onSuccess, void Function(AppError error) onError) {
    if (isSuccess) {
      onSuccess(_data as T);
    } else {
      onError(_error!);
    }
  }
}

/// Helper class to convert various error types to AppError
class AppErrorTypeConverter {
  static AppError fromDynamic(dynamic error) {
    if (error is AppError) {
      return error;
    } else if (error is String) {
      return GeneralError(message: error);
    } else {
      return GeneralError(message: error.toString());
    }
  }
}