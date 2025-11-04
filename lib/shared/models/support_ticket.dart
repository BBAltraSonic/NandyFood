import 'package:equatable/equatable.dart';

enum SupportTicketCategory {
  orderIssues('order_issues', 'Order Issues'),
  paymentIssues('payment_issues', 'Payment Issues'),
  restaurantIssues('restaurant_issues', 'Restaurant Issues'),
  accountIssues('account_issues', 'Account Issues'),
  technicalIssues('technical_issues', 'Technical Issues'),
  other('other', 'Other');

  const SupportTicketCategory(this.value, this.label);
  final String value;
  final String label;

  static SupportTicketCategory fromString(String value) {
    return SupportTicketCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => SupportTicketCategory.other,
    );
  }
}

enum SupportTicketPriority {
  low('low', 'Low'),
  medium('medium', 'Medium'),
  high('high', 'High'),
  urgent('urgent', 'Urgent');

  const SupportTicketPriority(this.value, this.label);
  final String value;
  final String label;

  static SupportTicketPriority fromString(String value) {
    return SupportTicketPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => SupportTicketPriority.medium,
    );
  }
}

enum SupportTicketStatus {
  open('open', 'Open'),
  inProgress('in_progress', 'In Progress'),
  waitingOnCustomer('waiting_on_customer', 'Waiting on Customer'),
  resolved('resolved', 'Resolved'),
  closed('closed', 'Closed');

  const SupportTicketStatus(this.value, this.label);
  final String value;
  final String label;

  static SupportTicketStatus fromString(String value) {
    return SupportTicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SupportTicketStatus.open,
    );
  }

  bool get isActive => this == open || this == inProgress || this == waitingOnCustomer;
  bool get isClosed => this == resolved || this == closed;
}

class SupportTicket extends Equatable {
  const SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    this.orderId,
    this.restaurantId,
    this.assignedTo,
    this.rating,
    this.feedback,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: SupportTicketCategory.fromString(json['category'] as String),
      priority: SupportTicketPriority.fromString(json['priority'] as String),
      status: SupportTicketStatus.fromString(json['status'] as String),
      orderId: json['order_id'] as String?,
      restaurantId: json['restaurant_id'] as String?,
      assignedTo: json['assigned_to'] as String?,
      rating: (json['rating'] as int?)?.toInt(),
      feedback: json['feedback'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String subject;
  final String description;
  final SupportTicketCategory category;
  final SupportTicketPriority priority;
  final SupportTicketStatus status;
  final String? orderId;
  final String? restaurantId;
  final String? assignedTo;
  final int? rating;
  final String? feedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'subject': subject,
      'description': description,
      'category': category.value,
      'priority': priority.value,
      'status': status.value,
      'order_id': orderId,
      'restaurant_id': restaurantId,
      'assigned_to': assignedTo,
      'rating': rating,
      'feedback': feedback,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? subject,
    String? description,
    SupportTicketCategory? category,
    SupportTicketPriority? priority,
    SupportTicketStatus? status,
    String? orderId,
    String? restaurantId,
    String? assignedTo,
    int? rating,
    String? feedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      orderId: orderId ?? this.orderId,
      restaurantId: restaurantId ?? this.restaurantId,
      assignedTo: assignedTo ?? this.assignedTo,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        subject,
        description,
        category,
        priority,
        status,
        orderId,
        restaurantId,
        assignedTo,
        rating,
        feedback,
        createdAt,
        updatedAt,
      ];
}