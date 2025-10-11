import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/order/presentation/providers/cart_provider.dart';
import 'package:food_delivery_app/features/profile/presentation/providers/address_provider.dart';
import 'package:food_delivery_app/shared/models/address.dart';
import 'package:go_router/go_router.dart';

class AddressSelector extends ConsumerWidget {
  const AddressSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final addressState = ref.watch(addressProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Don't show address selector for pickup
    if (cartState.deliveryMethod == DeliveryMethod.pickup) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Address',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                // Navigate to add address screen
                context.push('/profile/addresses/add');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add New'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (addressState.isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (addressState.addresses.isEmpty)
          _EmptyAddressCard(
            onAddAddress: () {
              context.push('/profile/addresses/add');
            },
          )
        else
          Column(
            children: [
              ...addressState.addresses.map(
                (address) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _AddressCard(
                    address: address,
                    isSelected: cartState.selectedAddress?.id == address.id,
                    onSelect: () {
                      cartNotifier.setSelectedAddress(address);
                    },
                    onEdit: () {
                      context.push('/profile/addresses/edit/${address.id}');
                    },
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _DeliveryNotesField(
          initialValue: cartState.deliveryNotes,
          onChanged: (notes) {
            cartNotifier.setDeliveryNotes(notes);
          },
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final Address address;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  const _AddressCard({
    required this.address,
    required this.isSelected,
    required this.onSelect,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : colorScheme.surface,
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getIconForAddressType(address.type),
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _getLabelForAddressType(address.type),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.primary
                              : null,
                        ),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${address.street}${address.apartment != null ? ', ${address.apartment}' : ''}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Text(
                    '${address.city}, ${address.state} ${address.zipCode}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (address.deliveryInstructions != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      address.deliveryInstructions!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onEdit,
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Edit address',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForAddressType(AddressType type) {
    switch (type) {
      case AddressType.home:
        return Icons.home_outlined;
      case AddressType.work:
        return Icons.work_outline;
      case AddressType.other:
        return Icons.location_on_outlined;
    }
  }

  String _getLabelForAddressType(AddressType type) {
    switch (type) {
      case AddressType.home:
        return 'Home';
      case AddressType.work:
        return 'Work';
      case AddressType.other:
        return 'Other';
    }
  }
}

class _EmptyAddressCard extends StatelessWidget {
  final VoidCallback onAddAddress;

  const _EmptyAddressCard({required this.onAddAddress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border.all(
          color: colorScheme.outlineVariant,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 48,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No saved addresses',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a delivery address to continue',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAddAddress,
            icon: const Icon(Icons.add),
            label: const Text('Add Address'),
          ),
        ],
      ),
    );
  }
}

class _DeliveryNotesField extends StatelessWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const _DeliveryNotesField({
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: initialValue),
      decoration: const InputDecoration(
        labelText: 'Delivery Instructions (Optional)',
        hintText: 'e.g., Ring the doorbell, Leave at door',
        prefixIcon: Icon(Icons.notes_outlined),
        border: OutlineInputBorder(),
      ),
      maxLines: 2,
      maxLength: 200,
      onChanged: onChanged,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
