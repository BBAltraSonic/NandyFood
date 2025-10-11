import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Generic state class for managing loading, success, and error states
class AsyncState<T> {
  final bool isLoading;
  final T? data;
  final Object? error;
  final String? errorMessage;

  AsyncState({
    this.isLoading = false,
    this.data,
    this.error,
    this.errorMessage,
  });

  factory AsyncState.loading() {
    return AsyncState(isLoading: true);
  }

  factory AsyncState.data(T data) {
    return AsyncState(data: data);
  }

  factory AsyncState.error(Object error, [String? errorMessage]) {
    return AsyncState(
      error: error,
      errorMessage: errorMessage ?? error.toString(),
    );
  }

  AsyncState<T> copyWith({
    bool? isLoading,
    T? data,
    Object? error,
    String? errorMessage,
  }) {
    return AsyncState<T>(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  bool get hasData => data != null;
  bool get hasError => error != null;
}

/// Extension on AsyncState for easier usage
extension AsyncStateX<T> on AsyncState<T> {
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(Object error, String? errorMessage) error,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.data != null) {
      return data(this.data as T);
    } else if (this.error != null) {
      return error(this.error!, this.errorMessage);
    } else {
      // This should not happen in normal circumstances
      return error(
        StateError('AsyncState is in an invalid state'),
        'Invalid state',
      );
    }
  }

  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? data,
    R Function(Object error, String? errorMessage)? error,
    required R Function() orElse,
  }) {
    if (isLoading && loading != null) {
      return loading();
    } else if (this.data != null && data != null) {
      return data(this.data as T);
    } else if (this.error != null && error != null) {
      return error(this.error!, this.errorMessage);
    } else {
      return orElse();
    }
  }

  void whenOrNull({
    void Function()? loading,
    void Function(T data)? data,
    void Function(Object error, String? errorMessage)? error,
  }) {
    if (isLoading) {
      loading?.call();
    } else if (this.data != null) {
      data?.call(this.data as T);
    } else if (this.error != null) {
      error?.call(this.error!, this.errorMessage);
    }
  }
}

/// Generic state notifier for Riverpod with built-in error handling
class AsyncStateNotifier<T> extends Notifier<AsyncState<T>> {
  @override
  AsyncState<T> build() {
    return AsyncState<T>();
  }

  /// Set state to loading
  void setLoading() {
    state = AsyncState.loading();
  }

  /// Set state to data
  void setData(T data) {
    state = AsyncState.data(data);
  }

  /// Set state to error
  void setError(Object error, [String? errorMessage]) {
    state = AsyncState.error(error, errorMessage);
  }

  /// Execute an async function with automatic state management
  Future<void> runAsync(
    Future<T> Function() function, {
    void Function(Object error)? onError,
  }) async {
    try {
      setLoading();
      final result = await function();
      setData(result);
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Async error: $error\nStack trace: $stackTrace');
      }
      setError(error);
      onError?.call(error);
    }
  }

  /// Execute an async function that returns void with automatic state management
  Future<void> runAsyncVoid(
    Future<void> Function() function, {
    void Function(Object error)? onError,
  }) async {
    try {
      setLoading();
      await function();
      state = AsyncState(); // Empty success state
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('Async error: $error\nStack trace: $stackTrace');
      }
      setError(error);
      onError?.call(error);
    }
  }
}