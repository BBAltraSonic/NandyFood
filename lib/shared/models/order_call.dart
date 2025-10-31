import 'package:json_annotation/json_annotation.dart';

part 'order_call.g.dart';

@JsonSerializable()
class OrderCall {
  final String id;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'order_id')
  final String orderId;

  // Call participants
  @JsonKey(name: 'initiator_id')
  final String? initiatorId;
  @JsonKey(name: 'receiver_id')
  final String? receiverId;

  // Call details
  @JsonKey(name: 'call_type')
  final CallType callType;
  final String status;
  final int duration; // in seconds

  // Call quality metrics
  @JsonKey(name: 'connection_quality')
  final String? connectionQuality;
  @JsonKey(name: 'signal_strength')
  final int? signalStrength;

  // Technical details
  @JsonKey(name: 'rtc_session_id')
  final String? rtcSessionId;
  @JsonKey(name: 'signaling_server')
  final String? signalingServer;

  // Timestamps
  @JsonKey(name: 'initiated_at')
  final DateTime initiatedAt;
  @JsonKey(name: 'connected_at')
  final DateTime? connectedAt;
  @JsonKey(name: 'ended_at')
  final DateTime? endedAt;

  // End reason
  @JsonKey(name: 'end_reason')
  final String? endReason;

  final Map<String, dynamic> metadata;

  // Additional fields from joins
  final String? initiatorName;
  final String? receiverName;
  final String? initiatorAvatar;
  final String? receiverAvatar;
  final bool? isInitiatedByMe;
  final bool? isWithMe;

  const OrderCall({
    required this.id,
    required this.conversationId,
    required this.orderId,
    this.initiatorId,
    this.receiverId,
    required this.callType,
    required this.status,
    this.duration = 0,
    this.connectionQuality,
    this.signalStrength,
    this.rtcSessionId,
    this.signalingServer,
    required this.initiatedAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
    this.metadata = const {},
    this.initiatorName,
    this.receiverName,
    this.initiatorAvatar,
    this.receiverAvatar,
    this.isInitiatedByMe,
    this.isWithMe,
  });

  factory OrderCall.fromJson(Map<String, dynamic> json) => _$OrderCallFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCallToJson(this);

  /// Getters for convenience
  bool get isVoiceCall => callType == CallType.voice;
  bool get isVideoCall => callType == CallType.video;
  bool get isInitiated => status == 'initiated';
  bool get isRinging => status == 'ringing';
  bool get isConnected => status == 'connected';
  bool get isEnded => status == 'ended';
  bool get isMissed => status == 'missed';
  bool get isFailed => status == 'failed';
  bool get isActive => !isEnded && !isMissed && !isFailed;

  /// Check if call is from current user
  bool get isFromCurrentUser => isInitiatedByMe ?? false;

  /// Check if call is with current user
  bool get isWithCurrentUser => isWithMe ?? false;

  /// Get call duration text
  String getFormattedDuration() {
    if (duration == 0 && connectedAt != null && endedAt != null) {
      final callDuration = endedAt!.difference(connectedAt!).inSeconds;
      return _formatDuration(callDuration);
    }
    return _formatDuration(duration);
  }

  /// Get formatted duration
  String _formatDuration(int seconds) {
    if (seconds == 0) return '0:00';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Get call status display text
  String getDisplayStatus() {
    switch (status) {
      case 'initiated':
        return 'Initiating call...';
      case 'ringing':
        return 'Ringing...';
      case 'connected':
        return isConnected ? 'In call' : 'Call ended';
      case 'ended':
        return 'Call ended';
      case 'missed':
        return 'Missed call';
      case 'failed':
        return 'Call failed';
      default:
        return 'Unknown status';
    }
  }

  /// Get call end reason display text
  String getDisplayEndReason() {
    if (endReason == null) return '';

    switch (endReason) {
      case 'user_hung_up':
        return 'Call ended';
      case 'connection_lost':
        return 'Connection lost';
      case 'call_rejected':
        return 'Call declined';
      case 'timeout':
        return 'No response';
      default:
        return endReason ?? 'Unknown error';
    }
  }

  /// Get connection quality display
  String? getConnectionQualityDisplay() {
    if (connectionQuality == null) return null;

    switch (connectionQuality) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      case 'poor':
        return 'Poor';
      default:
        return connectionQuality;
    }
  }

  /// Get signal strength percentage
  int? getSignalStrengthPercentage() {
    if (signalStrength == null) return null;
    return (signalStrength! / 5 * 100).round();
  }

  /// Check if call has good quality
  bool get hasGoodQuality {
    return connectionQuality != null &&
        ['excellent', 'good'].contains(connectionQuality);
  }

  /// Get total call time in minutes
  double get durationInMinutes {
    return duration / 60;
  }

  /// Get formatted call time for display
  String getFormattedCallTime({bool showDate = false}) {
    final now = DateTime.now();
    final difference = now.difference(initiatedAt);

    if (showDate || difference.inDays > 0) {
      return '${initiatedAt.day}/${initiatedAt.month}/${initiatedAt.year}';
    }

    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }

    return 'Just now';
  }

  /// Get participant display name
  String getParticipantName({bool isInitiator = true}) {
    if (isInitiator) {
      return initiatorName ?? 'Unknown';
    } else {
      return receiverName ?? 'Unknown';
    }
  }

  /// Alias for getParticipantName for backward compatibility
  String participantName({bool isInitiator = true}) {
    return getParticipantName(isInitiator: isInitiator);
  }

  OrderCall copyWith({
    String? id,
    String? conversationId,
    String? orderId,
    String? initiatorId,
    String? receiverId,
    CallType? callType,
    String? status,
    int? duration,
    String? connectionQuality,
    int? signalStrength,
    String? rtcSessionId,
    String? signalingServer,
    DateTime? initiatedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    String? endReason,
    Map<String, dynamic>? metadata,
    String? initiatorName,
    String? receiverName,
    String? initiatorAvatar,
    String? receiverAvatar,
    bool? isInitiatedByMe,
    bool? isWithMe,
  }) {
    return OrderCall(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      orderId: orderId ?? this.orderId,
      initiatorId: initiatorId ?? this.initiatorId,
      receiverId: receiverId ?? this.receiverId,
      callType: callType ?? this.callType,
      status: status ?? this.status,
      duration: duration ?? this.duration,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      signalStrength: signalStrength ?? this.signalStrength,
      rtcSessionId: rtcSessionId ?? this.rtcSessionId,
      signalingServer: signalingServer ?? this.signalingServer,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
      metadata: metadata ?? this.metadata,
      initiatorName: initiatorName ?? this.initiatorName,
      receiverName: receiverName ?? this.receiverName,
      initiatorAvatar: initiatorAvatar ?? this.initiatorAvatar,
      receiverAvatar: receiverAvatar ?? this.receiverAvatar,
      isInitiatedByMe: isInitiatedByMe ?? this.isInitiatedByMe,
      isWithMe: isWithMe ?? this.isWithMe,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderCall &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OrderCall(id: $id, type: $callType, status: $status)';
}

/// Call type enum
enum CallType {
  @JsonValue('voice')
  voice,
  @JsonValue('video')
  video,
}

/// Call status enum
enum CallStatus {
  @JsonValue('initiated')
  initiated,
  @JsonValue('ringing')
  ringing,
  @JsonValue('connected')
  connected,
  @JsonValue('ended')
  ended,
  @JsonValue('missed')
  missed,
  @JsonValue('failed')
  failed,
}

/// Connection quality enum
enum ConnectionQuality {
  excellent,
  good,
  fair,
  poor,
}