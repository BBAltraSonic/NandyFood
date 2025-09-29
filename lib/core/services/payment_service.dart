import 'package:food_delivery_app/shared/models/order.dart';

// Mock payment method class for our payment service
class PaymentMethod {
  final String id;
  final String type; // 'card', 'paypal', etc.
  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  /// Initialize the payment service
  Future<void> initialize() async {
    // In a real implementation, this would initialize the payment provider
    print('Payment service initialized');
  }

  /// Create a payment intent for an order
  Future<String?> createPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Return a mock payment intent ID
      return 'pi_mock_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  /// Confirm a payment using the payment method
  Future<bool> confirmPayment({
    required String paymentIntentId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate payment processing - 90% success rate
      final random = DateTime.now().millisecond % 10;
      return random != 0; // 90% success rate (if random is not 0)
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

 /// Create a payment method from card details
  Future<PaymentMethod> createPaymentMethod({
    required String type,
    required String number,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    required String holderName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Create a mock payment method
    return PaymentMethod(
      id: 'pm_mock_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      last4: number.substring(number.length - 4),
      brand: getCardBrand(number),
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
    );
 }

  /// Process a complete payment for an order
  Future<bool> processOrderPayment({
    required Order order,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      // Create payment intent
      final paymentIntentId = await createPaymentIntent(
        amount: order.totalAmount * 100, // Convert to cents
        currency: 'usd',
        description: 'Order ${order.id} for ${order.userId}',
      );

      if (paymentIntentId == null) {
        return false;
      }

      // Confirm payment
      final paymentSuccess = await confirmPayment(
        paymentIntentId: paymentIntentId,
        paymentMethod: paymentMethod,
      );

      return paymentSuccess;
    } catch (e) {
      print('Error processing order payment: $e');
      return false;
    }
  }

 /// Get card brand from card number
 String getCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) {
      return 'Visa';
    } else if (cardNumber.startsWith('5') || cardNumber.startsWith('2')) {
      return 'Mastercard';
    } else if (cardNumber.startsWith('3')) {
      return 'Amex';
    } else {
      return 'Unknown';
    }
  }

 /// Validate card number
  bool validateCardNumber(String cardNumber) {
    // Remove spaces and other characters
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\s+'), '');
    
    // Check if it's numeric and has valid length
    if (!RegExp(r'^\d{13,19}$').hasMatch(cleanCardNumber)) {
      return false;
    }
    
    // Implement Luhn algorithm for validation
    return _validateLuhn(cleanCardNumber);
  }

  /// Validate expiry date
  bool validateExpiryDate(int month, int year) {
    final now = DateTime.now();
    final currentYear = now.year % 100; // Get last 2 digits of year
    final currentMonth = now.month;

    if (year < currentYear) {
      return false;
    }
    
    if (year == currentYear && month < currentMonth) {
      return false;
    }
    
    return true;
  }

 /// Validate CVC
  bool validateCvc(String cvc, String cardNumber) {
    final cleanCvc = cvc.replaceAll(RegExp(r'\s+'), '');
    
    if (cardNumber.startsWith('3')) {
      // Amex cards have 4-digit CVC
      return RegExp(r'^\d{4}$').hasMatch(cleanCvc);
    } else {
      // Other cards have 3-digit CVC
      return RegExp(r'^\d{3}$').hasMatch(cleanCvc);
    }
  }

 /// Luhn algorithm implementation
  bool _validateLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10 == 0);
  }
}