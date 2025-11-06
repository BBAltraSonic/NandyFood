import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Unified notification system that handles notifications for all user roles
class UnifiedNotificationSystem extends ConsumerStatefulWidget {
  final bool showBellIcon;
  final bool allowDismiss;
  final bool autoHide;

  const UnifiedNotificationSystem({
    super.key,
    this.showBellIcon = true,
    this.allowDismiss = true,
    this.autoHide = false,
  });

  @override
  ConsumerState<UnifiedNotificationSystem> createState() =>
      _UnifiedNotificationSystemState();
}

class _UnifiedNotificationSystemState extends ConsumerState<UnifiedNotificationSystem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  List<UnifiedNotification> _notifications = [];
  bool _showNotifications = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _loadMockNotifications();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(primaryRoleProvider);
    final unreadCount = _getUnreadCount();

    return Column(
      children: [
        // Notification bell with badge
        if (showBellIcon) _buildNotificationBell(unreadCount),
        // Notification panel
        if (_showNotifications) _buildNotificationPanel(userRole),
      ],
    );
  }

  Widget _buildNotificationBell(int unreadCount) {
    return Positioned(
      top: 0,
      right: 0,
      child: Stack(
        children: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _toggleNotifications,
            iconSize: 24,
          ),
          if (unreadCount > 0)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationPanel(UserRoleType userRole) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 300),
          child: Container(
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildNotificationHeader(userRole),
                Expanded(
                  child: _buildNotificationList(userRole),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationHeader(UserRoleType userRole) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getRoleIcon(userRole),
            color: _getRoleColor(userRole),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getRoleSpecificTitle(userRole),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleNotifications,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(UserRoleType userRole) {
    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
            Text(
              'You\'re all caught up!',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationItem(notification, userRole);
      },
    );
  }

  Widget _buildNotificationItem(
    UnifiedNotification notification,
    UserRoleType userRole,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: notification.isRead
            ? Colors.transparent
            : _getRoleColor(userRole).withValues(alpha: 0.05),
        ),
        border: Border(
          left: BorderSide(
            color: _getNotificationColor(notification.type),
            width: 3,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type).withValues(alpha: 0.1),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: notification.actionUrl != null
            ? IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                onPressed: () => _handleNotificationAction(notification),
              )
            : null,
        onTap: () => _markAsRead(notification),
      ),
    );
  }

  void _toggleNotifications() {
    setState(() {
      _showNotifications = !_showNotifications;
      if (_showNotifications) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _loadMockNotifications() {
    final userRole = ref.read(primaryRoleProvider);

    setState(() {
      _notifications = _getMockNotifications(userRole);
    });
  }

  List<UnifiedNotification> _getMockNotifications(UserRoleType userRole) {
    switch (userRole) {
      case UserRoleType.restaurantOwner:
        return [
          UnifiedNotification(
            id: '1',
            title: 'New order received!',
            message: 'Order #1234 for \$45.99 from John Doe',
            type: NotificationType.newOrder,
            timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
            isRead: false,
            actionUrl: '/restaurant/orders',
          ),
          UnifiedNotification(
            id: '2',
            title: 'Revenue milestone',
            message: 'Congratulations! You\'ve reached \$1,000 in daily revenue',
            type: NotificationType.milestone,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: false,
            actionUrl: '/restaurant/analytics',
          ),
          UnifiedNotification(
            id: '3',
            title: 'Low inventory alert',
            message: 'Tomatoes are running low. Only 5 portions remaining.',
            type: NotificationType.inventory,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
            actionUrl: '/restaurant/inventory',
          ),
          UnifiedNotification(
            id: '4',
            title: 'Customer review',
            message: 'Sarah left a 5-star review for your restaurant!',
            type: NotificationType.review,
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
            isRead: true,
            actionUrl: '/restaurant/reviews',
          ),
        ];
      case UserRoleType.consumer:
        return [
          UnifiedNotification(
            id: '1',
            title: 'Order status update',
            message: 'Your order is now being prepared',
            type: NotificationType.orderStatus,
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
            actionUrl: '/order/track/1234',
          ),
          UnifiedNotification(
            id: '2',
            title: 'Special offer near you',
            message: '20% off at Pizza Palace - only 2 hours left!',
            type: NotificationType.promotion,
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isRead: false,
            actionUrl: '/promotions',
          ),
          UnifiedNotification(
            id: '3',
            title: 'Delivery update',
            message: 'Your driver is 5 minutes away',
            type: NotificationType.delivery,
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: true,
            actionUrl: '/order/track/1234',
          ),
        ];
      case UserRoleType.admin:
        return [
          UnifiedNotification(
            id: '1',
            title: 'New restaurant registration',
            message: '3 new restaurants pending verification',
            type: NotificationType.system,
            timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
            isRead: false,
            actionUrl: '/admin/restaurants',
          ),
          UnifiedNotification(
            id: '2',
            title: 'System alert',
            message: 'Database backup completed successfully',
            type: NotificationType.system,
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isRead: true,
            actionUrl: '/admin/system',
          ),
        ];
      default:
        return [];
    }
  }

  int _getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  void _handleNotificationAction(UnifiedNotification notification) {
    if (notification.actionUrl != null) {
      context.push(notification.actionUrl!);
    }
    _markAsRead(notification);
  }

  void _markAsRead(UnifiedNotification notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    });
  }

  IconData _getRoleIcon(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return Icons.store;
      case UserRoleType.restaurantStaff:
        return Icons.people;
      case UserRoleType.admin:
        return Icons.admin_panel_settings;
      case UserRoleType.deliveryDriver:
        return Icons.delivery_dining;
      case UserRoleType.consumer:
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return Colors.deepPurple;
      case UserRoleType.restaurantStaff:
        return Colors.blue;
      case UserRoleType.admin:
        return Colors.red;
      case UserRoleType.deliveryDriver:
        return Colors.green;
      case UserRoleType.consumer:
      default:
        return Colors.orange;
    }
  }

  String _getRoleSpecificTitle(UserRoleType role) {
    switch (role) {
      case UserRoleType.restaurantOwner:
        return 'Business updates and order alerts';
      case UserRoleType.restaurantStaff:
        return 'Shift updates and task notifications';
      case UserRoleType.admin:
        return 'System alerts and platform updates';
      case UserRoleType.deliveryDriver:
        return 'New delivery opportunities';
      case UserRoleType.consumer:
      default:
        return 'Order updates and special offers';
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Colors.green;
      case NotificationType.orderStatus:
        return Colors.blue;
      case NotificationType.delivery:
        return Colors.purple;
      case NotificationType.review:
        return Colors.amber;
      case NotificationType.promotion:
        return Colors.red;
      case NotificationType.inventory:
        return Colors.orange;
      case NotificationType.milestone:
        return Colors.teal;
      case NotificationType.system:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.newOrder:
        return Icons.receipt_long;
      case NotificationType.orderStatus:
        return Icons.info;
      case NotificationType.delivery:
        return Icons.delivery_dining;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.inventory:
        return Icons.inventory_2;
      case NotificationType.milestone:
        return Icons.trending_up;
      case NotificationType.system:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Model for unified notification
class UnifiedNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;

  const UnifiedNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.actionUrl,
    this.data,
  });

  UnifiedNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? actionUrl,
    Map<String, dynamic>? data,
  }) {
    return UnifiedNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
      data: data ?? this.data,
    );
  }
}

/// Notification types
enum NotificationType {
  newOrder,
  orderStatus,
  delivery,
  review,
  promotion,
  inventory,
  milestone,
  system,
}

/// Notification service for managing notifications
class NotificationService {
  static const String _storageKey = 'unified_notifications';

  static Future<void> addNotification(UnifiedNotification notification) async {
    // TODO: Implement notification storage and push notifications
  }

  static Future<void> markAsRead(String notificationId) async {
    // TODO: Implement mark as read functionality
  }

  static Future<void> markAllAsRead() async {
    // TODO: Implement mark all as read functionality
  }

  static Future<List<UnifiedNotification>> getNotifications(
      {bool unreadOnly = false}) async {
    // TODO: Implement notification retrieval
    return [];
  }

  static Future<int> getUnreadCount() async {
    // TODO: Implement unread count calculation
    return 0;
  }

  static Future<void> clearAll() async {
    // TODO: Implement clear all notifications
  }
}

/// Notification center screen for managing all notifications
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleFilterAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Notifications'),
              ),
              const PopupMenuItem(
                value: 'unread',
                child: Text('Unread Only'),
              ),
              const PopupMenuItem(
                value: 'orders',
                child: Text('Orders Only'),
              ),
              const PopupMenuItem(
                value: 'system',
                child: Text('System Only'),
              ),
            ],
          ),
        ],
      ),
      body: const UnifiedNotificationSystem(
        showBellIcon: false,
        allowDismiss: true,
      ),
    );
  }

  void _markAllAsRead() {
    // TODO: Implement mark all as read
  }

  void _handleFilterAction(String filter) {
    // TODO: Implement notification filtering
  }
}