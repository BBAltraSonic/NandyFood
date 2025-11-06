import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Widget for displaying visual role indicators for restaurant users
class RestaurantRoleIndicator extends ConsumerWidget {
  final bool showFullInfo;
  final bool showAvatar;
  final bool showPermissions;
  final EdgeInsets? padding;

  const RestaurantRoleIndicator({
    super.key,
    this.showFullInfo = true,
    this.showAvatar = true,
    this.showPermissions = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(primaryRoleProvider);
    final staffData = ref.watch(staffDataProvider);
    final restaurantData = ref.watch(restaurantDataProvider);

    if (!_isRestaurantRole(userRole)) {
      return const SizedBox.shrink();
    }

    final roleInfo = _getRoleInfo(userRole ?? UserRoleType.consumer, null);

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: roleInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: roleInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showAvatar) ...[
                _buildRoleAvatar(roleInfo),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showFullInfo) ...[
                      Text(
                        roleInfo.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: roleInfo.color,
                            ),
                      ),
                      Text(
                        roleInfo.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ] else ...[
                      Text(
                        roleInfo.shortName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: roleInfo.color,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildRoleBadge(roleInfo),
            ],
          ),
          if (showPermissions && roleInfo.permissions.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPermissionsList(roleInfo.permissions),
          ],
          if (showFullInfo && restaurantData != null) ...[
            const SizedBox(height: 8),
            Text(
              restaurantData?['name']?.toString() ?? 'Restaurant',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.secondaryText,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleAvatar(RoleInfo roleInfo) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: roleInfo.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: roleInfo.color,
          width: 2,
        ),
      ),
      child: Icon(
        roleInfo.icon,
        color: roleInfo.color,
        size: 24,
      ),
    );
  }

  Widget _buildRoleBadge(RoleInfo roleInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: roleInfo.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleInfo.level,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPermissionsList(List<String> permissions) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: permissions.map((permission) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            permission,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  RoleInfo _getRoleInfo(UserRoleType role, RestaurantStaff? staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return RoleInfo(
          displayName: 'Restaurant Owner',
          shortName: 'Owner',
          description: 'Full access to all restaurant features',
          level: 'ADMIN',
          icon: Icons.store_rounded,
          color: Colors.deepPurple,
          permissions: [
            'Manage Restaurant',
            'Manage Staff',
            'View Analytics',
            'Manage Menu',
            'Process Orders',
            'Financial Reports',
          ],
        );
      case UserRoleType.restaurantStaff:
        return _getStaffRoleInfo(staffData);
      default:
        return RoleInfo(
          displayName: 'Unknown Role',
          shortName: 'Unknown',
          description: 'Role not recognized',
          level: 'UNKNOWN',
          icon: Icons.help_outline,
          color: Colors.grey,
          permissions: [],
        );
    }
  }

  RoleInfo _getStaffRoleInfo(RestaurantStaff? staffData) {
    final staffRole = staffData?.role?.name.toLowerCase();

    switch (staffRole) {
      case 'manager':
        return RoleInfo(
          displayName: 'Restaurant Manager',
          shortName: 'Manager',
          description: 'Can manage most restaurant operations',
          level: 'MANAGER',
          icon: Icons.admin_panel_settings,
          color: Colors.indigo,
          permissions: [
            'Manage Orders',
            'Manage Menu',
            'View Analytics',
            'Manage Basic Staff',
            'Customer Service',
          ],
        );

      case 'chef':
        return RoleInfo(
          displayName: 'Chef',
          shortName: 'Chef',
          description: 'Kitchen operations and menu management',
          level: 'KITCHEN',
          icon: Icons.restaurant_rounded,
          color: Colors.orange,
          permissions: [
            'Manage Kitchen Orders',
            'View Menu Items',
            'Update Prep Times',
            'Inventory Management',
          ],
        );

      case 'cashier':
        return RoleInfo(
          displayName: 'Cashier',
          shortName: 'Cashier',
          description: 'Order processing and payment handling',
          level: 'FRONT_DESK',
          icon: Icons.point_of_sale_rounded,
          color: Colors.green,
          permissions: [
            'Process Orders',
            'Handle Payments',
            'Customer Service',
            'Basic Reports',
          ],
        );

      case 'server':
        return RoleInfo(
          displayName: 'Server',
          shortName: 'Server',
          description: 'Customer service and order management',
          level: 'SERVICE',
          icon: Icons.room_service_rounded,
          color: Colors.blue,
          permissions: [
            'Manage Customer Orders',
            'View Menu',
            'Customer Service',
          ],
        );

      case 'delivery_coordinator':
        return RoleInfo(
          displayName: 'Delivery Coordinator',
          shortName: 'Coordinator',
          description: 'Manages delivery operations',
          level: 'LOGISTICS',
          icon: Icons.delivery_dining,
          color: Colors.purple,
          permissions: [
            'Manage Deliveries',
            'Track Orders',
            'Driver Management',
          ],
        );

      case 'basic_staff':
      default:
        return RoleInfo(
          displayName: 'Staff Member',
          shortName: 'Staff',
          description: 'Basic restaurant operations',
          level: 'STAFF',
          icon: Icons.people_rounded,
          color: Colors.teal,
          permissions: [
            'View Orders',
            'Basic Operations',
          ],
        );
    }
  }
}

/// Model for role information
class RoleInfo {
  final String displayName;
  final String shortName;
  final String description;
  final String level;
  final IconData icon;
  final Color color;
  final List<String> permissions;

  const RoleInfo({
    required this.displayName,
    required this.shortName,
    required this.description,
    required this.level,
    required this.icon,
    required this.color,
    required this.permissions,
  });
}

/// Compact role indicator for use in headers and tight spaces
class CompactRoleIndicator extends ConsumerWidget {
  final bool showLabel;

  const CompactRoleIndicator({
    super.key,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(primaryRoleProvider);
    final staffData = ref.watch(staffDataProvider);

    if (!_isRestaurantRole(userRole)) {
      return const SizedBox.shrink();
    }

    final roleInfo = _getRoleInfo(userRole ?? UserRoleType.consumer, null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: roleInfo.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            roleInfo.icon,
            color: roleInfo.color,
            size: 16,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            roleInfo.shortName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: roleInfo.color,
            ),
          ),
        ],
      ],
    );
  }

  RoleInfo _getRoleInfo(UserRoleType role, RestaurantStaff? staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return const RoleInfo(
          displayName: 'Restaurant Owner',
          shortName: 'Owner',
          description: 'Full access to all restaurant features',
          level: 'ADMIN',
          icon: Icons.store_rounded,
          color: Colors.deepPurple,
          permissions: [],
        );
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.name.toLowerCase();
        return RoleInfo(
          displayName: staffData?.role?.name ?? 'Staff',
          shortName: staffData?.role?.name.toUpperCase() ?? 'STAFF',
          description: 'Restaurant staff member',
          level: 'STAFF',
          icon: _getStaffIcon(staffRole),
          color: _getStaffColor(staffRole),
          permissions: [],
        );
      default:
        return const RoleInfo(
          displayName: 'Unknown Role',
          shortName: 'Unknown',
          description: 'Role not recognized',
          level: 'UNKNOWN',
          icon: Icons.help_outline,
          color: Colors.grey,
          permissions: [],
        );
    }
  }

  IconData _getStaffIcon(String? staffRole) {
    switch (staffRole) {
      case 'manager':
        return Icons.admin_panel_settings;
      case 'chef':
        return Icons.restaurant_rounded;
      case 'cashier':
        return Icons.point_of_sale_rounded;
      case 'server':
        return Icons.room_service_rounded;
      case 'delivery_coordinator':
        return Icons.delivery_dining;
      default:
        return Icons.people_rounded;
    }
  }

  Color _getStaffColor(String? staffRole) {
    switch (staffRole) {
      case 'manager':
        return Colors.indigo;
      case 'chef':
        return Colors.orange;
      case 'cashier':
        return Colors.green;
      case 'server':
        return Colors.blue;
      case 'delivery_coordinator':
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}

/// Permission-based widget that shows/hides content based on user permissions
class PermissionWidget extends ConsumerWidget {
  final List<String> requiredPermissions;
  final Widget child;
  final Widget? fallback;
  final UserRoleType? requiredRole;

  const PermissionWidget({
    super.key,
    required this.requiredPermissions,
    required this.child,
    this.fallback,
    this.requiredRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(primaryRoleProvider);
    final staffData = ref.watch(staffDataProvider);

    // Check if user has required role
    if (requiredRole != null && userRole != requiredRole) {
      return fallback ?? const SizedBox.shrink();
    }

    // Check if user has required permissions
    if (requiredPermissions.isNotEmpty) {
      final userPermissions = _getUserPermissions(userRole ?? UserRoleType.consumer, null);
      final hasPermission = requiredPermissions
          .any((permission) => userPermissions.contains(permission));

      if (!hasPermission) {
        return fallback ?? const SizedBox.shrink();
      }
    }

    return child;
  }

  List<String> _getUserPermissions(UserRoleType role, RestaurantStaff? staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return [
          'manage_restaurant',
          'manage_staff',
          'view_analytics',
          'manage_menu',
          'process_orders',
          'financial_reports',
          'manage_settings',
          'manage_promotions',
        ];
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.name.toLowerCase();
        switch (staffRole) {
          case 'manager':
            return [
              'manage_orders',
              'manage_menu',
              'view_analytics',
              'manage_basic_staff',
              'customer_service',
            ];
          case 'chef':
            return [
              'manage_kitchen_orders',
              'view_menu_items',
              'update_prep_times',
              'inventory_management',
            ];
          case 'cashier':
            return [
              'process_orders',
              'handle_payments',
              'customer_service',
              'basic_reports',
            ];
          case 'server':
            return [
              'manage_customer_orders',
              'view_menu',
              'customer_service',
            ];
          case 'delivery_coordinator':
            return [
              'manage_deliveries',
              'track_orders',
              'driver_management',
            ];
          default:
            return ['view_orders', 'basic_operations'];
        }
      default:
        return [];
    }
  }

  }

/// Helper function to check if a role is a restaurant-related role
bool _isRestaurantRole(UserRoleType? role) {
  if (role == null) return false;
  return role == UserRoleType.restaurantOwner || role == UserRoleType.restaurantStaff;
}