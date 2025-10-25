import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

enum StatusType {
  cooking,
  ready,
  delivering,
  delivered,
  cancelled,
  pending,
  confirmed,
}

class StatusBadgeWidget extends StatelessWidget {
  final StatusType status;
  final String? customLabel;
  final bool small;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.customLabel,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.icon != null) ...[
            Icon(
              config.icon,
              size: small ? 12 : 14,
              color: config.textColor,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            customLabel ?? config.label,
            style: TextStyle(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.w600,
              color: config.textColor,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(StatusType status) {
    switch (status) {
      case StatusType.cooking:
        return _StatusConfig(
          label: 'Cooking',
          backgroundColor: const Color(0xFFFDE68A),
          textColor: const Color(0xFF92400E),
          icon: Icons.restaurant,
        );
      case StatusType.ready:
        return _StatusConfig(
          label: 'Ready',
          backgroundColor: AppTheme.mutedGreen.withOpacity(0.2),
          textColor: const Color(0xFF065F46),
          icon: Icons.check_circle,
        );
      case StatusType.delivering:
        return _StatusConfig(
          label: 'Delivering',
          backgroundColor: const Color(0xFFBFDBFE),
          textColor: const Color(0xFF1E40AF),
          icon: Icons.delivery_dining,
        );
      case StatusType.delivered:
        return _StatusConfig(
          label: 'Delivered',
          backgroundColor: AppTheme.mutedGreen,
          textColor: Colors.white,
          icon: Icons.check_circle_outline,
        );
      case StatusType.cancelled:
        return _StatusConfig(
          label: 'Cancelled',
          backgroundColor: const Color(0xFFFECDD3),
          textColor: const Color(0xFF991B1B),
          icon: Icons.cancel_outlined,
        );
      case StatusType.pending:
        return _StatusConfig(
          label: 'Pending',
          backgroundColor: const Color(0xFFE5E7EB),
          textColor: const Color(0xFF374151),
          icon: Icons.access_time,
        );
      case StatusType.confirmed:
        return _StatusConfig(
          label: 'Confirmed',
          backgroundColor: AppTheme.oliveGreen,
          textColor: Colors.white,
          icon: Icons.check,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  _StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}
