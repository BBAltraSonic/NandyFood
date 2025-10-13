import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RestaurantSettingsScreen extends ConsumerWidget {
  const RestaurantSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Restaurant Info'),
            subtitle: const Text('Update basic information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to restaurant info
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Operating Hours'),
            subtitle: const Text('Manage opening hours'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to operating hours
            },
          ),
          ListTile(
            leading: const Icon(Icons.delivery_dining),
            title: const Text('Delivery Settings'),
            subtitle: const Text('Configure delivery options'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to delivery settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Staff Management'),
            subtitle: const Text('Manage restaurant staff'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to staff management
            },
          ),
        ],
      ),
    );
  }
}
