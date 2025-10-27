import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/image_upload_service.dart';
import 'package:food_delivery_app/core/services/database_service.dart';
import 'package:food_delivery_app/features/authentication/presentation/providers/user_provider.dart';
import 'package:food_delivery_app/shared/models/user_profile.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen> {
  final _imageService = ImageUploadService();
  String? _avatarUrl;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    final authState = ref.read(authStateProvider);
    final user = ref.read(userProvider).userProfile;
    if (authState.user != null) {
      _nameController.text = user?.fullName ??
          authState.user!.userMetadata?['full_name'] ??
          authState.user!.email?.split('@')[0] ??
          '';
      _emailController.text = authState.user!.email ?? '';
      _phoneController.text = user?.phoneNumber ?? '';
      _avatarUrl = user?.avatarUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState!.validate()) {
                      await _updateProfile();
                    }
                  },
            child: const Text('Save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile picture section
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: (_avatarUrl ?? ref.watch(userProvider).userProfile?.avatarUrl) != null
                              ? NetworkImage((_avatarUrl ?? ref.watch(userProvider).userProfile!.avatarUrl)!)
                              : null,
                          child: (_avatarUrl ?? ref.watch(userProvider).userProfile?.avatarUrl) == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _isLoading ? null : _pickAndUploadAvatar,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.deepOrange,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    TextFormField(
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        hintText: 'Tell us about yourself',
                        prefixIcon: Icon(Icons.info),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () async {
                                if (_formKey.currentState!.validate()) {
                                  await _updateProfile();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const LoadingIndicator()
                            : const Text(
                                'Save Changes',
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = <String, dynamic>{
        'full_name': _nameController.text.trim(),
      };
      if (_phoneController.text.trim().isNotEmpty) {
        data['phone_number'] = _phoneController.text.trim();
      }
      if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
        data['avatar_url'] = _avatarUrl;
      }

      await DatabaseService().updateUserProfile(userId, data);

      // Update local provider state
      final current = ref.read(userProvider).userProfile;
      if (current != null) {
        await ref.read(userProvider.notifier).updateUserProfile(
              current.copyWith(
                fullName: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim().isEmpty
                    ? null
                    : _phoneController.text.trim(),
                avatarUrl: _avatarUrl ?? current.avatarUrl,
              ),
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to change avatar')),
      );
      return;
    }

    try {
      final File? image = await _imageService.showImageSourceDialog(context: context);
      if (image == null) return;

      setState(() => _isLoading = true);

      final oldUrl = _avatarUrl ?? ref.read(userProvider).userProfile?.avatarUrl;

      final newUrl = await _imageService.uploadAvatar(image, userId);

      // Delete old avatar (best-effort)
      if (oldUrl != null && oldUrl.isNotEmpty) {
        await _imageService.deleteOldAvatar(oldUrl);
      }

      // Persist new avatar URL to DB
      await DatabaseService().updateUserProfile(userId, {
        'avatar_url': newUrl,
      });

      // Update local state/provider
      final current = ref.read(userProvider).userProfile;
      if (current != null) {
        await ref.read(userProvider.notifier).updateUserProfile(
              current.copyWith(avatarUrl: newUrl),
            );
      }

      if (!mounted) return;
      setState(() {
        _avatarUrl = newUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update avatar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

}
