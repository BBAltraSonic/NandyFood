import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/profile_header_widget.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/features/authentication/presentation/screens/login_screen.dart';

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
                            Navigator.of(context).pop(); // Go back to previous screen
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
          ? _buildProfileContent(context, authState.user!)
          : _buildNotAuthenticatedContent(context),
    );
  }

  Widget _buildProfileContent(BuildContext context, user) {
    // Create a UserProfile object from the Supabase user data
    final userProfile = UserProfile(
      id: user.id,
      email: user.email ?? 'No email',
      fullName: user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? 'User',
      createdAt: DateTime.now(), // This would normally come from the database
      updatedAt: DateTime.now(), // This would normally come from the database
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile header
            ProfileHeaderWidget(
              userProfile: userProfile,
              onEditProfile: () {
                // TODO: Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile functionality coming soon')),
                );
              },
            ),
            
            const SizedBox(height: 30),
            
            // Profile options
            _buildProfileOption(
              context,
              icon: Icons.person,
              title: 'Edit Profile',
              onTap: () {
                // TODO: Navigate to edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile functionality coming soon')),
                );
              },
            ),
            
            _buildProfileOption(
              context,
              icon: Icons.location_on,
              title: 'Delivery Addresses',
              onTap: () {
                // TODO: Navigate to addresses screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Delivery Addresses functionality coming soon')),
                );
              },
            ),
            
            _buildProfileOption(
              context,
              icon: Icons.payment,
              title: 'Payment Methods',
              onTap: () {
                // TODO: Navigate to payment methods screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment Methods functionality coming soon')),
                );
              },
            ),
            
            _buildProfileOption(
              context,
              icon: Icons.history,
              title: 'Order History',
              onTap: () {
                // TODO: Navigate to order history screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Order History functionality coming soon')),
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
                  const SnackBar(content: Text('Settings functionality coming soon')),
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
                            final authNotifier = ProviderScope.containerOf(context).read(authStateProvider.notifier);
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
          const Icon(
            Icons.account_circle,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'Not Signed In',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign in to access your profile',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
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
}