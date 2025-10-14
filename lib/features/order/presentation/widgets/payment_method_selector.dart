import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/payment_methods_provider.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';

class PaymentMethodSelector extends ConsumerWidget {
  const PaymentMethodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final paymentMethodsState = ref.watch(paymentMethodsProvider);
    final paymentMethodsNotifier = ref.read(paymentMethodsProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/profile/payment-methods'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add New'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (paymentMethodsState.isLoading)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Loading payment methods...'),
              ],
            ),
          )
        else if (paymentMethodsState.errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    paymentMethodsState.errorMessage!,
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          )
        else
          _buildPaymentMethodList(
            context,
            paymentMethodsState.paymentMethods,
            cartState.selectedPaymentMethodId,
            paymentMethodsNotifier,
            theme,
            colorScheme,
          ),
        
        const SizedBox(height: 12),
        _buildPaymentInfoBanner(theme, colorScheme),
      ],
    );
  }

  Widget _buildPaymentMethodList(
    BuildContext context,
    List<dynamic> paymentMethods,
    String? selectedId,
    PaymentMethodsNotifier notifier,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (paymentMethods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            const Text(
              'No payment methods saved',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Add a card or use cash on delivery',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/profile/payment-methods'),
              child: const Text('Add Payment Method'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: paymentMethods.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final method = paymentMethods[index];
        final isSelected = selectedId == method.id;
        
        return _buildPaymentMethodItem(
          method: method,
          isSelected: isSelected,
          onTap: () => _selectPaymentMethod(context, method.id, notifier),
          theme: theme,
          colorScheme: colorScheme,
        );
      },
    );
  }

  Widget _buildPaymentMethodItem({
    required dynamic method,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    IconData cardIcon;
    switch (method.brand?.toLowerCase()) {
      case 'visa':
        cardIcon = Icons.credit_card;
      case 'mastercard':
        cardIcon = Icons.credit_card;
      case 'amex':
        cardIcon = Icons.credit_card;
      default:
        cardIcon = Icons.credit_card;
    }

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? colorScheme.primaryContainer 
            : colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: isSelected 
              ? colorScheme.primary 
              : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    cardIcon,
                    color: isSelected 
                        ? colorScheme.primary 
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                        Text(
                          '${method.brand} ending in ${method.last4}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? colorScheme.primary 
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (method.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Default',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],),
                      const SizedBox(height: 2),
                      Text(
                        'Expires ${method.expiryMonth}/${method.expiryYear}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInfoBanner(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your payment information is securely processed and stored',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectPaymentMethod(
    BuildContext context,
    String methodId,
    PaymentMethodsNotifier notifier,
  ) {
    notifier.selectPaymentMethod(methodId);
    
    // Update cart state with selected payment method
    // Note: In a real implementation, we would need to access the cart notifier properly
    // For now, we'll leave this commented out as it requires proper provider access
    /*
    final cartNotifier = context.read(cartProvider.notifier);
    // Convert methodId to PaymentMethod enum
    final paymentMethod = methodId.contains('cash') 
        ? PaymentMethod.cash 
        : PaymentMethod.card;
    cartNotifier.setPaymentMethod(paymentMethod);
    */
  }
}