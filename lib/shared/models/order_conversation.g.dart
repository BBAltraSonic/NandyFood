// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderConversation _$OrderConversationFromJson(Map<String, dynamic> json) =>
    OrderConversation(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      restaurantId: json['restaurant_id'] as String,
      customerId: json['customer_id'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      lastActivityAt: json['last_activity_at'] == null
          ? null
          : DateTime.parse(json['last_activity_at'] as String),
      isMuted: json['is_muted'] as bool? ?? false,
      autoTranslate: json['auto_translate'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
      restaurantName: json['restaurantName'] as String?,
      customerName: json['customerName'] as String?,
      lastMessage: json['lastMessage'] == null
          ? null
          : OrderMessage.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] as num?)?.toInt(),
      orderStatus: json['orderStatus'] as String?,
      activityStatus: json['activityStatus'] as String?,
    );

Map<String, dynamic> _$OrderConversationToJson(OrderConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'restaurant_id': instance.restaurantId,
      'customer_id': instance.customerId,
      'title': instance.title,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'last_message_at': instance.lastMessageAt?.toIso8601String(),
      'last_activity_at': instance.lastActivityAt?.toIso8601String(),
      'is_muted': instance.isMuted,
      'auto_translate': instance.autoTranslate,
      'metadata': instance.metadata,
      'restaurantName': instance.restaurantName,
      'customerName': instance.customerName,
      'lastMessage': instance.lastMessage,
      'unreadCount': instance.unreadCount,
      'orderStatus': instance.orderStatus,
      'activityStatus': instance.activityStatus,
    };
