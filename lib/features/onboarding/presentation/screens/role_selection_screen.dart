import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

/// Enhanced role selection screen for clear user path identification
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  List<UserRoleOption> selectedRoles = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    _buildRoleOptions(),
                    const SizedBox(height: 32),
                    _buildMultiRoleInfo(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to NandyFood!',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryBlack,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'How would you like to use our platform?\nSelect all that apply to you.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade700,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildRoleOptions() {
    final roles = [
      UserRoleOption(
        id: 'customer',
        title: 'I want to order food',
        description: 'Discover restaurants, place orders, and track deliveries',
        icon: Icons.restaurant_menu_rounded,
        color: Colors.orange,
        features: [
          'Browse restaurants & menus',
          'Place orders for delivery/pickup',
          'Track orders in real-time',
          'Save favorites & reorder',
          'Pay securely online',
        ],
        isPrimary: true,
      ),
      UserRoleOption(
        id: 'restaurant_owner',
        title: 'I own a restaurant',
        description: 'Manage your restaurant, orders, and grow your business',
        icon: Icons.store_rounded,
        color: Colors.deepPurple,
        features: [
          'Manage menu & pricing',
          'Accept & process orders',
          'Track revenue & analytics',
          'Manage staff & schedules',
          'Reach more customers',
        ],
        isPrimary: true,
      ),
      UserRoleOption(
        id: 'delivery_driver',
        title: 'I deliver orders',
        description: 'Earn money by delivering food orders',
        icon: Icons.delivery_dining_rounded,
        color: Colors.green,
        features: [
          'View available deliveries',
          'Optimize delivery routes',
          'Track earnings',
          'Flexible work schedule',
        ],
        isPrimary: false,
      ),
    ];

    return Column(
      children: roles.map((role) {
        final isSelected = selectedRoles.contains(role);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _toggleRole(role),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? role.color.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? role.color
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: role.color.withValues(alpha: 0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
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
                              color: role.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              role.icon,
                              color: role.color,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.title,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? role.color
                                            : AppTheme.primaryBlack,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role.description,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? role.color
                                    : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected
                                  ? role.color
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What you\'ll get:',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: role.color,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              ...role.features.map((feature) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: role.color,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultiRoleInfo() {
    if (selectedRoles.length <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You can easily switch between roles anytime from your profile',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blue.shade800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: selectedRoles.isNotEmpty ? 0.33 : 0.0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryBlack,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Step 1 of 3',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _skipForNow(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      'Skip for now',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: selectedRoles.isEmpty ? null : _continueToSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlack,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleRole(UserRoleOption role) {
    setState(() {
      if (selectedRoles.contains(role)) {
        selectedRoles.remove(role);
      } else {
        if (selectedRoles.length < 3) {
          selectedRoles.add(role);
        }
      }
    });
  }

  void _continueToSetup() async {
    if (selectedRoles.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Save selected roles to user profile
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId != null) {
        // TODO: Save roles to backend
        await Future.delayed(const Duration(seconds: 1)); // Simulate API call

        // Navigate to appropriate setup flow
        if (mounted) {
          _navigateToSetup();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSetup() {
    final primaryRole = selectedRoles.firstWhere(
      (role) => role.isPrimary,
      orElse: () => selectedRoles.first,
    );

    switch (primaryRole.id) {
      case 'restaurant_owner':
        context.push('/onboarding/restaurant-setup');
        break;
      case 'delivery_driver':
        context.push('/onboarding/driver-setup');
        break;
      case 'customer':
      default:
        context.push('/onboarding/customer-setup');
        break;
    }
  }

  void _skipForNow() {
    // Navigate to main app based on existing user data or default to customer view
    context.go(RoutePaths.home);
  }
}

/// Model for user role selection option
class UserRoleOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> features;
  final bool isPrimary;

  const UserRoleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.features,
    this.isPrimary = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserRoleOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}