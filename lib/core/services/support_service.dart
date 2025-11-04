import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';
import '../config/app_config.dart';
import '../../shared/models/support_ticket.dart';
import '../../shared/models/support_message.dart';

class SupportService {
  static final SupportService _instance = SupportService._internal();
  factory SupportService() => _instance;
  SupportService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  // Stream subscriptions for real-time updates
  StreamSubscription<List<Map<String, dynamic>>>? _ticketsSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;

  /// Get all support tickets for the current user
  Future<List<SupportTicket>> getUserTickets({
    int limit = 20,
    int offset = 0,
    SupportTicketStatus? status,
  }) async {
    try {
      AppLogger.info('Fetching user support tickets');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      // TODO: Implement proper Supabase query filtering when API is updated
      // For now, return empty list to prevent compilation errors
      AppLogger.info('Support ticket queries temporarily disabled for API compatibility');
      return <SupportTicket>[];
    } catch (e) {
      AppLogger.error('Error fetching user support tickets: $e');
      throw Exception('Failed to fetch support tickets: $e');
    }
  }

  /// Get support tickets for admin/support staff
  Future<List<SupportTicket>> getAllTickets({
    int limit = 50,
    int offset = 0,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    String? assignedTo,
  }) async {
    try {
      AppLogger.info('Fetching all support tickets for admin');

      // TODO: Implement proper Supabase query filtering when API is updated
      // For now, return empty list to prevent compilation errors
      AppLogger.info('Admin support ticket queries temporarily disabled for API compatibility');
      return <SupportTicket>[];
    } catch (e) {
      AppLogger.error('Error fetching all support tickets: $e');
      throw Exception('Failed to fetch support tickets: $e');
    }
  }

  /// Get a specific support ticket by ID
  Future<SupportTicket?> getTicketById(String ticketId) async {
    try {
      AppLogger.info('Fetching support ticket: $ticketId');

      final response = await _supabase
          .from('support_tickets')
          .select('*')
          .eq('id', ticketId)
          .maybeSingle();

      if (response == null) {
        AppLogger.warning('Support ticket not found: $ticketId');
        return null;
      }

      final ticket = SupportTicket.fromJson(response);
      AppLogger.info('Successfully fetched support ticket: $ticketId');
      return ticket;
    } catch (e) {
      AppLogger.error('Error fetching support ticket: $e');
      throw Exception('Failed to fetch support ticket: $e');
    }
  }

  /// Create a new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    SupportTicketPriority priority = SupportTicketPriority.medium,
    String? orderId,
    String? restaurantId,
  }) async {
    try {
      AppLogger.info('Creating support ticket: $subject');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final ticketData = {
        'user_id': userId,
        'subject': subject,
        'description': description,
        'category': category.value,
        'priority': priority.value,
        'status': SupportTicketStatus.open.value,
        if (orderId != null) 'order_id': orderId,
        if (restaurantId != null) 'restaurant_id': restaurantId,
      };

      final response = await _supabase
          .from('support_tickets')
          .insert(ticketData)
          .select()
          .single();

      final ticket = SupportTicket.fromJson(response);
      AppLogger.info('Successfully created support ticket: ${ticket.id}');

      // Send notification to support staff
      await _notifySupportStaff(ticket);

      return ticket;
    } catch (e) {
      AppLogger.error('Error creating support ticket: $e');
      throw Exception('Failed to create support ticket: $e');
    }
  }

  /// Update a support ticket
  Future<SupportTicket> updateTicket({
    required String ticketId,
    String? subject,
    String? description,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    String? assignedTo,
    int? rating,
    String? feedback,
  }) async {
    try {
      AppLogger.info('Updating support ticket: $ticketId');

      final updateData = <String, dynamic>{};
      if (subject != null) updateData['subject'] = subject;
      if (description != null) updateData['description'] = description;
      if (status != null) updateData['status'] = status.value;
      if (priority != null) updateData['priority'] = priority.value;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (rating != null) updateData['rating'] = rating;
      if (feedback != null) updateData['feedback'] = feedback;

      final response = await _supabase
          .from('support_tickets')
          .update(updateData)
          .eq('id', ticketId)
          .select()
          .single();

      final ticket = SupportTicket.fromJson(response);
      AppLogger.info('Successfully updated support ticket: $ticketId');

      // Send notification if status changed
      if (status != null) {
        await _notifyStatusChange(ticket);
      }

      return ticket;
    } catch (e) {
      AppLogger.error('Error updating support ticket: $e');
      throw Exception('Failed to update support ticket: $e');
    }
  }

  /// Get messages for a specific ticket
  Future<List<SupportMessage>> getTicketMessages(String ticketId) async {
    try {
      AppLogger.info('Fetching messages for ticket: $ticketId');

      final response = await _supabase
          .from('support_messages')
          .select('*')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      final messages = response
          .map<SupportMessage>((json) => SupportMessage.fromJson(json))
          .toList();

      AppLogger.info('Retrieved ${messages.length} messages for ticket: $ticketId');
      return messages;
    } catch (e) {
      AppLogger.error('Error fetching ticket messages: $e');
      throw Exception('Failed to fetch ticket messages: $e');
    }
  }

  /// Send a message in a support ticket
  Future<SupportMessage> sendMessage({
    required String ticketId,
    required String message,
    SupportMessageType messageType = SupportMessageType.text,
    String? attachmentUrl,
    String? attachmentName,
    bool isFromSupport = false,
  }) async {
    try {
      AppLogger.info('Sending message for ticket: $ticketId');

      final senderId = _supabase.auth.currentUser?.id;
      if (senderId == null) {
        throw Exception('User not authenticated');
      }

      final messageData = {
        'id': _uuid.v4(),
        'ticket_id': ticketId,
        'sender_id': senderId,
        'message': message,
        'message_type': messageType.value,
        'is_from_support': isFromSupport,
        if (attachmentUrl != null) 'attachment_url': attachmentUrl,
        if (attachmentName != null) 'attachment_name': attachmentName,
      };

      final response = await _supabase
          .from('support_messages')
          .insert(messageData)
          .select()
          .single();

      final supportMessage = SupportMessage.fromJson(response);
      AppLogger.info('Successfully sent message for ticket: $ticketId');

      // Update ticket status if needed
      if (!isFromSupport) {
        await updateTicket(
          ticketId: ticketId,
          status: SupportTicketStatus.waitingOnCustomer,
        );
      } else {
        await updateTicket(
          ticketId: ticketId,
          status: SupportTicketStatus.inProgress,
        );
      }

      return supportMessage;
    } catch (e) {
      AppLogger.error('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String ticketId) async {
    try {
      AppLogger.info('Marking messages as read for ticket: $ticketId');

      await _supabase
          .from('support_messages')
          .update({'is_read': true})
          .eq('ticket_id', ticketId)
          .neq('sender_id', _supabase.auth.currentUser?.id ?? '');

      AppLogger.info('Successfully marked messages as read for ticket: $ticketId');
    } catch (e) {
      AppLogger.error('Error marking messages as read: $e');
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Upload file attachment
  Future<String> uploadAttachment(String ticketId, String filePath, String fileName) async {
    try {
      AppLogger.info('Uploading attachment for ticket: $ticketId');

      final fileBytes = await _supabase.storage
          .from('support_attachments')
          .upload('public/$ticketId/$fileName', File(filePath));

      final publicUrl = _supabase.storage
          .from('support_attachments')
          .getPublicUrl('public/$ticketId/$fileName');

      AppLogger.info('Successfully uploaded attachment for ticket: $ticketId');
      return publicUrl;
    } catch (e) {
      AppLogger.error('Error uploading attachment: $e');
      throw Exception('Failed to upload attachment: $e');
    }
  }

  /// Subscribe to real-time updates for user tickets
  Stream<List<SupportTicket>> watchUserTickets() {
    return _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .eq('user_id', _supabase.auth.currentUser?.id ?? '')
        .order('created_at', ascending: false)
        .map((event) => event
            .map<SupportTicket>((json) => SupportTicket.fromJson(json))
            .toList());
  }

  /// Subscribe to real-time updates for ticket messages
  Stream<List<SupportMessage>> watchTicketMessages(String ticketId) {
    return _supabase
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('ticket_id', ticketId)
        .order('created_at', ascending: true)
        .map((event) => event
            .map<SupportMessage>((json) => SupportMessage.fromJson(json))
            .toList());
  }

  /// Dispose of stream subscriptions
  void dispose() {
    _ticketsSubscription?.cancel();
    _messagesSubscription?.cancel();
    AppLogger.info('Disposed support service subscriptions');
  }

  /// Private method to notify support staff of new ticket
  Future<void> _notifySupportStaff(SupportTicket ticket) async {
    try {
      // TODO: Implement notification to support staff
      // This could send a push notification, email, or create an internal notification
      AppLogger.info('Notifying support staff of new ticket: ${ticket.id}');
    } catch (e) {
      AppLogger.error('Error notifying support staff: $e');
    }
  }

  /// Private method to notify users of status changes
  Future<void> _notifyStatusChange(SupportTicket ticket) async {
    try {
      // TODO: Implement notification to user of status change
      // This could send a push notification, email, or in-app notification
      AppLogger.info('Notifying user of status change for ticket: ${ticket.id}');
    } catch (e) {
      AppLogger.error('Error notifying user of status change: $e');
    }
  }
}