import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final UserProfile userProfile;
  final VoidCallback? onEditProfile;

  const ProfileHeaderWidget({
    super.key,
    required this.userProfile,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.black87.withValues(alpha: 0.1),
              backgroundImage: userProfile.avatarUrl != null
                  ? NetworkImage(userProfile.avatarUrl!)
                  : null,
              child: userProfile.avatarUrl == null
                  ? const Icon(Icons.person, size: 50, color: Colors.black87)
                  : null,
            ),
            const SizedBox(height: 16),
            // User name
            Text(
              userProfile.fullName ?? 'User',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // User email
            Text(
              userProfile.email,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // Edit profile button
            ElevatedButton.icon(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
