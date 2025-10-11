import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/widgets/enhanced_error_message_widget.dart';
import 'package:food_delivery_app/core/utils/error_handler.dart';

/// Error boundary widget that catches errors in its subtree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? fallback;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final String? context;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.onError,
    this.context,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // If we have a custom fallback, use it
      if (widget.fallback != null) {
        return widget.fallback!(_error!, _stackTrace ?? StackTrace.empty);
      }

      // Otherwise, show a default error message
      return Scaffold(
        body: Center(
          child: EnhancedErrorMessageWidget(
            title: 'Something went wrong',
            message: ErrorHandler.getErrorMessage(_error!),
            onRetry: () {
              setState(() {
                _error = null;
                _stackTrace = null;
              });
            },
          ),
        ),
      );
    }

    // Wrap child in a try-catch using an InheritedWidget approach
    return _ErrorBoundaryInherited(
      errorBoundaryState: this,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // Call custom error handler if provided
    widget.onError?.call(error, stackTrace);

    // Log the error
    ErrorHandler.logError(error, stackTrace, logContext: widget.context);
  }
}

class _ErrorBoundaryInherited extends InheritedWidget {
  final _ErrorBoundaryState errorBoundaryState;

  const _ErrorBoundaryInherited({
    required this.errorBoundaryState,
    required super.child,
  });

  @override
  bool updateShouldNotify(_ErrorBoundaryInherited oldWidget) {
    return false;
  }
}

/// Mixin for widgets that want to handle errors gracefully
mixin ErrorBoundaryMixin<T extends StatefulWidget> on State<T> {
  _ErrorBoundaryState? get errorBoundary {
    final context = this.context;
    if (context is Element) {
      final inheritedElement = context
          .getElementForInheritedWidgetOfExactType<_ErrorBoundaryInherited>()
          ?.widget as _ErrorBoundaryInherited?;
      return inheritedElement?.errorBoundaryState;
    }
    return null;
  }

  void handleError(Object error, [StackTrace? stackTrace]) {
    errorBoundary?._handleError(error, stackTrace ?? StackTrace.current);
  }
}