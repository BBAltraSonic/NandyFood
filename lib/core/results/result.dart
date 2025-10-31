sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => this is Success<T> ? (this as Success<T>).value : null;
  Failure? get failureOrNull => this is Err<T> ? (this as Err<T>).failure : null;

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    final self = this;
    if (self is Success<T>) return success(self.value);
    return failure((self as Err<T>).failure);
  }

  Result<U> map<U>(U Function(T value) transform) {
    final self = this;
    if (self is Success<T>) return Success<U>(transform(self.value));
    return Err<U>((self as Err<T>).failure);
  }

  Result<U> flatMap<U>(Result<U> Function(T value) transform) {
    final self = this;
    if (self is Success<T>) return transform(self.value);
    return Err<U>((self as Err<T>).failure);
  }
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}

/// Base Failure type used by Result
abstract class Failure {
  final String message;
  final String? code;
  final Object? exception;
  final StackTrace? stackTrace;

  const Failure({
    required this.message,
    this.code,
    this.exception,
    this.stackTrace,
  });

  @override
  String toString() => 'Failure(code: ${code ?? 'unknown'}, message: $message)';
}

/// Common failure specializations
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class PermissionDeniedFailure extends Failure {
  const PermissionDeniedFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

class UnknownFailure extends Failure {
  const UnknownFailure({
    required super.message,
    super.code,
    super.exception,
    super.stackTrace,
  });
}

