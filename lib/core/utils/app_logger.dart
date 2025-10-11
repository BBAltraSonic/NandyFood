import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Comprehensive console logger for runtime debugging
class AppLogger {
  static const String _reset = '\x1B[0m';
  static const String _red = '\x1B[31m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _blue = '\x1B[34m';
  static const String _magenta = '\x1B[35m';
  static const String _cyan = '\x1B[36m';
  static const String _white = '\x1B[37m';
  static const String _bold = '\x1B[1m';

  static void init(String message) {
    _log('🔷 INIT', message, _cyan);
  }

  static void success(String message, {String? details}) {
    _log('✅ SUCCESS', message, _green);
    if (details != null) {
      debugPrint('$_green   └─ $details$_reset');
    }
  }

  static void error(String message, {dynamic error, StackTrace? stack}) {
    _log('❌ ERROR', message, _red);
    if (error != null) {
      debugPrint('$_red   └─ Error: $error$_reset');
    }
    if (stack != null) {
      debugPrint('$_red   └─ Stack: ${stack.toString().split('\n').take(5).join('\n       ')}$_reset');
    }
  }

  static void warning(String message) {
    _log('⚠️  WARNING', message, _yellow);
  }

  static void info(String message, {Map<String, dynamic>? data}) {
    _log('📘 INFO', message, _blue);
    if (data != null && data.isNotEmpty) {
      data.forEach((key, value) {
        debugPrint('$_blue   └─ $key: $value$_reset');
      });
    }
  }

  static void debug(String message, {dynamic data}) {
    if (kDebugMode) {
      _log('🔍 DEBUG', message, _magenta);
      if (data != null) {
        debugPrint('$_magenta   └─ Data: $data$_reset');
      }
    }
  }

  static void function(String functionName, String action, {Map<String, dynamic>? params, dynamic result}) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    
    if (action == 'ENTER') {
      debugPrint('$_cyan━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
      debugPrint('$_cyan[$timestamp] 🔵 ENTER → $functionName$_reset');
      if (params != null && params.isNotEmpty) {
        debugPrint('$_cyan   Parameters:$_reset');
        params.forEach((key, value) {
          debugPrint('$_cyan     • $key: $value$_reset');
        });
      }
    } else if (action == 'EXIT') {
      if (result != null) {
        debugPrint('$_green   ↳ Result: $result$_reset');
      }
      debugPrint('$_green[$timestamp] 🔴 EXIT ← $functionName$_reset');
      debugPrint('$_green━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$_reset');
    }
  }

  static void http(String method, String url, {int? statusCode, dynamic body}) {
    debugPrint('$_magenta┌─ HTTP $method$_reset');
    debugPrint('$_magenta│  URL: $url$_reset');
    if (statusCode != null) {
      final color = statusCode >= 200 && statusCode < 300 ? _green : _red;
      debugPrint('$color│  Status: $statusCode$_reset');
    }
    if (body != null) {
      debugPrint('$_magenta│  Body: $body$_reset');
    }
    debugPrint('$_magenta└─$_reset');
  }

  static void database(String operation, String table, {dynamic data, int? count}) {
    debugPrint('$_yellow┌─ 🗄️  DATABASE $operation$_reset');
    debugPrint('$_yellow│  Table: $table$_reset');
    if (count != null) {
      debugPrint('$_yellow│  Count: $count records$_reset');
    }
    if (data != null) {
      debugPrint('$_yellow│  Data: $data$_reset');
    }
    debugPrint('$_yellow└─$_reset');
  }

  static void navigation(String from, String to) {
    debugPrint('$_blue┌─ 🧭 NAVIGATION$_reset');
    debugPrint('$_blue│  From: $from$_reset');
    debugPrint('$_blue│  To: $to$_reset');
    debugPrint('$_blue└─$_reset');
  }

  static void state(String provider, String action, {dynamic oldValue, dynamic newValue}) {
    debugPrint('$_magenta┌─ 🔄 STATE CHANGE$_reset');
    debugPrint('$_magenta│  Provider: $provider$_reset');
    debugPrint('$_magenta│  Action: $action$_reset');
    if (oldValue != null) {
      debugPrint('$_magenta│  Old: $oldValue$_reset');
    }
    if (newValue != null) {
      debugPrint('$_magenta│  New: $newValue$_reset');
    }
    debugPrint('$_magenta└─$_reset');
  }

  static void performance(String operation, Duration duration) {
    final ms = duration.inMilliseconds;
    final color = ms < 100 ? _green : ms < 500 ? _yellow : _red;
    debugPrint('$color⏱️  PERFORMANCE: $operation took ${ms}ms$_reset');
  }

  static void separator() {
    debugPrint('$_white═══════════════════════════════════════════════════════$_reset');
  }

  static void section(String title) {
    debugPrint('\n$_bold$_cyan╔═══════════════════════════════════════════════════════╗$_reset');
    debugPrint('$_bold$_cyan║  $title$_reset');
    debugPrint('$_bold$_cyan╚═══════════════════════════════════════════════════════╝$_reset\n');
  }

  static void _log(String level, String message, String color) {
    final timestamp = DateTime.now().toIso8601String().split('T')[1].split('.')[0];
    debugPrint('$color[$timestamp] $level: $message$_reset');
    
    // Also log to developer console for better debugging
    developer.log(
      message,
      name: level,
      time: DateTime.now(),
    );
  }

  /// Log app lifecycle events
  static void lifecycle(String event, {String? details}) {
    debugPrint('$_cyan┌─ 🔄 LIFECYCLE: $event$_reset');
    if (details != null) {
      debugPrint('$_cyan│  Details: $details$_reset');
    }
    debugPrint('$_cyan└─$_reset');
  }

  /// Log user interactions
  static void userAction(String action, {Map<String, dynamic>? context}) {
    debugPrint('$_green┌─ 👆 USER ACTION: $action$_reset');
    if (context != null) {
      context.forEach((key, value) {
        debugPrint('$_green│  $key: $value$_reset');
      });
    }
    debugPrint('$_green└─$_reset');
  }

  /// Log widget builds
  static void widgetBuild(String widgetName, {String? reason}) {
    if (kDebugMode) {
      debugPrint('$_magenta🎨 BUILD: $widgetName${reason != null ? ' (Reason: $reason)' : ''}$_reset');
    }
  }
}
