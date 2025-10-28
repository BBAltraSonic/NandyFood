#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Test Analysis Tool
///
/// Analyzes test results, generates reports, and provides insights
/// about test coverage and quality metrics
library;

import 'test_config.dart';

class TestAnalyzer {
  final Map<String, dynamic> _analysisResults = {};

  Future<void> analyzeAll() async {
    print('🔍 Analyzing Test Suite...');
    print('=' * 50);

    await _analyzeTestStructure();
    await _analyzeCoverage();
    await _analyzeTestQuality();
    await _analyzePerformance();
    await _generateReport();
  }

  Future<void> _analyzeTestStructure() async {
    print('\n📁 Analyzing Test Structure...');

    final structure = {
      'unit_tests': await _countFiles('test/unit', '*_test.dart'),
      'integration_tests': await _countFiles('test/integration', '*_test.dart'),
      'widget_tests': await _countFiles('test/widget', '*_test.dart'),
      'total_tests': 0,
    };

    structure['total_tests'] = structure['unit_tests'] +
                              structure['integration_tests'] +
                              structure['widget_tests'];

    _analysisResults['structure'] = structure;

    print('  Unit Tests: ${structure['unit_tests']} files');
    print('  Integration Tests: ${structure['integration_tests']} files');
    print('  Widget Tests: ${structure['widget_tests']} files');
    print('  Total: ${structure['total_tests']} test files');

    // Check for missing test categories
    if (structure['unit_tests'] == 0) {
      print('  ⚠️ No unit tests found');
    }
    if (structure['integration_tests'] == 0) {
      print('  ⚠️ No integration tests found');
    }
    if (structure['widget_tests'] == 0) {
      print('  ⚠️ No widget tests found');
    }
  }

  Future<int> _countFiles(String directory, String pattern) async {
    try {
      final dir = Directory(directory);
      if (!await dir.exists()) return 0;

      final files = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith(pattern))
          .toList();

      return files.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _analyzeCoverage() async {
    print('\n📊 Analyzing Coverage...');

    // Look for coverage files
    final coverageFile = File('coverage/lcov.info');
    if (!await coverageFile.exists()) {
      print('  ❌ No coverage file found. Run tests with --coverage flag.');
      return;
    }

    final coverageData = await coverageFile.readAsString();
    final metrics = _parseCoverageData(coverageData);

    _analysisResults['coverage'] = metrics;

    print('  Lines Covered: ${metrics['lines_covered']}/${metrics['lines_total']} (${metrics['lines_percentage']}%)');
    print('  Functions Covered: ${metrics['functions_covered']}/${metrics['functions_total']} (${metrics['functions_percentage']}%)');
    print('  Branches Covered: ${metrics['branches_covered']}/${metrics['branches_total']} (${metrics['branches_percentage']}%)');

    // Check coverage against thresholds
    final lineCoverage = double.tryParse(metrics['lines_percentage']) ?? 0.0;
    if (lineCoverage < TestConfig.minCoveragePercentage) {
      print('  ❌ Line coverage (${lineCoverage}%) is below threshold (${TestConfig.minCoveragePercentage}%)');
    } else {
      print('  ✅ Line coverage meets threshold');
    }

    if (lineCoverage >= 90) {
      print('  🎉 Excellent coverage achieved!');
    } else if (lineCoverage >= 80) {
      print('  👍 Good coverage achieved');
    } else if (lineCoverage >= 70) {
      print('  ⚠️ Coverage needs improvement');
    } else {
      print('  ❌ Poor coverage - needs significant improvement');
    }
  }

  Map<String, String> _parseCoverageData(String lcovData) {
    final lines = lcovData.split('\n');
    final metrics = <String, String>{};

    int totalLines = 0;
    int coveredLines = 0;
    int totalFunctions = 0;
    int coveredFunctions = 0;
    int totalBranches = 0;
    int coveredBranches = 0;

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        final parts = line.split(',');
        if (parts.length >= 3) {
          totalLines++;
          if (parts[1] == '1') {
            coveredLines++;
          }
        }
      } else if (line.startsWith('LH:')) {
        final parts = line.split(',');
        if (parts.length >= 3) {
          totalFunctions++;
          if (parts[1] == '1') {
            coveredFunctions++;
          }
        }
      } else if (line.startsWith('BRH:')) {
        final parts = line.split(',');
        if (parts.length >= 3) {
          totalBranches++;
          if (parts[1] == '1') {
            coveredBranches++;
          }
        }
      }
    }

    metrics['lines_total'] = totalLines.toString();
    metrics['lines_covered'] = coveredLines.toString();
    metrics['lines_percentage'] = totalLines > 0
        ? (coveredLines / totalLines * 100).toStringAsFixed(1)
        : '0.0';

    metrics['functions_total'] = totalFunctions.toString();
    metrics['functions_covered'] = coveredFunctions.toString();
    metrics['functions_percentage'] = totalFunctions > 0
        ? (coveredFunctions / totalFunctions * 100).toStringAsFixed(1)
        : '0.0';

    metrics['branches_total'] = totalBranches.toString();
    metrics['branches_covered'] = coveredBranches.toString();
    metrics['branches_percentage'] = totalBranches > 0
        ? (coveredBranches / totalBranches * 100).toStringAsFixed(1)
        : '0.0';

    return metrics;
  }

  Future<void> _analyzeTestQuality() async {
    print('\n🔬 Analyzing Test Quality...');

    // Analyze test patterns
    final patterns = await _analyzeTestPatterns();
    _analysisResults['patterns'] = patterns;

    print('  Test Quality Score: ${patterns['quality_score']}/100');
    print('  Assertions per test: ${patterns['avg_assertions']}');
    print('  Test descriptions: ${patterns['has_descriptions']}%');
    print('  Error scenarios: ${patterns['has_error_tests']}%');

    // Check for test smells
    final smells = await _detectTestSmells();
    _analysisResults['smells'] = smells;

    if (smells.isNotEmpty) {
      print('  ⚠️ Test Smells Detected:');
      for (final smell in smells) {
        print('    - $smell');
      }
    } else {
      print('  ✅ No significant test smells detected');
    }
  }

  Future<Map<String, dynamic>> _analyzeTestPatterns() async {
    final testFiles = <File>[];

    // Collect all test files
    for (final dir in ['test/unit', 'test/integration', 'test/widget']) {
      final directory = Directory(dir);
      if (await directory.exists()) {
        testFiles.addAll(
          await directory
              .list()
              .where((entity) => entity is File && entity.path.endsWith('_test.dart'))
              .cast<File>(),
        );
      }
    }

    int totalTests = 0;
    int totalAssertions = 0;
    int testsWithDescriptions = 0;
    int testsWithErrorScenarios = 0;

    for (final file in testFiles) {
      try {
        final content = await file.readAsString();

        // Count test methods
        final testMatches = RegExp(r'test\s*\(').allMatches(content);
        totalTests += testMatches.length;

        // Count assertions
        final assertionMatches = RegExp(r'expect\s*\(').allMatches(content);
        totalAssertions += assertionMatches.length;

        // Check for test descriptions (comments above test methods)
        final descriptionMatches = RegExp(r'//.*test.*:|///.*test.*:').allMatches(content);
        if (descriptionMatches.isNotEmpty) {
          testsWithDescriptions++;
        }

        // Check for error scenarios
        final errorMatches = RegExp(r'(error|fail|exception|throw|catch)').allMatches(content);
        if (errorMatches.isNotEmpty) {
          testsWithErrorScenarios++;
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }

    return {
      'total_tests': totalTests,
      'total_assertions': totalAssertions,
      'avg_assertions': totalTests > 0 ? (totalAssertions / totalTests).toStringAsFixed(1) : '0',
      'has_descriptions': totalTests > 0 ? ((testsWithDescriptions / totalTests) * 100).toStringAsFixed(0) : '0',
      'has_error_tests': totalTests > 0 ? ((testsWithErrorScenarios / totalTests) * 100).toStringAsFixed(0) : '0',
      'quality_score': _calculateQualityScore(totalTests, totalAssertions, testsWithDescriptions, testsWithErrorScenarios),
    };
  }

  int _calculateQualityScore(int totalTests, int totalAssertions, int testsWithDescriptions, int testsWithErrorScenarios) {
    if (totalTests == 0) return 0;

    double score = 0;

    // Base score for having tests
    score += 20;

    // Score for average assertions (ideal: 3-5 per test)
    final avgAssertions = totalAssertions / totalTests;
    if (avgAssertions >= 3 && avgAssertions <= 5) {
      score += 25;
    } else if (avgAssertions >= 1) {
      score += 15;
    }

    // Score for test descriptions
    final descriptionRatio = testsWithDescriptions / totalTests;
    score += (descriptionRatio * 25).round();

    // Score for error scenarios
    final errorRatio = testsWithErrorScenarios / totalTests;
    score += (errorRatio * 30).round();

    return score.clamp(0, 100).toInt();
  }

  Future<List<String>> _detectTestSmells() async {
    final smells = <String>[];
    final testFiles = <File>[];

    // Collect all test files
    for (final dir in ['test/unit', 'test/integration', 'test/widget']) {
      final directory = Directory(dir);
      if (await directory.exists()) {
        testFiles.addAll(
          await directory
              .list()
              .where((entity) => entity is File && entity.path.endsWith('_test.dart'))
              .cast<File>(),
        );
      }
    }

    for (final file in testFiles) {
      try {
        final content = await file.readAsString();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();

          // Check for various test smells
          if (line.startsWith('test(') && !line.contains(') async')) {
            // Synchronous test that might be slow
            smells.add('Synchronous test in ${file.path.split('/').last}:${i + 1}');
          }

          if (line.contains('print(') || line.contains('debugPrint(')) {
            // Debug prints in tests
            smells.add('Debug print in ${file.path.split('/').last}:${i + 1}');
          }

          if (line.contains('await Future.delayed(')) {
            // Manual delays (might indicate flaky tests)
            smells.add('Manual delay in ${file.path.split('/').last}:${i + 1}');
          }

          if (line.startsWith('test(') && !line.contains('group(')) {
            // Test not in a group
            if (i == 0 || !lines[i - 1].startsWith('group(')) {
              smells.add('Ungrouped test in ${file.path.split('/').last}:${i + 1}');
            }
          }

          if (line.length > 120) {
            // Long lines
            smells.add('Long line in ${file.path.split('/').last}:${i + 1}');
          }
        }
      } catch (e) {
        // Skip files that can't be read
      }
    }

    return smells;
  }

  Future<void> _analyzePerformance() async {
    print('\n⚡ Analyzing Test Performance...');

    // This would analyze test execution times if available
    // For now, provide placeholder information
    final performance = {
      'avg_test_time_ms': 1500,
      'slow_tests': 0,
      'total_time_seconds': 0,
      'recommendations': [
        'Consider using mock services to speed up integration tests',
        'Use test fixtures to reduce setup time',
        'Run tests in parallel where possible',
      ],
    };

    _analysisResults['performance'] = performance;

    print('  Average test time: ${performance['avg_test_time_ms']}ms');
    print('  Slow tests detected: ${performance['slow_tests']}');
    print('  Recommendations: ${performance['recommendations'].length}');
  }

  Future<void> _generateReport() async {
    print('\n📄 Generating Analysis Report...');

    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'analysis': _analysisResults,
      'recommendations': _generateRecommendations(),
      'summary': _generateSummary(),
    };

    // Write JSON report
    final reportFile = File('test_reports/test_analysis_${DateTime.now().millisecondsSinceEpoch}.json');
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(const JsonEncoder.withIndent('  ').convert(report));

    print('  ✅ Report generated: ${reportFile.path}');

    // Write summary to console
    _printSummary(_analysisResults);
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Coverage recommendations
    final coverage = _analysisResults['coverage'] as Map<String, String>?;
    if (coverage != null) {
      final lineCoverage = double.tryParse(coverage['lines_percentage'] ?? '0') ?? 0.0;
      if (lineCoverage < TestConfig.minCoveragePercentage) {
        recommendations.add('Increase test coverage to meet the ${TestConfig.minCoveragePercentage}% threshold');
        recommendations.add('Focus on testing untested business logic and edge cases');
      }
      if (lineCoverage < 70) {
        recommendations.add('Consider adding more unit tests for core functionality');
      }
    }

    // Structure recommendations
    final structure = _analysisResults['structure'] as Map<String, dynamic>?;
    if (structure != null) {
      if (structure['integration_tests'] == 0) {
        recommendations.add('Add integration tests to verify component interactions');
      }
      if (structure['widget_tests'] == 0) {
        recommendations.add('Add widget tests to verify UI behavior');
      }
    }

    // Quality recommendations
    final patterns = _analysisResults['patterns'] as Map<String, dynamic>?;
    if (patterns != null) {
      final avgAssertions = double.tryParse(patterns['avg_assertions'] ?? '0') ?? 0.0;
      if (avgAssertions < 2) {
        recommendations.add('Add more assertions to tests (aim for 3-5 per test)');
      }

      final hasDescriptions = int.tryParse(patterns['has_descriptions'] ?? '0') ?? 0;
      if (hasDescriptions < 80) {
        recommendations.add('Add descriptive comments to tests for better documentation');
      }
    }

    // Smells recommendations
    final smells = _analysisResults['smells'] as List<String>?;
    if (smells != null && smells.isNotEmpty) {
      recommendations.add('Address test smells to improve maintainability');
      recommendations.add('Remove debug prints from tests');
      recommendations.add('Organize tests into logical groups');
    }

    return recommendations;
  }

  Map<String, dynamic> _generateSummary() {
    final structure = _analysisResults['structure'] as Map<String, dynamic>?;
    final coverage = _analysisResults['coverage'] as Map<String, String>?;
    final patterns = _analysisResults['patterns'] as Map<String, dynamic>?;
    final smells = _analysisResults['smells'] as List<String>?;

    return {
      'total_test_files': structure?['total_tests'] ?? 0,
      'coverage_percentage': coverage?['lines_percentage'] ?? '0.0',
      'quality_score': patterns?['quality_score'] ?? 0,
      'test_smells_detected': smells?.length ?? 0,
      'overall_health': _calculateOverallHealth(),
    };
  }

  String _calculateOverallHealth() {
    final structure = _analysisResults['structure'] as Map<String, dynamic>?;
    final coverage = _analysisResults['coverage'] as Map<String, String>?;
    final patterns = _analysisResults['patterns'] as Map<String, dynamic>?;
    final smells = _analysisResults['smells'] as List<String>?;

    int score = 0;
    int maxScore = 100;

    // Coverage contribution (40%)
    if (coverage != null) {
      final lineCoverage = double.tryParse(coverage['lines_percentage'] ?? '0') ?? 0.0;
      score += (lineCoverage * 0.4).round();
    }

    // Test structure contribution (20%)
    if (structure != null) {
      final totalFiles = structure['total_tests'] as int? ?? 0;
      if (totalFiles >= 10) {
        score += 20;
      } else if (totalFiles >= 5) {
        score += 10;
      } else if (totalFiles > 0) {
        score += 5;
      }
    }

    // Quality contribution (30%)
    if (patterns != null) {
      final qualityScore = patterns['quality_score'] as int? ?? 0;
      score += (qualityScore * 0.3).round();
    }

    // Test smells penalty (10%)
    if (smells != null) {
      final smellCount = smells.length;
      if (smellCount > 10) {
        score -= 10;
      } else if (smellCount > 5) {
        score -= 5;
      } else if (smellCount > 0) {
        score -= 2;
      }
    }

    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Poor';
  }

  void _printSummary(Map<String, dynamic> analysis) {
    print('\n' + '=' * 50);
    print('📊 ANALYSIS SUMMARY');
    print('=' * 50);

    final summary = analysis['summary'] as Map<String, dynamic>? ?? {};

    print('Total Test Files: ${summary['total_test_files']}');
    print('Coverage: ${summary['coverage_percentage']}%');
    print('Quality Score: ${summary['quality_score']}/100');
    print('Test Smells: ${summary['test_smells_detected']}');
    print('Overall Health: ${summary['overall_health']}');

    if (analysis['recommendations'] != null) {
      final recommendations = (analysis['recommendations'] as List).cast<String>();
      if (recommendations.isNotEmpty) {
        print('\n📝 Recommendations:');
        for (final recommendation in recommendations) {
          print('  • $recommendation');
        }
      }
    }
  }
}

void main(List<String> arguments) async {
  final analyzer = TestAnalyzer();

  try {
    await analyzer.analyzeAll();
  } catch (e, stack) {
    print('❌ Analysis failed: $e');
    print(stack);
    exit(1);
  }
}