import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

enum RoleGuardType {
  any, // Any authenticated user
  consumer,
  restaurantOwner,
  restaurantStaff,
  admin,
  deliveryDriver,
  // Multiple roles
  restaurantAccess, // Owner or Staff
  staffAccess, // Staff, Admin, or Owner
}

class RoleGuard extends ConsumerWidget {
  final Widget child;
  final RoleGuardType requiredRole;
  final Widget? fallback;
  final String? redirectTo;
  final bool checkVerification;

  const RoleGuard({
    Key? key,
    required this.child,
    required this.requiredRole,
    this.fallback,
    this.redirectTo,
    this.checkVerification = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    // Check if user is authenticated
    if (user == null) {
      AppLogger.warning('RoleGuard: User not authenticated');
      return _buildUnauthorized(context, ref);
    }

    // Use FutureBuilder to check role asynchronously
    return FutureBuilder<bool>(
      future: _checkUserRole(user.id, requiredRole, checkVerification),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.data!) {
          AppLogger.warning('RoleGuard: User does not have required role: $requiredRole');
          return _buildUnauthorized(context, ref);
        }

        AppLogger.info('RoleGuard: User has required role: $requiredRole');
        return child;
      },
    );
  }

  Widget _buildUnauthorized(BuildContext context, WidgetRef ref) {
    if (fallback != null) {
      return fallback!;
    }

    if (redirectTo != null) {
      // Redirect using GoRouter
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go(redirectTo!);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Default unauthorized screen
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access Denied'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _getDeniedMessage(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDeniedMessage() {
    switch (requiredRole) {
      case RoleGuardType.consumer:
        return 'You need to be logged in as a customer to access this feature.';
      case RoleGuardType.restaurantOwner:
        return 'You need to be a restaurant owner to access this feature.';
      case RoleGuardType.restaurantStaff:
        return 'You need to be restaurant staff to access this feature.';
      case RoleGuardType.admin:
        return 'You need administrator privileges to access this feature.';
      case RoleGuardType.deliveryDriver:
        return 'You need to be a delivery driver to access this feature.';
      case RoleGuardType.restaurantAccess:
        return 'You need restaurant access privileges to view this page.';
      case RoleGuardType.staffAccess:
        return 'You need staff privileges to access this feature.';
      case RoleGuardType.any:
        return 'You need to be logged in to access this feature.';
    }
  }

  Future<bool> _checkUserRole(
    String userId,
    RoleGuardType requiredRole,
    bool checkVerification,
  ) async {
    try {
      final roleService = RoleService();

      switch (requiredRole) {
        case RoleGuardType.any:
          return true; // Already authenticated above

        case RoleGuardType.consumer:
          final role = await roleService.getPrimaryRole(userId);
          return role?.role == UserRoleType.consumer;

        case RoleGuardType.restaurantOwner:
          final role = await roleService.getPrimaryRole(userId);
          if (role?.role != UserRoleType.restaurantOwner) return false;

          if (checkVerification) {
            final restaurants = await roleService.getUserRestaurants(userId);
            return restaurants.isNotEmpty;
          }
          return true;

        case RoleGuardType.restaurantStaff:
          final role = await roleService.getPrimaryRole(userId);
          return role?.role == UserRoleType.restaurantStaff;

        case RoleGuardType.admin:
          final role = await roleService.getPrimaryRole(userId);
          return role?.role == UserRoleType.admin;

        case RoleGuardType.deliveryDriver:
          final role = await roleService.getPrimaryRole(userId);
          return role?.role == UserRoleType.deliveryDriver;

        case RoleGuardType.restaurantAccess:
          final hasOwnerRole = await roleService.hasRole(userId, UserRoleType.restaurantOwner);
          final hasStaffRole = await roleService.hasRole(userId, UserRoleType.restaurantStaff);

          if (checkVerification && hasOwnerRole) {
            final restaurants = await roleService.getUserRestaurants(userId);
            return restaurants.isNotEmpty || hasStaffRole;
          }
          return hasOwnerRole || hasStaffRole;

        case RoleGuardType.staffAccess:
          final hasOwnerRole = await roleService.hasRole(userId, UserRoleType.restaurantOwner);
          final hasStaffRole = await roleService.hasRole(userId, UserRoleType.restaurantStaff);
          final hasAdminRole = await roleService.hasRole(userId, UserRoleType.admin);

          if (checkVerification && hasOwnerRole) {
            final restaurants = await roleService.getUserRestaurants(userId);
            return restaurants.isNotEmpty || hasStaffRole || hasAdminRole;
          }
          return hasOwnerRole || hasStaffRole || hasAdminRole;
      }
    } catch (e) {
      AppLogger.error('Error checking user role', error: e);
      return false;
    }
  }
}

/// Convenience widget for restaurant owner protection
class RestaurantOwnerGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? redirectTo;
  final bool checkVerification;

  const RestaurantOwnerGuard({
    Key? key,
    required this.child,
    this.fallback,
    this.redirectTo,
    this.checkVerification = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: RoleGuardType.restaurantOwner,
      child: child,
      fallback: fallback,
      redirectTo: redirectTo,
      checkVerification: checkVerification,
    );
  }
}

/// Convenience widget for restaurant access (owner or staff)
class RestaurantAccessGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final String? redirectTo;
  final bool checkVerification;

  const RestaurantAccessGuard({
    Key? key,
    required this.child,
    this.fallback,
    this.redirectTo,
    this.checkVerification = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      requiredRole: RoleGuardType.restaurantAccess,
      child: child,
      fallback: fallback,
      redirectTo: redirectTo,
      checkVerification: checkVerification,
    );
  }
}

/// Extension method for easy role checking
extension RoleGuardExtension on Widget {
  Widget guardWithRole({
    required RoleGuardType role,
    Widget? fallback,
    String? redirectTo,
    bool checkVerification = false,
  }) {
    return RoleGuard(
      requiredRole: role,
      child: this,
      fallback: fallback,
      redirectTo: redirectTo,
      checkVerification: checkVerification,
    );
  }
}