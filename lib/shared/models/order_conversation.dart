import 'package:json_annotation/json_annotation.dart';
import 'package:food_delivery_app/shared/models/order_message.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

part 'order_conversation.g.dart';

@JsonSerializable()
class OrderConversation {
  final String id;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'restaurant_id')
  final String restaurantId;
  @JsonKey(name: 'customer_id')
  final String customerId;
  final String title;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'last_message_at')
  final DateTime? lastMessageAt;
  @JsonKey(name: 'last_activity_at')
  final DateTime? lastActivityAt;
  @JsonKey(name: 'is_muted')
  final bool isMuted;
  @JsonKey(name: 'auto_translate')
  final bool autoTranslate;
  final Map<String, dynamic> metadata;

  // Additional fields from joins
  final String? restaurantName;
  final String? customerName;
  final OrderMessage? lastMessage;
  final int? unreadCount;
  final String? orderStatus;
  final String? activityStatus;

  const OrderConversation({
    required this.id,
    required this.orderId,
    required this.restaurantId,
    required this.customerId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastActivityAt,
    this.isMuted = false,
    this.autoTranslate = true,
    this.metadata = const {},
    this.restaurantName,
    this.customerName,
    this.lastMessage,
    this.unreadCount,
    this.orderStatus,
    this.activityStatus,
  });

  factory OrderConversation.fromJson(Map<String, dynamic> json) => _$OrderConversationFromJson(json);

  Map<String, dynamic> toJson() => _$OrderConversationToJson(this);

  /// Getters for convenience
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';
  bool get isCompleted => status == 'completed';
  bool get hasUnreadMessages => (unreadCount ?? 0) > 0;

  /// Get activity status based on last activity
  String get displayActivityStatus {
    if (activityStatus != null) return activityStatus!;

    if (lastActivityAt == null) return 'inactive';

    final now = DateTime.now();
    final difference = now.difference(lastActivityAt!);

    if (difference.inMinutes < 5) return 'active';
    if (difference.inHours < 1) return 'recent';
    return 'inactive';
  }

  /// Get formatted last activity time
  String get lastActivityText {
    if (lastActivityAt == null) return 'No activity';

    final now = DateTime.now();
    final difference = now.difference(lastActivityAt!);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  /// Check if conversation is accessible for user
  bool isAccessibleForUser(String userId) {
    return customerId == userId || isActive;
  }

  /// Get conversation display name for a user
  String getDisplayNameForUser(String userId) {
    if (customerId == userId) {
      return restaurantName ?? 'Restaurant';
    } else {
      return customerName ?? 'Customer';
    }
  }

  /// Get conversation subtitle for display
  String getSubtitleForUser(String userId) {
    if (lastMessage != null) {
      return lastMessage!.getDisplayText();
    }

    if (orderStatus != null) {
      switch (orderStatus!) {
        case 'confirmed':
          return 'Order confirmed';
        case 'preparing':
          return 'Preparing your order';
        case 'ready_for_pickup':
          return 'Ready for pickup';
        case 'cancelled':
          return 'Order cancelled';
        default:
          return 'Order updated';
      }
    }

    return 'Start a conversation';
  }

  OrderConversation copyWith({
    String? id,
    String? orderId,
    String? restaurantId,
    String? customerId,
    String? title,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    DateTime? lastActivityAt,
    bool? isMuted,
    bool? autoTranslate,
    Map<String, dynamic>? metadata,
    String? restaurantName,
    String? customerName,
    OrderMessage? lastMessage,
    int? unreadCount,
    String? orderStatus,
    String? activityStatus,
  }) {
    return OrderConversation(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      restaurantId: restaurantId ?? this.restaurantId,
      customerId: customerId ?? this.customerId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      isMuted: isMuted ?? this.isMuted,
      autoTranslate: autoTranslate ?? this.autoTranslate,
      metadata: metadata ?? this.metadata,
      restaurantName: restaurantName ?? this.restaurantName,
      customerName: customerName ?? this.customerName,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      orderStatus: orderStatus ?? this.orderStatus,
      activityStatus: activityStatus ?? this.activityStatus,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderConversation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OrderConversation(id: $id, orderId: $orderId, title: $title)';
}

/// Conversation status enum
enum ConversationStatus {
  @JsonValue('active')
  active,
  @JsonValue('completed')
  completed,
  @JsonValue('archived')
  archived,
}

/// Activity status enum
enum ActivityStatus {
  active,
  recent,
  inactive,
}