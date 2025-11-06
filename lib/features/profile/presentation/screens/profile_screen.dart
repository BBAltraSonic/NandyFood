import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';
import 'package:food_delivery_app/features/support/presentation/screens/customer_support_screen.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

// Provider to fetch user profile from database
final userProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) async {
  try {
    AppLogger.info('Loading user profile for: $userId');
    
    final response = await DatabaseService()
        .client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      AppLogger.warning('No user profile found for: $userId');
      return null;
    }

    AppLogger.success('User profile loaded successfully');
    return UserProfile.fromJson(response);
  } catch (e) {
    AppLogger.error('Error loading user profile: $e');
    return null;
  }
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // If not authenticated, show login prompt
    if (!authState.isAuthenticated || authState.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(
          child: Text('Please log in to view your profile'),
        ),
      );
    }

    final userId = authState.user!.id;
    final userProfileAsync = ref.watch(userProfileProvider(userId));

    return Scaffold(
      backgroundColor: NeutralColors.background,
      appBar: AppBar(
        backgroundColor: BrandColors.secondary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: BrandColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: BrandColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: BrandColors.primary,
                size: 24,
              ),
              onPressed: () {
                // Navigate to edit profile screen
              },
            ),
          ),
        ],
      ),
      body: userProfileAsync.when(
        data: (userProfile) {
          if (userProfile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Profile not found'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(userProfileProvider(userId));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return _buildProfileContent(context, ref, userProfile);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error('Profile error: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${error.toString()}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(userProfileProvider(userId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build profile content
  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    UserProfile userProfile,
  ) {
    return Container(
      color: NeutralColors.background,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile header
            _buildProfileHeader(userProfile),

            // Profile sections
            const SizedBox(height: 32),
            _buildProfileSection(
              context,
              'Personal Information',
              Icons.person_outline,
              _buildPersonalInfo(userProfile),
              onTap: () {
                // Navigate to edit personal info
              },
            ),

            _buildProfileSection(
              context,
              'Addresses',
              Icons.location_on_outlined,
              _buildAddressesSection(ref, userProfile),
              onTap: () {
                // Navigate to addresses screen
              },
            ),

            _buildProfileSection(
              context,
              'Payment Methods',
              Icons.payment_outlined,
              _buildPaymentMethodsSection(),
              onTap: () {
                // Navigate to payment methods screen
              },
            ),

            _buildProfileSection(
              context,
              'Order History',
              Icons.history_outlined,
              _buildOrderHistorySection(),
              onTap: () {
                // Navigate to order history screen
              },
            ),

            _buildProfileSection(
              context,
              'Preferences',
              Icons.settings_outlined,
              _buildPreferencesSection(ref, userProfile),
              onTap: () {
                // Navigate to preferences screen
              },
            ),

            _buildProfileSection(
              context,
              'Send Feedback',
              Icons.feedback_outlined,
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help us improve the app',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: NeutralColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share your thoughts and suggestions',
                    style: TextStyle(
                      fontSize: 14,
                      color: NeutralColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              onTap: () {
                context.push('/profile/feedback');
              },
            ),

            _buildProfileSection(
              context,
              'Customer Support',
              Icons.support_agent_outlined,
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Get help and support',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: NeutralColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Contact our support team for assistance',
                    style: TextStyle(
                      fontSize: 14,
                      color: NeutralColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CustomerSupportScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),
            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildModernLogoutButton(context, ref),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Build profile header
  Widget _buildProfileHeader(UserProfile userProfile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.primary,
            BrandColors.primaryLight,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile picture with status indicator
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: BrandColors.secondary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        BrandColors.secondary,
                        BrandColors.secondaryLight,
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: BrandColors.primary,
                  ),
                ),
              ),
              // Online status indicator
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: SemanticColors.success,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: BrandColors.secondary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User info
          Column(
            children: [
              Text(
                userProfile.fullName ?? 'User',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.secondary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                userProfile.email,
                style: TextStyle(
                  fontSize: 16,
                  color: BrandColors.secondary.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (userProfile.phoneNumber != null) ...[
                const SizedBox(height: 6),
                Text(
                  userProfile.phoneNumber!,
                  style: TextStyle(
                    fontSize: 16,
                    color: BrandColors.secondary.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: BrandColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Premium Member',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: BrandColors.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: BrandColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: BrandColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: NeutralColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    if (onTap != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NeutralColors.gray100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: BrandColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build personal info section
  Widget _buildPersonalInfo(UserProfile userProfile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Full Name', userProfile.fullName ?? 'Not provided'),
        const SizedBox(height: 12),
        _buildInfoRow('Email', userProfile.email),
        const SizedBox(height: 12),
        _buildInfoRow('Phone', userProfile.phoneNumber ?? 'Not provided'),
        const SizedBox(height: 12),
        _buildInfoRow(
          'Member Since',
          '${userProfile.createdAt.day}/${userProfile.createdAt.month}/${userProfile.createdAt.year}',
        ),
      ],
    );
  }

  /// Build addresses section
  Widget _buildAddressesSection(WidgetRef ref, UserProfile userProfile) {
    final defaultAddress = userProfile.defaultAddress;

    if (defaultAddress == null) {
      return Row(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 20,
            color: NeutralColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            'No addresses saved',
            style: TextStyle(
              fontSize: 16,
              color: NeutralColors.textTertiary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20,
              color: BrandColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${defaultAddress['street']}, ${defaultAddress['city']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: NeutralColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: BrandColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Default Address',
            style: TextStyle(
              fontSize: 12,
              color: BrandColors.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Build payment methods section
  Widget _buildPaymentMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: NeutralColors.gray100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'VISA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: BrandColors.primary,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•••• •••• •••• 1234',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: NeutralColors.textPrimary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: SemanticColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Default Payment Method',
            style: TextStyle(
              fontSize: 12,
              color: SemanticColors.success,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  /// Build order history section
  Widget _buildOrderHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: BrandColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '24 orders completed',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: NeutralColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Last order: Yesterday',
          style: TextStyle(
            fontSize: 14,
            color: NeutralColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Build preferences section
  Widget _buildPreferencesSection(WidgetRef ref, UserProfile userProfile) {
    final preferences = userProfile.preferences ?? {};
    final notificationsEnabled = preferences['notifications'] as bool? ?? true;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              notificationsEnabled ? Icons.notifications_outlined : Icons.notifications_off_outlined,
              size: 20,
              color: notificationsEnabled ? BrandColors.primary : NeutralColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Text(
              'Push Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: NeutralColors.textPrimary,
              ),
            ),
          ],
        ),
        Switch(
          value: notificationsEnabled,
          onChanged: (value) {
            // Update notification preference
          },
          activeTrackColor: BrandColors.primary.withValues(alpha: 0.3),
          activeColor: BrandColors.primary,
          inactiveTrackColor: NeutralColors.gray300,
          inactiveThumbColor: NeutralColors.gray500,
        ),
      ],
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: NeutralColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: NeutralColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build modern logout button
  Widget _buildModernLogoutButton(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutConfirmation(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.red.withValues(alpha: 0.9),
                  Colors.red.withValues(alpha: 0.8),
                ],
              ),
              border: Border.all(
                color: Colors.red.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_outlined,
                  color: BrandColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: BrandColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: BrandColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout_outlined,
                    size: 32,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to logout?',
                  style: TextStyle(
                    fontSize: 16,
                    color: NeutralColors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: NeutralColors.gray300,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.primary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            ref.read(authStateProvider.notifier).signOut();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.red.withValues(alpha: 0.9),
                                  Colors.red.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BrandColors.secondary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
      },
    );
  }
}
