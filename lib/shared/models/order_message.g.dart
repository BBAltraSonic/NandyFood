// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderMessage _$OrderMessageFromJson(Map<String, dynamic> json) => OrderMessage(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  orderId: json['order_id'] as String,
  senderId: json['sender_id'] as String?,
  content: json['content'] as String,
  messageType: $enumDecode(_$MessageTypeEnumMap, json['message_type']),
  status: json['status'] as String,
  fileUrl: json['file_url'] as String?,
  fileType: json['file_type'] as String?,
  fileSize: (json['file_size'] as num?)?.toInt(),
  fileName: json['file_name'] as String?,
  voiceDuration: (json['voice_duration'] as num?)?.toInt(),
  voiceWaveform: (json['voice_waveform'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  callId: json['call_id'] as String?,
  callDuration: (json['call_duration'] as num?)?.toInt(),
  callType: json['call_type'] as String?,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  readAt: json['read_at'] == null
      ? null
      : DateTime.parse(json['read_at'] as String),
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  senderName: json['senderName'] as String?,
  senderAvatar: json['senderAvatar'] as String?,
  isFromMe: json['isFromMe'] as bool?,
  isRead: json['isRead'] as bool?,
);

Map<String, dynamic> _$OrderMessageToJson(OrderMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'order_id': instance.orderId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'message_type': _$MessageTypeEnumMap[instance.messageType]!,
      'status': instance.status,
      'file_url': instance.fileUrl,
      'file_type': instance.fileType,
      'file_size': instance.fileSize,
      'file_name': instance.fileName,
      'voice_duration': instance.voiceDuration,
      'voice_waveform': instance.voiceWaveform,
      'call_id': instance.callId,
      'call_duration': instance.callDuration,
      'call_type': instance.callType,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'read_at': instance.readAt?.toIso8601String(),
      'metadata': instance.metadata,
      'senderName': instance.senderName,
      'senderAvatar': instance.senderAvatar,
      'isFromMe': instance.isFromMe,
      'isRead': instance.isRead,
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'text',
  MessageType.image: 'image',
  MessageType.voice: 'voice',
  MessageType.file: 'file',
  MessageType.callStarted: 'call_started',
  MessageType.callEnded: 'call_ended',
  MessageType.orderStatus: 'order_status',
};
