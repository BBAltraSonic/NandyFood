import 'package:equatable/equatable.dart';

enum SupportMessageType {
  text('text', 'Text'),
  image('image', 'Image'),
  file('file', 'File'),
  system('system', 'System');

  const SupportMessageType(this.value, this.label);
  final String value;
  final String label;

  static SupportMessageType fromString(String value) {
    return SupportMessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SupportMessageType.text,
    );
  }
}

class SupportMessage extends Equatable {
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.message,
    required this.messageType,
    this.attachmentUrl,
    this.attachmentName,
    this.isFromSupport = false,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      messageType: SupportMessageType.fromString(json['message_type'] as String),
      attachmentUrl: json['attachment_url'] as String?,
      attachmentName: json['attachment_name'] as String?,
      isFromSupport: json['is_from_support'] as bool? ?? false,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String ticketId;
  final String senderId;
  final String message;
  final SupportMessageType messageType;
  final String? attachmentUrl;
  final String? attachmentName;
  final bool isFromSupport;
  final bool isRead;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType.value,
      'attachment_url': attachmentUrl,
      'attachment_name': attachmentName,
      'is_from_support': isFromSupport,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SupportMessage copyWith({
    String? id,
    String? ticketId,
    String? senderId,
    String? message,
    SupportMessageType? messageType,
    String? attachmentUrl,
    String? attachmentName,
    bool? isFromSupport,
    bool? isRead,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentName: attachmentName ?? this.attachmentName,
      isFromSupport: isFromSupport ?? this.isFromSupport,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isTextMessage => messageType == SupportMessageType.text;
  bool get isImageMessage => messageType == SupportMessageType.image;
  bool get isFileMessage => messageType == SupportMessageType.file;
  bool get isSystemMessage => messageType == SupportMessageType.system;

  @override
  List<Object?> get props => [
        id,
        ticketId,
        senderId,
        message,
        messageType,
        attachmentUrl,
        attachmentName,
        isFromSupport,
        isRead,
        createdAt,
        updatedAt,
      ];
}