import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/address_provider.dart';
import 'package:food_delivery_app/shared/models/address.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/features/profile/presentation/screens/add_edit_address_screen.dart';

class AddressScreen extends ConsumerWidget {
  const AddressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final userId = auth.user?.id;
    final state = ref.watch(addressProvider);
    final notifier = ref.read(addressProvider.notifier);

    // Load addresses on first build when authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userId != null && !state.isLoading && state.addresses.isEmpty) {
        notifier.loadAddresses(userId);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddAddress(context, ref),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (userId == null) {
            return const Center(child: Text('Please sign in to manage addresses'));
          }
          if (state.isLoading && state.addresses.isEmpty) {
            return const Center(child: LoadingIndicator());
          }
          if (state.errorMessage != null && state.addresses.isEmpty) {
            return Center(
              child: ErrorMessageWidget(
                message: state.errorMessage!,
                onRetry: () => notifier.loadAddresses(userId),
              ),
            );
          }

          final addresses = state.addresses;
          return ListView.builder(
            itemCount: addresses.length + 1, // +1 for the "Add New Address" option
            itemBuilder: (context, index) {
              if (index == addresses.length) {
                // Add new address option
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: OutlinedButton(
                    onPressed: () => _navigateToAddAddress(context, ref),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.deepOrange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.deepOrange),
                        SizedBox(width: 8),
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
                      _iconForType(address.type),
                      color: Colors.deepOrange,
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(
                        _labelForType(address.type),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (address.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
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
                    _formatAddress(address),
                    style: const TextStyle(height: 1.4),
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _navigateToEditAddress(context, ref, address.id);
                      } else if (value == 'delete') {
                        _showDeleteConfirmationDialog(context, () async {
                          await notifier.removeAddress(address.id);
                        });
                      } else if (value == 'set_default') {
                        await notifier.setDefaultAddress(address.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Default address updated')),
                          );
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star_border, size: 20),
                            SizedBox(width: 10),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
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
          );
        },
      ),
    );
  }

  IconData _iconForType(AddressType type) {
    switch (type) {
      case AddressType.home:
        return Icons.home;
      case AddressType.work:
        return Icons.work;
      case AddressType.other:
        return Icons.place;
    }
  }

  String _labelForType(AddressType type) {
    switch (type) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }

  String _formatAddress(Address a) {
    final parts = [
      a.street,
      if (a.apartment != null && a.apartment!.isNotEmpty) a.apartment!,
      '${a.city}, ${a.state} ${a.zipCode}',
    ];
    return parts.where((e) => e.trim().isNotEmpty).join(', ');
  }

  Future<void> _navigateToAddAddress(BuildContext context, WidgetRef ref) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
    );
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }
  }

  Future<void> _navigateToEditAddress(
      BuildContext context, WidgetRef ref, String addressId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditAddressScreen(addressId: addressId),
      ),
    );
    final userId = ref.read(authStateProvider).user?.id;
    if (userId != null) {
      await ref.read(addressProvider.notifier).loadAddresses(userId);
    }
  }

  void _showDeleteConfirmationDialog(
      BuildContext context, Future<void> Function() onConfirm) {
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
              Navigator.of(context).pop();
              await onConfirm();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Address deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
