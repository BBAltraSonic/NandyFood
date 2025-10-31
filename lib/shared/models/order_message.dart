import 'package:json_annotation/json_annotation.dart';

part 'order_message.g.dart';

@JsonSerializable()
class OrderMessage {
  final String id;
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  @JsonKey(name: 'order_id')
  final String orderId;
  @JsonKey(name: 'sender_id')
  final String? senderId;
  final String content;
  @JsonKey(name: 'message_type')
  final MessageType messageType;
  final String status;

  // Media attachments
  @JsonKey(name: 'file_url')
  final String? fileUrl;
  @JsonKey(name: 'file_type')
  final String? fileType;
  @JsonKey(name: 'file_size')
  final int? fileSize;
  @JsonKey(name: 'file_name')
  final String? fileName;

  // Voice message specifics
  @JsonKey(name: 'voice_duration')
  final int? voiceDuration; // in seconds
  @JsonKey(name: 'voice_waveform')
  final List<double>? voiceWaveform; // waveform data

  // Call specifics
  @JsonKey(name: 'call_id')
  final String? callId;
  @JsonKey(name: 'call_duration')
  final int? callDuration; // in seconds
  @JsonKey(name: 'call_type')
  final String? callType; // 'voice', 'video'

  // Timestamps
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;

  final Map<String, dynamic> metadata;

  // Additional fields from joins
  final String? senderName;
  final String? senderAvatar;
  final bool? isFromMe;
  final bool? isRead;

  const OrderMessage({
    required this.id,
    required this.conversationId,
    required this.orderId,
    this.senderId,
    required this.content,
    required this.messageType,
    required this.status,
    this.fileUrl,
    this.fileType,
    this.fileSize,
    this.fileName,
    this.voiceDuration,
    this.voiceWaveform,
    this.callId,
    this.callDuration,
    this.callType,
    required this.createdAt,
    required this.updatedAt,
    this.readAt,
    this.metadata = const {},
    this.senderName,
    this.senderAvatar,
    this.isFromMe,
    this.isRead,
  });

  factory OrderMessage.fromJson(Map<String, dynamic> json) => _$OrderMessageFromJson(json);

  Map<String, dynamic> toJson() => _$OrderMessageToJson(this);

  /// Getters for convenience
  bool get isTextMessage => messageType == MessageType.text;
  bool get isImageMessage => messageType == MessageType.image;
  bool get isVoiceMessage => messageType == MessageType.voice;
  bool get isFileMessage => messageType == MessageType.file;
  bool get isCallMessage => messageType == MessageType.callStarted || messageType == MessageType.callEnded;
  bool get isSystemMessage => messageType == MessageType.orderStatus;
  bool get isSent => status == 'sent';
  bool get isDelivered => status == 'delivered';
  bool get isReadStatus => status == 'read';
  bool get isFailed => status == 'failed';

  /// Check if message is from current user
  bool get isFromCurrentUser => isFromMe ?? false;

  /// Get display text for message
  String getDisplayText() {
    if (isSystemMessage) return content;
    if (isCallMessage) return content;
    if (isTextMessage && content.isNotEmpty) return content;
    if (isVoiceMessage) return '🎙️ Voice message';
    if (isImageMessage) return '📷 Image';
    if (isFileMessage) return '📎 File';
    return content;
  }

  /// Get formatted time for display
  String getFormattedTime({bool showDate = false}) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (showDate || difference.inDays > 0) {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }

    if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    }

    if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    }

    return 'Just now';
  }

  /// Get file size formatted text
  String? getFormattedFileSize() {
    if (fileSize == null) return null;

    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    if (fileSize! < 1024 * 1024 * 1024) return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(fileSize! / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Get voice duration formatted text
  String getFormattedVoiceDuration() {
    if (voiceDuration == null) return '';

    final minutes = (voiceDuration! ~/ 60);
    final seconds = voiceDuration! % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get call duration formatted text
  String getFormattedCallDuration() {
    if (callDuration == null || callDuration == 0) return '';

    final minutes = (callDuration! ~/ 60);
    final seconds = callDuration! % 60;

    if (minutes > 0) {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '0:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Check if message has been read by recipient
  bool get isReadByRecipient => isRead ?? (readAt != null);

  OrderMessage copyWith({
    String? id,
    String? conversationId,
    String? orderId,
    String? senderId,
    String? content,
    MessageType? messageType,
    String? status,
    String? fileUrl,
    String? fileType,
    int? fileSize,
    String? fileName,
    int? voiceDuration,
    List<double>? voiceWaveform,
    String? callId,
    int? callDuration,
    String? callType,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readAt,
    Map<String, dynamic>? metadata,
    String? senderName,
    String? senderAvatar,
    bool? isFromMe,
    bool? isRead,
  }) {
    return OrderMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      orderId: orderId ?? this.orderId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      status: status ?? this.status,
      fileUrl: fileUrl ?? this.fileUrl,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      fileName: fileName ?? this.fileName,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      voiceWaveform: voiceWaveform ?? this.voiceWaveform,
      callId: callId ?? this.callId,
      callDuration: callDuration ?? this.callDuration,
      callType: callType ?? this.callType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readAt: readAt ?? this.readAt,
      metadata: metadata ?? this.metadata,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      isFromMe: isFromMe ?? this.isFromMe,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderMessage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'OrderMessage(id: $id, type: $messageType, content: $content)';
}

/// Message type enum
enum MessageType {
  @JsonValue('text')
  text,
  @JsonValue('image')
  image,
  @JsonValue('voice')
  voice,
  @JsonValue('file')
  file,
  @JsonValue('call_started')
  callStarted,
  @JsonValue('call_ended')
  callEnded,
  @JsonValue('order_status')
  orderStatus,
}

/// Message status enum
enum MessageStatus {
  @JsonValue('sent')
  sent,
  @JsonValue('delivered')
  delivered,
  @JsonValue('read')
  read,
  @JsonValue('failed')
  failed,
}