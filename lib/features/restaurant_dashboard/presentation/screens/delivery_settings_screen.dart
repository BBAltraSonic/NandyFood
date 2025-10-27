import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';

class DeliverySettingsScreen extends ConsumerStatefulWidget {
  const DeliverySettingsScreen({super.key});

  @override
  ConsumerState<DeliverySettingsScreen> createState() =>
      _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState
    extends ConsumerState<DeliverySettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late String _restaurantId;

  // Form controllers
  final _deliveryFeeController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _estimatedTimeController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();

  double _deliveryRadius = 5.0;
  String _feeStructure = 'fixed'; // fixed, distance, free_threshold

  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantSettings();
  }

  Future<void> _loadRestaurantSettings() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);
      if (restaurants.isEmpty) return;

      _restaurantId = restaurants.first.restaurantId;
      final restaurant =
          await _restaurantService.getRestaurant(_restaurantId);

      // Populate form
      _deliveryFeeController.text = restaurant.deliveryFee?.toString() ?? '20.00';
      _minimumOrderController.text =
          restaurant.minimumOrderAmount?.toString() ?? '50.00';
      _estimatedTimeController.text =
          restaurant.estimatedDeliveryTime.toString();
      _deliveryRadius = restaurant.deliveryRadius;

      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Failed to load settings: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _deliveryFeeController.dispose();
    _minimumOrderController.dispose();
    _estimatedTimeController.dispose();
    _freeDeliveryThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Settings'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSettings,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDeliveryRadiusCard(),
          const SizedBox(height: 16),
          _buildFeeStructureCard(),
          const SizedBox(height: 16),
          _buildMinimumOrderCard(),
          const SizedBox(height: 16),
          _buildEstimatedTimeCard(),
          const SizedBox(height: 16),
          _buildPreviewCard(),
        ],
      ),
    );
  }

  Widget _buildDeliveryRadiusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Delivery Radius',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'How far will you deliver?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            Text(
              '${_deliveryRadius.toStringAsFixed(1)} km',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            Slider(
              value: _deliveryRadius,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_deliveryRadius.toStringAsFixed(1)} km',
              onChanged: (value) {
                setState(() => _deliveryRadius = value);
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km', style: TextStyle(color: Colors.grey.shade600)),
                Text('20 km', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is the maximum distance from your restaurant',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeStructureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.attach_money, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Delivery Fee',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RadioListTile<String>(
              title: const Text('Fixed Fee'),
              subtitle: const Text('Same fee for all deliveries'),
              value: 'fixed',
              // ignore: deprecated_member_use
              groupValue: _feeStructure,
              // ignore: deprecated_member_use
              onChanged: (value) {
                setState(() => _feeStructure = value!);
              },
            ),
            if (_feeStructure == 'fixed')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextFormField(
                  controller: _deliveryFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Fee',
                    prefixText: 'R ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            const Divider(),
            RadioListTile<String>(
              title: const Text('Distance-Based'),
              subtitle: const Text('Fee increases with distance (coming soon)'),
              value: 'distance',
              // ignore: deprecated_member_use
              groupValue: _feeStructure,
              // ignore: deprecated_member_use
              onChanged: null, // Disabled for now
            ),
            const Divider(),
            RadioListTile<String>(
              title: const Text('Free Above Threshold'),
              subtitle: const Text('Free delivery for large orders (coming soon)'),
              value: 'free_threshold',
              // ignore: deprecated_member_use
              groupValue: _feeStructure,
              // ignore: deprecated_member_use
              onChanged: null, // Disabled for now
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimumOrderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_cart, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Minimum Order Amount',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Smallest order you\'ll accept',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minimumOrderController,
              decoration: const InputDecoration(
                labelText: 'Minimum Order',
                prefixText: 'R ',
                border: OutlineInputBorder(),
                helperText: 'Orders below this amount will be rejected',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedTimeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.purple),
                const SizedBox(width: 8),
                Text(
                  'Estimated Delivery Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Average time from order to delivery',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedTimeController,
              decoration: const InputDecoration(
                labelText: 'Estimated Time (minutes)',
                suffixText: 'min',
                border: OutlineInputBorder(),
                helperText: 'This will be shown to customers',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Customer View Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPreviewRow(
                    Icons.location_on,
                    'Delivery Radius',
                    '${_deliveryRadius.toStringAsFixed(1)} km from restaurant',
                  ),
                  const Divider(height: 24),
                  _buildPreviewRow(
                    Icons.attach_money,
                    'Delivery Fee',
                    'R ${double.tryParse(_deliveryFeeController.text)?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  const Divider(height: 24),
                  _buildPreviewRow(
                    Icons.shopping_cart,
                    'Minimum Order',
                    'R ${double.tryParse(_minimumOrderController.text)?.toStringAsFixed(2) ?? '0.00'}',
                  ),
                  const Divider(height: 24),
                  _buildPreviewRow(
                    Icons.access_time,
                    'Estimated Delivery',
                    '${_estimatedTimeController.text} minutes',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    // Validation
    if (_deliveryFeeController.text.isEmpty ||
        double.tryParse(_deliveryFeeController.text) == null) {
      _showError('Please enter a valid delivery fee');
      return;
    }

    if (_minimumOrderController.text.isEmpty ||
        double.tryParse(_minimumOrderController.text) == null) {
      _showError('Please enter a valid minimum order amount');
      return;
    }

    if (_estimatedTimeController.text.isEmpty ||
        int.tryParse(_estimatedTimeController.text) == null) {
      _showError('Please enter a valid estimated time');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updates = {
        'delivery_radius': _deliveryRadius,
        'delivery_fee': double.parse(_deliveryFeeController.text),
        'minimum_order_amount': double.parse(_minimumOrderController.text),
        'estimated_delivery_time': int.parse(_estimatedTimeController.text),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _restaurantService.updateRestaurant(_restaurantId, updates);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery settings updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      _showError('Failed to save settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
