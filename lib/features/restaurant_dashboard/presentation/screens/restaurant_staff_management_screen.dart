import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/providers/role_provider.dart';
import 'package:food_delivery_app/core/widgets/role_guard.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/providers/staff_management_provider.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/widgets/staff_member_card.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/presentation/screens/add_edit_staff_screen.dart';

class RestaurantStaffManagementScreen extends ConsumerStatefulWidget {
  const RestaurantStaffManagementScreen({super.key});

  @override
  ConsumerState<RestaurantStaffManagementScreen> createState() =>
      _RestaurantStaffManagementScreenState();
}

class _RestaurantStaffManagementScreenState
    extends ConsumerState<RestaurantStaffManagementScreen> {
  String? _restaurantId;
  final _searchController = TextEditingController();
  StaffRoleType? _selectedRole;
  StaffStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadRestaurantId();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantId() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      if (mounted) {
        context.go(RoutePaths.authLogin);
      }
      return;
    }

    try {
      // Get restaurant ID from current user's staff record or ownership
      final roleService = ref.read(roleServiceProvider);
      final restaurants = await roleService.getUserRestaurants(userId);

      if (restaurants.isNotEmpty) {
        setState(() {
          _restaurantId = restaurants.first;
        });
      } else {
        // Check if user is staff at any restaurant
        final staffService = ref.read(staffServiceProvider);
        // This would need to be implemented in the role service
        // For now, we'll use the first restaurant the user has access to
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading restaurant: $e'),
            backgroundColor: Colors.red,
          ),
        );
        context.go(RoutePaths.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RestaurantAccessGuard(
      checkVerification: true,
      redirectTo: '/home',
      child: Builder(
        builder: (context) {
          if (_restaurantId == null) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final staffState = ref.watch(staffManagementProvider(_restaurantId!));
          final staffStats = ref.watch(staffStatsProvider(_restaurantId!));

          return Scaffold(
            appBar: AppBar(
              title: const Text('Staff Management'),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: _buildFiltersAndSearch(),
              ),
            ),
            body: RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(staffManagementProvider(_restaurantId!).notifier)
                    .refresh();
              },
              child: staffState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : staffState.error != null
                      ? _buildErrorState(staffState.error!)
                      : _buildContent(staffState, staffStats),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _addStaffMember(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Staff'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltersAndSearch() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search staff...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref
                            .read(staffManagementProvider(_restaurantId!).notifier)
                            .setSearchQuery(null);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              ref
                  .read(staffManagementProvider(_restaurantId!).notifier)
                  .setSearchQuery(value.isEmpty ? null : value);
            },
          ),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<StaffRoleType?>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    ...StaffRoleType.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role.name
                            .split('_')
                            .map((word) => word[0].toUpperCase() + word.substring(1))
                            .join(' ')),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    ref
                        .read(staffManagementProvider(_restaurantId!).notifier)
                        .setRoleFilter(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<StaffStatus?>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...StaffStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.name
                            .split('_')
                            .map((word) => word[0].toUpperCase() + word.substring(1))
                            .join(' ')),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value;
                    });
                    ref
                        .read(staffManagementProvider(_restaurantId!).notifier)
                        .setStatusFilter(value);
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedRole = null;
                    _selectedStatus = null;
                  });
                  ref
                      .read(staffManagementProvider(_restaurantId!).notifier)
                      .clearFilters();
                },
                icon: const Icon(Icons.clear_all),
                tooltip: 'Clear Filters',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(StaffManagementState state, Map<String, int> stats) {
    return CustomScrollView(
      slivers: [
        // Stats section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildStatsCards(stats),
          ),
        ),

        // Staff list header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Staff Members (${state.filteredStaff.length})',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (state.filteredStaff.length != state.staffList.length)
                  TextButton(
                    onPressed: () {
                      ref
                          .read(staffManagementProvider(_restaurantId!).notifier)
                          .clearFilters();
                      _searchController.clear();
                      setState(() {
                        _selectedRole = null;
                        _selectedStatus = null;
                      });
                    },
                    child: const Text('Clear Filters'),
                  ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Staff list
        if (state.filteredStaff.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(state.staffList.isNotEmpty),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final staff = state.filteredStaff[index];
                return StaffMemberCard(
                  staff: staff,
                  onEdit: () => _editStaffMember(staff),
                  onUpdateStatus: (status) => _updateStaffStatus(staff, status),
                  onRemove: () => _removeStaffMember(staff),
                );
              },
              childCount: state.filteredStaff.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildStatsCards(Map<String, int> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.5,
          children: [
            _buildStatCard('Total Staff', stats['total'] ?? 0, Colors.blue),
            _buildStatCard('Active', stats['active'] ?? 0, Colors.green),
            _buildStatCard('Managers', stats['managers'] ?? 0, Colors.purple),
            _buildStatCard('On Leave', stats['on_leave'] ?? 0, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool hasFilters) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.filter_list : Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No staff match your filters' : 'No staff members yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            hasFilters
                ? 'Try adjusting your search or filters'
                : 'Add your first staff member to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          if (!hasFilters) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _addStaffMember(),
              icon: const Icon(Icons.person_add),
              label: const Text('Add First Staff Member'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading staff',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref
                  .read(staffManagementProvider(_restaurantId!).notifier)
                  .refresh();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _addStaffMember() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditStaffScreen(
          restaurantId: _restaurantId!,
          onSave: (request) async {
            final success = await ref
                .read(staffManagementProvider(_restaurantId!).notifier)
                .addStaffMember(request);
            return success != null;
          },
        ),
      ),
    );
  }

  void _editStaffMember(RestaurantStaff staff) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditStaffScreen(
          restaurantId: _restaurantId!,
          staff: staff,
          onSave: (request) async {
            final updateRequest = UpdateStaffRequest(
              role: request.role,
              employmentType: request.employmentType,
              hourlyRate: request.hourlyRate,
              notes: request.notes,
            );
            return await ref
                .read(staffManagementProvider(_restaurantId!).notifier)
                .updateStaffMember(staff.id, updateRequest);
          },
        ),
      ),
    );
  }

  void _updateStaffStatus(RestaurantStaff staff, StaffStatus status) async {
    if (status == StaffStatus.terminated) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Terminate Staff Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to terminate ${staff.userProfile?.fullName ?? 'this staff member'}?'),
              const SizedBox(height: 16),
              const Text('This action can be undone by changing their status back to active.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Terminate'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    final success = await ref
        .read(staffManagementProvider(_restaurantId!).notifier)
        .updateStaffStatus(staff.id, status);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Staff status updated to ${status.name}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _removeStaffMember(RestaurantStaff staff) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RemovalReasonDialog(staff: staff),
    );

    if (reason != null) {
      final success = await ref
          .read(staffManagementProvider(_restaurantId!).notifier)
          .removeStaffMember(staff.id, reason: reason);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staff member removed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

class _RemovalReasonDialog extends StatefulWidget {
  final RestaurantStaff staff;

  const _RemovalReasonDialog({required this.staff});

  @override
  State<_RemovalReasonDialog> createState() => _RemovalReasonDialogState();
}

class _RemovalReasonDialogState extends State<_RemovalReasonDialog> {
  String? _selectedReason;
  final _customReasonController = TextEditingController();

  final List<String> _reasons = [
    'Resignation',
    'Performance issues',
    'Violation of policies',
    'Business needs',
    'Other',
  ];

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Remove Staff Member'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Removing ${widget.staff.userProfile?.fullName ?? 'this staff member'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            const Text('Reason for removal:'),
            const SizedBox(height: 8),
            ..._reasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() => _selectedReason = value);
                },
                dense: true,
              );
            }),
            if (_selectedReason == 'Other')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextField(
                  controller: _customReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Please specify',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  final reason = _selectedReason == 'Other'
                      ? _customReasonController.text
                      : _selectedReason!;
                  Navigator.pop(context, reason);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remove'),
        ),
      ],
    );
  }
}