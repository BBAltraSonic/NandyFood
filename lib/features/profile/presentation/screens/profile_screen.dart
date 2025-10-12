import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/authentication/presentation/providers/user_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
            },
          ),
        ],
      ),
      body: userState.userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(context, ref, userState.userProfile!),
    );
  }

  /// Build profile content
  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    dynamic userProfile,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          _buildProfileHeader(userProfile),

          // Profile sections
          const SizedBox(height: 20),
          _buildProfileSection(
            context,
            'Personal Information',
            Icons.person,
            _buildPersonalInfo(userProfile),
            onTap: () {
              // Navigate to edit personal info
            },
          ),

          const SizedBox(height: 10),
          _buildProfileSection(
            context,
            'Addresses',
            Icons.location_on,
            _buildAddressesSection(ref, userProfile),
            onTap: () {
              // Navigate to addresses screen
            },
          ),

          const SizedBox(height: 10),
          _buildProfileSection(
            context,
            'Payment Methods',
            Icons.payment,
            _buildPaymentMethodsSection(),
            onTap: () {
              // Navigate to payment methods screen
            },
          ),

          const SizedBox(height: 10),
          _buildProfileSection(
            context,
            'Order History',
            Icons.history,
            _buildOrderHistorySection(),
            onTap: () {
              // Navigate to order history screen
            },
          ),

          const SizedBox(height: 10),
          _buildProfileSection(
            context,
            'Preferences',
            Icons.settings,
            _buildPreferencesSection(ref, userProfile),
            onTap: () {
              // Navigate to preferences screen
            },
          ),

          const SizedBox(height: 30),
          // Logout button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                _showLogoutConfirmation(context, ref);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Build profile header
  Widget _buildProfileHeader(dynamic userProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.deepOrange.withValues(alpha: 0.1)),
      child: Row(
        children: [
          // Profile picture
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.deepOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 20),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfile.fullName ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userProfile.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                if (userProfile.phoneNumber != null)
                  Text(
                    userProfile.phoneNumber,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile section
  Widget _buildProfileSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content, {
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.deepOrange),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (onTap != null)
                    const Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        ),
      ),
    );
  }

  /// Build personal info section
  Widget _buildPersonalInfo(dynamic userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Full Name', userProfile.fullName ?? 'Not provided'),
        const SizedBox(height: 8),
        _buildInfoRow('Email', userProfile.email),
        const SizedBox(height: 8),
        _buildInfoRow('Phone', userProfile.phoneNumber ?? 'Not provided'),
        const SizedBox(height: 8),
        _buildInfoRow(
          'Member Since',
          '${userProfile.createdAt.day}/${userProfile.createdAt.month}/${userProfile.createdAt.year}',
        ),
      ],
    );
  }

  /// Build addresses section
  Widget _buildAddressesSection(WidgetRef ref, dynamic userProfile) {
    final defaultAddress = userProfile.defaultAddress;

    if (defaultAddress == null) {
      return const Text('No addresses saved');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${defaultAddress['street']}, ${defaultAddress['city']}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        const Text(
          'Default Address',
          style: TextStyle(
            fontSize: 14,
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build payment methods section
  Widget _buildPaymentMethodsSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• • • • • • • • 1234', style: TextStyle(fontSize: 16)),
        SizedBox(height: 4),
        Text(
          'Visa • Default',
          style: TextStyle(
            fontSize: 14,
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build order history section
  Widget _buildOrderHistorySection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('24 orders completed', style: TextStyle(fontSize: 16)),
        SizedBox(height: 4),
        Text(
          'Last order: Yesterday',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// Build preferences section
  Widget _buildPreferencesSection(WidgetRef ref, dynamic userProfile) {
    final preferences = userProfile.preferences ?? {};
    final notificationsEnabled = preferences['notifications'] as bool? ?? true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Notifications', style: TextStyle(fontSize: 16)),
        Switch(
          value: notificationsEnabled,
          onChanged: (value) {
            // Update notification preference
          },
          activeColor: Colors.deepOrange,
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
      ],
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(userProvider.notifier).signOut();
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
