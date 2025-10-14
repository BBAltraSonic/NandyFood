import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/profile/presentation/widgets/avatar_upload_widget.dart';
import 'package:food_delivery_app/features/authentication/presentation/providers/user_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load current user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  void _loadUserData() {
    final userState = ref.read(userProvider);
    if (userState.userProfile != null) {
      final profile = userState.userProfile!;
      _nameController.text = profile.fullName ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phoneNumber ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      // In a real app, you would call the update profile API
      final userNotifier = ref.read(userProvider.notifier);
      await userNotifier.updateProfile(
        fullName: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final userState = ref.watch(userProvider);
          if (userState.userProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar upload
                  AvatarUploadWidget(
                    currentImageUrl: userState.userProfile?.avatarUrl,
                    onImageUploaded: (imageUrl) async {
                      // Update avatar in profile
                      await ref.read(userProvider.notifier).updateAvatar(imageUrl);
                    },
                  ),
                  const SizedBox(height: 24),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Dietary preferences section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Dietary Preferences',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDietaryPreferencesSection(),
                  const SizedBox(height: 24),

                  // Address section
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Addresses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAddressesSection(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDietaryPreferencesSection() {
    final userState = ref.watch(userProvider);
    final dietaryPrefs = userState.userProfile?.dietaryPreferences as List<String>? ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildDietaryChip('Vegetarian', dietaryPrefs.contains('Vegetarian')),
        _buildDietaryChip('Vegan', dietaryPrefs.contains('Vegan')),
        _buildDietaryChip('Gluten-Free', dietaryPrefs.contains('Gluten-Free')),
        _buildDietaryChip('Dairy-Free', dietaryPrefs.contains('Dairy-Free')),
        _buildDietaryChip('Keto', dietaryPrefs.contains('Keto')),
        _buildDietaryChip('Paleo', dietaryPrefs.contains('Paleo')),
      ],
    );
  }

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
        // In a real app, you would update the user's dietary preferences
        // For now, we'll just show a snackbar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selected ? 'Added' : 'Removed'} $label preference'),
          ),
        );
      },
      selectedColor: Colors.deepOrange,
    );
  }

  Widget _buildAddressesSection() {
    final userState = ref.watch(userProvider);
    final addresses = userState.userProfile?.addresses as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (addresses.isEmpty)
          const Text('No addresses saved', style: TextStyle(color: Colors.grey))
        else
          ...addresses.map((address) => _buildAddressItem(address)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            // Navigate to add address screen
          },
          icon: const Icon(Icons.add),
          label: const Text('Add New Address'),
        ),
      ],
    );
  }

  Widget _buildAddressItem(dynamic address) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address['name'] ?? 'Home',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${address['street']}, ${address['city']}, ${address['state']} ${address['zipCode']}',
                ),
                if (address['isDefault'] == true)
                  const Text(
                    'Default Address',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit address screen
            },
          ),
        ],
      ),
    );
  }
}