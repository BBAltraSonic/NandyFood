import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

class PaymentMethodSelectorWidget extends ConsumerWidget {
  final Function(String paymentMethodId)? onPaymentMethodSelected;
  final String? initialPaymentMethodId;

  const PaymentMethodSelectorWidget({
    Key? key,
    this.onPaymentMethodSelected,
    this.initialPaymentMethodId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsState = ref.watch(paymentMethodsProvider);
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);

    // Set initial selected payment method
    if (paymentMethodsState.selectedPaymentMethod == null && 
        paymentMethodsState.paymentMethods.isNotEmpty) {
      final initialMethod = initialPaymentMethodId != null
          ? paymentMethodsState.paymentMethods.firstWhere(
              (method) => method.id == initialPaymentMethodId,
              orElse: () => paymentMethodsState.paymentMethods.first,
            )
          : paymentMethodsState.paymentMethods.firstWhere(
              (method) => method.isDefault,
              orElse: () => paymentMethodsState.paymentMethods.first,
            );
      paymentMethodsNotifier.selectPaymentMethod(initialMethod.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (paymentMethodsState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (paymentMethodsState.errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Error: ${paymentMethodsState.errorMessage}',
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (paymentMethodsState.paymentMethods.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No payment methods available'),
          )
        else
          ...paymentMethodsState.paymentMethods.map(
            (method) => RadioListTile<String>(
              title: Text('${method.brand} ending in ${method.last4}'),
              subtitle: Text('${method.expiryMonth}/${method.expiryYear}'),
              value: method.id,
              groupValue: paymentMethodsState.selectedPaymentMethod?.id,
              onChanged: (value) {
                if (value != null) {
                  paymentMethodsNotifier.selectPaymentMethod(value);
                  
                  // Update the cart's selected payment method
                  ref.read(cartProvider.notifier).updateSelectedPaymentMethod(value);
                  
                  if (onPaymentMethodSelected != null) {
                    onPaymentMethodSelected!(value);
                  }
                }
              },
              secondary: method.isDefault
                  ? const Icon(
                      Icons.star,
                      color: Colors.amber,
                    )
                  : null,
            ),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () {
              // Navigate to add payment method screen
              Navigator.of(context).pushNamed('/profile/add-payment');
            },
            child: const Text('Add Payment Method'),
          ),
        ),
      ],
    );
  }
}