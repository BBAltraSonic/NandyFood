import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator_widget.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock addresses data
    final addresses = [
      {
        'id': '1',
        'label': 'Home',
        'address': '123 Main Street, Apt 4B, New York, NY 10001',
        'isDefault': true,
      },
      {
        'id': '2',
        'label': 'Work',
        'address': '456 Business Ave, Suite 101, New York, NY 1002',
        'isDefault': false,
      },
      {
        'id': '3',
        'label': 'Gym',
        'address': '789 Fitness Blvd, New York, NY 10003',
        'isDefault': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add new address screen
              _navigateToAddAddress(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: addresses.length + 1, // +1 for the "Add New Address" option
        itemBuilder: (context, index) {
          if (index == addresses.length) {
            // Add new address option
            return Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => _navigateToAddAddress(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      'Add New Address',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
            );
          }

          final address = addresses[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.deepOrange),
                ),
                child: Icon(
                  address['label'] == 'Home' 
                      ? Icons.home 
                      : address['label'] == 'Work' 
                          ? Icons.work 
                          : Icons.fitness_center,
                  color: Colors.deepOrange,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    address['label'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (address['isDefault'] as bool)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                address['address'] as String,
                style: const TextStyle(height: 1.4),
              ),
              trailing: PopupMenuButton(
                onSelected: (value) {
                  if (value == 'edit') {
                    _navigateToEditAddress(context, address['id'] as String);
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context, address['id'] as String);
                  } else if (value == 'set_default') {
                    // TODO: Implement set as default functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Set as default address')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'set_default',
                    child: Row(
                      children: [
                        Icon(Icons.star_border, size: 20),
                        SizedBox(width: 10),
                        Text('Set as Default'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20),
                        SizedBox(width: 10),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToAddAddress(BuildContext context) {
    // Navigate to address screen
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new address functionality coming soon')),
    );
  }

 void _navigateToEditAddress(BuildContext context, String addressId) {
    // Navigate to edit address screen
    // For now, show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit address functionality coming soon')),
    );
  }

 void _showDeleteConfirmationDialog(BuildContext context, String addressId) {
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
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Address deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
 }
}