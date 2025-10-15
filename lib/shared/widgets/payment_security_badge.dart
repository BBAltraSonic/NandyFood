import 'package:flutter/material.dart';

/// Payment security badge widget to display trust indicators
class PaymentSecurityBadge extends StatelessWidget {
  final bool showLogo;
  final bool compact;
  final SecurityBadgeVariant variant;

  const PaymentSecurityBadge({
    super.key,
    this.showLogo = true,
    this.compact = false,
    this.variant = SecurityBadgeVariant.full,
  });

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case SecurityBadgeVariant.full:
        return _buildFullBadge(context);
      case SecurityBadgeVariant.compact:
        return _buildCompactBadge(context);
      case SecurityBadgeVariant.mini:
        return _buildMiniBadge(context);
    }
  }

  Widget _buildFullBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, color: Colors.green.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Secured by PayFast',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showLogo) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'PayFast',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Security features
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSecurityFeature(
                context,
                Icons.verified_user,
                'SSL\nEncrypted',
              ),
              _buildSecurityFeature(
                context,
                Icons.security,
                'PCI\nCompliant',
              ),
              _buildSecurityFeature(
                context,
                Icons.check_circle,
                'Verified\nMerchant',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, color: Colors.green.shade700, size: 16),
          const SizedBox(width: 6),
          Text(
            'Secured by PayFast',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Icon(
        Icons.lock,
        color: Colors.green.shade700,
        size: 16,
      ),
    );
  }

  Widget _buildSecurityFeature(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(
          icon,
          color: Colors.green.shade700,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.green.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Security badge variants
enum SecurityBadgeVariant {
  full,
  compact,
  mini,
}
