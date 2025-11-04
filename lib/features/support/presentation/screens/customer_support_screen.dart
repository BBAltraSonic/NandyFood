import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import '../providers/support_provider.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class CustomerSupportScreen extends ConsumerStatefulWidget {
  const CustomerSupportScreen({super.key});

  @override
  ConsumerState<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends ConsumerState<CustomerSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTickets();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTickets() async {
    await ref.read(supportProvider.notifier).loadTickets();
  }

  Future<void> _refreshTickets() async {
    final tabIndex = _tabController.index;
    SupportTicketStatus? status;

    switch (tabIndex) {
      case 0: // All
        status = null;
        break;
      case 1: // Open
        status = SupportTicketStatus.open;
        break;
      case 2: // In Progress
        status = SupportTicketStatus.inProgress;
        break;
      case 3: // Waiting
        status = SupportTicketStatus.waitingOnCustomer;
        break;
      case 4: // Resolved
        status = SupportTicketStatus.resolved;
        break;
    }

    await ref.read(supportProvider.notifier).refreshTickets(status: status);
  }

  void _createNewTicket() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateTicketScreen(),
      ),
    );
  }

  void _viewTicket(SupportTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final supportState = ref.watch(supportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Support'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) async {
            SupportTicketStatus? status;
            switch (index) {
              case 0: // All
                status = null;
                break;
              case 1: // Open
                status = SupportTicketStatus.open;
                break;
              case 2: // In Progress
                status = SupportTicketStatus.inProgress;
                break;
              case 3: // Waiting
                status = SupportTicketStatus.waitingOnCustomer;
                break;
              case 4: // Resolved
                status = SupportTicketStatus.resolved;
                break;
            }
            await ref.read(supportProvider.notifier).refreshTickets(status: status);
          },
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Open'),
            Tab(text: 'In Progress'),
            Tab(text: 'Waiting'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTicketList(null),
          _buildTicketList(SupportTicketStatus.open),
          _buildTicketList(SupportTicketStatus.inProgress),
          _buildTicketList(SupportTicketStatus.waitingOnCustomer),
          _buildTicketList(SupportTicketStatus.resolved),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewTicket,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTicketList(SupportTicketStatus? status) {
    final supportState = ref.watch(supportProvider);
    final tickets = status == null
        ? supportState.tickets
        : supportState.tickets.where((ticket) => ticket.status == status).toList();

    if (supportState.isLoading && tickets.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No support tickets found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              status == null
                  ? 'Create your first support ticket'
                  : 'No ${status.label.toLowerCase()} tickets',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewTicket,
              icon: const Icon(Icons.add),
              label: const Text('Create Ticket'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshTickets,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
              supportState.hasMore &&
              !supportState.isLoading) {
            ref.read(supportProvider.notifier).loadMoreTickets(status: status);
          }
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tickets.length + (supportState.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == tickets.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final ticket = tickets[index];
            return _TicketCard(
              ticket: ticket,
              onTap: () => _viewTicket(ticket),
            );
          },
        ),
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({
    required this.ticket,
    required this.onTap,
  });

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _PriorityBadge(priority: ticket.priority),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _CategoryBadge(category: ticket.category),
                  const SizedBox(width: 8),
                  _StatusBadge(status: ticket.status),
                  const Spacer(),
                  Text(
                    DateFormat('MMM d, yyyy').format(ticket.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
              if (ticket.rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < ticket.rating! ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.black54,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      'Rated',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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