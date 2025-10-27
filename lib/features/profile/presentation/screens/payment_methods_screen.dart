import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';

import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';

class PaymentMethodsScreen extends ConsumerWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsState = ref.watch(paymentMethodsProvider);
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);
    final userId = ref.watch(authStateProvider).user?.id;


    // Load payment methods when the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (paymentMethodsState.paymentMethods.isEmpty &&
          !paymentMethodsState.isLoading) {
        if (userId != null) {
          paymentMethodsNotifier.loadPaymentMethods(userId);
        }
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods'), centerTitle: true),
      body:
          paymentMethodsState.isLoading &&
              paymentMethodsState.paymentMethods.isEmpty
          ? const Center(child: LoadingIndicator())
          : paymentMethodsState.errorMessage != null
          ? ErrorMessageWidget(
              message: paymentMethodsState.errorMessage!,
              onRetry: () {
                if (userId != null) {
                  paymentMethodsNotifier.loadPaymentMethods(userId);
                }
              },
            )
          : _buildPaymentMethodsList(
              paymentMethodsState,
              paymentMethodsNotifier,
              context,
              userId,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/profile/add-payment');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentMethodsList(
    PaymentMethodsState state,
    PaymentMethodsNotifier notifier,
    BuildContext context,
    String? userId,
  ) {
    if (state.paymentMethods.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No payment methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'Add a payment method to get started',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => Future.sync(() => userId != null ? notifier.loadPaymentMethods(userId) : Future.value()),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.paymentMethods.length,
        itemBuilder: (context, index) {
          final method = state.paymentMethods[index];
          return _buildPaymentMethodCard(method, notifier, context, userId);
        },
      ),
    );
  }

  Widget _buildPaymentMethodCard(
    PaymentMethodInfo method,
    PaymentMethodsNotifier notifier,
    BuildContext context,
    String? userId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 32,
              decoration: BoxDecoration(
                color: _getBrandColor(method.brand),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _getBrandInitial(method.brand),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${method.brand} ending in ${method.last4}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires ${method.expiryMonth}/${method.expiryYear.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (method.isDefault)
                    const Text(
                      'Default',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (String value) async {
                if (value == 'set_default') {
                  if (userId != null) {
                    await notifier.setDefaultPaymentMethod(userId, method.id);
                  }
                } else if (value == 'remove') {
                  final confirmed = await _showDeleteConfirmationDialog(
                    context,
                    method,
                  );
                  if (confirmed) {
                    await notifier.removePaymentMethod(method.id);
                  }
                }
              },
              itemBuilder: (BuildContext context) => [
                if (!method.isDefault)
                  const PopupMenuItem<String>(
                    value: 'set_default',
                    child: Text('Set as default'),
                  ),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getBrandColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Colors.blue.shade700;
      case 'mastercard':
        return Colors.red.shade700;
      case 'amex':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getBrandInitial(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return 'V';
      case 'mastercard':
        return 'M';
      case 'amex':
        return 'A';
      default:
        return brand.substring(0, 1).toUpperCase();
    }
  }

  Future<bool> _showDeleteConfirmationDialog(
    BuildContext context,
    PaymentMethodInfo method,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Payment Method'),
          content: Text(
            'Are you sure you want to remove your ${method.brand} ending in ${method.last4}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }
}
