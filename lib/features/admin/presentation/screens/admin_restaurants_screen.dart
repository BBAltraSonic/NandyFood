import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/features/admin/presentation/providers/admin_stats_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// Admin Restaurants Screen for managing all restaurants on the platform
class AdminRestaurantsScreen extends ConsumerStatefulWidget {
  const AdminRestaurantsScreen({super.key});

  @override
  ConsumerState<AdminRestaurantsScreen> createState() => _AdminRestaurantsScreenState();
}

class _AdminRestaurantsScreenState extends ConsumerState<AdminRestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedVerification = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsState = ref.watch(adminRestaurantsProvider);

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        title: const Text('Restaurant Management'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.refresh(adminRestaurantsProvider);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterSection(),
          Expanded(
            child: restaurantsState.when(
              data: (restaurants) => _buildRestaurantsList(restaurants),
              loading: () => const LoadingIndicator(),
              error: (error, stack) => _buildErrorView(error),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddRestaurantDialog();
        },
        backgroundColor: BrandColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Restaurant',
      ),
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
              hintText: 'Search restaurants...',
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
                child: FilterChip(
                  label: const Text('All Status'),
                  selected: _selectedStatus == 'all',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = 'all';
                    });
                  },
                  backgroundColor: NeutralColors.gray100,
                  selectedColor: BrandColors.primary.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedStatus == 'all' ? BrandColors.primary : NeutralColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('Active'),
                  selected: _selectedStatus == 'active',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = 'active';
                    });
                  },
                  backgroundColor: NeutralColors.gray100,
                  selectedColor: SemanticColors.success.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedStatus == 'active' ? SemanticColors.success : NeutralColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilterChip(
                  label: const Text('Inactive'),
                  selected: _selectedStatus == 'inactive',
                  onSelected: (selected) {
                    setState(() {
                      _selectedStatus = 'inactive';
                    });
                  },
                  backgroundColor: NeutralColors.gray100,
                  selectedColor: SemanticColors.error.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: _selectedStatus == 'inactive' ? SemanticColors.error : NeutralColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsList(List<Map<String, dynamic>> restaurants) {
    final filteredRestaurants = _filterRestaurants(restaurants);

    if (filteredRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store,
              size: 64,
              color: NeutralColors.gray400,
            ),
            const SizedBox(height: 16),
            Text(
              'No restaurants found',
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

    return RefreshIndicator(
      onRefresh: () async {
        ref.refresh(adminRestaurantsProvider);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = filteredRestaurants[index];
          return _buildRestaurantCard(restaurant);
        },
      ),
    );
  }

  List<Map<String, dynamic>> _filterRestaurants(List<Map<String, dynamic>> restaurants) {
    var filtered = restaurants.where((restaurant) {
      final searchQuery = _searchController.text.toLowerCase();
      final name = (restaurant['name'] as String? ?? '').toLowerCase();
      final email = (restaurant['email'] as String? ?? '').toLowerCase();

      final matchesSearch = name.contains(searchQuery) || email.contains(searchQuery);

      bool matchesStatus = true;
      if (_selectedStatus == 'active') {
        matchesStatus = restaurant['is_active'] == true;
      } else if (_selectedStatus == 'inactive') {
        matchesStatus = restaurant['is_active'] == false;
      }

      bool matchesVerification = true;
      if (_selectedVerification == 'verified') {
        matchesVerification = restaurant['verification_status'] == 'verified';
      } else if (_selectedVerification == 'pending') {
        matchesVerification = restaurant['verification_status'] == 'pending';
      } else if (_selectedVerification == 'rejected') {
        matchesVerification = restaurant['verification_status'] == 'rejected';
      }

      return matchesSearch && matchesStatus && matchesVerification;
    }).toList();

    return filtered;
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurant) {
    final isActive = restaurant['is_active'] as bool? ?? false;
    final verificationStatus = restaurant['verification_status'] as String? ?? 'pending';
    final owner = restaurant['user_profiles'] as Map<String, dynamic>? ?? {};
    final ownerName = owner['full_name'] as String? ?? 'Unknown Owner';
    final createdAt = DateTime.parse(restaurant['created_at'] as String? ?? DateTime.now().toIso8601String());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadiusTokens.borderRadiusLg,
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(color: NeutralColors.gray200),
      ),
      child: InkWell(
        onTap: () => _showRestaurantDetails(restaurant),
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
                      color: isActive ? BrandColors.primary.withValues(alpha: 0.1) : NeutralColors.gray100,
                      borderRadius: BorderRadiusTokens.borderRadiusMd,
                    ),
                    child: Icon(
                      Icons.store,
                      color: isActive ? BrandColors.primary : NeutralColors.gray600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant['name'] as String? ?? 'Unknown Restaurant',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: NeutralColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ownerName,
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
                      _buildStatusChip(isActive ? 'Active' : 'Inactive', isActive),
                      const SizedBox(height: 8),
                      _buildVerificationChip(verificationStatus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.email,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      restaurant['email'] as String? ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: NeutralColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.phone,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    restaurant['phone'] as String? ?? 'No phone',
                    style: TextStyle(
                      fontSize: 14,
                      color: NeutralColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: NeutralColors.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Joined ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: NeutralColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      _handleRestaurantAction(value, restaurant);
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
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit),
                            const SizedBox(width: 8),
                            Text('Edit Restaurant'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: isActive ? 'deactivate' : 'activate',
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.block : Icons.check_circle,
                              color: isActive ? SemanticColors.error : SemanticColors.success,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                color: isActive ? SemanticColors.error : SemanticColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (verificationStatus == 'pending')
                        PopupMenuItem(
                          value: 'verify',
                          child: Row(
                            children: [
                              const Icon(Icons.verified, color: SemanticColors.success),
                              const SizedBox(width: 8),
                              const Text('Verify Restaurant', style: TextStyle(color: SemanticColors.success)),
                            ],
                          ),
                        ),
                      if (verificationStatus == 'pending')
                        PopupMenuItem(
                          value: 'reject',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel, color: SemanticColors.error),
                              const SizedBox(width: 8),
                              const Text('Reject Verification', style: TextStyle(color: SemanticColors.error)),
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

  Widget _buildStatusChip(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? SemanticColors.success.withValues(alpha: 0.1) : SemanticColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
        border: Border.all(
          color: isActive ? SemanticColors.success : SemanticColors.error,
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? SemanticColors.success : SemanticColors.error,
        ),
      ),
    );
  }

  Widget _buildVerificationChip(String status) {
    Color color;
    Color backgroundColor;
    String displayText;

    switch (status) {
      case 'verified':
        color = SemanticColors.success;
        backgroundColor = SemanticColors.success.withValues(alpha: 0.1);
        displayText = 'Verified';
        break;
      case 'rejected':
        color = SemanticColors.error;
        backgroundColor = SemanticColors.error.withValues(alpha: 0.1);
        displayText = 'Rejected';
        break;
      default:
        color = SemanticColors.warning;
        backgroundColor = SemanticColors.warning.withValues(alpha: 0.1);
        displayText = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.full),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Restaurants'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Verification Status:'),
                const SizedBox(height: 8),
                RadioListTile<String>(
                  title: const Text('All'),
                  value: 'all',
                  groupValue: _selectedVerification,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedVerification = value!;
                    });
                    setState(() {
                      _selectedVerification = value!;
                    });
                  },
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Verified'),
                  value: 'verified',
                  groupValue: _selectedVerification,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedVerification = value!;
                    });
                    setState(() {
                      _selectedVerification = value!;
                    });
                  },
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Pending'),
                  value: 'pending',
                  groupValue: _selectedVerification,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedVerification = value!;
                    });
                    setState(() {
                      _selectedVerification = value!;
                    });
                  },
                  dense: true,
                ),
                RadioListTile<String>(
                  title: const Text('Rejected'),
                  value: 'rejected',
                  groupValue: _selectedVerification,
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedVerification = value!;
                    });
                    setState(() {
                      _selectedVerification = value!;
                    });
                  },
                  dense: true,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showRestaurantDetails(Map<String, dynamic> restaurant) {
    // TODO: Navigate to restaurant details screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restaurant details for ${restaurant['name']}'),
        action: SnackBarAction(
          label: 'View Full Details',
          onPressed: () {
            // TODO: Navigate to detailed restaurant view
          },
        ),
      ),
    );
  }

  void _handleRestaurantAction(String action, Map<String, dynamic> restaurant) {
    switch (action) {
      case 'view':
        _showRestaurantDetails(restaurant);
        break;
      case 'edit':
        _showEditRestaurantDialog(restaurant);
        break;
      case 'activate':
        _toggleRestaurantStatus(restaurant, true);
        break;
      case 'deactivate':
        _toggleRestaurantStatus(restaurant, false);
        break;
      case 'verify':
        _verifyRestaurant(restaurant, true);
        break;
      case 'reject':
        _verifyRestaurant(restaurant, false);
        break;
    }
  }

  void _showAddRestaurantDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add restaurant functionality coming soon')),
    );
  }

  void _showEditRestaurantDialog(Map<String, dynamic> restaurant) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${restaurant['name']} functionality coming soon')),
    );
  }

  void _toggleRestaurantStatus(Map<String, dynamic> restaurant, bool activate) {
    final restaurantName = restaurant['name'] as String? ?? 'Unknown Restaurant';
    final action = activate ? 'activate' : 'deactivate';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action.capitalizeFirst() Restaurant'),
        content: Text('Are you sure you want to $action $restaurantName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual status update
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$restaurantName ${action}d successfully'),
                  backgroundColor: SemanticColors.success,
                ),
              );
              ref.refresh(adminRestaurantsProvider);
            },
            style: TextButton.styleFrom(foregroundColor: activate ? SemanticColors.success : SemanticColors.error),
            child: Text(action.capitalizeFirst()),
          ),
        ],
      ),
    );
  }

  void _verifyRestaurant(Map<String, dynamic> restaurant, bool verify) {
    final restaurantName = restaurant['name'] as String? ?? 'Unknown Restaurant';
    final action = verify ? 'verify' : 'reject verification for';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action.capitalizeFirst() Restaurant'),
        content: Text('Are you sure you want to $action $restaurantName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual verification update
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$restaurantName ${verify ? 'verified' : 'verification rejected'} successfully'),
                  backgroundColor: verify ? SemanticColors.success : SemanticColors.warning,
                ),
              );
              ref.refresh(adminRestaurantsProvider);
            },
            style: TextButton.styleFrom(foregroundColor: verify ? SemanticColors.success : SemanticColors.warning),
            child: Text(verify ? 'Verify' : 'Reject'),
          ),
        ],
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
              color: SemanticColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load restaurants',
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
                ref.refresh(adminRestaurantsProvider);
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

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}