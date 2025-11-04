import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import 'package:food_delivery_app/shared/models/support_message.dart';
import '../providers/support_provider.dart';

class TicketDetailScreen extends ConsumerStatefulWidget {
  const TicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  final String ticketId;

  @override
  ConsumerState<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends ConsumerState<TicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  bool _showRatingDialog = false;

  @override
  void initState() {
    super.initState();
    _loadTicket();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (currentScroll >= maxScroll - 50) {
        _focusNode.unfocus();
      }
    }
  }

  Future<void> _loadTicket() async {
    await ref.read(supportProvider.notifier).selectTicket(widget.ticketId);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    _focusNode.unfocus();

    await ref.read(supportProvider.notifier).sendMessage(
      ticketId: widget.ticketId,
      message: message,
    );

    _scrollToBottom();
  }

  void _showTicketRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => _TicketRatingDialog(
        ticketId: widget.ticketId,
        onSubmit: (rating, feedback) {
          ref.read(supportProvider.notifier).updateTicket(
            ticketId: widget.ticketId,
            rating: rating,
            feedback: feedback,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportProvider);
    final ticket = supportState.selectedTicket;
    final messages = supportState.messages;

    if (ticket == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(ticket.subject),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (ticket.status == SupportTicketStatus.resolved && ticket.rating == null)
            IconButton(
              icon: const Icon(Icons.star_rate),
              onPressed: _showTicketRatingDialog,
              tooltip: 'Rate Support',
            ),
        ],
      ),
      body: Column(
        children: [
          // Ticket info header
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryBadge(category: ticket.category),
                    const SizedBox(width: 8),
                    _StatusBadge(status: ticket.status),
                    const Spacer(),
                    _PriorityBadge(priority: ticket.priority),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Ticket #${ticket.id.substring(0, 8).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Created ${DateFormat('MMM d, yyyy \'at\' h:mm a').format(ticket.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: supportState.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(
                        child: Text('No messages yet'),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _MessageBubble(message: message);
                        },
                      ),
          ),
          // Message input
          if (ticket.status.isActive)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: supportState.isSendingMessage ? null : _sendMessage,
                    icon: supportState.isSendingMessage
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isFromSupport = message.isFromSupport;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            message.message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromSupport
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          if (isFromSupport) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.support_agent,
                size: 20,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isFromSupport
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isFromSupport
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.hasAttachment) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              message.isImageMessage
                                  ? Icons.image
                                  : Icons.attach_file,
                              size: 16,
                              color: isFromSupport
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                message.attachmentName ?? 'Attachment',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isFromSupport
                                      ? Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isFromSupport
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a').format(message.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (!isFromSupport) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});

  final SupportTicketCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final SupportTicketStatus status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case SupportTicketStatus.open:
        color = Colors.black87;      // Dark gray (was blue)
        break;
      case SupportTicketStatus.inProgress:
        color = Colors.black54;      // Medium gray (was orange)
        break;
      case SupportTicketStatus.waitingOnCustomer:
        color = Colors.black38;      // Lighter gray (was purple)
        break;
      case SupportTicketStatus.resolved:
        color = Colors.black26;      // Light gray (was green)
        break;
      case SupportTicketStatus.closed:
        color = Colors.grey;         // Gray (unchanged)
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final SupportTicketPriority priority;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case SupportTicketPriority.low:
        color = Colors.black26;      // Light gray (was green)
        break;
      case SupportTicketPriority.medium:
        color = Colors.black54;      // Medium gray (was orange)
        break;
      case SupportTicketPriority.high:
        color = Colors.black87;      // Dark gray (was red)
        break;
      case SupportTicketPriority.urgent:
        color = Colors.black;        // Pure black (was purple)
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _TicketRatingDialog extends StatefulWidget {
  const _TicketRatingDialog({
    required this.ticketId,
    required this.onSubmit,
  });

  final String ticketId;
  final Function(int rating, String feedback) onSubmit;

  @override
  State<_TicketRatingDialog> createState() => _TicketRatingDialogState();
}

class _TicketRatingDialogState extends State<_TicketRatingDialog> {
  int _rating = 0;
  final _feedbackController = TextEditingController();

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate Your Support Experience'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('How would you rate your support experience?'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  size: 32,
                  color: Colors.black54,
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _feedbackController,
            decoration: const InputDecoration(
              labelText: 'Additional feedback (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0
              ? () {
                  widget.onSubmit(_rating, _feedbackController.text.trim());
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}