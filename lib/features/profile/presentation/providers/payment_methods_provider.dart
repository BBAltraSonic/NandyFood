import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/payment_service.dart';
import 'package:food_delivery_app/features/profile/data/repositories/payment_method_repository.dart';


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

  factory PaymentMethodInfo.fromJson(Map<String, dynamic> json) {
    return PaymentMethodInfo(
      id: json['id'] as String,
      type: json['type'] as String,
      last4: json['last4'] as String,
      brand: json['brand'] as String,
      expiryMonth: json['expiry_month'] as int,
      expiryYear: json['expiry_year'] as int,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'last4': last4,
        'brand': brand,
        'expiry_month': expiryMonth,
        'expiry_year': expiryYear,
        'is_default': isDefault,
      };
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
  final PaymentMethodRepository _repo;
  PaymentMethodsNotifier({PaymentMethodRepository? repo})
      : _repo = repo ?? PaymentMethodRepository(),
        super(PaymentMethodsState());

  // Load payment methods
  Future<void> loadPaymentMethods(String userId) async {
    state = state.copyWith(isLoading: true);

    try {
      final rows = await _repo.fetchPaymentMethods(userId);
      final methods = rows.map((r) => PaymentMethodInfo.fromJson(r)).toList();
      state = state.copyWith(paymentMethods: methods, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Add a new payment method
  Future<void> addPaymentMethod({
    required String userId,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvc,
    String? holderName,
    bool isDefault = false,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final row = await _repo.createCardPaymentMethod(
        userId: userId,
        cardNumber: cardNumber,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        cvc: cvc,
        cardholderName: holderName,
        isDefault: isDefault,
      );

      final created = PaymentMethodInfo.fromJson(row);
      final updated = [...state.paymentMethods, created];

      state = state.copyWith(paymentMethods: updated, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // Remove a payment method
  Future<void> removePaymentMethod(String paymentMethodId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repo.deletePaymentMethod(paymentMethodId);

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
  Future<void> setDefaultPaymentMethod(String userId, String paymentMethodId) async {
    state = state.copyWith(isLoading: true);

    try {
      await _repo.setDefaultPaymentMethod(userId, paymentMethodId);

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
