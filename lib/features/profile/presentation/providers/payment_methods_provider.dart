import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';

// Payment method model
class PaymentMethodInfo {
  final String id;
  final String type;
  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;

  PaymentMethodInfo({
    required this.id,
    required this.type,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    this.isDefault = false,
  });
}

// Payment methods state
class PaymentMethodsState {
  final List<PaymentMethodInfo> paymentMethods;
  final bool isLoading;
  final String? errorMessage;
  final PaymentMethodInfo? selectedPaymentMethod;

  PaymentMethodsState({
    this.paymentMethods = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedPaymentMethod,
  });

  PaymentMethodsState copyWith({
    List<PaymentMethodInfo>? paymentMethods,
    bool? isLoading,
    String? errorMessage,
    PaymentMethodInfo? selectedPaymentMethod,
  }) {
    return PaymentMethodsState(
      paymentMethods: paymentMethods ?? this.paymentMethods,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
    );
  }
}

// Payment methods provider
final paymentMethodsProvider =
    StateNotifierProvider<PaymentMethodsNotifier, PaymentMethodsState>(
      (ref) => PaymentMethodsNotifier(),
    );

class PaymentMethodsNotifier extends StateNotifier<PaymentMethodsState> {
  PaymentMethodsNotifier() : super(PaymentMethodsState());

  // Load payment methods
  Future<void> loadPaymentMethods() async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate loading payment methods
      await Future.delayed(const Duration(milliseconds: 500));

      // For now, return some mock payment methods
      final mockPaymentMethods = [
        PaymentMethodInfo(
          id: 'pm_1',
          type: 'card',
          last4: '4242',
          brand: 'Visa',
          expiryMonth: 12,
          expiryYear: 25,
          isDefault: true,
        ),
        PaymentMethodInfo(
          id: 'pm_2',
          type: 'card',
          last4: '1234',
          brand: 'Mastercard',
          expiryMonth: 6,
          expiryYear: 26,
          isDefault: false,
        ),
      ];

      state = state.copyWith(
        paymentMethods: mockPaymentMethods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Add a new payment method
  Future<void> addPaymentMethod({
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    required String holderName,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      // Validate card details
      final paymentService = PaymentService();
      if (!paymentService.validateCardNumber(cardNumber)) {
        throw Exception('Invalid card number');
      }

      if (!paymentService.validateExpiryDate(expiryMonth, expiryYear)) {
        throw Exception('Invalid expiry date');
      }

      if (!paymentService.validateCvc(cvc, cardNumber)) {
        throw Exception('Invalid CVC');
      }

      // Simulate creating a payment method
      await Future.delayed(const Duration(milliseconds: 800));

      // Create mock payment method
      final newPaymentMethod = PaymentMethodInfo(
        id: 'pm_${DateTime.now().millisecondsSinceEpoch}',
        type: 'card',
        last4: cardNumber.substring(cardNumber.length - 4),
        brand: paymentService.getCardBrand(cardNumber),
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: state.paymentMethods.isEmpty,
      );

      final updatedPaymentMethods = [...state.paymentMethods, newPaymentMethod];

      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Remove a payment method
  Future<void> removePaymentMethod(String paymentMethodId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate removing a payment method
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedPaymentMethods = state.paymentMethods
          .where((method) => method.id != paymentMethodId)
          .toList();

      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Set a payment method as default
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Simulate setting default payment method
      await Future.delayed(const Duration(milliseconds: 300));

      final updatedPaymentMethods = state.paymentMethods.map((method) {
        return method.copyWith(isDefault: method.id == paymentMethodId);
      }).toList();

      state = state.copyWith(
        paymentMethods: updatedPaymentMethods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Select a payment method for current transaction
  void selectPaymentMethod(String paymentMethodId) {
    final selectedMethod = state.paymentMethods.firstWhere(
      (method) => method.id == paymentMethodId,
      orElse: () => state.paymentMethods.first,
    );

    state = state.copyWith(selectedPaymentMethod: selectedMethod);
  }

  // Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Extension to make copying easier
extension PaymentMethodInfoExtension on PaymentMethodInfo {
  PaymentMethodInfo copyWith({
    String? id,
    String? type,
    String? last4,
    String? brand,
    int? expiryMonth,
    int? expiryYear,
    bool? isDefault,
  }) {
    return PaymentMethodInfo(
      id: id ?? this.id,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
