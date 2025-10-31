// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_call.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderCall _$OrderCallFromJson(Map<String, dynamic> json) => OrderCall(
  id: json['id'] as String,
  conversationId: json['conversation_id'] as String,
  orderId: json['order_id'] as String,
  initiatorId: json['initiator_id'] as String?,
  receiverId: json['receiver_id'] as String?,
  callType: $enumDecode(_$CallTypeEnumMap, json['call_type']),
  status: json['status'] as String,
  duration: (json['duration'] as num?)?.toInt() ?? 0,
  connectionQuality: json['connection_quality'] as String?,
  signalStrength: (json['signal_strength'] as num?)?.toInt(),
  rtcSessionId: json['rtc_session_id'] as String?,
  signalingServer: json['signaling_server'] as String?,
  initiatedAt: DateTime.parse(json['initiated_at'] as String),
  connectedAt: json['connected_at'] == null
      ? null
      : DateTime.parse(json['connected_at'] as String),
  endedAt: json['ended_at'] == null
      ? null
      : DateTime.parse(json['ended_at'] as String),
  endReason: json['end_reason'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
  initiatorName: json['initiatorName'] as String?,
  receiverName: json['receiverName'] as String?,
  initiatorAvatar: json['initiatorAvatar'] as String?,
  receiverAvatar: json['receiverAvatar'] as String?,
  isInitiatedByMe: json['isInitiatedByMe'] as bool?,
  isWithMe: json['isWithMe'] as bool?,
);

Map<String, dynamic> _$OrderCallToJson(OrderCall instance) => <String, dynamic>{
  'id': instance.id,
  'conversation_id': instance.conversationId,
  'order_id': instance.orderId,
  'initiator_id': instance.initiatorId,
  'receiver_id': instance.receiverId,
  'call_type': _$CallTypeEnumMap[instance.callType]!,
  'status': instance.status,
  'duration': instance.duration,
  'connection_quality': instance.connectionQuality,
  'signal_strength': instance.signalStrength,
  'rtc_session_id': instance.rtcSessionId,
  'signaling_server': instance.signalingServer,
  'initiated_at': instance.initiatedAt.toIso8601String(),
  'connected_at': instance.connectedAt?.toIso8601String(),
  'ended_at': instance.endedAt?.toIso8601String(),
  'end_reason': instance.endReason,
  'metadata': instance.metadata,
  'initiatorName': instance.initiatorName,
  'receiverName': instance.receiverName,
  'initiatorAvatar': instance.initiatorAvatar,
  'receiverAvatar': instance.receiverAvatar,
  'isInitiatedByMe': instance.isInitiatedByMe,
  'isWithMe': instance.isWithMe,
};

const _$CallTypeEnumMap = {CallType.voice: 'voice', CallType.video: 'video'};
