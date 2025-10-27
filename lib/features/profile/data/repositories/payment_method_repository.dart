import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

class PaymentMethodRepository {
  final DatabaseService _db;
  final PaymentService _paymentService;

  PaymentMethodRepository({DatabaseService? db, PaymentService? paymentService})
      : _db = db ?? DatabaseService(),
        _paymentService = paymentService ?? PaymentService();

  Future<List<Map<String, dynamic>>> fetchPaymentMethods(String userId) async {
    return _db.getPaymentMethods(userId);
  }

  Future<Map<String, dynamic>> createCardPaymentMethod({
    required String userId,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? cardholderName,
    bool isDefault = false,
  }) async {
    // Validate
    if (!_paymentService.validateCardNumber(cardNumber)) {
      throw ArgumentError('Invalid card number');
    }
    if (!_paymentService.validateExpiryDate(expiryMonth, expiryYear)) {
      throw ArgumentError('Invalid expiry date');
    }
    if (!_paymentService.validateCvc(cvc)) {
      throw ArgumentError('Invalid CVC');
    }

    final brand = _paymentService.getCardBrand(cardNumber);
    final last4 = cardNumber.replaceAll(RegExp(r'\s+'), '').substring(cardNumber.length - 4);

    final payload = {
      'user_id': userId,
      'type': 'card',
      'brand': brand,
      'last4': last4,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'is_default': isDefault,
      'cardholder_name': cardholderName,
    }..removeWhere((k, v) => v == null);

    final row = await _db.createPaymentMethod(payload);

    // Enforce default uniqueness
    if (isDefault) {
      await _db.setDefaultPaymentMethod(userId, row['id'] as String);
    }

    return row;
  }

  Future<void> deletePaymentMethod(String id) async {
    await _db.deletePaymentMethod(id);
  }

  Future<void> setDefaultPaymentMethod(String userId, String id) async {
    await _db.setDefaultPaymentMethod(userId, id);
  }
}

