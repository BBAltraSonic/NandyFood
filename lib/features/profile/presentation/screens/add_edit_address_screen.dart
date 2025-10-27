import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/address_provider.dart';
import 'package:food_delivery_app/shared/models/address.dart';
import 'package:food_delivery_app/shared/widgets/location_selector_widget.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final String? addressId; // Null for add, populated for edit
  final Map<String, dynamic>? address; // Null for add, populated for edit

  const AddEditAddressScreen({super.key, this.addressId, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _streetController = TextEditingController();
  final _apartmentController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _showLocationSelector = false;
  double? _latitude;
  double? _longitude;

  final _instructionsController = TextEditingController();

  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelController.text = (widget.address!['label'] as String?) ?? '';
      _streetController.text = (widget.address!['street'] as String?) ?? '';
      _apartmentController.text = (widget.address!['apartment'] as String?) ?? '';
      _cityController.text = (widget.address!['city'] as String?) ?? '';
      _stateController.text = (widget.address!['state'] as String?) ?? '';
      _zipCodeController.text = (widget.address!['zipCode'] as String?) ?? '';
      _instructionsController.text = (widget.address!['instructions'] as String?) ?? '';
      _isDefault = (widget.address!['isDefault'] as bool?) ?? false;
      _latitude = (widget.address!['latitude'] as num?)?.toDouble();
      _longitude = (widget.address!['longitude'] as num?)?.toDouble();
    } else if (widget.addressId != null) {
      final list = ref.read(addressProvider).addresses;
      Address? a;
      for (final x in list) {
        if (x.id == widget.addressId) {
          a = x;
          break;
        }
      }
      if (a != null) {
        _labelController.text = _labelFromType(a.type);
        _streetController.text = a.street;
        _apartmentController.text = a.apartment ?? '';
        _cityController.text = a.city;
        _stateController.text = a.state;
        _zipCodeController.text = a.zipCode;
        _instructionsController.text = a.deliveryInstructions ?? '';
        _isDefault = a.isDefault;
        _latitude = a.latitude;
        _longitude = a.longitude;
      }
    }
  }

  AddressType _typeFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return AddressType.home;
      case 'work':
        return AddressType.work;
      default:
        return AddressType.other;
    }
  }

  String _labelFromType(AddressType type) {
    switch (type) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }


  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.address == null ? 'Add Address' : 'Edit Address'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAddress,
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
                    // Address label
                    TextFormField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Address Label',
                        hintText: 'e.g., Home, Work, Gym',
                        prefixIcon: Icon(Icons.label),
                        border: OutlineInputBorder(),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an address label';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Street address
                    TextFormField(
                      controller: _streetController,
                      decoration: const InputDecoration(
                        labelText: 'Street Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter street address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Apartment/Suite
                    TextFormField(
                      controller: _apartmentController,
                      decoration: const InputDecoration(
                        labelText: 'Apartment/Suite (Optional)',
                        prefixIcon: Icon(Icons.apartment),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Use Map/Search
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showLocationSelector = !_showLocationSelector;
                          });
                        },
                        icon: const Icon(Icons.map),
                        label: Text(_showLocationSelector ? 'Hide Map/Search' : 'Use Map or Search'),
                      ),
                    ),
                    if (_showLocationSelector) ...[
                      const SizedBox(height: 12),
                      LocationSelectorWidget(
                        onLocationSelected: (loc) {
                          setState(() {
                            _streetController.text = (loc['street'] ?? '').toString();
                            _cityController.text = (loc['city'] ?? '').toString();
                            _stateController.text = (loc['state'] ?? '').toString();
                            _zipCodeController.text = (loc['postalCode'] ?? '').toString();
                            _latitude = (loc['latitude'] as num?)?.toDouble();
                            _longitude = (loc['longitude'] as num?)?.toDouble();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // City
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // State
                    TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // ZIP Code
                    TextFormField(
                      controller: _zipCodeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'ZIP Code',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ZIP code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Delivery instructions
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Instructions (Optional)',
                        hintText:
                            'e.g., Ring doorbell twice, leave at front desk',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Set as default address
                    CheckboxListTile(
                      title: const Text('Set as default delivery address'),
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAddress,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.address == null
                              ? 'Add Address'
                              : 'Update Address',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Delete button (only for edit mode)
                    if (widget.address != null) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => _deleteAddress(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Delete Address',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to save an address.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Map label to AddressType
      final label = _labelController.text.trim().toLowerCase();
      AddressType type;
      if (label == 'home') {
        type = AddressType.home;
      } else if (label == 'work') {
        type = AddressType.work;
      } else {
        type = AddressType.other;
      }

      final now = DateTime.now();
      final notifier = ref.read(addressProvider.notifier);

      if (widget.address == null) {
        final address = Address(
          id: 'temp_${now.millisecondsSinceEpoch}',
          userId: userId,
          type: type,
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          country: 'South Africa',
          isDefault: _isDefault,
          createdAt: now,
          updatedAt: now,
          apartment: _apartmentController.text.trim().isEmpty ? null : _apartmentController.text.trim(),
          deliveryInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        await notifier.addAddress(address);
      } else {
        // Editing: use provided address id when available
        final id = (widget.addressId ?? widget.address?['id']?.toString() ?? 'temp_${now.millisecondsSinceEpoch}');
        final address = Address(
          id: id,
          userId: userId,
          type: type,
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
          country: 'South Africa',
          isDefault: _isDefault,
          createdAt: now,
          updatedAt: now,
          apartment: _apartmentController.text.trim().isEmpty ? null : _apartmentController.text.trim(),
          deliveryInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
        );
        await notifier.updateAddress(address);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.address == null ? 'Address added successfully' : 'Address updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving address: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteAddress(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              setState(() {
                _isLoading = true;
              });

              try {
                final id = (widget.addressId ?? widget.address?['id']?.toString());
                if (id == null || id.isEmpty) {
                  throw Exception('Missing address id');
                }
                await ref.read(addressProvider.notifier).removeAddress(id);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.of(context).pop(); // Close edit screen
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting address: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
