import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import 'package:food_delivery_app/shared/models/support_message.dart';
import '../providers/support_provider.dart';
import '../screens/create_ticket_screen.dart';
import '../screens/ticket_detail_screen.dart';

class SupportChatWidget extends ConsumerStatefulWidget {
  const SupportChatWidget({super.key});

  @override
  ConsumerState<SupportChatWidget> createState() => _SupportChatWidgetState();
}

class _SupportChatWidgetState extends ConsumerState<SupportChatWidget>
    with TickerProviderStateMixin {
  final _quickReplyController = TextEditingController();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _isOpen = false;
  bool _isExpanded = false;
  bool _hasActiveTickets = false;
  String? _activeTicketId;

  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _animation;
  late Animation<double> _fabAnimation;

  final List<String> _quickReplies = [
    'I need help with my order',
    'Payment issue',
    'Restaurant problem',
    'Account question',
    'Technical support',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    // Delay provider modification until after widget tree is built
    Future(() => _loadActiveTickets());
  }

  @override
  void dispose() {
    _quickReplyController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveTickets() async {
    try {
      await ref.read(supportProvider.notifier).loadTickets();
      final supportState = ref.read(supportProvider);
      final activeTickets = supportState.tickets.where((ticket) => ticket.status.isActive).toList();

      setState(() {
        _hasActiveTickets = activeTickets.isNotEmpty;
        _activeTicketId = activeTickets.isNotEmpty ? activeTickets.first.id : null;
      });
    } catch (e) {
      // Handle error silently for floating widget
    }
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      _isExpanded = false;
    });

    if (_isOpen) {
      _animationController.forward();
      _fabAnimationController.forward();
      _loadActiveTickets();
    } else {
      _animationController.reverse();
      _fabAnimationController.reverse();
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _goToFullSupport() {
    _toggleChat();
    Navigator.of(context).pushNamed('/support');
  }

  void _createTicketFromQuickReply(String reply) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateTicketScreen(
          initialSubject: reply,
          initialCategory: _getCategoryFromReply(reply),
        ),
      ),
    );
  }

  void _goToActiveTicket() {
    if (_activeTicketId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TicketDetailScreen(ticketId: _activeTicketId!),
        ),
      );
    }
  }

  SupportTicketCategory _getCategoryFromReply(String reply) {
    switch (reply.toLowerCase()) {
      case 'i need help with my order':
        return SupportTicketCategory.orderIssues;
      case 'payment issue':
        return SupportTicketCategory.paymentIssues;
      case 'restaurant problem':
        return SupportTicketCategory.restaurantIssues;
      case 'account question':
        return SupportTicketCategory.accountIssues;
      case 'technical support':
        return SupportTicketCategory.technicalIssues;
      default:
        return SupportTicketCategory.other;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Stack(
      children: [
        // Chat window
        Positioned(
          bottom: isSmallScreen ? 80 : 100,
          right: isSmallScreen ? 16 : 24,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Transform.scale(
                  scale: _animation.value,
                  alignment: Alignment.bottomRight,
                  child: Container(
                    width: isSmallScreen
                        ? size.width - 32
                        : _isExpanded
                            ? 450
                            : 350,
                    height: _isExpanded ? 500 : 400,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.support_agent,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Customer Support',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _toggleExpanded,
                                icon: Icon(
                                  _isExpanded ? Icons.compress : Icons.expand,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              IconButton(
                                onPressed: _toggleChat,
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Content
                        Expanded(
                          child: _buildChatContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: isSmallScreen ? 16 : 24,
          right: isSmallScreen ? 16 : 24,
          child: AnimatedBuilder(
            animation: _fabAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _fabAnimation.value * 0.75,
                child: FloatingActionButton.extended(
                  onPressed: _toggleChat,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  icon: _isOpen
                      ? const Icon(Icons.close)
                      : Stack(
                          children: [
                            const Icon(Icons.support_agent),
                            if (_hasActiveTickets)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                  label: Text(_isOpen ? 'Close' : 'Support'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatContent() {
    if (_hasActiveTickets && _activeTicketId != null) {
      return _buildActiveTicketContent();
    } else {
      return _buildQuickReplyContent();
    }
  }

  Widget _buildActiveTicketContent() {
    final supportState = ref.watch(supportProvider);
    final ticket = supportState.selectedTicket;
    final messages = supportState.messages;

    if (ticket == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Ticket info
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ticket.subject,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _StatusBadge(status: ticket.status),
                  const Spacer(),
                  Text(
                    '${messages.length} messages',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        // Messages
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _MiniMessageBubble(message: message);
                  },
                ),
        ),
        // Quick actions
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _goToActiveTicket,
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open Full Chat'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _goToFullSupport,
                    icon: const Icon(Icons.list),
                    label: const Text('All Tickets'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'For detailed conversation and file attachments, please open the full chat interface.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickReplyContent() {
    return Column(
      children: [
        // Welcome message
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.support_agent,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi! How can we help?',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Select an option below or describe your issue',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Quick Help:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ..._quickReplies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _createTicketFromQuickReply(reply),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getReplyIcon(reply),
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                reply,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _goToFullSupport,
                        icon: const Icon(Icons.list),
                        label: const Text('View All Tickets'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateTicketScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('New Ticket'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getReplyIcon(String reply) {
    switch (reply.toLowerCase()) {
      case 'i need help with my order':
        return Icons.shopping_bag;
      case 'payment issue':
        return Icons.payment;
      case 'restaurant problem':
        return Icons.restaurant;
      case 'account question':
        return Icons.account_circle;
      case 'technical support':
        return Icons.settings;
      default:
        return Icons.help_outline;
    }
  }
}

class _MiniMessageBubble extends StatelessWidget {
  const _MiniMessageBubble({required this.message});

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final isFromSupport = message.isFromSupport;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromSupport
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
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
                  Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: isFromSupport
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onPrimary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('h:mm a').format(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isFromSupport
                          ? Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}