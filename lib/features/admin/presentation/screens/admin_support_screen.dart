import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/shared/models/support_ticket.dart';
import 'package:food_delivery_app/features/support/presentation/providers/support_provider.dart';
import 'package:food_delivery_app/features/support/presentation/screens/ticket_detail_screen.dart';

/// Admin Support Screen for customer support management
class AdminSupportScreen extends ConsumerStatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  ConsumerState<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends ConsumerState<AdminSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedPriority = 'all';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load all tickets on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminSupportProvider.notifier).loadAllTickets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Customer Support'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewTicket,
            tooltip: 'New Ticket',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Tickets'),
                Tab(text: 'Analytics'),
                Tab(text: 'Knowledge Base'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketsTab(),
                _buildAnalyticsTab(),
                _buildKnowledgeBaseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsTab() {
    return Column(
      children: [
        _buildSearchAndFilterSection(),
        Expanded(
          child: _buildTicketsList(),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search support tickets...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadiusTokens.borderRadiusMd,
                borderSide: BorderSide(color: NeutralColors.gray300),
              ),
              filled: true,
              fillColor: NeutralColors.gray50,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'All',
                  _selectedStatus == 'all',
                  () {
                    setState(() {
                      _selectedStatus = 'all';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Open',
                  _selectedStatus == 'open',
                  () {
                    setState(() {
                      _selectedStatus = 'open';
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Closed',
                  _selectedStatus == 'closed',
                  () {
                    setState(() {
                      _selectedStatus = 'closed';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPriorityFilterChip('High', 'high'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityFilterChip('Medium', 'medium'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPriorityFilterChip('Low', 'low'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: NeutralColors.gray100,
      selectedColor: BrandColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? BrandColors.primary : NeutralColors.textSecondary,
      ),
    );
  }

  Widget _buildPriorityFilterChip(String label, String priority) {
    final isSelected = _selectedPriority == priority;
    Color color;
    switch (priority) {
      case 'high':
        color = SemanticColors.error;
        break;
      case 'medium':
        color = SemanticColors.warning;
        break;
      case 'low':
        color = SemanticColors.success;
        break;
      default:
        color = NeutralColors.gray600;
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedPriority = selected ? priority : 'all';
        });
      },
      backgroundColor: NeutralColors.gray100,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : NeutralColors.textSecondary,
      ),
    );
  }

  Widget _buildTicketsList() {
    final supportState = ref.watch(adminSupportProvider);
    final tickets = supportState.tickets;
    final filteredTickets = _filterTickets(tickets);

    if (supportState.isLoading && tickets.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (supportState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: SemanticColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tickets',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: SemanticColors.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              supportState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NeutralColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredTickets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent_outlined,
              size: 64,
              color: NeutralColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No support tickets found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NeutralColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NeutralColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            supportState.hasMore &&
            !supportState.isLoading) {
          SupportTicketStatus? status;
          SupportTicketPriority? priority;

          if (_selectedStatus != 'all') {
            status = SupportTicketStatus.fromString(_selectedStatus);
          }
          if (_selectedPriority != 'all') {
            priority = SupportTicketPriority.fromString(_selectedPriority);
          }

          ref.read(adminSupportProvider.notifier).loadAllTickets(
            status: status,
            priority: priority,
          );
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTickets.length + (supportState.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == filteredTickets.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final ticket = filteredTickets[index];
          return _buildTicketCard(ticket);
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final ticketId = ticket.id;
    final subject = ticket.subject;
    final status = ticket.status.value;
    final priority = ticket.priority.value;
    final createdAt = ticket.createdAt;
    final lastActivity = ticket.updatedAt;
    final assignedTo = ticket.assignedTo;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(color: NeutralColors.gray200),
      ),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket),
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(priority).withValues(alpha: 0.1),
                      borderRadius: BorderRadiusTokens.borderRadiusMd,
                    ),
                    child: Icon(
                      _getPriorityIcon(priority),
                      color: _getPriorityColor(priority),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ticket #${ticketId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: NeutralColors.textTertiary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: NeutralColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'User: ${ticket.userId.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            color: NeutralColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildStatusChip(status),
                      const SizedBox(height: 8),
                      _buildPriorityChip(priority),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Created ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: NeutralColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.update,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Updated ${_formatDate(lastActivity)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: NeutralColors.textTertiary,
                    ),
                  ),
                ],
              ),
              if (assignedTo != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: NeutralColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assigned to $assignedTo',
                      style: TextStyle(
                        fontSize: 12,
                        color: NeutralColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleTicketAction(value, ticket);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility),
                            const SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (ticket.status.isActive)
                        PopupMenuItem(
                          value: 'respond',
                          child: Row(
                            children: [
                              const Icon(Icons.reply),
                              const SizedBox(width: 8),
                              Text('Respond'),
                            ],
                          ),
                        ),
                      if (ticket.status.isActive)
                        PopupMenuItem(
                          value: 'assign',
                          child: Row(
                            children: [
                              const Icon(Icons.person_add),
                              const SizedBox(width: 8),
                              Text('Assign'),
                            ],
                          ),
                        ),
                      if (ticket.status.isActive)
                        PopupMenuItem(
                          value: 'close',
                          child: Row(
                            children: [
                              const Icon(Icons.close, color: SemanticColors.success),
                              const SizedBox(width: 8),
                              Text('Close Ticket', style: TextStyle(color: SemanticColors.success)),
                            ],
                          ),
                        ),
                      if (ticket.status.isClosed)
                        PopupMenuItem(
                          value: 'reopen',
                          child: Row(
                            children: [
                              const Icon(Icons.replay, color: BrandColors.primary),
                              const SizedBox(width: 8),
                              Text('Reopen Ticket'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusValue) {
    final status = SupportTicketStatus.fromString(statusValue);
    Color color;
    String displayText;

    switch (status) {
      case SupportTicketStatus.open:
        color = SemanticColors.info;
        displayText = 'Open';
        break;
      case SupportTicketStatus.inProgress:
        color = SemanticColors.warning;
        displayText = 'In Progress';
        break;
      case SupportTicketStatus.waitingOnCustomer:
        color = SemanticColors.warningDark;
        displayText = 'Waiting';
        break;
      case SupportTicketStatus.resolved:
        color = SemanticColors.success;
        displayText = 'Resolved';
        break;
      case SupportTicketStatus.closed:
        color = NeutralColors.gray600;
        displayText = 'Closed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final color = _getPriorityColor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        priority.capitalizeFirst(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return SemanticColors.error;
      case 'medium':
        return SemanticColors.warning;
      case 'low':
        return SemanticColors.success;
      default:
        return NeutralColors.gray600;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  List<SupportTicket> _filterTickets(List<SupportTicket> tickets) {
    return tickets.where((ticket) {
      final searchQuery = _searchController.text.toLowerCase();
      final subject = ticket.subject.toLowerCase();
      final userId = ticket.userId.toLowerCase();

      final matchesSearch = subject.contains(searchQuery) || userId.contains(searchQuery);

      bool matchesStatus = true;
      if (_selectedStatus != 'all') {
        matchesStatus = ticket.status.value == _selectedStatus;
      }

      bool matchesPriority = true;
      if (_selectedPriority != 'all') {
        matchesPriority = ticket.priority.value == _selectedPriority;
      }

      return matchesSearch && matchesStatus && matchesPriority;
    }).toList();
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Support Metrics
          _buildSupportMetrics(),
          const SizedBox(height: 24),

          // Response Time Analytics
          _buildResponseTimeAnalytics(),
          const SizedBox(height: 24),

          // Team Performance
          _buildTeamPerformance(),
          const SizedBox(height: 24),

          // Ticket Trends
          _buildTicketTrends(),
        ],
      ),
    );
  }

  Widget _buildSupportMetrics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Support Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              _buildMetricCard('Open Tickets', '23', Icons.support_agent, SemanticColors.info),
              _buildMetricCard('Avg Response Time', '2.5h', Icons.access_time, SemanticColors.warning),
              _buildMetricCard('Satisfaction Rate', '4.8/5', Icons.thumb_up, SemanticColors.success),
              _buildMetricCard('Tickets Today', '15', Icons.today, BrandColors.primary),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadiusTokens.borderRadiusMd,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: NeutralColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTimeAnalytics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Response Time Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeDistribution(),
        ],
      ),
    );
  }

  Widget _buildTimeDistribution() {
    return Column(
      children: [
        _buildTimeBar('Under 1 hour', 35, SemanticColors.success),
        const SizedBox(height: 8),
        _buildTimeBar('1-3 hours', 45, SemanticColors.warning),
        const SizedBox(height: 8),
        _buildTimeBar('3-6 hours', 15, SemanticColors.warningDark),
        const SizedBox(height: 8),
        _buildTimeBar('Over 6 hours', 5, SemanticColors.error),
      ],
    );
  }

  Widget _buildTimeBar(String label, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 14)),
            Text('$percentage%', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: NeutralColors.gray200,
            borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamPerformance() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTeamMemberList(),
        ],
      ),
    );
  }

  Widget _buildTeamMemberList() {
    final teamMembers = [
      {'name': 'Sarah Wilson', 'tickets': 12, 'responseTime': '1.8h'},
      {'name': 'Mike Johnson', 'tickets': 8, 'responseTime': '2.2h'},
      {'name': 'Emma Davis', 'tickets': 15, 'responseTime': '1.5h'},
    ];

    return Column(
      children: teamMembers.map((member) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: BrandColors.primary.withValues(alpha: 0.2),
            child: Text(
              (member['name'] as String).substring(0, 2).toUpperCase(),
              style: TextStyle(
                color: BrandColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(member['name'] as String),
          subtitle: Text('Avg response: ${member['responseTime']}'),
          trailing: Text(
            '${member['tickets']} tickets',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTicketTrends() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ticket Trends (Last 7 Days)',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Chart visualization coming soon',
            style: TextStyle(
              color: NeutralColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildKnowledgeBaseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Create
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadiusTokens.borderRadiusLg,
              boxShadow: ShadowTokens.shadowSm,
            ),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search knowledge base...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadiusTokens.borderRadiusMd,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _createArticle,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Article'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _manageCategories,
                        icon: const Icon(Icons.category),
                        label: const Text('Categories'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Popular Articles
          _buildPopularArticles(),
          const SizedBox(height: 24),

          // Recent Articles
          _buildRecentArticles(),
        ],
      ),
    );
  }

  Widget _buildPopularArticles() {
    final articles = [
      {'title': 'How to place an order', 'views': 1234, 'category': 'Getting Started'},
      {'title': 'Payment methods explained', 'views': 987, 'category': 'Payments'},
      {'title': 'Track your delivery', 'views': 756, 'category': 'Orders'},
      {'title': 'Contact support', 'views': 543, 'category': 'Support'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Popular Articles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: articles.map((article) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.article, color: BrandColors.primary),
                title: Text(article['title'] as String),
                subtitle: Text(article['category'] as String),
                trailing: Text('${article['views']} views'),
                onTap: () => _viewArticle(article['title'] as String),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentArticles() {
    final recentArticles = [
      {'title': 'Updated refund policy', 'date': '2 hours ago', 'author': 'Sarah Wilson'},
      {'title': 'New restaurant onboarding guide', 'date': '1 day ago', 'author': 'Mike Johnson'},
      {'title': 'Mobile app troubleshooting', 'date': '3 days ago', 'author': 'Emma Davis'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Articles',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: recentArticles.map((article) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.description, color: NeutralColors.textSecondary),
                title: Text(article['title'] as String),
                subtitle: Text('${article['date']} • ${article['author']}'),
                onTap: () => _viewArticle(article['title'] as String),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    AppLogger.info('Refreshing support data...');
    ref.read(adminSupportProvider.notifier).loadAllTickets(refresh: true);
  }

  void _createNewTicket() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create new ticket functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  void _handleTicketAction(String action, SupportTicket ticket) {
    switch (action) {
      case 'view':
        _showTicketDetails(ticket);
        break;
      case 'respond':
        _respondToTicket(ticket);
        break;
      case 'assign':
        _assignTicket(ticket);
        break;
      case 'close':
        _closeTicket(ticket);
        break;
      case 'reopen':
        _reopenTicket(ticket);
        break;
    }
  }

  void _respondToTicket(SupportTicket ticket) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TicketDetailScreen(ticketId: ticket.id),
      ),
    );
  }

  void _assignTicket(SupportTicket ticket) {
    // For now, assign to current admin user
    ref.read(adminSupportProvider.notifier).assignTicket(
      ticket.id,
      'current_admin_user', // This would be the current admin's ID
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket assigned to you'),
        backgroundColor: SemanticColors.success,
      ),
    );
  }

  void _closeTicket(SupportTicket ticket) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close Ticket #${ticket.id.substring(0, 8).toUpperCase()}'),
        content: const Text('Are you sure you want to close this ticket?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(adminSupportProvider.notifier).updateTicket(
                ticketId: ticket.id,
                status: SupportTicketStatus.closed,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ticket closed successfully'),
                  backgroundColor: SemanticColors.success,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: SemanticColors.success),
            child: const Text('Close Ticket'),
          ),
        ],
      ),
    );
  }

  void _reopenTicket(SupportTicket ticket) {
    ref.read(adminSupportProvider.notifier).updateTicket(
      ticketId: ticket.id,
      status: SupportTicketStatus.open,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket reopened successfully'),
        backgroundColor: BrandColors.primary,
      ),
    );
  }

  void _createArticle() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create article functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }

  void _manageCategories() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manage categories functionality coming soon'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }

  void _viewArticle(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing article: $title'),
        backgroundColor: SemanticColors.info,
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}