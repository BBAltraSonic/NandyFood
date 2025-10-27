import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:food_delivery_app/features/order/presentation/providers/payment_provider.dart';
import 'package:food_delivery_app/core/services/payfast_service.dart';
import 'package:food_delivery_app/core/services/connectivity_service.dart';

class FakePayFastService implements PayFastService {
  @override
  Future<Map<String, String>> initializePayment({
    required String orderId,
    required String userId,
    required double amount,
    required String itemName,
    String? itemDescription,
    String? customerEmail,
    String? customerFirstName,
    String? customerLastName,
    String? customerPhone,
  }) async {
    return {
      'merchant_id': 'test',
      'merchant_key': 'test',
      'return_url': 'https://return',
      'cancel_url': 'https://cancel',
      'notify_url': 'https://notify',
      'm_payment_id': 'ref-123',
      'amount': amount.toStringAsFixed(2),
      'item_name': itemName,
      'signature': 'sig',
    };
  }

  @override
  Future<bool> verifyPaymentWebhook(Map<String, String> postData, String sourceIP) async => true;

  @override
  Future<Map<String, dynamic>> processPaymentResponse({
    required Map<String, String> responseData,
  }) async {
    return {
      'success': responseData['payment_status'] == 'COMPLETE',
      'payment_reference': responseData['m_payment_id'] ?? 'ref-123',
      'status': responseData['payment_status'] ?? 'COMPLETE',
      'message': 'Payment successful',
    };
  }

  @override
  Future<Map<String, dynamic>?> getTransactionStatus(String paymentRef) async {
    return {'status': 'completed'};
  }

  @override
  Future<String> initiateRefund({
    required String paymentRef,
    required double amount,
    required String reason,
  }) async => 'refund-1';

  @override
  Future<void> logWebhook({
    required Map<String, String> data,
    required String sourceIP,
    required bool verified,
  }) async {}
}

class FakeConnectivityService implements ConnectivityService {
  @override
  Future<bool> checkConnectivity() async => true;

  @override
  Stream<bool> get connectivityStream => const Stream.empty();

  @override
  void dispose() {}

  @override
  Future<void> initialize() async {}

  @override
  bool get isConnected => true;

  @override
  bool get isMobile => false;

  @override
  bool get isWiFi => false;

  @override
  String get connectionType => 'Test';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('metadata');
  });

  tearDown(() async {
    final box = Hive.box<dynamic>('metadata');
    await box.clear();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  test('persists pending payment on initializePayment', () async {
    final notifier = PaymentNotifier(
      payfastService: FakePayFastService(),
      connectivityService: FakeConnectivityService(),
    );

    await notifier.initializePayment(
      orderId: 'o1',
      userId: 'u1',
      amount: 12.34,
      itemName: 'Test',
    );

    final box = Hive.box<dynamic>('metadata');
    final pending = box.get('pending_payment') as Map?;

    expect(pending, isNotNull);
    expect(pending!['payment_ref'], 'ref-123');
    expect(pending['order_id'], 'o1');
    expect(pending['amount'], 12.34);
    expect(pending['started_at'], isNotNull);
  });

  test('clears pending payment after successful processing', () async {
    final notifier = PaymentNotifier(
      payfastService: FakePayFastService(),
      connectivityService: FakeConnectivityService(),
    );

    await notifier.initializePayment(
      orderId: 'o2',
      userId: 'u2',
      amount: 22.00,
      itemName: 'Order',
    );

    // Simulate PayFast redirect with success
    await notifier.processPaymentResponse({
      'm_payment_id': 'ref-123',
      'payment_status': 'COMPLETE',
    });

    final box = Hive.box<dynamic>('metadata');
    final pending = box.get('pending_payment');
    expect(pending, isNull);
  });
}

