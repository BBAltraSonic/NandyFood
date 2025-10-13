import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

class RoleSelectorWidget extends ConsumerWidget {
  const RoleSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    if (!authState.hasMultipleRoles) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...authState.allRoles.map((role) {
            final isActive = role.isPrimary;
            return _RoleItem(
              role: role,
              isActive: isActive,
              onTap: () => _switchRole(context, ref, role),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
  ) async {
    if (role.isPrimary) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await ref.read(authStateProvider.notifier).switchRole(role.role);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        // Navigate to appropriate screen
        if (role.isRestaurantOwner) {
          context.go('/restaurant/dashboard');
        } else {
          context.go('/home');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _RoleItem extends StatelessWidget {
  final UserRole role;
  final bool isActive;
  final VoidCallback onTap;

  const _RoleItem({
    required this.role,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isActive ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _getRoleIcon(context, role.role),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.roleDisplayName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                    Text(
                      _getRoleDescription(role.role),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isActive)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getRoleIcon(BuildContext context, UserRoleType roleType) {
    IconData iconData;
    Color color;

    switch (roleType) {
      case UserRoleType.consumer:
        iconData = Icons.shopping_bag_rounded;
        color = Colors.blue;
        break;
      case UserRoleType.restaurantOwner:
        iconData = Icons.store_rounded;
        color = Colors.orange;
        break;
      case UserRoleType.restaurantStaff:
        iconData = Icons.badge_rounded;
        color = Colors.purple;
        break;
      case UserRoleType.admin:
        iconData = Icons.admin_panel_settings_rounded;
        color = Colors.red;
        break;
      case UserRoleType.deliveryDriver:
        iconData = Icons.delivery_dining_rounded;
        color = Colors.green;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  String _getRoleDescription(UserRoleType roleType) {
    switch (roleType) {
      case UserRoleType.consumer:
        return 'Browse and order food';
      case UserRoleType.restaurantOwner:
        return 'Manage your restaurant';
      case UserRoleType.restaurantStaff:
        return 'Process orders';
      case UserRoleType.admin:
        return 'System administration';
      case UserRoleType.deliveryDriver:
        return 'Deliver orders';
    }
  }
}
