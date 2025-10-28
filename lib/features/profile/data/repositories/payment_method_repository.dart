import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

/// Payment method types supported by the app
enum PaymentMethodType {
  card,
  bankAccount,
  digitalWallet,
  cash,
}

class PaymentMethodRepository {
  final DatabaseService _db;
  final PaymentService _paymentService;

  PaymentMethodRepository({DatabaseService? db, PaymentService? paymentService})
      : _db = db ?? DatabaseService(),
        _paymentService = paymentService ?? PaymentService();

  Future<List<Map<String, dynamic>>> fetchPaymentMethods(String userId) async {
    return _db.getPaymentMethods(userId);
  }

  /// Get the default payment method for a user
  Future<Map<String, dynamic>?> getDefaultPaymentMethod(String userId) async {
    final methods = await fetchPaymentMethods(userId);
    try {
      return methods.firstWhere((method) => method['is_default'] == true);
    } catch (e) {
      return null;
    }
  }

  /// Validate payment method data and return error message if invalid
  String? validatePaymentMethod({
    required PaymentMethodType type,
    String? cardNumber,
    int? expiryMonth,
    int? expiryYear,
    String? cvc,
    String? cardholderName,
    String? bankAccountNumber,
    String? routingNumber,
    String? accountHolderName,
    String? walletProvider,
    String? walletEmail,
  }) {
    switch (type) {
      case PaymentMethodType.card:
        return _validateCardDetails(
          cardNumber: cardNumber,
          expiryMonth: expiryMonth,
          expiryYear: expiryYear,
          cvc: cvc,
          cardholderName: cardholderName,
        );

      case PaymentMethodType.bankAccount:
        return _validateBankAccountDetails(
          bankAccountNumber: bankAccountNumber,
          routingNumber: routingNumber,
          accountHolderName: accountHolderName,
        );

      case PaymentMethodType.digitalWallet:
        return _validateDigitalWalletDetails(
          walletProvider: walletProvider,
          walletEmail: walletEmail,
        );

      case PaymentMethodType.cash:
        // Cash doesn't require validation
        return null;
    }
  }

  /// Validate credit/debit card details
  String? _validateCardDetails({
    String? cardNumber,
    int? expiryMonth,
    int? expiryYear,
    String? cvc,
    String? cardholderName,
  }) {
    if (cardNumber == null || cardNumber.trim().isEmpty) {
      return 'Card number is required';
    }

    if (!_paymentService.validateCardNumber(cardNumber)) {
      return 'Invalid card number';
    }

    if (expiryMonth == null || expiryYear == null) {
      return 'Expiry date is required';
    }

    if (!_paymentService.validateExpiryDate(expiryMonth, expiryYear)) {
      return 'Invalid expiry date';
    }

    if (cvc == null || cvc.trim().isEmpty) {
      return 'CVC is required';
    }

    if (!_paymentService.validateCvc(cvc, cardNumber)) {
      return 'Invalid CVC';
    }

    if (cardholderName != null && cardholderName.trim().isNotEmpty) {
      if (cardholderName.trim().length < 3) {
        return 'Cardholder name seems too short';
      }
      if (cardholderName.trim().length > 100) {
        return 'Cardholder name is too long (max 100 characters)';
      }
    }

    return null;
  }

  /// Validate bank account details
  String? _validateBankAccountDetails({
    String? bankAccountNumber,
    String? routingNumber,
    String? accountHolderName,
  }) {
    if (bankAccountNumber == null || bankAccountNumber.trim().isEmpty) {
      return 'Bank account number is required';
    }

    if (!RegExp(r'^\d{8,17}$').hasMatch(bankAccountNumber.replaceAll(RegExp(r'\s'), ''))) {
      return 'Invalid bank account number';
    }

    if (routingNumber == null || routingNumber.trim().isEmpty) {
      return 'Routing number is required';
    }

    if (!RegExp(r'^\d{9}$').hasMatch(routingNumber.replaceAll(RegExp(r'\s'), ''))) {
      return 'Invalid routing number (must be 9 digits)';
    }

    if (accountHolderName == null || accountHolderName.trim().isEmpty) {
      return 'Account holder name is required';
    }

    if (accountHolderName.trim().length < 3) {
      return 'Account holder name seems too short';
    }
    if (accountHolderName.trim().length > 100) {
      return 'Account holder name is too long (max 100 characters)';
    }

    return null;
  }

  /// Validate digital wallet details
  String? _validateDigitalWalletDetails({
    String? walletProvider,
    String? walletEmail,
  }) {
    if (walletProvider == null || walletProvider.trim().isEmpty) {
      return 'Wallet provider is required';
    }

    if (walletEmail == null || walletEmail.trim().isEmpty) {
      return 'Wallet email is required';
    }

    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(walletEmail.trim())) {
      return 'Invalid email address';
    }

    return null;
  }

  /// Format payment method for display
  String formatPaymentMethod(Map<String, dynamic> method) {
    final type = method['type'] as String;

    switch (type) {
      case 'card':
        final brand = method['brand'] as String? ?? 'Unknown';
        final last4 = method['last4'] as String? ?? '****';
        final cardholderName = method['cardholder_name'] as String?;
        final name = cardholderName != null ? ' ($cardholderName)' : '';
        return '$brand ending in $last4$name';

      case 'bank_account':
        final accountHolderName = method['account_holder_name'] as String? ?? 'Account';
        final last4 = method['account_last4'] as String? ?? '****';
        return 'Bank Account ($accountHolderName) ending in $last4';

      case 'digital_wallet':
        final provider = method['wallet_provider'] as String? ?? 'Wallet';
        final email = method['wallet_email'] as String? ?? '';
        return '$provider ($email)';

      case 'cash':
        return 'Cash on Delivery';

      default:
        return 'Unknown Payment Method';
    }
  }

  /// Check if payment method is expired (for cards)
  bool isPaymentMethodExpired(Map<String, dynamic> method) {
    if (method['type'] != 'card') return false;

    final expiryMonth = method['expiry_month'] as int?;
    final expiryYear = method['expiry_year'] as int?;

    if (expiryMonth == null || expiryYear == null) return true;

    return !_paymentService.validateExpiryDate(expiryMonth, expiryYear);
  }

  /// Get payment method expiry date formatted for display
  String? getPaymentMethodExpiry(Map<String, dynamic> method) {
    if (method['type'] != 'card') return null;

    final month = method['expiry_month'] as int?;
    final year = method['expiry_year'] as int?;

    if (month == null || year == null) return null;

    return '${month.toString().padLeft(2, '0')}/${year.toString().substring(2)}';
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
    // Enhanced validation using our validation method
    final validationError = _validateCardDetails(
      cardNumber: cardNumber,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      cvc: cvc,
      cardholderName: cardholderName,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
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

  /// Create a bank account payment method
  Future<Map<String, dynamic>> createBankAccountPaymentMethod({
    required String userId,
    required String bankAccountNumber,
    required String routingNumber,
    required String accountHolderName,
    bool isDefault = false,
  }) async {
    // Validate bank account details
    final validationError = _validateBankAccountDetails(
      bankAccountNumber: bankAccountNumber,
      routingNumber: routingNumber,
      accountHolderName: accountHolderName,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final accountLast4 = bankAccountNumber.replaceAll(RegExp(r'\s'), '').substring(bankAccountNumber.length - 4);

    final payload = {
      'user_id': userId,
      'type': 'bank_account',
      'account_last4': accountLast4,
      'routing_number': routingNumber,
      'account_holder_name': accountHolderName,
      'is_default': isDefault,
    };

    final row = await _db.createPaymentMethod(payload);

    // Enforce default uniqueness
    if (isDefault) {
      await _db.setDefaultPaymentMethod(userId, row['id'] as String);
    }

    return row;
  }

  /// Create a digital wallet payment method
  Future<Map<String, dynamic>> createDigitalWalletPaymentMethod({
    required String userId,
    required String walletProvider,
    required String walletEmail,
    bool isDefault = false,
  }) async {
    // Validate digital wallet details
    final validationError = _validateDigitalWalletDetails(
      walletProvider: walletProvider,
      walletEmail: walletEmail,
    );

    if (validationError != null) {
      throw ArgumentError(validationError);
    }

    final payload = {
      'user_id': userId,
      'type': 'digital_wallet',
      'wallet_provider': walletProvider,
      'wallet_email': walletEmail,
      'is_default': isDefault,
    };

    final row = await _db.createPaymentMethod(payload);

    // Enforce default uniqueness
    if (isDefault) {
      await _db.setDefaultPaymentMethod(userId, row['id'] as String);
    }

    return row;
  }

  /// Create a cash on delivery payment method (usually for default setup)
  Future<Map<String, dynamic>> createCashPaymentMethod({
    required String userId,
    bool isDefault = false,
  }) async {
    final payload = {
      'user_id': userId,
      'type': 'cash',
      'is_default': isDefault,
    };

    final row = await _db.createPaymentMethod(payload);

    // Enforce default uniqueness
    if (isDefault) {
      await _db.setDefaultPaymentMethod(userId, row['id'] as String);
    }

    return row;
  }

  /// Update payment method
  Future<Map<String, dynamic>> updatePaymentMethod({
    required String id,
    required String userId,
    String? cardholderName,
    bool? isDefault,
  }) async {
    final data = <String, dynamic>{
      if (cardholderName != null) 'cardholder_name': cardholderName,
      if (isDefault != null) 'is_default': isDefault,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final row = await _db.updatePaymentMethod(id, data);

    // If isDefault set to true, enforce only one default
    if (isDefault == true) {
      await _db.setDefaultPaymentMethod(userId, id);
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

