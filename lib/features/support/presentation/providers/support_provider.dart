import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/services/support_service.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import 'package:food_delivery_app/shared/models/support_message.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

// Support service provider
final supportServiceProvider = Provider<SupportService>((ref) {
  return SupportService();
});

// Loading states
class SupportState {
  const SupportState({
    this.tickets = const [],
    this.selectedTicket,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMessages = false,
    this.isCreatingTicket = false,
    this.isSendingMessage = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
    this.hasMoreMessages = true,
    this.currentMessagePage = 0,
  });

  final List<SupportTicket> tickets;
  final SupportTicket? selectedTicket;
  final List<SupportMessage> messages;
  final bool isLoading;
  final bool isLoadingMessages;
  final bool isCreatingTicket;
  final bool isSendingMessage;
  final String? error;
  final bool hasMore;
  final int currentPage;
  final bool hasMoreMessages;
  final int currentMessagePage;

  SupportState copyWith({
    List<SupportTicket>? tickets,
    SupportTicket? selectedTicket,
    List<SupportMessage>? messages,
    bool? isLoading,
    bool? isLoadingMessages,
    bool? isCreatingTicket,
    bool? isSendingMessage,
    String? error,
    bool? hasMore,
    int? currentPage,
    bool? hasMoreMessages,
    int? currentMessagePage,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      selectedTicket: selectedTicket ?? this.selectedTicket,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMessages: isLoadingMessages ?? this.isLoadingMessages,
      isCreatingTicket: isCreatingTicket ?? this.isCreatingTicket,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      currentMessagePage: currentMessagePage ?? this.currentMessagePage,
    );
  }

  SupportState clearError() {
    return copyWith(error: null);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupportState &&
        other.tickets == tickets &&
        other.selectedTicket == selectedTicket &&
        other.messages == messages &&
        other.isLoading == isLoading &&
        other.isLoadingMessages == isLoadingMessages &&
        other.isCreatingTicket == isCreatingTicket &&
        other.isSendingMessage == isSendingMessage &&
        other.error == error &&
        other.hasMore == hasMore &&
        other.currentPage == currentPage &&
        other.hasMoreMessages == hasMoreMessages &&
        other.currentMessagePage == currentMessagePage;
  }

  @override
  int get hashCode {
    return Object.hash(
      tickets,
      selectedTicket,
      messages,
      isLoading,
      isLoadingMessages,
      isCreatingTicket,
      isSendingMessage,
      error,
      hasMore,
      currentPage,
      hasMoreMessages,
      currentMessagePage,
    );
  }
}

// Support provider for customers
class SupportNotifier extends StateNotifier<SupportState> {
  final SupportService _supportService;
  // AppLogger is static, no instance needed
  StreamSubscription<List<SupportTicket>>? _ticketsSubscription;
  StreamSubscription<List<SupportMessage>>? _messagesSubscription;

  SupportNotifier(this._supportService) : super(const SupportState()) {
    _initializeRealtimeSubscriptions();
  }

  Future<void> _initializeRealtimeSubscriptions() async {
    try {
      // Subscribe to user's tickets
      _ticketsSubscription = _supportService.watchUserTickets().listen(
        (tickets) {
          state = state.copyWith(tickets: tickets, isLoading: false);
        },
        onError: (error) {
          AppLogger.error('Error in tickets subscription: $error');
          state = state.copyWith(error: error.toString());
        },
      );
    } catch (e) {
      AppLogger.error('Error initializing subscriptions: $e');
    }
  }

  Future<void> loadTickets({
    bool refresh = false,
    SupportTicketStatus? status,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = refresh ? 0 : state.currentPage;
      final tickets = await _supportService.getUserTickets(
        limit: 20,
        offset: page * 20,
        status: status,
      );

      final allTickets = refresh ? tickets : [...state.tickets, ...tickets];
      final hasMore = tickets.length >= 20;

      state = state.copyWith(
        tickets: allTickets,
        isLoading: false,
        hasMore: hasMore,
        currentPage: page + 1,
      );
    } catch (e) {
      AppLogger.error('Error loading tickets: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadMoreTickets({SupportTicketStatus? status}) async {
    if (!state.hasMore || state.isLoading) return;
    await loadTickets(status: status);
  }

  Future<void> selectTicket(String ticketId) async {
    state = state.copyWith(selectedTicket: null, messages: [], error: null);

    try {
      final ticket = await _supportService.getTicketById(ticketId);
      if (ticket != null) {
        state = state.copyWith(selectedTicket: ticket);
        await loadMessages(ticketId);

        // Subscribe to messages for this ticket
        _messagesSubscription?.cancel();
        _messagesSubscription = _supportService
            .watchTicketMessages(ticketId)
            .listen(
              (messages) {
                state = state.copyWith(
                  messages: messages,
                  isLoadingMessages: false,
                );
              },
              onError: (error) {
                AppLogger.error('Error in messages subscription: $error');
                state = state.copyWith(error: error.toString());
              },
            );

        // Mark messages as read
        await _supportService.markMessagesAsRead(ticketId);
      }
    } catch (e) {
      AppLogger.error('Error selecting ticket: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMessages(String ticketId, {bool refresh = false}) async {
    if (state.isLoadingMessages && !refresh) return;

    state = state.copyWith(isLoadingMessages: true);

    try {
      final page = refresh ? 0 : state.currentMessagePage;
      final messages = await _supportService.getTicketMessages(ticketId);

      state = state.copyWith(
        messages: messages,
        isLoadingMessages: false,
        hasMoreMessages: messages.length >= 20,
        currentMessagePage: page + 1,
      );
    } catch (e) {
      AppLogger.error('Error loading messages: $e');
      state = state.copyWith(
        isLoadingMessages: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    SupportTicketPriority priority = SupportTicketPriority.medium,
    String? orderId,
    String? restaurantId,
  }) async {
    state = state.copyWith(isCreatingTicket: true, error: null);

    try {
      final ticket = await _supportService.createTicket(
        subject: subject,
        description: description,
        category: category,
        priority: priority,
        orderId: orderId,
        restaurantId: restaurantId,
      );

      state = state.copyWith(
        isCreatingTicket: false,
        tickets: [ticket, ...state.tickets],
      );
    } catch (e) {
      AppLogger.error('Error creating ticket: $e');
      state = state.copyWith(
        isCreatingTicket: false,
        error: e.toString(),
      );
    }
  }

  Future<void> sendMessage({
    required String ticketId,
    required String message,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    state = state.copyWith(isSendingMessage: true, error: null);

    try {
      final newMessage = await _supportService.sendMessage(
        ticketId: ticketId,
        message: message,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
      );

      state = state.copyWith(
        isSendingMessage: false,
        messages: [...state.messages, newMessage],
      );
    } catch (e) {
      AppLogger.error('Error sending message: $e');
      state = state.copyWith(
        isSendingMessage: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateTicket({
    required String ticketId,
    SupportTicketStatus? status,
    int? rating,
    String? feedback,
  }) async {
    try {
      final updatedTicket = await _supportService.updateTicket(
        ticketId: ticketId,
        status: status,
        rating: rating,
        feedback: feedback,
      );

      // Update the ticket in the list
      final updatedTickets = state.tickets.map((ticket) {
        return ticket.id == ticketId ? updatedTicket : ticket;
      }).toList();

      state = state.copyWith(
        tickets: updatedTickets,
        selectedTicket: state.selectedTicket?.id == ticketId
            ? updatedTicket
            : state.selectedTicket,
      );
    } catch (e) {
      AppLogger.error('Error updating ticket: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> refreshTickets({SupportTicketStatus? status}) async {
    await loadTickets(refresh: true, status: status);
  }

  void clearError() {
    state = state.clearError();
  }

  @override
  void dispose() {
    _ticketsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

// Provider instances
final supportProvider = StateNotifierProvider<SupportNotifier, SupportState>((ref) {
  final supportService = ref.watch(supportServiceProvider);
  return SupportNotifier(supportService);
});

// Admin support provider
class AdminSupportNotifier extends StateNotifier<SupportState> {
  final SupportService _supportService;
  // AppLogger is static, no instance needed

  AdminSupportNotifier(this._supportService) : super(const SupportState());

  Future<void> loadAllTickets({
    bool refresh = false,
    SupportTicketStatus? status,
    SupportTicketPriority? priority,
    String? assignedTo,
  }) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final page = refresh ? 0 : state.currentPage;
      final tickets = await _supportService.getAllTickets(
        limit: 50,
        offset: page * 50,
        status: status,
        priority: priority,
        assignedTo: assignedTo,
      );

      final allTickets = refresh ? tickets : [...state.tickets, ...tickets];
      final hasMore = tickets.length >= 50;

      state = state.copyWith(
        tickets: allTickets,
        isLoading: false,
        hasMore: hasMore,
        currentPage: page + 1,
      );
    } catch (e) {
      AppLogger.error('Error loading all tickets: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> assignTicket(String ticketId, String assignedTo) async {
    try {
      final updatedTicket = await _supportService.updateTicket(
        ticketId: ticketId,
        assignedTo: assignedTo,
      );

      final updatedTickets = state.tickets.map((ticket) {
        return ticket.id == ticketId ? updatedTicket : ticket;
      }).toList();

      state = state.copyWith(
        tickets: updatedTickets,
        selectedTicket: state.selectedTicket?.id == ticketId
            ? updatedTicket
            : state.selectedTicket,
      );
    } catch (e) {
      AppLogger.error('Error assigning ticket: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> sendSupportMessage({
    required String ticketId,
    required String message,
    String? attachmentUrl,
    String? attachmentName,
  }) async {
    state = state.copyWith(isSendingMessage: true, error: null);

    try {
      final newMessage = await _supportService.sendMessage(
        ticketId: ticketId,
        message: message,
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        isFromSupport: true,
      );

      state = state.copyWith(
        isSendingMessage: false,
        messages: [...state.messages, newMessage],
      );
    } catch (e) {
      AppLogger.error('Error sending support message: $e');
      state = state.copyWith(
        isSendingMessage: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateTicket({
    required String ticketId,
    SupportTicketStatus? status,
    int? rating,
    String? feedback,
    String? assignedTo,
  }) async {
    try {
      final updatedTicket = await _supportService.updateTicket(
        ticketId: ticketId,
        status: status,
        rating: rating,
        feedback: feedback,
        assignedTo: assignedTo,
      );

      // Update the ticket in the list
      final updatedTickets = state.tickets.map((ticket) {
        return ticket.id == ticketId ? updatedTicket : ticket;
      }).toList();

      state = state.copyWith(
        tickets: updatedTickets,
        selectedTicket: state.selectedTicket?.id == ticketId
            ? updatedTicket
            : state.selectedTicket,
      );
    } catch (e) {
      AppLogger.error('Error updating ticket: $e');
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminSupportProvider = StateNotifierProvider<AdminSupportNotifier, SupportState>((ref) {
  final supportService = ref.watch(supportServiceProvider);
  return AdminSupportNotifier(supportService);
});