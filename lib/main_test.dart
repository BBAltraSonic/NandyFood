import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/providers/theme_provider.dart';
import '../test_runner.dart';
import 'main.dart' as app;

/// Test version of main.dart with comprehensive logging
Future<void> main() async {
  final logger = TestLogger();

  logger.logFunctionEntry('main', {'mode': 'TEST'});

  try {
    logger.logDebug('main', 'Initializing Flutter bindings');
    WidgetsFlutterBinding.ensureInitialized();
    logger.logSuccess('main', 'Flutter bindings initialized');

    // Load environment variables
    logger.logDebug('main', 'Loading environment variables');
    try {
      await dotenv.load(fileName: '.env');
      logger.logSuccess('main', '.env file loaded');
    } catch (e) {
      logger.logWarning('main', '.env file not found, using defaults');
    }

    // Initialize DatabaseService
    logger.logDebug('main', 'Initializing DatabaseService');
    try {
      final dbService = DatabaseService();
      await dbService.initialize();
      logger.logSuccess('main', 'DatabaseService initialized');
    } catch (e, stack) {
      logger.logError(
        'main',
        'DatabaseService initialization failed: $e',
        stack,
      );
    }

    // Run app
    logger.logDebug('main', 'Starting app');
    runApp(const ProviderScope(child: TestApp()));
    logger.logSuccess('main', 'App started');
  } catch (e, stack) {
    logger.logError('main', e, stack);
    rethrow;
  } finally {
    logger.logFunctionExit('main');
  }
}

class TestApp extends ConsumerStatefulWidget {
  const TestApp({super.key});

  @override
  ConsumerState<TestApp> createState() => _TestAppState();
}

class _TestAppState extends ConsumerState<TestApp> with LoggableMixin {
  late final _router;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    logEntry('initState');

    try {
      _router = app.createRouter();
      logSuccess('initState', 'Router created');
    } catch (e, stack) {
      logError('initState', e, stack);
    }

    logExit('initState');
  }

  @override
  Widget build(BuildContext context) {
    logEntry('build');

    final themeState = ref.watch(themeProvider);
    logDebug('build', 'Theme mode: ${themeState.themeMode}');

    final app = MaterialApp.router(
      title: 'NandyFood (TEST MODE)',
      debugShowCheckedModeBanner: true,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: themeState.flutterThemeMode,
      routerConfig: _router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox(),

            // Test mode indicator
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showLogs = !_showLogs;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bug_report,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TEST MODE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating log button
            if (!_showLogs)
              Positioned(
                bottom: 80,
                right: 16,
                child: FloatingActionButton(
                  heroTag: 'logs_button',
                  backgroundColor: Colors.purple,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LogViewerWidget(),
                      ),
                    );
                  },
                  child: const Icon(Icons.list_alt),
                ),
              ),

            // Inline log viewer
            if (_showLogs)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.code, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Runtime Logs',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showLogs = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<LogEntry>(
                          stream: TestLogger().logStream,
                          builder: (context, snapshot) {
                            final logs = TestLogger().logs;

                            return ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[logs.length - 1 - index];
                                return _buildLogItem(log);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );

    logExit('build');
    return app;
  }

  Widget _buildLogItem(LogEntry log) {
    Color color;
    IconData icon;

    switch (log.level) {
      case LogLevel.info:
        color = Colors.blue;
        icon = Icons.info;
        break;
      case LogLevel.success:
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case LogLevel.warning:
        color = Colors.orange;
        icon = Icons.warning;
        break;
      case LogLevel.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case LogLevel.debug:
        color = Colors.grey;
        icon = Icons.bug_report;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.function,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  log.message,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            _formatTime(log.timestamp),
            style: const TextStyle(color: Colors.white54, fontSize: 10),
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

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.light,
      ),
      textTheme: Typography.blackCupertino,
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      textTheme: Typography.whiteCupertino,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.grey[900],
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.grey[850],
      ),
      scaffoldBackgroundColor: Colors.grey[900],
    );
  }
}
