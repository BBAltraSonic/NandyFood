import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(Object error, StackTrace stackTrace)? onError;
  final VoidCallback? onReset;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.onReset,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
    // Catch errors that happen during widget building
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
          _stackTrace = details.stack;
        });
      }
    };
  }

  @override
  void dispose() {
    FlutterError.onError = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // If an error occurred, return the error widget
      return widget.onError?.call(_error!, _stackTrace!) ?? 
          _buildDefaultErrorWidget(_error!, _stackTrace!);
    }

    // If no error occurred, return the child widget
    return widget.child;
  }

  Widget _buildDefaultErrorWidget(Object error, StackTrace stackTrace) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Reset the error state
                  setState(() {
                    _error = null;
                    _stackTrace = null;
                  });
                  widget.onReset?.call();
                },
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wrapper widget for screens that commonly experience errors
class ScreenErrorBoundary extends StatelessWidget {
  final String screenName;
  final Widget child;
  final VoidCallback? onReset;

  const ScreenErrorBoundary({
    super.key,
    required this.screenName,
    required this.child,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        // Log the error in a real app, you would send it to a service like Sentry
        debugPrint('Error in $screenName: $error');
        debugPrint('Stack trace: $stackTrace');

        return Scaffold(
          appBar: AppBar(
            title: Text('$screenName Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading $screenName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We encountered an issue loading this screen. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Call the onReset callback if provided, or navigator.pop to go back
                      if (onReset != null) {
                        onReset!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      onReset: onReset,
      child: child,
    );
  }
}