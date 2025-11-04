import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/models/restaurant_staff.dart';
import 'package:food_delivery_app/core/utils/app_logger.dart';

class AddEditStaffScreen extends ConsumerStatefulWidget {
  final String restaurantId;
  final RestaurantStaff? staff;
  final Future<bool> Function(CreateStaffRequest request) onSave;

  const AddEditStaffScreen({
    super.key,
    required this.restaurantId,
    this.staff,
    required this.onSave,
  });

  @override
  ConsumerState<AddEditStaffScreen> createState() => _AddEditStaffScreenState();
}

class _AddEditStaffScreenState extends ConsumerState<AddEditStaffScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _notesController = TextEditingController();

  StaffRoleType _selectedRole = StaffRoleType.basicStaff;
  EmploymentType _selectedEmploymentType = EmploymentType.fullTime;
  StaffPermissions _permissions = const StaffPermissions();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _initializeFromStaff();
    } else {
      _updatePermissionsForRole(_selectedRole);
    }

    // Listen to role changes
    _emailController.addListener(() {});
    _fullNameController.addListener(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _hourlyRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromStaff() {
    final staff = widget.staff!;
    _emailController.text = staff.userProfile?.email ?? '';
    _fullNameController.text = staff.userProfile?.fullName ?? '';
    _phoneNumberController.text = staff.userProfile?.phoneNumber ?? '';
    _selectedRole = staff.role;
    _selectedEmploymentType = staff.employmentType;
    _permissions = staff.permissions;
    _hourlyRateController.text = staff.hourlyRate?.toString() ?? '';
    _notesController.text = staff.notes ?? '';
  }

  void _updatePermissionsForRole(StaffRoleType role) {
    setState(() {
      _permissions = StaffPermissions.forRole(role);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff == null ? 'Add Staff Member' : 'Edit Staff Member'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveStaff,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildRoleSection(),
              const SizedBox(height: 24),
              _buildPermissionsSection(),
              const SizedBox(height: 24),
              _buildEmploymentSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Basic Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'staff@example.com',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          enabled: widget.staff == null, // Can't change email for existing staff
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an email address';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'John Doe',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a full name';
            }
            if (value.length < 2) {
              return 'Name must be at least 2 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneNumberController,
          decoration: const InputDecoration(
            labelText: 'Phone Number (Optional)',
            hintText: '+1 234 567 8900',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildRoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select the role for this staff member. Each role comes with default permissions.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        ...StaffRoleType.values.map((role) {
          return RadioListTile<StaffRoleType>(
            title: Text(_getRoleDisplayName(role)),
            subtitle: Text(_getRoleDescription(role)),
            value: role,
            groupValue: _selectedRole,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedRole = value;
                  _updatePermissionsForRole(value);
                });
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildPermissionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permissions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Customize permissions for this role. These can be adjusted as needed.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('View Orders'),
                subtitle: const Text('Can view order information'),
                value: _permissions.viewOrders,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(viewOrders: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Update Orders'),
                subtitle: const Text('Can update order status and details'),
                value: _permissions.updateOrders,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(updateOrders: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('View Menu'),
                subtitle: const Text('Can view menu items'),
                value: _permissions.viewMenu,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(viewMenu: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Update Menu'),
                subtitle: const Text('Can add/edit/remove menu items'),
                value: _permissions.updateMenu,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(updateMenu: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Manage Staff'),
                subtitle: const Text('Can add/edit/remove other staff members'),
                value: _permissions.manageStaff,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(manageStaff: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('View Analytics'),
                subtitle: const Text('Can view restaurant analytics and reports'),
                value: _permissions.viewAnalytics,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(viewAnalytics: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Process Payments'),
                subtitle: const Text('Can process payments and refunds'),
                value: _permissions.processPayments,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(processPayments: value ?? false);
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('View Reports'),
                subtitle: const Text('Can view detailed reports'),
                value: _permissions.viewReports,
                onChanged: (value) {
                  setState(() {
                    _permissions = _permissions.copyWith(viewReports: value ?? false);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmploymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employment Details',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<EmploymentType>(
          value: _selectedEmploymentType,
          decoration: const InputDecoration(
            labelText: 'Employment Type',
            prefixIcon: Icon(Icons.work),
            border: OutlineInputBorder(),
          ),
          items: EmploymentType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(_getEmploymentTypeDisplayName(type)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedEmploymentType = value;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _hourlyRateController,
          decoration: const InputDecoration(
            labelText: 'Hourly Rate (Optional)',
            hintText: '15.00',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              final rate = double.tryParse(value);
              if (rate == null || rate < 0) {
                return 'Please enter a valid hourly rate';
              }
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes',
            hintText: 'Add any additional notes about this staff member...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = CreateStaffRequest(
        email: _emailController.text.trim(),
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty
            ? null
            : _phoneNumberController.text.trim(),
        role: _selectedRole,
        employmentType: _selectedEmploymentType,
        permissions: _permissions,
        hourlyRate: _hourlyRateController.text.trim().isEmpty
            ? null
            : double.tryParse(_hourlyRateController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final success = await widget.onSave(request);

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.staff == null
                ? 'Staff member added successfully'
                : 'Staff member updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to save staff member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
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
  }

  String _getRoleDisplayName(StaffRoleType role) {
    switch (role) {
      case StaffRoleType.manager:
        return 'Manager';
      case StaffRoleType.chef:
        return 'Chef';
      case StaffRoleType.cashier:
        return 'Cashier';
      case StaffRoleType.server:
        return 'Server';
      case StaffRoleType.deliveryCoordinator:
        return 'Delivery Coordinator';
      case StaffRoleType.basicStaff:
        return 'Basic Staff';
    }
  }

  String _getRoleDescription(StaffRoleType role) {
    switch (role) {
      case StaffRoleType.manager:
        return 'Full restaurant management capabilities';
      case StaffRoleType.chef:
        return 'Can manage orders and view menu';
      case StaffRoleType.cashier:
        return 'Can handle orders and payments';
      case StaffRoleType.server:
        return 'Can view orders and menu';
      case StaffRoleType.deliveryCoordinator:
        return 'Can manage order deliveries';
      case StaffRoleType.basicStaff:
        return 'Basic viewing permissions';
    }
  }

  String _getEmploymentTypeDisplayName(EmploymentType type) {
    switch (type) {
      case EmploymentType.fullTime:
        return 'Full Time';
      case EmploymentType.partTime:
        return 'Part Time';
      case EmploymentType.contractor:
        return 'Contractor';
    }
  }
}