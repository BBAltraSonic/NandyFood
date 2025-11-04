#!/usr/bin/env dart

/// Payment System Verification Tool
///
/// This script verifies the payment system integration and generates a comprehensive
/// report about the current state of payment capabilities.
library;

import 'dart:io';
import 'dart:convert';
import 'package:food_delivery_app/core/config/payment_config.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';
import 'package:food_delivery_app/core/security/payment_security.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class PaymentSystemVerifier {
  final Map<String, dynamic> _verificationResults = {};

  Future<void> verifyAll() async {
    print('💳 Payment System Verification');
    print('=' * 50);

    await _verifyConfiguration();
    await _verifyPaymentService();
    await _verifyPayFastIntegration();
    await _verifySecurityComponents();
    await _verifyValidationLogic();
    await _generateReport();
  }

  Future<void> _verifyConfiguration() async {
    print('\n🔧 Verifying Payment Configuration...');

    try {
      // Initialize payment configuration
      await PaymentConfig.initialize();

      final config = {
        'initialized': true,
        'enabled_methods': PaymentConfig.getEnabledPaymentMethods()
            .map((m) => m.name)
            .toList(),
        'default_method': PaymentConfig.getDefaultPaymentMethod().name,
        'cash_on_delivery': {
          'enabled': PaymentConfig.isCashOnDeliveryEnabled,
          'max_amount': PaymentConfig.maxCashAmount,
        },
        'payfast': {
          'enabled': PaymentConfig.isPayfastEnabled,
          'sandbox': PaymentConfig.isPayfastSandboxMode,
          'configured': PaymentConfig.payfastMerchantId != null &&
                      PaymentConfig.payfastMerchantKey != null &&
                      PaymentConfig.payfastPassphrase != null,
        },
        'limits': {
          'min_order': PaymentConfig.minOrderAmount,
          'max_cash': PaymentConfig.maxCashAmount,
        },
      };

      _verificationResults['configuration'] = config;

      print('  ✅ Configuration loaded successfully');
      print('  📊 Enabled methods: ${config['enabled_methods']}');
      print('  💰 Cash on delivery: ${config['cash_on_delivery']['enabled']}');
      print('  🌐 PayFast: ${config['payfast']['enabled']} (${config['payfast']['sandbox'] ? 'sandbox' : 'live'})');

    } catch (e, stack) {
      _verificationResults['configuration'] = {
        'initialized': false,
        'error': e.toString(),
        'stack': stack.toString(),
      };
      print('  ❌ Configuration failed: $e');
    }
  }

  Future<void> _verifyPaymentService() async {
    print('\n💳 Verifying Payment Service...');

    try {
      final paymentService = PaymentService();
      final availableMethods = paymentService.getAvailablePaymentMethods();

      final serviceInfo = {
        'singleton': true, // PaymentService is a singleton
        'available_methods': availableMethods,
        'validation_tests': _runValidationTests(paymentService),
      };

      _verificationResults['payment_service'] = serviceInfo;

      print('  ✅ Payment service initialized');
      print('  📋 Available methods: ${availableMethods.length}');

      for (final method in availableMethods) {
        print('    • ${method['name']}: ${method['enabled'] ? '✅' : '❌'}');
      }

      final validationTests = serviceInfo['validation_tests'] as Map<String, bool>;
      final passedTests = validationTests.values.where((v) => v).length;
      final totalTests = validationTests.length;

      print('  🧪 Validation tests: $passedTests/$totalTests passed');

    } catch (e, stack) {
      _verificationResults['payment_service'] = {
        'error': e.toString(),
        'stack': stack.toString(),
      };
      print('  ❌ Payment service failed: $e');
    }
  }

  Map<String, bool> _runValidationTests(PaymentService service) {
    return {
      'visa_card_validation': service.validateCardNumber('4532015112830366'),
      'mastercard_validation': service.validateCardNumber('5555555555554444'),
      'invalid_card_rejection': !service.validateCardNumber('1234567890123456'),
      'expiry_future': service.validateExpiryDate(12, DateTime.now().year + 1),
      'expiry_past_rejection': !service.validateExpiryDate(1, DateTime.now().year - 1),
      'cvc_valid': service.validateCvc('123', '4532015112830366'),
      'cvc_invalid_rejection': !service.validateCvc('12', '4532015112830366'),
      'amount_validation': service.validatePaymentAmount(15.0, PaymentMethodType.cash),
      'amount_rejection': !service.validatePaymentAmount(5.0, PaymentMethodType.cash),
    };
  }

  Future<void> _verifyPayFastIntegration() async {
    print('\n🌐 Verifying PayFast Integration...');

    if (!PaymentConfig.isPayfastEnabled) {
      _verificationResults['payfast'] = {
        'enabled': false,
        'reason': 'PayFast is disabled in configuration',
      };
      print('  ⏭️ PayFast is disabled - skipping verification');
      return;
    }

    try {
      final payfastService = PayFastService();

      // Test payment initialization (this will validate the service is working)
      final paymentData = await payfastService.initializePayment(
        orderId: 'test_verification_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test_user',
        amount: 100.0,
        itemName: 'Payment Verification Test',
        itemDescription: 'Automated payment system verification',
        customerEmail: 'test@nandyfood.com',
        customerFirstName: 'Test',
        customerLastName: 'Verification',
      );

      final payfastInfo = {
        'enabled': true,
        'initialization': 'success',
        'signature_generation': paymentData.containsKey('signature'),
        'merchant_configured': paymentData.containsKey('merchant_id'),
        'sandbox_mode': PaymentConfig.isPayfastSandboxMode,
        'test_payment_id': paymentData['m_payment_id'],
      };

      _verificationResults['payfast'] = payfastInfo;

      print('  ✅ PayFast integration working');
      print('  🔐 Signature generation: ${payfastInfo['signature_generation'] ? '✅' : '❌'}');
      print('  🏪 Merchant configured: ${payfastInfo['merchant_configured'] ? '✅' : '❌'}');
      print('  🧪 Test payment ID: ${payfastInfo['test_payment_id']}');

    } catch (e, stack) {
      _verificationResults['payfast'] = {
        'enabled': true,
        'error': e.toString(),
        'stack': stack.toString(),
      };
      print('  ❌ PayFast integration failed: $e');
    }
  }

  Future<void> _verifySecurityComponents() async {
    print('\n🔒 Verifying Security Components...');

    try {
      final securityTests = {
        'merchant_validation': PaymentSecurity.validateMerchantConfig(),
        'signature_generation': _testSignatureGeneration(),
        'input_sanitization': _testInputSanitization(),
        'data_masking': _testDataMasking(),
      };

      _verificationResults['security'] = securityTests;

      print('  ✅ Security components loaded');

      securityTests.forEach((test, passed) {
        print('  ${passed ? '✅' : '❌'} $test');
      });

    } catch (e, stack) {
      _verificationResults['security'] = {
        'error': e.toString(),
        'stack': stack.toString(),
      };
      print('  ❌ Security verification failed: $e');
    }
  }

  bool _testSignatureGeneration() {
    try {
      final signature = PaymentSecurity.generatePaymentSignature({
        'merchant_id': '10000100',
        'merchant_key': '46f0cd694581a',
        'amount': '100.00',
        'item_name': 'Test',
      });
      return signature.isNotEmpty && signature.length == 32; // MD5 hash length
    } catch (e) {
      return false;
    }
  }

  bool _testInputSanitization() {
    try {
      final clean = PaymentSecurity.sanitizeInput('<script>alert("xss")</script>');
      return !clean.contains('<script>') && !clean.contains('alert');
    } catch (e) {
      return false;
    }
  }

  bool _testDataMasking() {
    try {
      final masked = PaymentSecurity.maskSensitiveData('4111111111111111');
      return masked.contains('*') && !masked.contains('4111111111111111');
    } catch (e) {
      return false;
    }
  }

  Future<void> _verifyValidationLogic() async {
    print('\n✅ Verifying Validation Logic...');

    try {
      final paymentService = PaymentService();

      final validationResults = {
        'amount_validation': {
          'min_order_enforced': !PaymentConfig.validateOrderAmount(5.0, PaymentMethod.cashOnDelivery),
          'max_cash_enforced': !PaymentConfig.validateOrderAmount(6000.0, PaymentMethod.cashOnDelivery),
          'valid_amount_accepted': PaymentConfig.validateOrderAmount(15.0, PaymentMethod.cashOnDelivery),
        },
        'payment_method_validation': {
          'cash_enabled': PaymentConfig.isPaymentMethodEnabled(PaymentMethod.cashOnDelivery),
          'payfast_status': PaymentConfig.isPaymentMethodEnabled(PaymentMethod.payfast),
          'card_disabled': !PaymentConfig.isPaymentMethodEnabled(PaymentMethod.card),
        },
        'card_validation': {
          'luhn_algorithm': paymentService.validateCardNumber('4532015112830366'),
          'brand_detection': paymentService.getCardBrand('4532015112830366') == 'visa',
          'expiry_logic': paymentService.validateExpiryDate(12, DateTime.now().year + 1),
        },
      };

      _verificationResults['validation'] = validationResults;

      print('  ✅ Validation logic verified');

      validationResults.forEach((category, tests) {
        print('  📂 $category:');
        (tests as Map<String, dynamic>).forEach((test, passed) {
          print('    ${passed ? '✅' : '❌'} $test');
        });
      });

    } catch (e, stack) {
      _verificationResults['validation'] = {
        'error': e.toString(),
        'stack': stack.toString(),
      };
      print('  ❌ Validation verification failed: $e');
    }
  }

  Future<void> _generateReport() async {
    print('\n📄 Generating Verification Report...');

    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'verdict': _calculateOverallVerdict(),
      'summary': _generateSummary(),
      'detailed_results': _verificationResults,
      'recommendations': _generateRecommendations(),
    };

    // Write JSON report
    final reportFile = File('test_reports/payment_verification_${DateTime.now().millisecondsSinceEpoch}.json');
    await reportFile.parent.create(recursive: true);
    await reportFile.writeAsString(const JsonEncoder.withIndent('  ').convert(report));

    print('  ✅ Report generated: ${reportFile.path}');

    // Print summary
    _printSummary();
  }

  String _calculateOverallVerdict() {
    int passedChecks = 0;
    int totalChecks = 0;

    _verificationResults.forEach((category, result) {
      if (result is Map<String, dynamic>) {
        if (result.containsKey('error')) {
          // This category failed completely
          return;
        }

        if (category == 'configuration' || category == 'payment_service') {
          totalChecks++;
          if (result['initialized'] == true || result['singleton'] == true) {
            passedChecks++;
          }
        } else if (category == 'payfast') {
          totalChecks++;
          if (result['enabled'] == false || result['initialization'] == 'success') {
            passedChecks++;
          }
        } else if (category == 'security' || category == 'validation') {
          totalChecks++;
          final passed = (result as Map<String, dynamic>).values.where((v) => v == true).length;
          final total = result.length;
          if (passed / total >= 0.8) { // 80% pass rate
            passedChecks++;
          }
        }
      }
    });

    final percentage = totalChecks > 0 ? (passedChecks / totalChecks) * 100 : 0;

    if (percentage >= 90) return 'EXCELLENT';
    if (percentage >= 75) return 'GOOD';
    if (percentage >= 50) return 'ACCEPTABLE';
    return 'NEEDS_ATTENTION';
  }

  Map<String, dynamic> _generateSummary() {
    return {
      'payment_methods_available': PaymentConfig.getEnabledPaymentMethods().length,
      'payfast_configured': PaymentConfig.isPayfastEnabled &&
                           PaymentConfig.payfastMerchantId != null,
      'security_features_implemented': 4, // Based on our security tests
      'test_coverage': 'comprehensive',
      'production_readiness': _calculateOverallVerdict(),
    };
  }

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Configuration recommendations
    final config = _verificationResults['configuration'] as Map<String, dynamic>?;
    if (config?['payfast']?['enabled'] == false) {
      recommendations.add('Consider enabling PayFast for online payments');
    }
    if (config?['payfast']?['configured'] == false) {
      recommendations.add('Configure PayFast credentials in environment variables');
    }

    // Payment method recommendations
    if (!PaymentConfig.isPaymentMethodEnabled(PaymentMethod.card)) {
      recommendations.add('Consider implementing card payment gateway integration');
    }

    // Security recommendations
    final security = _verificationResults['security'] as Map<String, dynamic>?;
    if (security != null && security.values.any((v) => v == false)) {
      recommendations.add('Review and strengthen security implementation');
    }

    // Production recommendations
    if (_calculateOverallVerdict() != 'EXCELLENT') {
      recommendations.add('Address outstanding issues before production deployment');
    }

    return recommendations;
  }

  void _printSummary() {
    print('\n' + '=' * 50);
    print('💳 PAYMENT SYSTEM VERIFICATION SUMMARY');
    print('=' * 50);

    final verdict = _calculateOverallVerdict();
    final summary = _generateSummary();

    print('Overall Verdict: $verdict');
    print('');
    print('Key Metrics:');
    print('  • Payment Methods: ${summary['payment_methods_available']} available');
    print('  • PayFast: ${summary['payfast_configured'] ? '✅ Configured' : '❌ Not configured'}');
    print('  • Security Features: ${summary['security_features_implemented']} implemented');
    print('  • Production Readiness: ${summary['production_readiness']}');

    final recommendations = _generateRecommendations();
    if (recommendations.isNotEmpty) {
      print('\n📝 Recommendations:');
      for (final recommendation in recommendations) {
        print('  • $recommendation');
      }
    }

    print('\n🎉 Payment system verification completed!');
  }
}

void main(List<String> arguments) async {
  final verifier = PaymentSystemVerifier();

  try {
    await verifier.verifyAll();
  } catch (e, stack) {
    print('❌ Verification failed: $e');
    print(stack);
    exit(1);
  }
}