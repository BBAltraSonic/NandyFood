import 'package:flutter/material.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Payment method types
enum PaymentMethodType {
  cash,
  card,
  // Future payment methods can be added here
  // digitalWallet,
  // bankTransfer,
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final DatabaseService _dbService = DatabaseService();

  /// Process cash payment
  /// For cash payments, we simply confirm the order and mark payment as "pending"
  /// Payment will be collected on delivery
  Future<bool> processPayment({
    required BuildContext context,
    required double amount,
    required String orderId,
    PaymentMethodType method = PaymentMethodType.cash,
  }) async {
    AppLogger.function('PaymentService.processPayment', 'ENTER', params: {
      'amount': amount,
      'orderId': orderId,
      'method': method.toString(),
    });

    try {
      if (method == PaymentMethodType.cash) {
        // Cash on delivery - no actual payment processing needed
        AppLogger.info('Processing cash on delivery payment');
        
        // Simulate a small delay for UX
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Record the payment intent in database
        await _recordPaymentIntent(
          orderId: orderId,
          amount: amount,
          method: 'cash',
          status: 'pending',
        );
        
        AppLogger.success('Cash payment confirmed', details: 'Payment will be collected on delivery');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order confirmed! Pay cash on delivery.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        AppLogger.function('PaymentService.processPayment', 'EXIT', result: true);
        return true;
      } else {
        // Card payment - to be implemented later
        AppLogger.warning('Card payment not yet implemented');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Card payment coming soon! Please use cash on delivery.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        
        AppLogger.function('PaymentService.processPayment', 'EXIT', result: false);
        return false;
      }
    } catch (e, stack) {
      AppLogger.error('Payment processing failed', error: e, stack: stack);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      AppLogger.function('PaymentService.processPayment', 'EXIT', result: false);
      return false;
    }
  }

  /// Record payment intent in database
  Future<void> _recordPaymentIntent({
    required String orderId,
    required double amount,
    required String method,
    required String status,
  }) async {
    try {
      AppLogger.database('INSERT', 'payment_transactions', data: {
        'order_id': orderId,
        'amount': amount,
        'method': method,
      });
      
      await _dbService.client.from('payment_transactions').insert({
        'order_id': orderId,
        'amount': amount,
        'payment_method': method,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      AppLogger.success('Payment intent recorded');
    } catch (e) {
      AppLogger.warning('Failed to record payment intent', );
      // Don't throw - this shouldn't block the order
    }
  }

  /// Confirm cash payment (called when driver confirms payment received)
  Future<bool> confirmCashPayment(String orderId) async {
    AppLogger.function('PaymentService.confirmCashPayment', 'ENTER', params: {
      'orderId': orderId,
    });

    try {
      await _dbService.client
          .from('payment_transactions')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId)
          .eq('payment_method', 'cash');
      
      AppLogger.success('Cash payment confirmed');
      AppLogger.function('PaymentService.confirmCashPayment', 'EXIT', result: true);
      return true;
    } catch (e, stack) {
      AppLogger.error('Failed to confirm cash payment', error: e, stack: stack);
      AppLogger.function('PaymentService.confirmCashPayment', 'EXIT', result: false);
      return false;
    }
  }

  /// Get payment methods available for orders
  List<Map<String, dynamic>> getAvailablePaymentMethods() {
    return [
      {
        'type': PaymentMethodType.cash,
        'name': 'Cash on Delivery',
        'description': 'Pay with cash when your order arrives',
        'icon': Icons.money,
        'enabled': true,
      },
      {
        'type': PaymentMethodType.card,
        'name': 'Credit/Debit Card',
        'description': 'Pay securely with your card',
        'icon': Icons.credit_card,
        'enabled': false, // Disabled for now
      },
    ];
  }

  /// Helper: Get payment method display name
  String getPaymentMethodName(PaymentMethodType type) {
    switch (type) {
      case PaymentMethodType.cash:
        return 'Cash on Delivery';
      case PaymentMethodType.card:
        return 'Credit/Debit Card';
    }
  }

  /// Validate card number using Luhn algorithm (for future card payments)
  bool validateCardNumber(String cardNumber) {
    // Remove spaces and dashes
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }
    
    // Check length (13-19 digits for most cards)
    if (cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }
    
    // Luhn algorithm
    int sum = 0;
    bool alternate = false;
    
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }

  /// Validate expiry date
  bool validateExpiryDate(int month, int year) {
    if (month < 1 || month > 12) {
      return false;
    }
    
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    // Handle 2-digit year
    final fullYear = year < 100 ? 2000 + year : year;
    
    // Check if card is expired
    if (fullYear < currentYear) {
      return false;
    }
    
    if (fullYear == currentYear && month < currentMonth) {
      return false;
    }
    
    return true;
  }

  /// Validate CVC/CVV
  bool validateCvc(String cvc, String cardNumber) {
    // Remove spaces
    final cleaned = cvc.replaceAll(RegExp(r'\s'), '');
    
    // Check if it's all digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return false;
    }
    
    // American Express uses 4 digits, others use 3
    final brand = getCardBrand(cardNumber);
    final expectedLength = (brand == 'amex') ? 4 : 3;
    
    return cleaned.length == expectedLength;
  }

  /// Get card brand from card number
  String getCardBrand(String cardNumber) {
    final cleaned = cardNumber.replaceAll(RegExp(r'[\s-]'), '');
    
    if (cleaned.isEmpty) {
      return 'unknown';
    }
    
    // Visa: starts with 4
    if (RegExp(r'^4').hasMatch(cleaned)) {
      return 'visa';
    }
    
    // Mastercard: starts with 51-55 or 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cleaned) || 
        RegExp(r'^2(2[2-9][0-9]|[3-6][0-9]{2}|7[0-1][0-9]|720)').hasMatch(cleaned)) {
      return 'mastercard';
    }
    
    // American Express: starts with 34 or 37
    if (RegExp(r'^3[47]').hasMatch(cleaned)) {
      return 'amex';
    }
    
    // Discover: starts with 6011, 622126-622925, 644-649, or 65
    if (RegExp(r'^6(?:011|5[0-9]{2}|4[4-9][0-9]|22(1(2[6-9]|[3-9][0-9])|[2-8][0-9]{2}|9([01][0-9]|2[0-5])))').hasMatch(cleaned)) {
      return 'discover';
    }
    
    // Diners Club: starts with 36 or 38 or 300-305
    if (RegExp(r'^3(?:0[0-5]|[68])').hasMatch(cleaned)) {
      return 'diners';
    }
    
    // JCB: starts with 2131, 1800, or 35
    if (RegExp(r'^(?:2131|1800|35)').hasMatch(cleaned)) {
      return 'jcb';
    }
    
    return 'unknown';
  }
}