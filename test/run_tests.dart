#!/usr/bin/env dart

import 'dart:io';
import 'test_config.dart';

/// Automated Test Runner
///
/// This script provides comprehensive test execution with coverage reporting
/// for the NandyFood Flutter application
///
/// Usage:
/// dart run test/run_tests.dart [options]
///
/// Options:
///   --unit              Run unit tests only
///   --integration       Run integration tests only
///   --widget            Run widget tests only
///   --all               Run all tests (default)
///   --coverage          Generate coverage report
///   --verbose           Verbose output
///   --ci                CI mode (fail on low coverage)
///   --clean             Clean previous results
///   --help              Show this help message

Future<void> main(List<String> arguments) async {
  final options = TestOptions.parse(arguments);

  if (options.showHelp) {
    _printUsage();
    return;
  }

  print('🧪 NandyFood Test Runner');
  print('=' * 50);

  try {
    // Setup environment
    await _setupEnvironment(options);

    // Clean previous results if requested
    if (options.clean) {
      await _cleanResults();
    }

    // Run tests based on options
    final results = TestResults();

    if (options.runAll || options.runUnit) {
      await _runUnitTests(options, results);
    }

    if (options.runAll || options.runIntegration) {
      await _runIntegrationTests(options, results);
    }

    if (options.runAll || options.runWidget) {
      await _runWidgetTests(options, results);
    }

    // Generate coverage if requested
    if (options.coverage) {
      await _generateCoverageReport(results);
    }

    // Generate test report
    await _generateTestReport(results);

    // Validate quality gates
    await _validateQualityGates(results, options);

    // Print summary
    _printSummary(results);

    // Exit with appropriate code
    if (results.hasFailures || (options.ciMode && results.hasLowCoverage)) {
      exit(1);
    }

    exit(0);

  } catch (e, stack) {
    print('❌ Test runner failed: $e');
    print(stack);
    exit(1);
  }
}

class TestOptions {
  final bool runUnit;
  final bool runIntegration;
  final bool runWidget;
  final bool runAll;
  final bool coverage;
  final bool verbose;
  final bool ciMode;
  final bool clean;
  final bool showHelp;

  const TestOptions({
    this.runUnit = false,
    this.runIntegration = false,
    this.runWidget = false,
    this.runAll = true,
    this.coverage = false,
    this.verbose = false,
    this.ciMode = false,
    this.clean = false,
    this.showHelp = false,
  });

  factory TestOptions.parse(List<String> arguments) {
    bool runUnit = false;
    bool runIntegration = false;
    bool runWidget = false;
    bool runAll = true;
    bool coverage = false;
    bool verbose = false;
    bool ciMode = false;
    bool clean = false;
    bool showHelp = false;

    for (final arg in arguments) {
      switch (arg) {
        case '--unit':
          runUnit = true;
          runAll = false;
          break;
        case '--integration':
          runIntegration = true;
          runAll = false;
          break;
        case '--widget':
          runWidget = true;
          runAll = false;
          break;
        case '--all':
          runAll = true;
          break;
        case '--coverage':
          coverage = true;
          break;
        case '--verbose':
          verbose = true;
          break;
        case '--ci':
          ciMode = true;
          break;
        case '--clean':
          clean = true;
          break;
        case '--help':
          showHelp = true;
          break;
      }
    }

    return TestOptions(
      runUnit: runUnit,
      runIntegration: runIntegration,
      runWidget: runWidget,
      runAll: runAll,
      coverage: coverage,
      verbose: verbose,
      ciMode: ciMode,
      clean: clean,
      showHelp: showHelp,
    );
  }
}

class TestResults {
  final Map<String, TestResult> results = {};

  void addResult(String testName, TestResult result) {
    results[testName] = result;
  }

  bool get hasFailures => results.values.any((r) => r.exitCode != 0);
  bool get hasLowCoverage => results.values.any((r) => r.coverage < TestConfig.minCoveragePercentage);

  int get totalTests => results.values.fold(0, (sum, r) => sum + r.totalTests);
  int get passedTests => results.values.fold(0, (sum, r) => sum + r.passedTests);
  int get failedTests => totalTests - passedTests;
  double get overallCoverage => results.values.isEmpty ? 0.0 :
      results.values.fold(0.0, (sum, r) => sum + r.coverage) / results.values.length;
}

class TestResult {
  final String name;
  final int exitCode;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final double coverage;
  final Duration duration;
  final String output;
  final String errorOutput;

  const TestResult({
    required this.name,
    required this.exitCode,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.coverage,
    required this.duration,
    required this.output,
    required this.errorOutput,
  });

  bool get isSuccess => exitCode == 0;
}

Future<void> _setupEnvironment(TestOptions options) async {
  print('🔧 Setting up test environment...');

  // Set environment variables
  final envVars = TestConfig.getTestEnvironmentVariables();
  for (final entry in envVars.entries) {
    await _setEnvironmentVariable(entry.key, entry.value);
  }

  // Create necessary directories
  await TestConfig.ensureDirectoryExists(TestConfig.coverageDir);
  await TestConfig.ensureDirectoryExists(TestConfig.reportsDir);
  await TestConfig.ensureDirectoryExists(TestConfig.testReportsPath);

  print('✅ Environment setup complete');
}

Future<void> _setEnvironmentVariable(String key, String value) async {
  // In a real implementation, this would set actual environment variables
  print('  Setting $key = $value');
}

Future<void> _cleanResults() async {
  print('🧹 Cleaning previous results...');

  await TestConfig.cleanDirectory(TestConfig.coverageDir);
  await TestConfig.cleanDirectory(TestConfig.reportsDir);

  print('✅ Results cleaned');
}

Future<void> _runUnitTests(TestOptions options, TestResults results) async {
  print('\n📋 Running Unit Tests...');
  final stopwatch = Stopwatch()..start();

  final command = TestConfig.getUnitTestsCommand(
    coverage: options.coverage,
    verbose: options.verbose,
  );

  print('  Command: $command');

  final result = await _runCommand(command, 'Unit Tests');
  result.addResult('unit_tests', TestResult(
    name: 'Unit Tests',
    exitCode: result.exitCode,
    totalTests: result.totalTests,
    passedTests: result.passedTests,
    failedTests: result.failedTests,
    coverage: result.coverage,
    duration: stopwatch.elapsed,
    output: result.output,
    errorOutput: result.errorOutput,
  ));

  stopwatch.stop();
  print('  Completed in ${stopwatch.elapsed.inSeconds}s');
}

Future<void> _runIntegrationTests(TestOptions options, TestResults results) async {
  print('\n🔗 Running Integration Tests...');
  final stopwatch = Stopwatch()..start();

  final command = TestConfig.getIntegrationTestsCommand(
    coverage: options.coverage,
    verbose: options.verbose,
  );

  print('  Command: $command');

  final result = await _runCommand(command, 'Integration Tests');
  result.addResult('integration_tests', TestResult(
    name: 'Integration Tests',
    exitCode: result.exitCode,
    totalTests: result.totalTests,
    passedTests: result.passedTests,
    failedTests: result.failedTests,
    coverage: result.coverage,
    duration: stopwatch.elapsed,
    output: result.output,
    errorOutput: result.errorOutput,
  ));

  stopwatch.stop();
  print('  Completed in ${stopwatch.elapsed.inSeconds}s');
}

Future<void> _runWidgetTests(TestOptions options, TestResults results) async {
  print('\n🎨 Running Widget Tests...');
  final stopwatch = Stopwatch()..start();

  final command = 'flutter test ${TestConfig.widgetTestDir}'
      '${options.coverage ? ' --coverage' : ''}'
      '${options.verbose ? ' --verbose' : ''}';

  print('  Command: $command');

  final result = await _runCommand(command, 'Widget Tests');
  result.addResult('widget_tests', TestResult(
    name: 'Widget Tests',
    exitCode: result.exitCode,
    totalTests: result.totalTests,
    passedTests: result.passedTests,
    failedTests: result.failedTests,
    coverage: result.coverage,
    duration: stopwatch.elapsed,
    output: result.output,
    errorOutput: result.errorOutput,
  ));

  stopwatch.stop();
  print('  Completed in ${stopwatch.elapsed.inSeconds}s');
}

Future<CommandResult> _runCommand(String command, String testName) async {
  final parts = command.split(' ');
  final process = await Process.start(parts.first, parts.skip(1).toList());

  final output = StringBuffer();
  final errorOutput = StringBuffer();

  process.stdout.transform(const Utf8Decoder()).listen((data) {
    output.write(data);
    if (options.verbose) {
      print(data);
    }
  });

  process.stderr.transform(const Utf8Decoder()).listen((data) {
    errorOutput.write(data);
    if (options.verbose) {
      print('STDERR: $data');
    }
  });

  final exitCode = await process.exitCode;

  // Parse test results from output
  final testResults = _parseTestOutput(output.toString());

  return CommandResult(
    exitCode: exitCode,
    output: output.toString(),
    errorOutput: errorOutput.toString(),
    totalTests: testResults['total'] ?? 0,
    passedTests: testResults['passed'] ?? 0,
    failedTests: testResults['failed'] ?? 0,
    coverage: testResults['coverage']?.toDouble() ?? 0.0,
  );
}

Map<String, int> _parseTestOutput(String output) {
  final results = <String, int>{};

  // Parse test count
  final testCountRegex = RegExp(r'(\d+)\s+tests?');
  final testMatch = testCountRegex.firstMatch(output);
  if (testMatch != null) {
    results['total'] = int.parse(testMatch.group(1)!);
  }

  // Parse passed/failed tests
  final passedRegex = RegExp(r'All tests passed!');
  if (passedRegex.hasMatch(output)) {
    results['passed'] = results['total'] ?? 0;
    results['failed'] = 0;
  } else {
    final failedRegex = RegExp(r'Some tests failed\.');
    if (failedRegex.hasMatch(output)) {
      // Extract failed count from output
      final failedCountRegex = RegExp(r'(\d+)\s+failed');
      final failedMatch = failedCountRegex.firstMatch(output);
      if (failedMatch != null) {
        results['failed'] = int.parse(failedMatch.group(1)!);
        results['passed'] = (results['total'] ?? 0) - results['failed']!;
      }
    }
  }

  // Parse coverage percentage
  final coverageRegex = RegExp(r'(\d+\.?\d*)%');
  final coverageMatches = coverageRegex.allMatches(output);
  if (coverageMatches.isNotEmpty) {
    results['coverage'] = double.tryParse(coverageMatches.last.group(1)!)?.toInt() ?? 0;
  }

  return results;
}

Future<void> _generateCoverageReport(TestResults results) async {
  print('\n📊 Generating Coverage Report...');

  // Generate HTML coverage report
  try {
    final result = await Process.run('genhtml', [
      'coverage/lcov.info',
      '--output-directory',
      TestConfig.htmlCoverageOutput,
    ]);

    if (result.exitCode == 0) {
      print('  ✅ HTML coverage report generated');
      print('  📁 Location: ${TestConfig.htmlCoverageOutput}');
    } else {
      print('  ⚠️ HTML coverage report generation failed');
    }
  } catch (e) {
    print('  ⚠️ Could not generate HTML coverage (genhtml not available)');
  }

  // Generate coverage summary
  try {
    final result = await Process.run('lcov', ['--summary', 'coverage/lcov.info']);
    if (result.exitCode == 0) {
      print('  📈 Coverage Summary:');
      for (final line in result.stdout.toString().split('\n')) {
        if (line.trim().isNotEmpty) {
          print('    $line');
        }
      }
    }
  } catch (e) {
    print('  ⚠️ Could not generate coverage summary');
  }
}

Future<void> _generateTestReport(TestResults results) async {
  print('\n📝 Generating Test Report...');

  final timestamp = DateTime.now().toIso8601String();
  final report = {
    'timestamp': timestamp,
    'summary': {
      'total_tests': results.totalTests,
      'passed_tests': results.passedTests,
      'failed_tests': results.failedTests,
      'success_rate': results.totalTests > 0 ? (results.passedTests / results.totalTests * 100).toStringAsFixed(2) : '0.0',
      'overall_coverage': results.overallCoverage.toStringAsFixed(2),
    },
    'test_suites': results.results.map((key, value) => MapEntry(key, {
      'name': value.name,
      'exit_code': value.exitCode,
      'total_tests': value.totalTests,
      'passed_tests': value.passedTests,
      'failed_tests': value.failedTests,
      'coverage': value.coverage,
      'duration_ms': value.duration.inMilliseconds,
      'success': value.isSuccess,
    })),
    'quality_gates': {
      'coverage_threshold': TestConfig.minCoveragePercentage,
      'coverage_passed': !results.hasLowCoverage,
      'tests_passed': !results.hasFailures,
      'overall_passed': !results.hasFailures && !results.hasLowCoverage,
    },
  };

  // Write JSON report
  final reportFile = File('${TestConfig.testReportsPath}/test_report.json');
  await reportFile.writeAsString(report.toString());

  print('  ✅ Test report generated');
  print('  📁 Location: ${reportFile.path}');
}

Future<void> _validateQualityGates(TestResults results, TestOptions options) async {
  print('\n🚦 Validating Quality Gates...');

  bool allPassed = true;

  // Coverage gate
  if (results.overallCoverage < TestConfig.minCoveragePercentage) {
    print('  ❌ Coverage Gate Failed: ${results.overallCoverage.toStringAsFixed(2)}% < ${TestConfig.minCoveragePercentage}%');
    allPassed = false;
  } else {
    print('  ✅ Coverage Gate Passed: ${results.overallCoverage.toStringAsFixed(2)}% >= ${TestConfig.minCoveragePercentage}%');
  }

  // Test success gate
  if (results.hasFailures) {
    print('  ❌ Test Success Gate Failed: ${results.failedTests} tests failed');
    allPassed = false;
  } else {
    print('  ✅ Test Success Gate Passed: All ${results.totalTests} tests passed');
  }

  if (!allPassed && options.ciMode) {
    print('  💀 Quality gates failed in CI mode');
  } else if (allPassed) {
    print('  🎉 All quality gates passed!');
  }
}

void _printSummary(TestResults results) {
  print('\n' + '=' * 50);
  print('📊 TEST SUMMARY');
  print('=' * 50);

  print('Total Tests: ${results.totalTests}');
  print('Passed: ${results.passedTests}');
  print('Failed: ${results.failedTests}');
  print('Coverage: ${results.overallCoverage.toStringAsFixed(2)}%');

  if (results.results.isNotEmpty) {
    print('\nTest Suites:');
    for (final entry in results.results.entries) {
      final result = entry.value;
      final status = result.isSuccess ? '✅' : '❌';
      print('  $status ${result.name}: ${result.passedTests}/${result.totalTests} passed (${result.coverage.toStringAsFixed(2)}% coverage)');
    }
  }

  print('\nOverall Status: ${results.hasFailures ? '❌ FAILED' : '✅ PASSED'}');
}

void _printUsage() {
  print('NandyFood Test Runner');
  print('');
  print('Usage: dart run test/run_tests.dart [options]');
  print('');
  print('Options:');
  print('  --unit              Run unit tests only');
  print('  --integration       Run integration tests only');
  print('  --widget            Run widget tests only');
  print('  --all               Run all tests (default)');
  print('  --coverage          Generate coverage report');
  print('  --verbose           Verbose output');
  print('  --ci                CI mode (fail on low coverage)');
  print('  --clean             Clean previous results');
  print('  --help              Show this help message');
  print('');
  print('Examples:');
  print('  dart run test/run_tests.dart                    # Run all tests');
  print('  dart run test/run_tests.dart --coverage         # Run with coverage');
  print('  dart run test/run_tests.dart --unit --verbose    # Run unit tests with verbose output');
  print('  dart run test/run_tests.dart --ci                 # CI mode with quality gates');
}

class CommandResult {
  final int exitCode;
  final String output;
  final String errorOutput;
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final int coverage;

  const CommandResult({
    required this.exitCode,
    required this.output,
    required this.errorOutput,
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.coverage,
  });

  bool get isSuccess => exitCode == 0;
}

// Note: TestOptions and TestResults classes are defined above in the same file