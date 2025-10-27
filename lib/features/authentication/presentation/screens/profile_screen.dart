import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/routing/route_paths.dart';
import 'package:food_delivery_app/shared/models/user_role.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/profile_header_widget.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/profile_settings_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/address_screen.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/payment_methods_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            onSelected: (value) {
              if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await authNotifier.signOut();
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close dialog
                            Navigator.of(
                              context,
                            ).pop(); // Go back to previous screen
                          }
                        },
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 10),
                    Text('Sign Out'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: authState.isAuthenticated && authState.user != null
          ? _buildProfileContent(context, ref, authState)
          : _buildNotAuthenticatedContent(context),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    AuthState authState,
  ) {
    final user = authState.user!;

    // Create a UserProfile object from the Supabase user data
    final userProfile = UserProfile(
      id: user.id,
      email: user.email ?? 'No email',
      fullName: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      createdAt: DateTime.now(), // This would normally come from the database
      updatedAt: DateTime.now(), // This would normally come from the database
    );

    final hasOwnerRole =
        authState.allRoles.any((r) => r.role == UserRoleType.restaurantOwner);
    final hasStaffRole =
        authState.allRoles.any((r) => r.role == UserRoleType.restaurantStaff);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            ProfileHeaderWidget(
              userProfile: userProfile,
              onEditProfile: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Profile options
            _buildProfileOption(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileSettingsScreen(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.location_on,
              title: 'Delivery Addresses',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddressScreen(),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                );
              },
            ),

            if (authState.canAccessRestaurantDashboard) ...[
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Restaurant',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 8),
              _buildProfileOption(
                context,
                icon: Icons.store,
                title: 'Restaurant Dashboard',
                onTap: () => context.push(RoutePaths.restaurantDashboard),
              ),
              _buildProfileOption(
                context,
                icon: Icons.receipt_long,
                title: 'Manage Orders',
                onTap: () => context.push(RoutePaths.restaurantOrders),
              ),
              _buildProfileOption(
                context,
                icon: Icons.restaurant_menu,
                title: 'Manage Menu',
                onTap: () => context.push(RoutePaths.restaurantMenu),
              ),
              _buildProfileOption(
                context,
                icon: Icons.insights,
                title: 'Analytics',
                onTap: () => context.push(RoutePaths.restaurantAnalytics),
              ),
              _buildProfileOption(
                context,
                icon: Icons.settings_applications,
                title: 'Restaurant Settings',
                onTap: () => context.push(RoutePaths.restaurantSettings),
              ),
            ],

            if (authState.hasMultipleRoles)
              _buildProfileOption(
                context,
                icon: Icons.swap_horiz,
                title: 'Switch Role',
                onTap: () => _showSwitchRoleSheet(context, ref, authState,
                    hasOwnerRole: hasOwnerRole, hasStaffRole: hasStaffRole),
              ),

            _buildProfileOption(
              context,
              icon: Icons.history,
              title: 'Order History',
              onTap: () {
                // TODO: Navigate to order history screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order History functionality coming soon'),
                  ),
                );
              },
            ),

            _buildProfileOption(
              context,
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                // TODO: Navigate to settings screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings functionality coming soon'),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Sign out button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // Same logout functionality as the app bar
                  showDialog(


                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Sign Out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            final authNotifier = ref.read(authStateProvider.notifier);
                            await authNotifier.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Close dialog
                              Navigator.of(context).pop(); // Go back to previous screen
                            }
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepOrange),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildNotAuthenticatedContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text(
            'Not Signed In',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to access your profile',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  void _showSwitchRoleSheet(
    BuildContext context,
    WidgetRef ref,
    AuthState authState, {
    required bool hasOwnerRole,
    required bool hasStaffRole,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final notifier = ref.read(authStateProvider.notifier);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Customer'),
                enabled: authState.primaryRole?.role != UserRoleType.consumer,
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await notifier.switchRole(UserRoleType.consumer);
                },
              ),
              if (hasOwnerRole)
                ListTile(
                  leading: const Icon(Icons.storefront),
                  title: const Text('Restaurant Owner'),
                  enabled: authState.primaryRole?.role != UserRoleType.restaurantOwner,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await notifier.switchRole(UserRoleType.restaurantOwner);
                  },
                ),
              if (hasStaffRole)
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Restaurant Staff'),
                  enabled: authState.primaryRole?.role != UserRoleType.restaurantStaff,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await notifier.switchRole(UserRoleType.restaurantStaff);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

}
