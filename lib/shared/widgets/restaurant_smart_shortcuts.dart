import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/widgets/restaurant_role_indicator.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Smart shortcuts widget that adapts to user behavior and context
class RestaurantSmartShortcuts extends ConsumerStatefulWidget {
  final int maxShortcuts;

  const RestaurantSmartShortcuts({
    super.key,
    this.maxShortcuts = 8,
  });

  @override
  ConsumerState<RestaurantSmartShortcuts> createState() =>
      _RestaurantSmartShortcutsState();
}

class _RestaurantSmartShortcutsState
    extends ConsumerState<RestaurantSmartShortcuts> {
  List<SmartShortcut> _smartShortcuts = [];

  @override
  void initState() {
    super.initState();
    _loadSmartShortcuts();
  }

  Future<void> _loadSmartShortcuts() async {
    // Simulate loading smart shortcuts based on user behavior
    final userRole = ref.read(primaryRoleProvider);
    final staffData = ref.read(staffDataProvider);

    final shortcuts = _generateSmartShortcuts(userRole ?? UserRoleType.consumer, staffData);

    setState(() {
      _smartShortcuts = shortcuts.take(widget.maxShortcuts).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_smartShortcuts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        _buildShortcutsGrid(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(
          Icons.bolt_rounded,
          color: Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Smart Shortcuts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Spacer(),
        TextButton(
          onPressed: _customizeShortcuts,
          child: const Text('Customize'),
        ),
      ],
    );
  }

  Widget _buildShortcutsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: _smartShortcuts.length,
      itemBuilder: (context, index) {
        final shortcut = _smartShortcuts[index];
        return PermissionWidget(
          requiredPermissions: shortcut.permissions,
          child: _buildShortcutCard(shortcut),
        );
      },
    );
  }

  Widget _buildShortcutCard(SmartShortcut shortcut) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _executeShortcut(shortcut),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: shortcut.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: shortcut.color.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                shortcut.icon,
                color: shortcut.color,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                shortcut.title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: shortcut.color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (shortcut.isRecommended) ...[
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 6,
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

  List<SmartShortcut> _generateSmartShortcuts(UserRoleType userRole, staffData) {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday;

    List<SmartShortcut> shortcuts = [];

    // Time-based shortcuts
    if (hour >= 11 && hour <= 14) {
      // Lunch rush hours
      shortcuts.addAll([
        SmartShortcut(
          id: 'quick_order_accept',
          title: 'Quick Accept',
          icon: Icons.check_circle,
          color: Colors.green,
          action: ShortcutAction.quickAcceptOrders,
          priority: ShortcutPriority.high,
          isRecommended: true,
          permissions: ['manage_orders'],
        ),
        SmartShortcut(
          id: 'kitchen_display',
          title: 'Kitchen',
          icon: Icons.restaurant,
          color: Colors.orange,
          action: ShortcutAction.openKitchenDisplay,
          priority: ShortcutPriority.high,
          permissions: ['manage_kitchen_orders'],
        ),
      ]);
    } else if (hour >= 17 && hour <= 21) {
      // Dinner rush hours
      shortcuts.addAll([
        SmartShortcut(
          id: 'evening_orders',
          title: 'Dinner Orders',
          icon: Icons.nightlife,
          color: Colors.purple,
          action: ShortcutAction.viewEveningOrders,
          priority: ShortcutPriority.high,
          isRecommended: true,
          permissions: ['manage_orders'],
        ),
        SmartShortcut(
          id: 'prep_time_update',
          title: 'Update Times',
          icon: Icons.timer,
          color: Colors.blue,
          action: ShortcutAction.updatePrepTimes,
          priority: ShortcutPriority.medium,
          permissions: ['manage_orders'],
        ),
      ]);
    }

    // Day-based shortcuts
    if (dayOfWeek == DateTime.monday) {
      shortcuts.add(
        SmartShortcut(
          id: 'weekly_reports',
          title: 'Weekly Report',
          icon: Icons.analytics,
          color: Colors.indigo,
          action: ShortcutAction.viewWeeklyReports,
          priority: ShortcutPriority.medium,
          permissions: ['view_analytics'],
        ),
      );
    } else if (dayOfWeek == DateTime.friday) {
      shortcuts.add(
        SmartShortcut(
          id: 'weekend_prep',
          title: 'Weekend Prep',
          icon: Icons.event,
          color: Colors.amber,
          action: ShortcutAction.weekendPreparation,
          priority: ShortcutPriority.medium,
          permissions: ['manage_menu'],
        ),
      );
    }

    // Role-based shortcuts
    switch (userRole) {
      case UserRoleType.restaurantOwner:
        shortcuts.addAll(_getOwnerShortcuts());
        break;
      case UserRoleType.restaurantStaff:
        shortcuts.addAll(_getStaffShortcuts(staffData));
        break;
      default:
        break;
    }

    // Contextual shortcuts based on recent activity
    shortcuts.addAll(_getContextualShortcuts());

    // Sort by priority and return
    shortcuts.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    return shortcuts;
  }

  List<SmartShortcut> _getOwnerShortcuts() {
    return [
      SmartShortcut(
        id: 'revenue_today',
        title: 'Today\'s Revenue',
        icon: Icons.attach_money,
        color: Colors.green,
        action: ShortcutAction.viewTodayRevenue,
        priority: ShortcutPriority.high,
        permissions: ['view_analytics'],
      ),
      SmartShortcut(
        id: 'staff_scheduling',
        title: 'Schedule',
        icon: Icons.schedule,
        color: Colors.teal,
        action: ShortcutAction.manageSchedule,
        priority: ShortcutPriority.medium,
        permissions: ['manage_staff'],
      ),
      SmartShortcut(
        id: 'inventory_alert',
        title: 'Inventory',
        icon: Icons.inventory_2,
        color: Colors.red,
        action: ShortcutAction.checkInventory,
        priority: ShortcutPriority.high,
        permissions: ['inventory_management'],
      ),
      SmartShortcut(
        id: 'customer_reviews',
        title: 'Reviews',
        icon: Icons.star,
        color: Colors.amber,
        action: ShortcutAction.viewReviews,
        priority: ShortcutPriority.medium,
        permissions: ['view_analytics'],
      ),
    ];
  }

  List<SmartShortcut> _getStaffShortcuts(staffData) {
    final staffRole = staffData?.role?.toLowerCase();
    List<SmartShortcut> shortcuts = [];

    switch (staffRole) {
      case 'chef':
        shortcuts.addAll([
          SmartShortcut(
            id: 'prep_queue',
            title: 'Prep Queue',
            icon: Icons.restaurant,
            color: Colors.orange,
            action: ShortcutAction.viewPrepQueue,
            priority: ShortcutPriority.high,
            permissions: ['manage_kitchen_orders'],
          ),
          SmartShortcut(
            id: 'recipe_guide',
            title: 'Recipes',
            icon: Icons.menu_book,
            color: Colors.brown,
            action: ShortcutAction.viewRecipes,
            priority: ShortcutPriority.medium,
            permissions: ['view_menu'],
          ),
        ]);
        break;
      case 'cashier':
        shortcuts.addAll([
          SmartShortcut(
            id: 'active_orders',
            title: 'Active Orders',
            icon: Icons.list_alt,
            color: Colors.blue,
            action: ShortcutAction.viewActiveOrders,
            priority: ShortcutPriority.high,
            permissions: ['process_orders'],
          ),
          SmartShortcut(
            id: 'payment_summary',
            title: 'Payments',
            icon: Icons.payment,
            color: Colors.green,
            action: ShortcutAction.viewPaymentSummary,
            priority: ShortcutPriority.medium,
            permissions: ['handle_payments'],
          ),
        ]);
        break;
      case 'server':
        shortcuts.addAll([
          SmartShortcut(
            id: 'table_orders',
            title: 'My Tables',
            icon: Icons.table_restaurant,
            color: Colors.purple,
            action: ShortcutAction.viewTableOrders,
            priority: ShortcutPriority.high,
            permissions: ['manage_customer_orders'],
          ),
        ]);
        break;
    }

    return shortcuts;
  }

  List<SmartShortcut> _getContextualShortcuts() {
    // These would be based on actual user activity and app state
    // For now, returning some contextual examples
    return [
      SmartShortcut(
        id: 'recent_customers',
        title: 'Recent',
        icon: Icons.history,
        color: Colors.grey,
        action: ShortcutAction.viewRecentActivity,
        priority: ShortcutPriority.low,
        permissions: ['view_orders'],
      ),
    ];
  }

  void _executeShortcut(SmartShortcut shortcut) {
    switch (shortcut.action) {
      case ShortcutAction.quickAcceptOrders:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quick accept mode activated')),
        );
        break;
      case ShortcutAction.openKitchenDisplay:
        // Navigate to kitchen display
        break;
      case ShortcutAction.viewEveningOrders:
        // Navigate to evening orders
        break;
      case ShortcutAction.updatePrepTimes:
        _showPrepTimeDialog();
        break;
      case ShortcutAction.viewWeeklyReports:
        // Navigate to weekly reports
        break;
      case ShortcutAction.weekendPreparation:
        // Navigate to weekend prep
        break;
      case ShortcutAction.viewTodayRevenue:
        // Navigate to today's revenue
        break;
      case ShortcutAction.manageSchedule:
        // Navigate to scheduling
        break;
      case ShortcutAction.checkInventory:
        // Navigate to inventory
        break;
      case ShortcutAction.viewReviews:
        // Navigate to reviews
        break;
      case ShortcutAction.viewPrepQueue:
        // Navigate to prep queue
        break;
      case ShortcutAction.viewRecipes:
        // Navigate to recipes
        break;
      case ShortcutAction.viewActiveOrders:
        // Navigate to active orders
        break;
      case ShortcutAction.viewPaymentSummary:
        // Navigate to payment summary
        break;
      case ShortcutAction.viewTableOrders:
        // Navigate to table orders
        break;
      case ShortcutAction.viewRecentActivity:
        _showRecentActivity();
        break;
    }
  }

  void _showPrepTimeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Preparation Times'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Standard prep time (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Rush hour prep time (minutes)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparation times updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showRecentActivity() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActivityItem('Order #1234 accepted', '2 minutes ago', Icons.check_circle, Colors.green),
            _buildActivityItem('New order received', '5 minutes ago', Icons.receipt, Colors.blue),
            _buildActivityItem('Menu item updated', '1 hour ago', Icons.edit, Colors.orange),
            _buildActivityItem('Customer review received', '2 hours ago', Icons.star, Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _customizeShortcuts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Shortcuts'),
        content: const Text('Choose which shortcuts appear based on your preferences and usage patterns.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadSmartShortcuts(); // Reload shortcuts
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

/// Model for a smart shortcut
class SmartShortcut {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final ShortcutAction action;
  final ShortcutPriority priority;
  final List<String> permissions;
  final bool isRecommended;

  SmartShortcut({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.action,
    required this.priority,
    required this.permissions,
    this.isRecommended = false,
  });
}

/// Enum for shortcut actions
enum ShortcutAction {
  quickAcceptOrders,
  openKitchenDisplay,
  viewEveningOrders,
  updatePrepTimes,
  viewWeeklyReports,
  weekendPreparation,
  viewTodayRevenue,
  manageSchedule,
  checkInventory,
  viewReviews,
  viewPrepQueue,
  viewRecipes,
  viewActiveOrders,
  viewPaymentSummary,
  viewTableOrders,
  viewRecentActivity,
}

/// Enum for shortcut priority
enum ShortcutPriority {
  low,
  medium,
  high,
}

/// Recent activity widget for tracking user actions
class RecentActivityWidget extends ConsumerWidget {
  final int maxItems;

  const RecentActivityWidget({
    super.key,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock recent activities - in real app, these would come from a service
    final activities = _getMockActivities();

    if (activities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _viewAllActivity(),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...activities.take(maxItems).map((activity) {
            return _buildActivityItem(activity);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: activity.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  activity.description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.timeAgo,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  List<RecentActivity> _getMockActivities() {
    return [
      RecentActivity(
        title: 'New order received',
        description: 'Order #1234 for \$45.99',
        timeAgo: '2 min ago',
        icon: Icons.receipt_long,
        color: Colors.blue,
      ),
      RecentActivity(
        title: 'Order completed',
        description: 'Order #1232 delivered successfully',
        timeAgo: '15 min ago',
        icon: Icons.check_circle,
        color: Colors.green,
      ),
      RecentActivity(
        title: 'Menu item updated',
        description: 'Classic Burger price changed',
        timeAgo: '1 hour ago',
        icon: Icons.edit,
        color: Colors.orange,
      ),
      RecentActivity(
        title: 'Customer review',
        description: '5-star rating received',
        timeAgo: '2 hours ago',
        icon: Icons.star,
        color: Colors.amber,
      ),
      RecentActivity(
        title: 'Staff shift started',
        description: 'John Doe began shift',
        timeAgo: '3 hours ago',
        icon: Icons.person,
        color: Colors.purple,
      ),
    ];
  }

  void _viewAllActivity() {
    // Navigate to full activity log
  }
}

/// Model for recent activity
class RecentActivity {
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color color;

  RecentActivity({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.color,
  });
}