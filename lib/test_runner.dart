import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Comprehensive Runtime Logger for NandyFood Testing
class TestLogger {
  static final TestLogger _instance = TestLogger._internal();
  factory TestLogger() => _instance;
  TestLogger._internal();

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logStream = StreamController.broadcast();

  Stream<LogEntry> get logStream => _logStream.stream;
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Log function entry
  void logFunctionEntry(String functionName, [Map<String, dynamic>? params]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      function: functionName,
      message: 'ENTER',
      params: params,
    );
    _addLog(entry);
  }

  /// Log function exit
  void logFunctionExit(String functionName, [dynamic result]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.info,
      function: functionName,
      message: 'EXIT',
      result: result,
    );
    _addLog(entry);
  }

  /// Log success
  void logSuccess(String functionName, String message, [dynamic data]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.success,
      function: functionName,
      message: message,
      result: data,
    );
    _addLog(entry);
  }

  /// Log error
  void logError(String functionName, dynamic error, [StackTrace? stackTrace]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.error,
      function: functionName,
      message: error.toString(),
      stackTrace: stackTrace,
    );
    _addLog(entry);
  }

  /// Log warning
  void logWarning(String functionName, String message) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.warning,
      function: functionName,
      message: message,
    );
    _addLog(entry);
  }

  /// Log debug info
  void logDebug(String functionName, String message, [dynamic data]) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: LogLevel.debug,
      function: functionName,
      message: message,
      result: data,
    );
    _addLog(entry);
  }

  void _addLog(LogEntry entry) {
    _logs.add(entry);
    _logStream.add(entry);

    // Print to console
    final icon = _getIcon(entry.level);
    final timestamp = entry.timestamp.toIso8601String();

    if (kDebugMode) {
      print('$icon [$timestamp] [${entry.function}] ${entry.message}');
      if (entry.params != null) {
        print('  └─ Params: ${entry.params}');
      }
      if (entry.result != null) {
        print('  └─ Result: ${entry.result}');
      }
      if (entry.stackTrace != null) {
        print('  └─ Stack: ${entry.stackTrace}');
      }
    }

    // Also log to developer tools
    developer.log(
      entry.message,
      name: entry.function,
      time: entry.timestamp,
      level: _getLevel(entry.level),
      error: entry.level == LogLevel.error ? entry.message : null,
      stackTrace: entry.stackTrace,
    );
  }

  String _getIcon(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return '📘';
      case LogLevel.success:
        return '✅';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.debug:
        return '🔍';
    }
  }

  int _getLevel(LogLevel level) {
    switch (level) {
      case LogLevel.info:
        return 800;
      case LogLevel.success:
        return 900;
      case LogLevel.warning:
        return 1000;
      case LogLevel.error:
        return 1100;
      case LogLevel.debug:
        return 500;
    }
  }

  /// Export logs to string
  String exportLogs() {
    final buffer = StringBuffer();
    buffer.writeln('=' * 80);
    buffer.writeln('NandyFood Runtime Test Logs');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${_logs.length}');
    buffer.writeln('=' * 80);
    buffer.writeln();

    for (final log in _logs) {
      buffer.writeln('[${log.timestamp.toIso8601String()}]');
      buffer.writeln('Function: ${log.function}');
      buffer.writeln('Level: ${log.level.name.toUpperCase()}');
      buffer.writeln('Message: ${log.message}');

      if (log.params != null) {
        buffer.writeln('Parameters: ${log.params}');
      }

      if (log.result != null) {
        buffer.writeln('Result: ${log.result}');
      }

      if (log.stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(log.stackTrace.toString());
      }

      buffer.writeln('-' * 80);
    }

    return buffer.toString();
  }

  /// Clear all logs
  void clearLogs() {
    _logs.clear();
  }

  /// Get statistics
  Map<String, dynamic> getStatistics() {
    final stats = <String, int>{};
    for (final level in LogLevel.values) {
      stats[level.name] = _logs.where((l) => l.level == level).length;
    }

    final functionCalls = <String, int>{};
    for (final log in _logs) {
      functionCalls[log.function] = (functionCalls[log.function] ?? 0) + 1;
    }

    return {
      'totalLogs': _logs.length,
      'byLevel': stats,
      'functionCalls': functionCalls,
      'startTime': _logs.isNotEmpty ? _logs.first.timestamp : null,
      'endTime': _logs.isNotEmpty ? _logs.last.timestamp : null,
    };
  }
}

enum LogLevel { info, success, warning, error, debug }

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String function;
  final String message;
  final Map<String, dynamic>? params;
  final dynamic result;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.function,
    required this.message,
    this.params,
    this.result,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'function': function,
    'message': message,
    if (params != null) 'params': params,
    if (result != null) 'result': result.toString(),
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
  };
}

/// Mixin to add logging to any class
mixin LoggableMixin {
  final logger = TestLogger();

  void logEntry(String functionName, [Map<String, dynamic>? params]) {
    logger.logFunctionEntry('${runtimeType}.$functionName', params);
  }

  void logExit(String functionName, [dynamic result]) {
    logger.logFunctionExit('${runtimeType}.$functionName', result);
  }

  void logSuccess(String functionName, String message, [dynamic data]) {
    logger.logSuccess('${runtimeType}.$functionName', message, data);
  }

  void logError(String functionName, dynamic error, [StackTrace? stackTrace]) {
    logger.logError('${runtimeType}.$functionName', error, stackTrace);
  }

  void logWarning(String functionName, String message) {
    logger.logWarning('${runtimeType}.$functionName', message);
  }

  void logDebug(String functionName, String message, [dynamic data]) {
    logger.logDebug('${runtimeType}.$functionName', message, data);
  }
}

/// Widget to display logs in real-time
class LogViewerWidget extends StatelessWidget {
  const LogViewerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final logger = TestLogger();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Runtime Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => logger.clearLogs(),
            tooltip: 'Clear Logs',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportLogs(context),
            tooltip: 'Export Logs',
          ),
        ],
      ),
      body: StreamBuilder<LogEntry>(
        stream: logger.logStream,
        builder: (context, snapshot) {
          final logs = logger.logs;

          if (logs.isEmpty) {
            return const Center(
              child: Text('No logs yet. Use the app to generate logs.'),
            );
          }

          return Column(
            children: [
              // Statistics
              _buildStatistics(logger.getStatistics()),

              // Log list
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[logs.length - 1 - index];
                    return _buildLogTile(log);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showStatistics(context),
        child: const Icon(Icons.analytics),
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    final byLevel = stats['byLevel'] as Map<String, int>;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(
            label: 'Total',
            value: stats['totalLogs'],
            color: Colors.black54,
          ),
          _StatChip(
            label: 'Info',
            value: byLevel['info'] ?? 0,
            color: Colors.black54,
          ),
          _StatChip(
            label: 'Success',
            value: byLevel['success'] ?? 0,
            color: Colors.black54,
          ),
          _StatChip(
            label: 'Warnings',
            value: byLevel['warning'] ?? 0,
            color: Colors.black87,
          ),
          _StatChip(
            label: 'Errors',
            value: byLevel['error'] ?? 0,
            color: Colors.black87,
          ),
        ],
      ),
    );
  }

  Widget _buildLogTile(LogEntry log) {
    Color color;
    IconData icon;

    switch (log.level) {
      case LogLevel.info:
        color = Colors.black54;
        icon = Icons.info;
        break;
      case LogLevel.success:
        color = Colors.black54;
        icon = Icons.check_circle;
        break;
      case LogLevel.warning:
        color = Colors.black87;
        icon = Icons.warning;
        break;
      case LogLevel.error:
        color = Colors.black87;
        icon = Icons.error;
        break;
      case LogLevel.debug:
        color = Colors.grey;
        icon = Icons.bug_report;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        title: Text(
          log.function,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(log.message),
        trailing: Text(
          _formatTime(log.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          if (log.params != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parameters:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(log.params.toString()),
                ],
              ),
            ),
          if (log.result != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Result:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(log.result.toString()),
                ],
              ),
            ),
          if (log.stackTrace != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black87[50],
                    child: Text(
                      log.stackTrace.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  void _exportLogs(BuildContext context) {
    final logger = TestLogger();
    final logs = logger.exportLogs();

    // In a real app, this would save to file
    // For now, just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logs Exported'),
        content: SingleChildScrollView(child: Text(logs)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final logger = TestLogger();
    final stats = logger.getStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Logs: ${stats['totalLogs']}'),
              const SizedBox(height: 16),
              const Text(
                'By Level:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(stats['byLevel'] as Map<String, int>).entries.map(
                (e) => Text('  ${e.key}: ${e.value}'),
              ),
              const SizedBox(height: 16),
              const Text(
                'Function Calls:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...(stats['functionCalls'] as Map<String, int>).entries
                  .take(10)
                  .map((e) => Text('  ${e.key}: ${e.value}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
