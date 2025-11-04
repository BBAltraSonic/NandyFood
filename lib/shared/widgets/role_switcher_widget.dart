import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Widget for switching between user roles
class RoleSwitcherWidget extends ConsumerWidget {
  final bool isCompact;
  final Function(String?)? onRoleChanged;

  const RoleSwitcherWidget({
    super.key,
    this.isCompact = false,
    this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Don't show role switcher if user has only one role or no roles
    if (!authState.hasMultipleRoles || !authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return isCompact ? _buildCompactSwitcher(context, ref, authState)
                         : _buildFullSwitcher(context, ref, authState);
  }

  Widget _buildFullSwitcher(BuildContext context, WidgetRef ref, AuthState authState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.swap_horiz,
                color: BrandColors.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Switch Role',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (authState.isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...authState.allRoles.map((role) => _buildRoleOption(
            context,
            ref,
            role,
            role == authState.primaryRole,
            authState.isLoading,
          )),
        ],
      ),
    );
  }

  Widget _buildCompactSwitcher(BuildContext context, WidgetRef ref, AuthState authState) {
    return PopupMenuButton<String>(
      tooltip: 'Switch Role',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_outline,
            color: Theme.of(context).iconTheme.color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(_getRoleDisplayName(authState.primaryRole!)),
        ],
      ),
      itemBuilder: (context) => authState.allRoles.map((role) {
        final isSelected = role == authState.primaryRole;
        return PopupMenuItem<String>(
          value: role.id,
          child: Row(
            children: [
              Icon(
                _getRoleIcon(role.role),
                color: isSelected ? BrandColors.accent : null,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                _getRoleDisplayName(role),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : null,
                  color: isSelected ? BrandColors.accent : null,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(
                  Icons.check,
                  color: BrandColors.accent,
                  size: 18,
                ),
            ],
          ),
        );
      }).toList(),
      onSelected: (value) {
        if (!authState.isLoading) {
          _switchRole(context, ref, value);
        }
      },
    );
  }

  Widget _buildRoleOption(
    BuildContext context,
    WidgetRef ref,
    UserRole role,
    bool isSelected,
    bool isLoading,
  ) {
    final isDisabled = isLoading;

    return InkWell(
      onTap: isDisabled ? null : () => _switchRole(context, ref, role.id),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? BrandColors.accent.withValues(alpha: 0.1)
              : isDisabled
                  ? NeutralColors.gray100
                  : NeutralColors.gray50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? BrandColors.accent
                : NeutralColors.gray200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? BrandColors.accent
                    : isDisabled
                        ? NeutralColors.gray300
                        : _getRoleColor(role.role).withValues(alpha: 0.8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRoleIcon(role.role),
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? BrandColors.accent
                          : isDisabled
                              ? NeutralColors.textSecondary
                              : NeutralColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRoleDescription(role.role),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? BrandColors.accent.withValues(alpha: 0.8)
                          : isDisabled
                              ? NeutralColors.textTertiary
                              : NeutralColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isDisabled)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? BrandColors.accent : NeutralColors.gray400,
              ),
          ],
        ),
      ),
    );
  }

  IconData _getRoleIcon(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Icons.person;
      case UserRoleType.restaurantOwner:
        return Icons.store;
      case UserRoleType.restaurantStaff:
        return Icons.work;
      case UserRoleType.admin:
        return Icons.admin_panel_settings;
      case UserRoleType.deliveryDriver:
        return Icons.delivery_dining;
    }
  }

  Color _getRoleColor(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Colors.black87;      // Dark gray (was blue)
      case UserRoleType.restaurantOwner:
        return Colors.black54;      // Medium gray (was green)
      case UserRoleType.restaurantStaff:
        return Colors.black38;      // Lighter gray (was orange)
      case UserRoleType.admin:
        return Colors.black;        // Pure black (was purple)
      case UserRoleType.deliveryDriver:
        return Colors.black26;      // Light gray (was red)
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role.role) {
      case UserRoleType.consumer:
        return 'Customer';
      case UserRoleType.restaurantOwner:
        return 'Restaurant Owner';
      case UserRoleType.restaurantStaff:
        return 'Restaurant Staff';
      case UserRoleType.admin:
        return 'Administrator';
      case UserRoleType.deliveryDriver:
        return 'Delivery Driver';
    }
  }

  
  String _getRoleDescription(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return 'Browse restaurants and place orders';
      case UserRoleType.restaurantOwner:
        return 'Manage restaurant and orders';
      case UserRoleType.restaurantStaff:
        return 'Process orders and manage menu';
      case UserRoleType.admin:
        return 'System administration and oversight';
      case UserRoleType.deliveryDriver:
        return 'Deliver orders to customers';
    }
  }

  Future<void> _switchRole(BuildContext context, WidgetRef ref, String roleId) async {
    try {
      final authState = ref.read(authStateProvider);

      // Switch role using the role service
      final userId = authState.user?.id;
      if (userId != null) {
        final role = authState.allRoles.firstWhere((r) => r.id == roleId);
        final roleService = RoleService();
        await roleService.switchPrimaryRole(userId, role.role);
      }

      // Refresh auth state to reflect the change
      await ref.read(authStateProvider.notifier).refreshRoles();

      // Notify callback if provided
      onRoleChanged?.call(roleId);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Role switched successfully'),
            backgroundColor: Colors.black87,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to appropriate dashboard for new role
        _navigateToRoleDashboard(context, ref);
      }
    } catch (e) {
      AppLogger.error('Failed to switch role', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: $e'),
            backgroundColor: Colors.black54,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _switchRole(context, ref, roleId),
            ),
          ),
        );
      }
    }
  }

  void _navigateToRoleDashboard(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    final primaryRole = authState.primaryRole?.role;

    switch (primaryRole) {
      case UserRoleType.restaurantOwner:
      case UserRoleType.restaurantStaff:
        context.go('/restaurant/dashboard');
        break;
      case UserRoleType.admin:
        context.go('/admin/dashboard');
        break;
      case UserRoleType.consumer:
      case UserRoleType.deliveryDriver:
        context.go('/home');
        break;
      default:
        context.go('/home');
        break;
    }
  }
}

/// Floating action button for role switching (compact version)
class RoleSwitcherFAB extends ConsumerWidget {
  const RoleSwitcherFAB({super.key});

  // Helper methods for RoleSwitcherFAB
  IconData _getRoleIcon(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Icons.person;
      case UserRoleType.restaurantOwner:
        return Icons.store;
      case UserRoleType.restaurantStaff:
        return Icons.work;
      case UserRoleType.admin:
        return Icons.admin_panel_settings;
      case UserRoleType.deliveryDriver:
        return Icons.delivery_dining;
    }
  }

  Color _getRoleColor(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Colors.black87;      // Dark gray (was blue)
      case UserRoleType.restaurantOwner:
        return Colors.black54;      // Medium gray (was green)
      case UserRoleType.restaurantStaff:
        return Colors.black38;      // Lighter gray (was orange)
      case UserRoleType.admin:
        return Colors.black;        // Pure black (was purple)
      case UserRoleType.deliveryDriver:
        return Colors.black26;      // Light gray (was red)
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role.role) {
      case UserRoleType.consumer:
        return 'Customer';
      case UserRoleType.restaurantOwner:
        return 'Restaurant Owner';
      case UserRoleType.restaurantStaff:
        return 'Restaurant Staff';
      case UserRoleType.admin:
        return 'Administrator';
      case UserRoleType.deliveryDriver:
        return 'Delivery Driver';
    }
  }

  String _getRoleDescription(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return 'Browse restaurants and place orders';
      case UserRoleType.restaurantOwner:
        return 'Manage restaurant and orders';
      case UserRoleType.restaurantStaff:
        return 'Process orders and manage menu';
      case UserRoleType.admin:
        return 'System administration and oversight';
      case UserRoleType.deliveryDriver:
        return 'Deliver orders to customers';
    }
  }

  Future<void> _switchRole(BuildContext context, WidgetRef ref, String roleId) async {
    try {
      final authState = ref.read(authStateProvider);

      // Switch role using the role service
      final userId = authState.user?.id;
      if (userId != null) {
        final role = authState.allRoles.firstWhere((r) => r.id == roleId);
        final roleService = RoleService();
        await roleService.switchPrimaryRole(userId, role.role);
      }

      // Refresh auth state to reflect the change
      await ref.read(authStateProvider.notifier).refreshRoles();

      // Navigate to appropriate dashboard for new role
      _navigateToRoleDashboard(context, ref);
    } catch (e) {
      AppLogger.error('Failed to switch role', error: e);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: $e'),
            backgroundColor: Colors.black54,
          ),
        );
      }
    }
  }

  void _navigateToRoleDashboard(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authStateProvider);
    final primaryRole = authState.primaryRole?.role;

    switch (primaryRole) {
      case UserRoleType.restaurantOwner:
      case UserRoleType.restaurantStaff:
        context.go('/restaurant/dashboard');
        break;
      case UserRoleType.admin:
        context.go('/admin/dashboard');
        break;
      case UserRoleType.consumer:
      case UserRoleType.deliveryDriver:
        context.go('/home');
        break;
      default:
        context.go('/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Don't show FAB if user has only one role or no roles
    if (!authState.hasMultipleRoles || !authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton.extended(
      onPressed: () => _showRoleSwitcherDialog(context, ref, authState),
      icon: const Icon(Icons.swap_horiz),
      label: Text('Switch to ${_getNextRoleName(authState)}'),
      backgroundColor: BrandColors.accent,
      foregroundColor: Colors.white,
    );
  }

  void _showRoleSwitcherDialog(BuildContext context, WidgetRef ref, AuthState authState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Role'),
        content: const Text('Select which role you want to switch to:'),
        contentPadding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        actions: [
          ...authState.allRoles.map((role) {
            final isSelected = role == authState.primaryRole;
            return ListTile(
              leading: Icon(
                _getRoleIcon(role.role),
                color: isSelected ? BrandColors.accent : _getRoleColor(role.role),
              ),
              title: Text(_getRoleDisplayName(role)),
              subtitle: Text(_getRoleDescription(role.role)),
              trailing: isSelected
                  ? const Icon(Icons.check, color: BrandColors.accent)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _switchRole(context, ref, role.id);
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getNextRoleName(AuthState authState) {
    if (authState.allRoles.length <= 1) return '';

    final currentIndex = authState.allRoles.indexOf(authState.primaryRole!);
    final nextIndex = (currentIndex + 1) % authState.allRoles.length;
    return _getRoleDisplayName(authState.allRoles[nextIndex]);
  }
}

/// Role information widget for displaying current role context
class RoleInfoWidget extends ConsumerWidget {
  final bool showIcon;
  final bool showDescription;

  const RoleInfoWidget({
    super.key,
    this.showIcon = true,
    this.showDescription = true,
  });

  // Helper methods for RoleInfoWidget
  IconData _getRoleIcon(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Icons.person;
      case UserRoleType.restaurantOwner:
        return Icons.store;
      case UserRoleType.restaurantStaff:
        return Icons.work;
      case UserRoleType.admin:
        return Icons.admin_panel_settings;
      case UserRoleType.deliveryDriver:
        return Icons.delivery_dining;
    }
  }

  Color _getRoleColor(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return Colors.black87;      // Dark gray (was blue)
      case UserRoleType.restaurantOwner:
        return Colors.black54;      // Medium gray (was green)
      case UserRoleType.restaurantStaff:
        return Colors.black38;      // Lighter gray (was orange)
      case UserRoleType.admin:
        return Colors.black;        // Pure black (was purple)
      case UserRoleType.deliveryDriver:
        return Colors.black26;      // Light gray (was red)
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role.role) {
      case UserRoleType.consumer:
        return 'Customer';
      case UserRoleType.restaurantOwner:
        return 'Restaurant Owner';
      case UserRoleType.restaurantStaff:
        return 'Restaurant Staff';
      case UserRoleType.admin:
        return 'Administrator';
      case UserRoleType.deliveryDriver:
        return 'Delivery Driver';
    }
  }

  String _getRoleDescription(UserRoleType role) {
    switch (role) {
      case UserRoleType.consumer:
        return 'Browse restaurants and place orders';
      case UserRoleType.restaurantOwner:
        return 'Manage restaurant and orders';
      case UserRoleType.restaurantStaff:
        return 'Process orders and manage menu';
      case UserRoleType.admin:
        return 'System administration and oversight';
      case UserRoleType.deliveryDriver:
        return 'Deliver orders to customers';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    if (!authState.isAuthenticated || authState.primaryRole == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: showDescription ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: _getRoleColor(authState.primaryRole!.role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getRoleColor(authState.primaryRole!.role).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _getRoleIcon(authState.primaryRole!.role),
              color: _getRoleColor(authState.primaryRole!.role),
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getRoleDisplayName(authState.primaryRole!),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getRoleColor(authState.primaryRole!.role),
                ),
              ),
              if (showDescription) ...[
                const SizedBox(height: 2),
                Text(
                  _getRoleDescription(authState.primaryRole!.role),
                  style: TextStyle(
                    fontSize: 10,
                    color: _getRoleColor(authState.primaryRole!.role).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ],
          ),
          if (authState.hasMultipleRoles) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: _getRoleColor(authState.primaryRole!.role),
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}