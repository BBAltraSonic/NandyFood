import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/widgets/role_switcher_widget.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_role_indicator.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/restaurant_home_screen.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/business_dashboard_screen.dart';
import 'package:food_delivery_app/features/restaurant_orders/presentation/screens/restaurant_orders_screen.dart';
import 'package:food_delivery_app/features/restaurant_menu/presentation/screens/restaurant_menu_screen.dart';
import 'package:food_delivery_app/features/restaurant_analytics/presentation/screens/restaurant_analytics_screen.dart';
import 'package:food_delivery_app/features/cross_role/presentation/screens/view_as_customer_screen.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Restaurant-specific navigation screen optimized for restaurant users
class RestaurantNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;

  const RestaurantNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<RestaurantNavigationScreen> createState() =>
      _RestaurantNavigationScreenState();
}

class _RestaurantNavigationScreenState
    extends ConsumerState<RestaurantNavigationScreen> {
  late int _currentIndex;
  late PageController _pageController;

  // Navigation destinations for different roles
  late List<NavigationDestination> _destinations;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _setupNavigationForRole();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Setup navigation based on user's restaurant role and permissions
  void _setupNavigationForRole() {
    final userRole = ref.read(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.read(staffDataProvider);

    if (isOwner) {
      _setupOwnerNavigation();
    } else {
      _setupStaffNavigation(staffData);
    }
  }

  /// Navigation setup for restaurant owners with full access
  void _setupOwnerNavigation() {
    _destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: 'Orders',
      ),
      const NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: 'Menu',
      ),
      const NavigationDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: 'Analytics',
      ),
      const NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Staff',
      ),
    ];

    _screens = const [
      BusinessDashboardScreen(),
      RestaurantOrdersScreen(),
      RestaurantMenuScreen(),
      RestaurantAnalyticsScreen(),
      RestaurantHomeScreen(), // Placeholder for staff management
    ];
  }

  /// Navigation setup for restaurant staff with limited access based on role
  void _setupStaffNavigation(staffData) {
    // Determine navigation based on staff role
    final staffRole = staffData?.role?.toLowerCase();

    switch (staffRole) {
      case 'chef':
        _destinations = [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Kitchen',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
        ];
        break;

      case 'cashier':
        _destinations = [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Payments',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
        ];
        break;

      case 'server':
        _destinations = [
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
        ];
        break;

      default: // Basic staff, delivery coordinator, etc.
        _destinations = [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Orders',
          ),
        ];
        break;
    }

    // Set role-specific screens
    // staffRole variable already declared above
    switch (staffRole) {
      case 'chef':
        _screens = const [
          RestaurantHomeScreen(), // Kitchen dashboard
          RestaurantMenuScreen(), // Menu items for kitchen
          RestaurantOrdersScreen(), // Kitchen orders
        ];
        break;
      case 'cashier':
        _screens = const [
          RestaurantOrdersScreen(), // Order processing
          RestaurantHomeScreen(), // Payment dashboard
          RestaurantHomeScreen(), // Customer management
        ];
        break;
      case 'server':
        _screens = const [
          RestaurantOrdersScreen(), // Service orders
          RestaurantMenuScreen(), // Menu for service
        ];
        break;
      default: // Basic staff, delivery coordinator, etc.
        _screens = const [
          RestaurantHomeScreen(), // Basic dashboard
          RestaurantOrdersScreen(), // View orders
        ];
        break;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Role Switcher Header for multi-role users
              Consumer(
                builder: (context, ref, child) {
                  final userRoles = ref.watch(userRolesProvider);

                  if (userRoles.length > 1) {
                    return Container(
                      color: Colors.white,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: RoleSwitcherWidget(
                          isCompact: true,
                        ),
                      ),
                    );
                  }

                  // Single role header with role indicator
                  return _buildRoleHeader();
                },
              ),
              // Main Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  children: _screens,
                ),
              ),
            ],
          ),
        ],
      ),
      // Restaurant-specific bottom navigation
      bottomNavigationBar: _buildRestaurantBottomNav(),
      // Floating action button for quick actions
      floatingActionButton: _buildQuickActionFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildRoleHeader() {
    final userRole = ref.watch(primaryRoleProvider);
    final restaurantData = ref.watch(restaurantDataProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: RestaurantRoleIndicator(
              showFullInfo: false,
              showAvatar: true,
              padding: EdgeInsets.zero,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantBottomNav() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _onTabTapped,
            destinations: _destinations,
            backgroundColor: Colors.transparent,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        _showQuickActionsMenu();
      },
      icon: const Icon(Icons.bolt_rounded),
      label: const Text('Quick Actions'),
      backgroundColor: AppTheme.primaryBlack,
      foregroundColor: Colors.white,
      elevation: 4,
    );
  }

  void _showQuickActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildQuickActionsSheet(),
    );
  }

  Widget _buildQuickActionsSheet() {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            padding: const EdgeInsets.all(16),
            childAspectRatio: 1,
            children: _buildQuickActionItems(isOwner),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActionItems(bool isOwner) {
    final List<Map<String, dynamic>> baseActions = [
      {
        'icon': Icons.storefront_outlined,
        'label': 'Toggle Open',
        'color': Colors.orange,
        'action': () => _toggleRestaurantStatus(),
        'permissions': ['manage_restaurant'],
      },
      {
        'icon': Icons.analytics_outlined,
        'label': 'Reports',
        'color': Colors.blue,
        'action': () => context.push(RoutePaths.restaurantAnalytics),
        'permissions': ['view_analytics'],
      },
    ];

    final List<Map<String, dynamic>> menuActions = [
      {
        'icon': Icons.add_circle_outline,
        'label': 'New Item',
        'color': Colors.green,
        'action': () => context.push(RoutePaths.restaurantMenu),
        'permissions': ['manage_menu'],
      },
    ];

    final List<Map<String, dynamic>> staffActions = [
      {
        'icon': Icons.people_outline,
        'label': 'Staff',
        'color': Colors.purple,
        'action': () => context.push('/restaurant/staff'),
        'permissions': ['manage_staff'],
      },
    ];

    final List<Map<String, dynamic>> ownerActions = [
      {
        'icon': Icons.person_outline,
        'label': 'View as Customer',
        'color': Colors.orange,
        'action': () => _viewAsCustomer(),
        'permissions': ['view_analytics'],
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'color': Colors.grey,
        'action': () => context.push(RoutePaths.restaurantSettings),
        'permissions': ['manage_settings'],
      },
      {
        'icon': Icons.local_offer_outlined,
        'label': 'Promotions',
        'color': Colors.red,
        'action': () => context.push('/restaurant/promotions'),
        'permissions': ['manage_promotions'],
      },
    ];

    // Combine all actions
    List<Map<String, dynamic>> allActions = [...baseActions];
    allActions.addAll(menuActions);
    allActions.addAll(staffActions);

    if (isOwner) {
      allActions.addAll(ownerActions);
    }

    return allActions.map((action) {
      return PermissionWidget(
        requiredPermissions: action['permissions'] as List<String>,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context); // Close bottom sheet
              action['action']();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (action['color'] as Color).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    action['icon'] as IconData,
                    color: action['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: action['color'] as Color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _toggleRestaurantStatus() {
    // TODO: Implement restaurant status toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Toggling restaurant status...')),
    );
  }

  void _viewAsCustomer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ViewAsCustomerScreen(),
      ),
    );
  }

  // Helper methods for role display
  String _getRoleDisplayName(UserRoleType role, staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return 'Restaurant Owner';
      case UserRoleType.restaurantStaff:
        return staffData?.role?.toUpperCase() ?? 'Staff Member';
      default:
        return 'Restaurant User';
    }
  }

  IconData _getRoleIcon(UserRoleType role, staffData) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return Icons.store_rounded;
      case UserRoleType.restaurantStaff:
        final staffRole = staffData?.role?.toLowerCase();
        switch (staffRole) {
          case 'chef':
            return Icons.restaurant_rounded;
          case 'cashier':
            return Icons.point_of_sale_rounded;
          case 'server':
            return Icons.room_service_rounded;
          default:
            return Icons.people_rounded;
        }
      default:
        return Icons.store_rounded;
    }
  }

  Color _getRoleColor(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return Colors.deepPurple;
      case UserRoleType.restaurantStaff:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}