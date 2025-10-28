import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:food_delivery_app/core/providers/auth_provider.dart';
import 'package:food_delivery_app/core/services/role_service.dart';
import 'package:food_delivery_app/features/restaurant_dashboard/services/restaurant_management_service.dart';

class OperatingHoursScreen extends ConsumerStatefulWidget {
  const OperatingHoursScreen({super.key});

  @override
  ConsumerState<OperatingHoursScreen> createState() =>
      _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends ConsumerState<OperatingHoursScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  late String _restaurantId;

  final Map<String, Map<String, dynamic>> _hours = {
    'monday': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'tuesday': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'wednesday': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'thursday': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'friday': {'isOpen': true, 'open': '09:00', 'close': '23:00'},
    'saturday': {'isOpen': true, 'open': '09:00', 'close': '23:00'},
    'sunday': {'isOpen': true, 'open': '10:00', 'close': '21:00'},
  };

  final List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  final _restaurantService = RestaurantManagementService();

  @override
  void initState() {
    super.initState();
    _loadRestaurantHours();
  }

  Future<void> _loadRestaurantHours() async {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId == null) return;

    try {
      final roleService = RoleService();
      final restaurants = await roleService.getUserRestaurants(userId);
      if (restaurants.isEmpty) return;

      _restaurantId = restaurants.first;
      final restaurant =
          await _restaurantService.getRestaurant(_restaurantId);

      // Load existing hours from restaurant
      _populateHours(restaurant.openingHours);

      setState(() => _isLoading = false);
    } catch (e) {
      _showError('Failed to load hours: $e');
      setState(() => _isLoading = false);
    }
  }

  void _populateHours(Map<String, dynamic> openingHours) {
    for (final day in _daysOfWeek) {
      if (openingHours.containsKey(day)) {
        final dayHours = openingHours[day] as Map<String, dynamic>;
        _hours[day] = {
          'isOpen': dayHours['open'] != null && dayHours['close'] != null,
          'open': dayHours['open'] ?? '09:00',
          'close': dayHours['close'] ?? '22:00',
        };
      }
    }
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
        title: const Text('Operating Hours'),
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
              onPressed: _saveHours,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _copyToAllDays,
                        icon: const Icon(Icons.copy_all, size: 18),
                        label: const Text('Copy Monday to All'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _copyToWeekdays,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: const Text('Copy to Weekdays'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _copyToWeekends,
                        icon: const Icon(Icons.weekend, size: 18),
                        label: const Text('Copy to Weekends'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._daysOfWeek.map((day) => _buildDayCard(day)),
        ],
      ),
    );
  }

  Widget _buildDayCard(String day) {
    final dayData = _hours[day]!;
    final isOpen = dayData['isOpen'] as bool;
    final open = dayData['open'] as String;
    final close = dayData['close'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _capitalize(day),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Switch(
                  value: isOpen,
                  onChanged: (value) {
                    setState(() {
                      _hours[day]!['isOpen'] = value;
                    });
                  },
                ),
              ],
            ),
            if (isOpen) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Opening Time',
                      value: open,
                      onChanged: (newTime) {
                        setState(() {
                          _hours[day]!['open'] = newTime;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      label: 'Closing Time',
                      value: close,
                      onChanged: (newTime) {
                        setState(() {
                          _hours[day]!['close'] = newTime;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Closed',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required String value,
    required Function(String) onChanged,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTime(value),
        );
        if (picked != null) {
          onChanged(_formatTime(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _formatTimeDisplay(value),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeDisplay(String timeStr) {
    final time = _parseTime(timeStr);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  String _capitalize(String str) {
    return str[0].toUpperCase() + str.substring(1);
  }

  void _copyToAllDays() {
    final mondayHours = _hours['monday']!;
    setState(() {
      for (final day in _daysOfWeek) {
        _hours[day] = Map<String, dynamic>.from(mondayHours);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monday hours copied to all days')),
    );
  }

  void _copyToWeekdays() {
    final mondayHours = _hours['monday']!;
    setState(() {
      for (final day in ['tuesday', 'wednesday', 'thursday', 'friday']) {
        _hours[day] = Map<String, dynamic>.from(mondayHours);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monday hours copied to weekdays')),
    );
  }

  void _copyToWeekends() {
    final mondayHours = _hours['monday']!;
    setState(() {
      for (final day in ['saturday', 'sunday']) {
        _hours[day] = Map<String, dynamic>.from(mondayHours);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monday hours copied to weekends')),
    );
  }

  Future<void> _saveHours() async {
    // Validate that opening time is before closing time
    for (final day in _daysOfWeek) {
      final dayData = _hours[day]!;
      if (dayData['isOpen'] as bool) {
        final open = _parseTime(dayData['open'] as String);
        final close = _parseTime(dayData['close'] as String);
        
        final openMinutes = open.hour * 60 + open.minute;
        final closeMinutes = close.hour * 60 + close.minute;
        
        if (openMinutes >= closeMinutes) {
          _showError(
            '${_capitalize(day)}: Opening time must be before closing time',
          );
          return;
        }
      }
    }

    setState(() => _isSaving = true);

    try {
      // Convert to format expected by database
      final hoursData = <String, dynamic>{};
      for (final day in _daysOfWeek) {
        final dayData = _hours[day]!;
        if (dayData['isOpen'] as bool) {
          hoursData[day] = {
            'open': dayData['open'],
            'close': dayData['close'],
          };
        } else {
          hoursData[day] = {
            'open': null,
            'close': null,
          };
        }
      }

      await _restaurantService.updateOperatingHours(_restaurantId, hoursData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Operating hours updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      context.pop();
    } catch (e) {
      _showError('Failed to save hours: $e');
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
