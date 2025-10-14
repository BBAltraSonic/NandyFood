import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/features/authentication/presentation/providers/user_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/avatar_upload_widget.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/order_history_filter_widget.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/favorites_section_widget.dart';

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
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.deepOrange),
                      const SizedBox(width: 12),
                      const Text(
                        'Order History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => context.push('/profile/order-history'),
                        child: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OrderHistoryFilterWidget(
                    onFilterChanged: (status) {
                      // Handle filter change
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildOrderHistorySection(),
                ],
              ),
            ),
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

          const SizedBox(height: 10),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite, color: Colors.deepOrange),
                      const SizedBox(width: 12),
                      const Text(
                        'Favorites',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => context.push('/profile/favorites'),
                        child: const Icon(Icons.arrow_forward_ios, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FavoritesSectionWidget(
                    favorites: userProfile.favoriteRestaurants ?? [],
                    onRemoveFavorite: (restaurantId) {
                      // Handle removing favorite
                    },
                  ),
                ],
              ),
            ),
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
          // Profile picture with upload
          AvatarUploadWidget(
            currentImageUrl: userProfile.avatarUrl,
            onImageUploaded: (imageUrl) {
              // Update user profile with new avatar
            },
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
    final dietaryPrefs = preferences['dietaryPreferences'] as List<String>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
        ),
        const SizedBox(height: 8),
        const Text('Dietary Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildDietaryChip('Vegetarian', dietaryPrefs.contains('Vegetarian')),
            _buildDietaryChip('Vegan', dietaryPrefs.contains('Vegan')),
            _buildDietaryChip('Gluten-Free', dietaryPrefs.contains('Gluten-Free')),
            _buildDietaryChip('Dairy-Free', dietaryPrefs.contains('Dairy-Free')),
          ],
        ),
      ],
    );
  }

  /// Build dietary preference chip
  Widget _buildDietaryChip(String label, bool isSelected) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        // Handle dietary preference selection
      },
      selectedColor: Colors.deepOrange,
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
