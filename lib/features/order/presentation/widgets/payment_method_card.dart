import 'package:flutter/material.dart';
import 'package:food_delivery_app/features/order/presentation/providers/payment_method_provider.dart';

/// Reusable card widget for displaying payment method option
class PaymentMethodCard extends StatelessWidget {
  final PaymentMethodInfo method;
  final bool isSelected;
  final VoidCallback? onTap;

  const PaymentMethodCard({
    super.key,
    required this.method,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : method.enabled
                  ? Colors.grey.shade300
                  : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: method.enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: method.enabled
                          ? colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      method.icon,
                      size: 32,
                      color: method.enabled
                          ? colorScheme.primary
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                method.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: method.enabled
                                      ? colorScheme.onSurface
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                            if (method.recommended && method.enabled)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                                child: Text(
                                  'RECOMMENDED',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          method.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: method.enabled
                                ? colorScheme.onSurfaceVariant
                                : Colors.grey.shade500,
                          ),
                        ),

                        // Disabled reason
                        if (!method.enabled && method.disabledReason != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    method.disabledReason!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Radio button
                  Radio<bool>(
                    value: true,
                    groupValue: isSelected,
                    onChanged: method.enabled
                        ? (value) {
                            if (onTap != null) onTap!();
                          }
                        : null,
                  ),
                ],
              ),
            ),

            // Disabled overlay
            if (!method.enabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
