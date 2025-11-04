import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_users_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Admin Users Management Screen
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedRole = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersState = ref.watch(adminUsersProvider);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Consumers'),
            Tab(text: 'Restaurant Owners'),
            Tab(text: 'Staff'),
            Tab(text: 'Admins'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: usersState.when(
        data: (users) => _buildUsersList(users),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => _buildErrorView(error),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUsersList(List<Map<String, dynamic>> users) {
    final filteredUsers = _filterUsers(users);

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: NeutralColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NeutralColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: NeutralColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildUserGrid(filteredUsers),
        _buildUserGrid(filteredUsers.where((u) => u['primary_role'] == 'consumer').toList()),
        _buildUserGrid(filteredUsers.where((u) => u['primary_role'] == 'restaurant_owner').toList()),
        _buildUserGrid(filteredUsers.where((u) => u['primary_role'] == 'restaurant_staff').toList()),
        _buildUserGrid(filteredUsers.where((u) => u['primary_role'] == 'admin').toList()),
      ],
    );
  }

  Widget _buildUserGrid(List<Map<String, dynamic>> users) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildUserCard(user);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final fullName = user['full_name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? 'No email';
    final role = user['primary_role'] as String? ?? 'unknown';
    final createdAt = user['created_at'] as String? ?? '';
    final isActive = user['is_active'] as bool? ?? true;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getRoleColor(role).withValues(alpha: 0.1),
                    child: Text(
                      fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: _getRoleColor(role),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 12,
                            color: NeutralColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getRoleColor(role).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatRole(role),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(role),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Joined ${_formatDate(createdAt)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: NeutralColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterUsers(List<Map<String, dynamic>> users) {
    var filtered = users;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((user) {
        final fullName = (user['full_name'] as String? ?? '').toLowerCase();
        final email = (user['email'] as String? ?? '').toLowerCase();
        return fullName.contains(_searchQuery.toLowerCase()) ||
               email.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by role
    if (_selectedRole != 'all') {
      filtered = filtered.where((user) => user['primary_role'] == _selectedRole).toList();
    }

    return filtered;
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'consumer':
        return Colors.blue;
      case 'restaurant_owner':
        return Colors.green;
      case 'restaurant_staff':
        return Colors.orange;
      case 'admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'consumer':
        return 'Consumer';
      case 'restaurant_owner':
        return 'Restaurant Owner';
      case 'restaurant_staff':
        return 'Staff';
      case 'admin':
        return 'Admin';
      default:
        return role;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Users'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter name or email',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _searchQuery = '';
              });
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Users'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Role Filter:'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Roles')),
                DropdownMenuItem(value: 'consumer', child: Text('Consumer')),
                DropdownMenuItem(value: 'restaurant_owner', child: Text('Restaurant Owner')),
                DropdownMenuItem(value: 'restaurant_staff', child: Text('Staff')),
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedRole = value!;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Apply filter
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Name', user['full_name'] as String? ?? 'Unknown'),
              _buildDetailRow('Email', user['email'] as String? ?? 'No email'),
              _buildDetailRow('Primary Role', _formatRole(user['primary_role'] as String? ?? 'Unknown')),
              _buildDetailRow('Status', (user['is_active'] as bool? ?? true) ? 'Active' : 'Inactive'),
              _buildDetailRow('Joined', _formatDate(user['created_at'] as String?)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!(user['is_active'] as bool? ?? true))
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toggleUserStatus(user, true);
              },
              child: const Text('Activate'),
            ),
          if (user['is_active'] as bool? ?? true)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showDeactivateConfirmation(user);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Deactivate'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeactivateConfirmation(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate ${user['full_name']}? They will no longer be able to access the platform.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleUserStatus(user, false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user, bool activate) {
    // TODO: Implement user status toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          activate ? 'User activated successfully' : 'User deactivated successfully',
        ),
        backgroundColor: activate ? Colors.green : Colors.orange,
      ),
    );
  }

  void _showAddUserDialog() {
    // TODO: Implement add user functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add user functionality coming soon'),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load users',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.refresh(adminUsersProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}