import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_role_indicator.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Categorized tools grid for restaurant users with smart organization
class RestaurantToolsGrid extends ConsumerWidget {
  final bool showCategories;
  final bool showSearch;
  final int crossAxisCount;
  final double childAspectRatio;

  const RestaurantToolsGrid({
    super.key,
    this.showCategories = true,
    this.showSearch = true,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);

    final toolCategories = _getToolCategories(ref, isOwner, staffData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSearch) _buildSearchBar(),
        if (showCategories) ...[
          _buildCategoryTabs(toolCategories),
          const SizedBox(height: 16),
        ],
        _buildToolsGrid(toolCategories),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tools and features...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(List<ToolCategory> categories) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: 16,
                    color: category.color,
                  ),
                  const SizedBox(width: 6),
                  Text(category.name),
                ],
              ),
              selected: category.isSelected,
              onSelected: (selected) {
                // TODO: Implement category selection
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: category.color.withOpacity(0.2),
              checkmarkColor: category.color,
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolsGrid(List<ToolCategory> categories) {
    return Column(
      children: categories.map((category) {
        if (!category.isSelected && categories.any((c) => c.isSelected)) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showCategories && categories.length > 1) ...[
              Row(
                children: [
                  Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: category.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${category.tools.length} tools',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: category.tools.length,
              itemBuilder: (context, index) {
                final tool = category.tools[index];
                return PermissionWidget(
                  requiredPermissions: tool.permissions,
                  child: _buildToolCard(tool),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildToolCard(RestaurantTool tool) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => tool.onTap(),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tool.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tool.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool.icon,
                color: tool.color,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                tool.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: tool.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (tool.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  tool.description!,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (tool.isNew) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<ToolCategory> _getToolCategories(WidgetRef ref, bool isOwner, staffData) {
    final List<ToolCategory> categories = [];

    // Daily Operations Category
    categories.add(ToolCategory(
      name: 'Daily Operations',
      icon: Icons.today,
      color: Colors.blue,
      tools: [
        RestaurantTool(
          name: 'Orders',
          icon: Icons.list_alt,
          color: Colors.blue,
          description: 'Manage customer orders',
          onTap: () => _navigateTo('/restaurant/orders'),
          permissions: ['manage_orders', 'view_orders'],
        ),
        RestaurantTool(
          name: 'Kitchen Display',
          icon: Icons.restaurant,
          color: Colors.orange,
          description: 'Kitchen order display',
          onTap: () => _navigateTo('/restaurant/kitchen'),
          permissions: ['manage_kitchen_orders'],
          isNew: true,
        ),
        RestaurantTool(
          name: 'Customer Service',
          icon: Icons.support_agent,
          color: Colors.green,
          description: 'Customer support',
          onTap: () => _navigateTo('/restaurant/support'),
          permissions: ['customer_service'],
        ),
      ],
    ));

    // Menu Management Category
    categories.add(ToolCategory(
      name: 'Menu Management',
      icon: Icons.restaurant_menu,
      color: Colors.orange,
      tools: [
        RestaurantTool(
          name: 'Menu Items',
          icon: Icons.dinner_dining,
          color: Colors.orange,
          description: 'Edit menu items',
          onTap: () => _navigateTo('/restaurant/menu'),
          permissions: ['view_menu', 'manage_menu'],
        ),
        RestaurantTool(
          name: 'Categories',
          icon: Icons.category,
          color: Colors.brown,
          description: 'Menu categories',
          onTap: () => _navigateTo('/restaurant/menu/categories'),
          permissions: ['manage_menu'],
        ),
        RestaurantTool(
          name: 'Inventory',
          icon: Icons.inventory_2,
          color: Colors.red,
          description: 'Stock management',
          onTap: () => _navigateTo('/restaurant/inventory'),
          permissions: ['inventory_management'],
        ),
        RestaurantTool(
          name: 'Pricing',
          icon: Icons.attach_money,
          color: Colors.green,
          description: 'Price management',
          onTap: () => _navigateTo('/restaurant/pricing'),
          permissions: ['manage_menu'],
        ),
      ],
    ));

    // Analytics Category
    if (isOwner || _hasPermission(ref, ['view_analytics'], staffData)) {
      categories.add(ToolCategory(
        name: 'Analytics',
        icon: Icons.analytics,
        color: Colors.purple,
        tools: [
          RestaurantTool(
            name: 'Dashboard',
            icon: Icons.dashboard,
            color: Colors.purple,
            description: 'Business overview',
            onTap: () => _navigateTo('/restaurant/analytics'),
            permissions: ['view_analytics'],
          ),
          RestaurantTool(
            name: 'Sales Reports',
            icon: Icons.trending_up,
            color: Colors.blue,
            description: 'Sales analytics',
            onTap: () => _navigateTo('/restaurant/analytics/sales'),
            permissions: ['view_analytics'],
          ),
          RestaurantTool(
            name: 'Customer Insights',
            icon: Icons.people,
            color: Colors.green,
            description: 'Customer data',
            onTap: () => _navigateTo('/restaurant/analytics/customers'),
            permissions: ['view_analytics'],
          ),
          RestaurantTool(
            name: 'Performance',
            icon: Icons.speed,
            color: Colors.orange,
            description: 'Performance metrics',
            onTap: () => _navigateTo('/restaurant/analytics/performance'),
            permissions: ['view_analytics'],
          ),
        ],
      ));
    }

    // Staff Management Category (Owner/Manager only)
    if (isOwner || _hasPermission(ref, ['manage_staff'], staffData)) {
      categories.add(ToolCategory(
        name: 'Staff Management',
        icon: Icons.people,
        color: Colors.teal,
        tools: [
          RestaurantTool(
            name: 'Team Members',
            icon: Icons.group,
            color: Colors.teal,
            description: 'Manage staff',
            onTap: () => _navigateTo('/restaurant/staff'),
            permissions: ['manage_staff'],
          ),
          RestaurantTool(
            name: 'Scheduling',
            icon: Icons.schedule,
            color: Colors.blue,
            description: 'Work schedules',
            onTap: () => _navigateTo('/restaurant/schedule'),
            permissions: ['manage_staff'],
          ),
          RestaurantTool(
            name: 'Permissions',
            icon: Icons.security,
            color: Colors.orange,
            description: 'Access control',
            onTap: () => _navigateTo('/restaurant/permissions'),
            permissions: ['manage_staff'],
          ),
          RestaurantTool(
            name: 'Performance',
            icon: Icons.assessment,
            color: Colors.green,
            description: 'Staff performance',
            onTap: () => _navigateTo('/restaurant/staff/performance'),
            permissions: ['manage_staff'],
          ),
        ],
      ));
    }

    // Settings & Configuration Category (Owner only)
    if (isOwner) {
      categories.add(ToolCategory(
        name: 'Settings',
        icon: Icons.settings,
        color: Colors.grey,
        tools: [
          RestaurantTool(
            name: 'Restaurant Info',
            icon: Icons.info,
            color: Colors.indigo,
            description: 'Basic information',
            onTap: () => _navigateTo('/restaurant/info'),
            permissions: ['manage_settings'],
          ),
          RestaurantTool(
            name: 'Payment Settings',
            icon: Icons.payment,
            color: Colors.green,
            description: 'Payment methods',
            onTap: () => _navigateTo('/restaurant/payments'),
            permissions: ['manage_settings'],
          ),
          RestaurantTool(
            name: 'Notifications',
            icon: Icons.notifications,
            color: Colors.red,
            description: 'Alert settings',
            onTap: () => _navigateTo('/restaurant/notifications'),
            permissions: ['manage_settings'],
          ),
          RestaurantTool(
            name: 'Integrations',
            icon: Icons.integration_instructions,
            color: Colors.purple,
            description: 'Third-party apps',
            onTap: () => _navigateTo('/restaurant/integrations'),
            permissions: ['manage_settings'],
          ),
        ],
      ));

      categories.add(ToolCategory(
        name: 'Marketing',
        icon: Icons.campaign,
        color: Colors.red,
        tools: [
          RestaurantTool(
            name: 'Promotions',
            icon: Icons.local_offer,
            color: Colors.red,
            description: 'Special offers',
            onTap: () => _navigateTo('/restaurant/promotions'),
            permissions: ['manage_promotions'],
          ),
          RestaurantTool(
            name: 'Reviews',
            icon: Icons.star,
            color: Colors.amber,
            description: 'Customer reviews',
            onTap: () => _navigateTo('/restaurant/reviews'),
            permissions: ['view_analytics'],
          ),
          RestaurantTool(
            name: 'Social Media',
            icon: Icons.share,
            color: Colors.blue,
            description: 'Social management',
            onTap: () => _navigateTo('/restaurant/social'),
            permissions: ['manage_promotions'],
          ),
        ],
      ));
    }

    return categories;
  }

  bool _hasPermission(WidgetRef ref, List<String> requiredPermissions, staffData) {
    final userRole = ref.read(primaryRoleProvider);
    // Simple permission check based on role type
    if (userRole == UserRoleType.restaurantOwner) {
      return true; // Owners have all permissions
    }
    // For other roles, implement basic permission logic
    // TODO: Implement proper permission system
    return false;
  }

  void _navigateTo(String route) {
    // TODO: Implement navigation
    // Get the current context and navigate
  }
}

/// Model for a tool category
class ToolCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<RestaurantTool> tools;
  bool isSelected;

  ToolCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.tools,
    this.isSelected = true,
  });
}

/// Model for a restaurant tool
class RestaurantTool {
  final String name;
  final IconData icon;
  final Color color;
  final String? description;
  final VoidCallback onTap;
  final List<String> permissions;
  final bool isNew;

  RestaurantTool({
    required this.name,
    required this.icon,
    required this.color,
    this.description,
    required this.onTap,
    required this.permissions,
    this.isNew = false,
  });
}

/// Quick access tool grid for frequently used tools
class QuickAccessTools extends ConsumerWidget {
  final List<String> toolIds;
  final int maxItems;

  const QuickAccessTools({
    super.key,
    this.toolIds = const [],
    this.maxItems = 6,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userRole = ref.watch(primaryRoleProvider);
    final isOwner = userRole == UserRoleType.restaurantOwner;
    final staffData = ref.watch(staffDataProvider);

    final quickTools = _getQuickAccessTools(isOwner, staffData, toolIds);

    if (quickTools.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Quick Access',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _customizeQuickAccess(),
              child: const Text('Customize'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: quickTools.length,
          itemBuilder: (context, index) {
            final tool = quickTools[index];
            return PermissionWidget(
              requiredPermissions: tool.permissions,
              child: _buildQuickAccessTool(tool),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickAccessTool(RestaurantTool tool) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tool.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: tool.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                tool.icon,
                color: tool.color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                tool.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: tool.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RestaurantTool> _getQuickAccessTools(
    bool isOwner,
    staffData,
    List<String> preferredToolIds,
  ) {
    // Default quick tools based on role
    List<RestaurantTool> defaultTools = [];

    if (isOwner) {
      defaultTools = [
        RestaurantTool(
          name: 'Orders',
          icon: Icons.list_alt,
          color: Colors.blue,
          onTap: () => _navigateTo('/restaurant/orders'),
          permissions: ['manage_orders'],
        ),
        RestaurantTool(
          name: 'Menu',
          icon: Icons.restaurant_menu,
          color: Colors.orange,
          onTap: () => _navigateTo('/restaurant/menu'),
          permissions: ['manage_menu'],
        ),
        RestaurantTool(
          name: 'Analytics',
          icon: Icons.analytics,
          color: Colors.purple,
          onTap: () => _navigateTo('/restaurant/analytics'),
          permissions: ['view_analytics'],
        ),
        RestaurantTool(
          name: 'Staff',
          icon: Icons.people,
          color: Colors.teal,
          onTap: () => _navigateTo('/restaurant/staff'),
          permissions: ['manage_staff'],
        ),
        RestaurantTool(
          name: 'Settings',
          icon: Icons.settings,
          color: Colors.grey,
          onTap: () => _navigateTo('/restaurant/settings'),
          permissions: ['manage_settings'],
        ),
        RestaurantTool(
          name: 'Promotions',
          icon: Icons.local_offer,
          color: Colors.red,
          onTap: () => _navigateTo('/restaurant/promotions'),
          permissions: ['manage_promotions'],
        ),
      ];
    } else {
      final staffRole = staffData?.role?.toLowerCase();
      switch (staffRole) {
        case 'chef':
          defaultTools = [
            RestaurantTool(
              name: 'Kitchen',
              icon: Icons.restaurant,
              color: Colors.orange,
              onTap: () => _navigateTo('/restaurant/kitchen'),
              permissions: ['manage_kitchen_orders'],
            ),
            RestaurantTool(
              name: 'Menu',
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              onTap: () => _navigateTo('/restaurant/menu'),
              permissions: ['view_menu'],
            ),
            RestaurantTool(
              name: 'Inventory',
              icon: Icons.inventory_2,
              color: Colors.red,
              onTap: () => _navigateTo('/restaurant/inventory'),
              permissions: ['inventory_management'],
            ),
          ];
          break;
        case 'cashier':
          defaultTools = [
            RestaurantTool(
              name: 'Orders',
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () => _navigateTo('/restaurant/orders'),
              permissions: ['process_orders'],
            ),
            RestaurantTool(
              name: 'Payments',
              icon: Icons.payment,
              color: Colors.green,
              onTap: () => _navigateTo('/restaurant/payments'),
              permissions: ['handle_payments'],
            ),
          ];
          break;
        case 'server':
          defaultTools = [
            RestaurantTool(
              name: 'Orders',
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () => _navigateTo('/restaurant/orders'),
              permissions: ['manage_customer_orders'],
            ),
            RestaurantTool(
              name: 'Menu',
              icon: Icons.restaurant_menu,
              color: Colors.orange,
              onTap: () => _navigateTo('/restaurant/menu'),
              permissions: ['view_menu'],
            ),
          ];
          break;
        default:
          defaultTools = [
            RestaurantTool(
              name: 'Orders',
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () => _navigateTo('/restaurant/orders'),
              permissions: ['view_orders'],
            ),
          ];
          break;
      }
    }

    // Limit to maxItems
    return defaultTools.take(maxItems).toList();
  }

  void _navigateTo(String route) {
    // TODO: Implement navigation
  }

  void _customizeQuickAccess() {
    // TODO: Implement quick access customization
  }
}