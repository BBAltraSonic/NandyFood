import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/connectivity_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

/// Payment method types
enum PaymentMethodType {
  cash,
  payfast,
}

/// Payment method information
class PaymentMethodInfo {
  final PaymentMethodType type;
  final String name;
  final String description;
  final IconData icon;
  final bool enabled;
  final String? disabledReason;
  final bool recommended;

  PaymentMethodInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.icon,
    this.enabled = true,
    this.disabledReason,
    this.recommended = false,
  });

  PaymentMethodInfo copyWith({
    PaymentMethodType? type,
    String? name,
    String? description,
    IconData? icon,
    bool? enabled,
    String? disabledReason,
    bool? recommended,
  }) {
    return PaymentMethodInfo(
      type: type ?? this.type,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      enabled: enabled ?? this.enabled,
      disabledReason: disabledReason ?? this.disabledReason,
      recommended: recommended ?? this.recommended,
    );
  }
}

/// Payment method state
class PaymentMethodState {
  final PaymentMethodType selectedMethod;
  final List<PaymentMethodInfo> availableMethods;
  final bool isLoading;

  PaymentMethodState({
    this.selectedMethod = PaymentMethodType.cash,
    this.availableMethods = const [],
    this.isLoading = false,
  });

  PaymentMethodState copyWith({
    PaymentMethodType? selectedMethod,
    List<PaymentMethodInfo>? availableMethods,
    bool? isLoading,
  }) {
    return PaymentMethodState(
      selectedMethod: selectedMethod ?? this.selectedMethod,
      availableMethods: availableMethods ?? this.availableMethods,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  // Helper getters
  bool get isCash => selectedMethod == PaymentMethodType.cash;
  bool get isPayFast => selectedMethod == PaymentMethodType.payfast;

  PaymentMethodInfo? get selectedMethodInfo {
    try {
      return availableMethods.firstWhere(
        (method) => method.type == selectedMethod,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Payment method notifier
class PaymentMethodNotifier extends StateNotifier<PaymentMethodState> {
  PaymentMethodNotifier() : super(PaymentMethodState()) {
    loadAvailableMethods();
  }

  final ConnectivityService _connectivityService = ConnectivityService();

  /// Load available payment methods
  Future<void> loadAvailableMethods() async {
    AppLogger.function('PaymentMethodNotifier.loadAvailableMethods', 'ENTER');

    try {
      state = state.copyWith(isLoading: true);

      // Check connectivity for online payment methods
      final isConnected = _connectivityService.isConnected;

      // Build available methods
      final methods = <PaymentMethodInfo>[
        // Cash on Delivery - always available
        PaymentMethodInfo(
          type: PaymentMethodType.cash,
          name: 'Cash on Delivery',
          description: 'Pay with cash when your order arrives',
          icon: Icons.money,
          enabled: true,
          recommended: false,
        ),

        // PayFast - requires internet connection
        PaymentMethodInfo(
          type: PaymentMethodType.payfast,
          name: 'Card Payment',
          description: 'Pay securely with your credit or debit card',
          icon: Icons.credit_card,
          enabled: isConnected,
          disabledReason: isConnected ? null : 'No internet connection',
          recommended: true,
        ),
      ];

      state = state.copyWith(
        availableMethods: methods,
        isLoading: false,
      );

      AppLogger.success('Loaded ${methods.length} payment methods');
      AppLogger.function('PaymentMethodNotifier.loadAvailableMethods', 'EXIT');
    } catch (e, stack) {
      AppLogger.error('Failed to load payment methods', error: e, stack: stack);
      state = state.copyWith(isLoading: false);
    }
  }

  /// Select payment method
  void selectMethod(PaymentMethodType method) {
    AppLogger.function('PaymentMethodNotifier.selectMethod', 'ENTER',
        params: {'method': method.toString()});

    // Check if method is available
    final methodInfo = state.availableMethods.firstWhere(
      (m) => m.type == method,
      orElse: () => PaymentMethodInfo(
        type: method,
        name: '',
        description: '',
        icon: Icons.error,
        enabled: false,
      ),
    );

    if (!methodInfo.enabled) {
      AppLogger.warning(
        'Cannot select disabled method: ${methodInfo.disabledReason}',
      );
      return;
    }

    state = state.copyWith(selectedMethod: method);

    AppLogger.success('Payment method selected: ${method.toString()}');
    AppLogger.function('PaymentMethodNotifier.selectMethod', 'EXIT');
  }

  /// Check if a specific method is available
  bool isMethodAvailable(PaymentMethodType method) {
    try {
      final methodInfo = state.availableMethods.firstWhere(
        (m) => m.type == method,
      );
      return methodInfo.enabled;
    } catch (e) {
      return false;
    }
  }

  /// Get method information
  PaymentMethodInfo? getMethodInfo(PaymentMethodType method) {
    try {
      return state.availableMethods.firstWhere(
        (m) => m.type == method,
      );
    } catch (e) {
      return null;
    }
  }

  /// Reset to default method
  void reset() {
    AppLogger.info('Resetting payment method to cash');
    state = state.copyWith(selectedMethod: PaymentMethodType.cash);
  }
}

/// Payment method provider
final paymentMethodProvider =
    StateNotifierProvider<PaymentMethodNotifier, PaymentMethodState>((ref) {
  return PaymentMethodNotifier();
});
