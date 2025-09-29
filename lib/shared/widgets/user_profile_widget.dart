import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

class UserProfileWidget extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onEditProfile;

  const UserProfileWidget({
    super.key,
    required this.userProfile,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Row(
              children: [
                // Profile picture placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.deepOrange,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                // User name and email
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProfile.fullName ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userProfile.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button
                if (onEditProfile != null)
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEditProfile,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // User details
            if (userProfile.phoneNumber != null)
              _buildDetailRow(
                Icons.phone,
                'Phone Number',
                userProfile.phoneNumber!,
              ),
            const SizedBox(height: 8),
            
            if (userProfile.defaultAddress != null)
              _buildDetailRow(
                Icons.location_on,
                'Default Address',
                _formatAddress(userProfile.defaultAddress!),
              ),
            const SizedBox(height: 8),
            
            _buildDetailRow(
              Icons.calendar_today,
              'Member Since',
              _formatDate(userProfile.createdAt),
            ),
            const SizedBox(height: 8),
            
            if (userProfile.preferences != null)
              _buildDetailRow(
                Icons.settings,
                'Preferences',
                _formatPreferences(userProfile.preferences!),
              ),
          ],
        ),
      ),
    );
  }

  /// Build a detail row with icon, label, and value
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.deepOrange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format address for display
  String _formatAddress(Map<String, dynamic> address) {
    final street = address['street'] ?? '';
    final city = address['city'] ?? '';
    final state = address['state'] ?? '';
    final zipCode = address['zip_code'] ?? '';
    
    return '$street, $city, $state $zipCode';
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format preferences for display
  String _formatPreferences(Map<String, dynamic> preferences) {
    return preferences.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  }
}