import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Account settings section
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Account Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.deepOrange),
                    title: const Text('Edit Profile'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to edit profile screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications, color: Colors.deepOrange),
                    title: const Text('Notifications'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Toggle notifications
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Notifications ${value ? 'enabled' : 'disabled'}')),
                        );
                      },
                      activeColor: Colors.deepOrange,
                    ),
                    onTap: () {
                      // Toggle notifications
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Toggle notifications functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security, color: Colors.deepOrange),
                    title: const Text('Security'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to security settings screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Security settings functionality coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Preferences section
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.deepOrange),
                    title: const Text('Dark Mode'),
                    trailing: Switch(
                      value: false,
                      onChanged: (value) {
                        // Toggle dark mode
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Dark mode ${value ? 'enabled' : 'disabled'}')),
                        );
                      },
                      activeColor: Colors.deepOrange,
                    ),
                    onTap: () {
                      // Toggle dark mode
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Toggle dark mode functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.deepOrange),
                    title: const Text('Language'),
                    subtitle: const Text('English'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to language selection screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Language selection functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.deepOrange),
                    title: const Text('Location Services'),
                    trailing: Switch(
                      value: true,
                      onChanged: (value) {
                        // Toggle location services
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Location services ${value ? 'enabled' : 'disabled'}')),
                        );
                      },
                      activeColor: Colors.deepOrange,
                    ),
                    onTap: () {
                      // Toggle location services
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Toggle location services functionality coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Support section
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help, color: Colors.deepOrange),
                    title: const Text('Help Center'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to help center
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help center functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback, color: Colors.deepOrange),
                    title: const Text('Send Feedback'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to feedback screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Feedback functionality coming soon')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info, color: Colors.deepOrange),
                    title: const Text('About'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to about screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('About functionality coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Danger zone section
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.delete, color: Colors.red),
                    title: const Text('Delete Account'),
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Show delete account confirmation dialog
                      _showDeleteAccountDialog(context, ref);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone. '
          'All your data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              
              // Show loading indicator
              final loadingDialog = AlertDialog(
                content: const Row(
                  children: [
                    LoadingIndicator(),
                    SizedBox(width: 20),
                    Text('Deleting account...'),
                  ],
                ),
              );
              
              showDialog(context: context, builder: (context) => loadingDialog);
              
              try {
                // In a real implementation, this would delete the user account
                await Future.delayed(const Duration(seconds: 2));
                
                // Close loading dialog
                Navigator.of(context).pop();
                
                // Sign out the user
                await ref.read(authStateProvider.notifier).signOut();
                
                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                // Navigate back to the home screen
                if (context.mounted) {
                  Navigator.of(context).pop(); // Close settings screen
                }
              } catch (e) {
                // Close loading dialog
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}