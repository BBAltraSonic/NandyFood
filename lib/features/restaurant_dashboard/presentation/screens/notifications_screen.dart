import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum NotificationType {
  newOrder,
  orderStatusChange,
  systemAlert,
  promotion,
  review,
  analytics,
}

class RestaurantNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String? actionUrl;

  RestaurantNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.data,
    this.isRead = false,
    this.actionUrl,
  });

  factory RestaurantNotification.fromJson(Map<String, dynamic> json) {
    return RestaurantNotification(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.systemAlert,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }
}

class NotificationsProvider extends StateNotifier<List<RestaurantNotification>> {
  NotificationsProvider() : super([]);

  void addNotification(RestaurantNotification notification) {
    state = [notification, ...state];
    AppLogger.info('Notification added: ${notification.title}');
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if (notification.id == notificationId) {
        return RestaurantNotification(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          timestamp: notification.timestamp,
          data: notification.data,
          isRead: true,
          actionUrl: notification.actionUrl,
        );
      }
      return notification;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((notification) {
      return RestaurantNotification(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        timestamp: notification.timestamp,
        data: notification.data,
        isRead: true,
        actionUrl: notification.actionUrl,
      );
    }).toList();
  }

  void clearNotifications() {
    state = [];
    AppLogger.info('All notifications cleared');
  }

  void clearOldNotifications({Duration maxAge = const Duration(days: 7)}) {
    final cutoff = DateTime.now().subtract(maxAge);
    state = state.where((notification) => notification.timestamp.isAfter(cutoff)).toList();
  }

  int get unreadCount => state.where((n) => !n.isRead).length;

  List<RestaurantNotification> get unreadNotifications =>
      state.where((n) => !n.isRead).toList();
}

final notificationsProvider = StateNotifierProvider<NotificationsProvider, List<RestaurantNotification>>(
  (ref) => NotificationsProvider(),
);

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(notificationsProvider.notifier).unreadCount;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    ref.read(notificationsProvider.notifier).markAllAsRead();
                    break;
                  case 'clear_all':
                    _showClearAllDialog();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      Icon(Icons.mark_email_read),
                      SizedBox(width: 8),
                      Text('Mark all as read'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Clear all'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: notifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(notifications),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<RestaurantNotification> notifications) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(notification);
      },
    );
  }

  Widget _buildNotificationCard(RestaurantNotification notification) {
    final isRead = notification.isRead;
    final timeAgo = _formatTimeAgo(notification.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isRead ? null : Colors.blue.shade50,
      child: InkWell(
        onTap: () {
          // Mark as read
          ref.read(notificationsProvider.notifier).markAsRead(notification.id);

          // Navigate to action URL if available
          if (notification.actionUrl != null) {
            context.push(notification.actionUrl!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade500,
                              ),
                        ),
                        if (notification.actionUrl != null) ...[
                          const Spacer(),
                          Text(
                            'View',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color color;

    switch (type) {
      case NotificationType.newOrder:
        icon = Icons.receipt_long_rounded;
        color = Colors.green;
        break;
      case NotificationType.orderStatusChange:
        icon = Icons.sync_rounded;
        color = Colors.blue;
        break;
      case NotificationType.systemAlert:
        icon = Icons.warning_rounded;
        color = Colors.orange;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer_rounded;
        color = Colors.purple;
        break;
      case NotificationType.review:
        icon = Icons.star_rounded;
        color = Colors.amber;
        break;
      case NotificationType.analytics:
        icon = Icons.analytics_rounded;
        color = Colors.indigo;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        icon,
        color: color,
        size: 20,
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to clear all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearNotifications();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}