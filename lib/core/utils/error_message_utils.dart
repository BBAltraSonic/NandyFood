/// Utility class for converting technical errors to user-friendly messages
class ErrorMessageUtils {
  /// Convert technical error messages to user-friendly versions
  static String getUserFriendlyMessage(String? technicalMessage) {
    if (technicalMessage == null || technicalMessage.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    final lowerCaseMessage = technicalMessage.toLowerCase();

    // Network related errors
    if (lowerCaseMessage.contains('network') ||
        lowerCaseMessage.contains('connection') ||
        lowerCaseMessage.contains('timeout') ||
        lowerCaseMessage.contains('unreachable')) {
      return 'Please check your internet connection and try again.';
    }

    // Location permission errors
    if (lowerCaseMessage.contains('location') ||
        lowerCaseMessage.contains('permission') ||
        lowerCaseMessage.contains('denied') ||
        lowerCaseMessage.contains('location permission denied') ||
        lowerCaseMessage.contains('location permission permanently denied')) {
      return 'Location access is needed to show nearby restaurants. Please enable location services.';
    }

    // Database related errors
    if (lowerCaseMessage.contains('database') ||
        lowerCaseMessage.contains('supabase') ||
        lowerCaseMessage.contains('postgres') ||
        lowerCaseMessage.contains('sql') ||
        lowerCaseMessage.contains('constraint')) {
      return 'Unable to load restaurant data right now. Please try again in a moment.';
    }

    // Authentication errors
    if (lowerCaseMessage.contains('unauthorized') ||
        lowerCaseMessage.contains('authentication') ||
        lowerCaseMessage.contains('auth') ||
        lowerCaseMessage.contains('jwt') ||
        lowerCaseMessage.contains('token')) {
      return 'Please sign in to continue.';
    }

    // Rate limiting errors
    if (lowerCaseMessage.contains('rate limit') ||
        lowerCaseMessage.contains('too many requests') ||
        lowerCaseMessage.contains('quota')) {
      return 'Too many requests. Please wait a moment and try again.';
    }

    // Server errors
    if (lowerCaseMessage.contains('server error') ||
        lowerCaseMessage.contains('internal server error') ||
        lowerCaseMessage.contains('500') ||
        lowerCaseMessage.contains('502') ||
        lowerCaseMessage.contains('503') ||
        lowerCaseMessage.contains('504')) {
      return 'Our servers are experiencing issues. Please try again later.';
    }

    // Not found errors
    if (lowerCaseMessage.contains('not found') ||
        lowerCaseMessage.contains('404')) {
      return 'The requested information could not be found.';
    }

    // Timeout errors
    if (lowerCaseMessage.contains('timeout') ||
        lowerCaseMessage.contains('deadline') ||
        lowerCaseMessage.contains('timed out')) {
      return 'The request took too long. Please check your connection and try again.';
    }

    // JSON/parsing errors
    if (lowerCaseMessage.contains('json') ||
        lowerCaseMessage.contains('parse') ||
        lowerCaseMessage.contains('format')) {
      return 'We encountered an issue processing the data. Please try again.';
    }

    // Validation errors
    if (lowerCaseMessage.contains('validation') ||
        lowerCaseMessage.contains('invalid') ||
        lowerCaseMessage.contains('required')) {
      return 'Please check your input and try again.';
    }

    // Permission errors
    if (lowerCaseMessage.contains('permission') ||
        lowerCaseMessage.contains('access denied') ||
        lowerCaseMessage.contains('forbidden')) {
      return 'You don\'t have permission to perform this action.';
    }

    // Default fallback
    return 'Something went wrong. Please try again.';
  }

  /// Get error severity level for UI styling
  static ErrorSeverity getErrorSeverity(String? technicalMessage) {
    if (technicalMessage == null) return ErrorSeverity.medium;

    final lowerCaseMessage = technicalMessage.toLowerCase();

    // High severity errors that need immediate attention
    if (lowerCaseMessage.contains('network') ||
        lowerCaseMessage.contains('connection') ||
        lowerCaseMessage.contains('server error') ||
        lowerCaseMessage.contains('database') ||
        lowerCaseMessage.contains('timeout')) {
      return ErrorSeverity.high;
    }

    // Medium severity errors
    if (lowerCaseMessage.contains('permission') ||
        lowerCaseMessage.contains('authentication') ||
        lowerCaseMessage.contains('validation') ||
        lowerCaseMessage.contains('not found')) {
      return ErrorSeverity.medium;
    }

    // Low severity errors
    if (lowerCaseMessage.contains('rate limit') ||
        lowerCaseMessage.contains('parse') ||
        lowerCaseMessage.contains('format')) {
      return ErrorSeverity.low;
    }

    return ErrorSeverity.medium;
  }

  /// Get appropriate action text based on error type
  static String getActionText(String? technicalMessage) {
    if (technicalMessage == null) return 'Try Again';

    final lowerCaseMessage = technicalMessage.toLowerCase();

    if (lowerCaseMessage.contains('location') ||
        lowerCaseMessage.contains('permission')) {
      return 'Enable Location';
    }

    if (lowerCaseMessage.contains('network') ||
        lowerCaseMessage.contains('connection')) {
      return 'Check Connection';
    }

    if (lowerCaseMessage.contains('authentication') ||
        lowerCaseMessage.contains('auth')) {
      return 'Sign In';
    }

    return 'Try Again';
  }

  /// Get icon suggestion based on error type
  static String getIconSuggestion(String? technicalMessage) {
    if (technicalMessage == null) return 'error_outline';

    final lowerCaseMessage = technicalMessage.toLowerCase();

    if (lowerCaseMessage.contains('network') ||
        lowerCaseMessage.contains('connection')) {
      return 'wifi_off';
    }

    if (lowerCaseMessage.contains('location') ||
        lowerCaseMessage.contains('permission')) {
      return 'location_off';
    }

    if (lowerCaseMessage.contains('server error') ||
        lowerCaseMessage.contains('database')) {
      return 'cloud_off';
    }

    if (lowerCaseMessage.contains('authentication') ||
        lowerCaseMessage.contains('auth')) {
      return 'lock';
    }

    if (lowerCaseMessage.contains('not found')) {
      return 'search_off';
    }

    return 'error_outline';
  }
}

/// Error severity levels for UI styling
enum ErrorSeverity {
  low,
  medium,
  high,
}