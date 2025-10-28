/// Test Configuration
///
/// Central configuration for all testing in the NandyFood app
/// including coverage reporting, test environments, and CI/CD setup
library;

import 'dart:io';

class TestConfig {
  // Test Directories
  static const String unitTestDir = 'test/unit';
  static const String integrationTestDir = 'test/integration';
  static const String widgetTestDir = 'test/widget';
  static const String coverageDir = 'coverage';
  static const String reportsDir = 'test_reports';

  // Coverage Configuration
  static const List<String> coverageExcludes = [
    '**/*.g.dart',
    '**/*.freezed.dart',
    '**/generated/**',
    '**/l10n/**',
    '**/test/**',
  ];

  static const List<String> coverageIncludes = [
    'lib/**',
  ];

  // Test Environment Variables
  static const Map<String, String> testEnvironment = {
    'FLUTTER_TEST': 'true',
    'ENVIRONMENT': 'test',
    'SUPABASE_URL': 'https://test.supabase.co',
    'SUPABASE_ANON_KEY': 'test-anon-key',
    'ENABLE_PAYFAST': 'false',
    'USE_MOCK_PAYMENT': 'true',
    'USE_MOCK_NOTIFICATIONS': 'true',
    'DEBUG_MODE': 'true',
  };

  // Test Execution Settings
  static const Duration defaultTimeout = Duration(minutes: 5);
  static const Duration longTimeout = Duration(minutes: 10);
  static const Duration slowNetworkDelay = Duration(seconds: 3);

  // Coverage Reporting
  static const String coverageFormat = 'lcov';
  static const String coverageOutputFile = 'coverage/lcov.info';
  static const String htmlCoverageOutput = 'coverage/html';

  // Test Categories
  static const List<String> unitTestPatterns = [
    'test/unit/**/*_test.dart',
  ];

  static const List<String> integrationTestPatterns = [
    'test/integration/**/*_test.dart',
  ];

  static const List<String> widgetTestPatterns = [
    'test/widget/**/*_test.dart',
  ];

  static const List<String> allTestPatterns = [
    'test/**/*_test.dart',
  ];

  // Performance Test Settings
  static const int maxBuildTimeMinutes = 5;
  static const int maxTestTimeMinutes = 10;
  static const double maxMemoryUsageMB = 512;

  // CI/CD Configuration
  static const bool enableCoverageInCI = true;
  static const bool enableTestReports = true;
  static const bool failOnLowCoverage = true;
  static const double minCoveragePercentage = 80.0;

  // Test Data Configuration
  static const String mockDataDir = 'test/mock_data';
  static const String fixturesDir = 'test/fixtures';

  // Notification Test Settings
  static const bool enableNotificationTests = true;
  static const Duration notificationTimeout = Duration(seconds: 5);

  // Network Test Settings
  static const bool enableNetworkTests = false; // Disabled for CI stability
  static const String mockNetworkHost = 'localhost';
  static const int mockNetworkPort = 8080;

  // Reporting Configuration
  static const bool generateJUnitReports = true;
  static const bool generateHTMLReports = true;
  static const bool generateJSONReports = true;

  // Utilities
  static bool get isCI => Platform.environment.containsKey('CI') ||
                         Platform.environment.containsKey('GITHUB_ACTIONS') ||
                         Platform.environment.containsKey('JENKINS_URL');

  static bool get isFlutterTest => Platform.environment.containsKey('FLUTTER_TEST');

  static String get testReportsPath => '$reportsDir/${DateTime.now().millisecondsSinceEpoch}';

  // File System Utilities
  static Future<void> ensureDirectoryExists(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
  }

  static Future<void> cleanDirectory(String path) async {
    final directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
    await ensureDirectoryExists(path);
  }

  // Test Execution Commands
  static String getUnitTestsCommand({
    bool coverage = false,
    bool verbose = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('flutter test');

    if (coverage) {
      buffer.write(' --coverage');
    }

    if (verbose) {
      buffer.write(' --verbose');
    }

    buffer.write(' $unitTestDir');

    return buffer.toString();
  }

  static String getIntegrationTestsCommand({
    bool coverage = false,
    bool verbose = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('flutter test');

    if (coverage) {
      buffer.write(' --coverage');
    }

    if (verbose) {
      buffer.write(' --verbose');
    }

    buffer.write(' $integrationTestDir');

    return buffer.toString();
  }

  static String getAllTestsCommand({
    bool coverage = false,
    bool verbose = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('flutter test');

    if (coverage) {
      buffer.write(' --coverage');
    }

    if (verbose) {
      buffer.write(' --verbose');
    }

    buffer.write(' test/');

    return buffer.toString();
  }

  // Coverage Analysis Commands
  static String getCoverageReportCommand() {
    return 'genhtml coverage/lcov.info --output-directory $htmlCoverageOutput';
  }

  static String getCoverageSummaryCommand() {
    return 'lcov --summary coverage/lcov.info';
  }

  // Validation Methods
  static bool validateCoverageThreshold(double coverage) {
    return coverage >= minCoveragePercentage;
  }

  static String getCoverageStatus(double coverage) {
    if (coverage >= 90) return 'Excellent';
    if (coverage >= minCoveragePercentage) return 'Good';
    if (coverage >= 70) return 'Needs Improvement';
    return 'Poor';
  }

  // Test Environment Setup
  static Map<String, String> getTestEnvironmentVariables() {
    final env = Map<String, String>.from(testEnvironment);

    if (isCI) {
      env.addAll({
        'CI': 'true',
        'HEADLESS': 'true',
        'ENABLE_COVERAGE': 'true',
      });
    }

    return env;
  }

  // Reporting Configuration
  static const Map<String, dynamic> testReportConfig = {
    'junit': {
      'enabled': true,
      'outputFile': 'test_reports/junit.xml',
    },
    'html': {
      'enabled': true,
      'outputDirectory': 'test_reports/html',
    },
    'json': {
      'enabled': true,
      'outputFile': 'test_reports/test_results.json',
    },
    'coverage': {
      'enabled': true,
      'outputFile': 'coverage/lcov.info',
      'htmlOutput': 'coverage/html',
      'threshold': minCoveragePercentage,
    },
  };

  // Mock Configuration
  static const Map<String, dynamic> mockConfig = {
    'database': {
      'enabled': true,
      'provider': 'mock',
    },
    'network': {
      'enabled': false,
      'delay': Duration(milliseconds: 500),
    },
    'notifications': {
      'enabled': true,
      'provider': 'mock',
    },
    'location': {
      'enabled': true,
      'provider': 'mock',
      'defaultLocation': {
        'latitude': -33.9249,
        'longitude': 18.4241,
      },
    },
    'payments': {
      'enabled': true,
      'provider': 'mock',
      'defaultSuccess': true,
    },
  };

  // Performance Benchmarks
  static const Map<String, Duration> performanceBenchmarks = {
    'app_startup': Duration(seconds: 3),
    'screen_load': Duration(seconds: 2),
    'api_response': Duration(seconds: 1),
    'navigation': Duration(milliseconds: 500),
    'cart_operation': Duration(milliseconds: 200),
    'payment_processing': Duration(seconds: 5),
  };

  // Quality Gates
  static const Map<String, dynamic> qualityGates = {
    'code_coverage': {
      'minimum': minCoveragePercentage,
      'enabled': true,
    },
    'test_success_rate': {
      'minimum': 100.0,
      'enabled': true,
    },
    'performance_benchmarks': {
      'enabled': false, // Disabled until performance tests are stable
      'threshold': 1.2, // 20% slower than benchmark
    },
    'static_analysis': {
      'enabled': true,
      'max_issues': 0,
    },
  };
}