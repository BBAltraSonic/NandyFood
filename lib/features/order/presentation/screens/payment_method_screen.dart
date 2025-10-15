import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_method_provider.dart';
import 'package:food_delivery_app/features/order/presentation/widgets/payment_method_card.dart';
import 'package:food_delivery_app/shared/widgets/payment_security_badge.dart';

/// Screen for selecting payment method
class PaymentMethodScreen extends ConsumerWidget {
  final String orderId;
  final double amount;

  const PaymentMethodScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final methodState = ref.watch(paymentMethodProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Payment Method'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment methods list
          Expanded(
            child: methodState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Security badge
                      const PaymentSecurityBadge(
                        variant: SecurityBadgeVariant.compact,
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Choose how you want to pay',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Payment method cards
                      ...methodState.availableMethods.map((method) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PaymentMethodCard(
                            method: method,
                            isSelected:
                                method.type == methodState.selectedMethod,
                            onTap: () {
                              ref
                                  .read(paymentMethodProvider.notifier)
                                  .selectMethod(method.type);
                            },
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Information card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your payment information is secure and encrypted',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Bottom section with amount and continue button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Amount display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'R ${amount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: methodState.selectedMethodInfo?.enabled ?? false
                          ? () => _handleContinue(context, ref)
                          : null,
                      child: Text(
                        methodState.selectedMethodInfo?.enabled ?? false
                            ? 'Continue to Payment'
                            : 'Select a Payment Method',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleContinue(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.read(paymentMethodProvider).selectedMethod;

    // Return selected method to checkout screen
    Navigator.pop(context, selectedMethod);
  }
}
