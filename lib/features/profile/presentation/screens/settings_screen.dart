import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/theme_provider.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Theme selection
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(themeState.themeMode)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showThemeDialog(context, ref),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Notifications',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Notification settings
          SwitchListTile(
            secondary: const Icon(Icons.notifications),
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive order updates'),
            value: true,
            onChanged: (value) {
              // TODO: Implement notification toggle
            },
          ),

          SwitchListTile(
            secondary: const Icon(Icons.email),
            title: const Text('Email Notifications'),
            subtitle: const Text('Receive promotional emails'),
            value: false,
            onChanged: (value) {
              // TODO: Implement email notification toggle
            },
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Account',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to edit profile
            },
          ),

          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Delivery Addresses'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to addresses
            },
          ),

          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payment Methods'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/profile/payment-methods'),
          ),

          const Divider(),

          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Support',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to help
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to privacy policy
            },
          ),

          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to terms
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            subtitle: const Text('Version 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showAboutDialog(context);
            },
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                _showLogoutConfirmation(context);
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System default';
    }
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.read(themeProvider).themeMode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppThemeMode>(
              title: const Text('Light'),
              value: AppThemeMode.light,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('Dark'),
              value: AppThemeMode.dark,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<AppThemeMode>(
              title: const Text('System default'),
              value: AppThemeMode.system,
              // ignore: deprecated_member_use
              groupValue: currentTheme,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'NandyFood',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.fastfood,
        size: 48,
        color: Colors.deepOrange,
      ),
      children: [
        const Text(
          'A modern food delivery application built with Flutter and Supabase.',
        ),
      ],
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement sign out
              Navigator.pop(context);
              context.go('/auth/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
