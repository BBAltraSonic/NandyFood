import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';

import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';

class RoleSelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialSelection;

  const RoleSelectionScreen({
    super.key,
    this.isInitialSelection = false,
  });

  @override
  ConsumerState<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  UserRoleType? _selectedRole;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isInitialSelection
            ? 'Choose Your Role'
            : 'Select Active Role'),
        automaticallyImplyLeading: !widget.isInitialSelection,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isInitialSelection) ...[
                Text(
                  'Welcome! 👋',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'How would you like to use NandyFood?',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 32),
              ],
              _buildRoleCard(
                context,
                role: UserRoleType.consumer,
                title: 'Consumer',
                description: 'Order delicious food from local restaurants',
                icon: Icons.shopping_bag_rounded,
                color: Colors.blue,
                features: [
                  'Browse restaurants',
                  'Place orders',
                  'Track deliveries',
                  'Rate & review',
                ],
              ),
              const SizedBox(height: 16),
              _buildRoleCard(
                context,
                role: UserRoleType.restaurantOwner,
                title: 'Restaurant Owner',
                description: 'Manage your restaurant business',
                icon: Icons.store_rounded,
                color: Colors.orange,
                features: [
                  'Manage menu items',
                  'Process orders',
                  'View analytics',
                  'Grow your business',
                ],
              ),
              if (!widget.isInitialSelection &&
                  authState.hasMultipleRoles) ...[
                const SizedBox(height: 16),
                _buildRoleCard(
                  context,
                  role: UserRoleType.deliveryDriver,
                  title: 'Delivery Driver',
                  description: 'Deliver orders and earn money',
                  icon: Icons.delivery_dining_rounded,
                  color: Colors.green,
                  features: [
                    'Accept deliveries',
                    'Navigate routes',
                    'Track earnings',
                    'Flexible hours',
                  ],
                ),
              ],
              const SizedBox(height: 32),
              if (_selectedRole != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required UserRoleType role,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required List<String> features,
  }) {
    final isSelected = _selectedRole == role;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedRole = role),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? color : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              ...features.map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: isSelected ? color : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          feature,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedRole == null) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authStateProvider.notifier).switchRole(_selectedRole!);

      if (!mounted) return;

      // Navigate based on selected role
      if (_selectedRole == UserRoleType.restaurantOwner) {
        // Check if user has a restaurant, otherwise go to registration
        context.go(RoutePaths.restaurantRegister);
      } else {
        context.go(RoutePaths.home);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
