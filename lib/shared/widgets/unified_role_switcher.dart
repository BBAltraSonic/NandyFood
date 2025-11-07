import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Unified role switcher with context preservation and smooth transitions
class UnifiedRoleSwitcher extends ConsumerStatefulWidget {
  final bool isCompact;
  final bool showCurrentLocation;
  final bool allowCustomRouting;

  const UnifiedRoleSwitcher({
    super.key,
    this.isCompact = false,
    this.showCurrentLocation = true,
    this.allowCustomRouting = true,
  });

  @override
  ConsumerState<UnifiedRoleSwitcher> createState() => _UnifiedRoleSwitcherState();
}

class _UnifiedRoleSwitcherState extends ConsumerState<UnifiedRoleSwitcher>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  String? _currentRoute;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRoles = ref.watch(userRolesProvider);
    final primaryRole = ref.watch(primaryRoleProvider);
    final currentLocation = widget.showCurrentLocation ? _getCurrentLocation() : null;

    final roleTypes = userRoles.map((r) => r.role).toList();
    final currentRoleType = primaryRole ?? UserRoleType.consumer;

    if (userRoles.length <= 1) {
      return _buildSingleRoleDisplay(currentRoleType, currentLocation);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoleSwitcherHeader(roleTypes, currentRoleType, currentLocation),
        if (_isExpanded) ...[
          const SizedBox(height: 12),
          _buildRoleOptions(roleTypes, currentRoleType),
        ],
      ],
    );
  }

  Widget _buildSingleRoleDisplay(UserRoleType role, String? currentLocation) {
    final roleInfo = _getRoleInfo(role);

    return widget.isCompact
        ? _buildCompactRoleDisplay(roleInfo)
        : _buildFullRoleDisplay(roleInfo, currentLocation);
  }

  Widget _buildCompactRoleDisplay(RoleInfo roleInfo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: roleInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: roleInfo.color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            roleInfo.icon,
            color: roleInfo.color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            roleInfo.shortName,
            style: TextStyle(
              color: roleInfo.color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullRoleDisplay(RoleInfo roleInfo, String? currentLocation) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: roleInfo.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              roleInfo.icon,
              color: roleInfo.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleInfo.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (currentLocation != null)
                  Text(
                    currentLocation,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleInfo.color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'ACTIVE',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSwitcherHeader(
    List<UserRoleType> userRoles,
    UserRoleType primaryRole,
    String? currentLocation,
  ) {
    final roleInfo = _getRoleInfo(primaryRole);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(widget.isCompact ? 8 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: roleInfo.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: roleInfo.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      roleInfo.icon,
                      color: roleInfo.color,
                      size: widget.isCompact ? 16 : 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isCompact ? roleInfo.shortName : roleInfo.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: widget.isCompact ? 12 : 14,
                            color: roleInfo.color,
                          ),
                        ),
                        if (!widget.isCompact && currentLocation != null)
                          Text(
                            currentLocation,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        if (userRoles.length > 1)
                          Text(
                            '${userRoles.length} roles available',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: roleInfo.color,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoleOptions(List<UserRoleType> userRoles, UserRoleType primaryRole) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Switch Role',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...userRoles.map((role) {
            final roleInfo = _getRoleInfo(role);
            final isActive = role == primaryRole;
            final isCurrent = role == primaryRole;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _switchRole(role),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? roleInfo.color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: roleInfo.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            roleInfo.icon,
                            color: roleInfo.color,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                roleInfo.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? roleInfo.color : null,
                                ),
                              ),
                              Text(
                                roleInfo.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: roleInfo.color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CURRENT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _switchRole(UserRoleType newRole) async {
    final currentRole = ref.read(primaryRoleProvider);
    if (newRole == currentRole) {
      _toggleExpanded();
      return;
    }

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (widget.allowCustomRouting) {
      final contextState = _captureCurrentContext();
      await _storeContextForRole(newRole, contextState);
    }

    try {
      final success = await ref.read(roleProvider.notifier).switchRole(userId, newRole);

      if (success && mounted) {
        _toggleExpanded();
        final targetRoute = _getRouteForRole(newRole);
        context.go(targetRoute);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to switch role'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  RoleContext _captureCurrentContext() {
    final modalRoute = ModalRoute.of(context);
    _currentRoute = modalRoute?.settings.name;
    
    return RoleContext(
      route: _currentRoute,
      arguments: modalRoute?.settings.arguments,
      timestamp: DateTime.now(),
      userData: {
        'lastScreen': _getCurrentScreen(),
        'scrollPosition': 0.0,
        'activeFilters': [],
      },
    );
  }

  Future<void> _storeContextForRole(UserRoleType role, RoleContext context) async {
    await RoleContextService.storeContext(role, context);
  }

  String _getCurrentLocation() {
    final route = ModalRoute.of(context)?.settings.name;
    if (route == null) return 'Home';
    
    final routeMap = {
      '/home': 'Home',
      '/restaurant/dashboard': 'Restaurant Dashboard',
      '/restaurant/orders': 'Restaurant Orders',
      '/admin/dashboard': 'Admin Dashboard',
      '/driver/dashboard': 'Driver Dashboard',
    };
    
    return routeMap[route] ?? route.split('/').last.replaceAll('_', ' ').split(' ').map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}').join(' ');
  }

  String _getCurrentScreen() {
    final route = ModalRoute.of(context)?.settings.name;
    return route?.split('/').last ?? 'home';
  }

  String _getRouteForRole(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return '/restaurant/dashboard';
      case UserRoleType.restaurantStaff:
        return '/restaurant/orders';
      case UserRoleType.admin:
        return '/admin/dashboard';
      case UserRoleType.deliveryDriver:
        return '/driver/dashboard';
      case UserRoleType.consumer:
        return '/home';
    }
  }

  RoleInfo _getRoleInfo(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return const RoleInfo(
          displayName: 'Restaurant Owner',
          shortName: 'OWNER',
          description: 'Manage your restaurant business',
          icon: Icons.store,
          color: Colors.deepPurple,
        );
      case UserRoleType.restaurantStaff:
        return const RoleInfo(
          displayName: 'Restaurant Staff',
          shortName: 'STAFF',
          description: 'Restaurant operations',
          icon: Icons.people,
          color: Colors.blue,
        );
      case UserRoleType.admin:
        return const RoleInfo(
          displayName: 'Administrator',
          shortName: 'ADMIN',
          description: 'System administration',
          icon: Icons.admin_panel_settings,
          color: Colors.red,
        );
      case UserRoleType.deliveryDriver:
        return const RoleInfo(
          displayName: 'Delivery Driver',
          shortName: 'DRIVER',
          description: 'Deliver food orders',
          icon: Icons.delivery_dining,
          color: Colors.green,
        );
      case UserRoleType.consumer:
        return const RoleInfo(
          displayName: 'Customer',
          shortName: 'CUSTOMER',
          description: 'Order and enjoy food',
          icon: Icons.person,
          color: Colors.orange,
        );
    }
  }
}

/// Model for role information
class RoleInfo {
  final String displayName;
  final String shortName;
  final String description;
  final IconData icon;
  final Color color;

  const RoleInfo({
    required this.displayName,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Model for role context preservation
class RoleContext {
  final String? route;
  final dynamic arguments;
  final DateTime timestamp;
  final Map<String, dynamic> userData;

  const RoleContext({
    this.route,
    this.arguments,
    required this.timestamp,
    required this.userData,
  });

  Map<String, dynamic> toJson() {
    return {
      'route': route,
      'arguments': arguments,
      'timestamp': timestamp.toIso8601String(),
      'userData': userData,
    };
  }

  factory RoleContext.fromJson(Map<String, dynamic> json) {
    return RoleContext(
      route: json['route'],
      arguments: json['arguments'],
      timestamp: DateTime.parse(json['timestamp']),
      userData: Map<String, dynamic>.from(json['userData'] ?? {}),
    );
  }
}

/// Context-aware role switching service
class RoleContextService {
  static const String _contextKeyPrefix = 'role_context_';

  static Future<void> storeContext(UserRoleType role, RoleContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_contextKeyPrefix${role.name}';
      final jsonString = jsonEncode(context.toJson());
      await prefs.setString(key, jsonString);
    } catch (e) {
      debugPrint('Error storing role context: $e');
    }
  }

  static Future<RoleContext?> getContext(UserRoleType role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_contextKeyPrefix${role.name}';
      final jsonString = prefs.getString(key);
      if (jsonString == null) return null;
      
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return RoleContext.fromJson(json);
    } catch (e) {
      debugPrint('Error retrieving role context: $e');
      return null;
    }
  }

  static Future<void> clearAllContexts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_contextKeyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error clearing role contexts: $e');
    }
  }
}

/// Role switching dialog for better UX
class RoleSwitchDialog extends StatelessWidget {
  final List<UserRoleType> availableRoles;
  final UserRoleType currentRole;
  final Function(UserRoleType) onRoleSelected;

  const RoleSwitchDialog({
    super.key,
    required this.availableRoles,
    required this.currentRole,
    required this.onRoleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.swap_horiz, color: AppTheme.primaryBlack),
                const SizedBox(width: 8),
                const Text(
                  'Switch Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Select which role you want to switch to:',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            ...availableRoles.map((role) {
              final roleInfo = _getRoleInfo(role);
              final isActive = role == currentRole;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onRoleSelected(role);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? roleInfo.color.withValues(alpha: 0.1)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? roleInfo.color
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            roleInfo.icon,
                            color: roleInfo.color,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  roleInfo.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isActive ? roleInfo.color : null,
                                  ),
                                ),
                                Text(
                                  roleInfo.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: roleInfo.color,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  static RoleInfo _getRoleInfo(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return const RoleInfo(
          displayName: 'Restaurant Owner',
          shortName: 'OWNER',
          description: 'Manage your restaurant business',
          icon: Icons.store,
          color: Colors.deepPurple,
        );
      case UserRoleType.restaurantStaff:
        return const RoleInfo(
          displayName: 'Restaurant Staff',
          shortName: 'STAFF',
          description: 'Restaurant operations',
          icon: Icons.people,
          color: Colors.blue,
        );
      case UserRoleType.admin:
        return const RoleInfo(
          displayName: 'Administrator',
          shortName: 'ADMIN',
          description: 'System administration',
          icon: Icons.admin_panel_settings,
          color: Colors.red,
        );
      case UserRoleType.deliveryDriver:
        return const RoleInfo(
          displayName: 'Delivery Driver',
          shortName: 'DRIVER',
          description: 'Deliver food orders',
          icon: Icons.delivery_dining,
          color: Colors.green,
        );
      case UserRoleType.consumer:
        return const RoleInfo(
          displayName: 'Customer',
          shortName: 'CUSTOMER',
          description: 'Order and enjoy food',
          icon: Icons.person,
          color: Colors.orange,
        );
    }
  }
}