import 'package:flutter/material.dart';

class FilterWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onFilterChanged;

  const FilterWidget({Key? key, required this.onFilterChanged})
    : super(key: key);

  @override
  State<FilterWidget> createState() => _FilterWidgetState();
}

class _FilterWidgetState extends State<FilterWidget> {
  String _selectedCuisine = 'All';
  double _selectedRating = 0.0;
  String _selectedDeliveryTime = 'Any';
  bool _vegetarianOnly = false;
  bool _veganOnly = false;
  bool _glutenFreeOnly = false;

  final List<String> _cuisineTypes = [
    'All',
    'Italian',
    'Mexican',
    'Chinese',
    'Indian',
    'American',
    'Japanese',
  ];
  final List<String> _deliveryTimes = [
    'Any',
    'Under 15 min',
    'Under 30 min',
    'Under 45 min',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Cuisine type filter
          const Text(
            'Cuisine Type',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedCuisine,
            items: _cuisineTypes.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedCuisine = newValue ?? 'All';
              });
              _notifyFilterChange();
            },
          ),
          const SizedBox(height: 16),

          // Rating filter
          const Text(
            'Minimum Rating',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _selectedRating,
            min: 0.0,
            max: 5.0,
            divisions: 10,
            label: _selectedRating.round().toString(),
            onChanged: (double newValue) {
              setState(() {
                _selectedRating = newValue;
              });
              _notifyFilterChange();
            },
          ),
          Text('$_selectedRating stars and up'),
          const SizedBox(height: 16),

          // Delivery time filter
          const Text(
            'Delivery Time',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          DropdownButton<String>(
            isExpanded: true,
            value: _selectedDeliveryTime,
            items: _deliveryTimes.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDeliveryTime = newValue ?? 'Any';
              });
              _notifyFilterChange();
            },
          ),
          const SizedBox(height: 16),

          // Dietary restrictions
          const Text(
            'Dietary Restrictions',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Vegetarian'),
                  value: _vegetarianOnly,
                  onChanged: (bool? value) {
                    setState(() {
                      _vegetarianOnly = value ?? false;
                    });
                    _notifyFilterChange();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Vegan'),
                  value: _veganOnly,
                  onChanged: (bool? value) {
                    setState(() {
                      _veganOnly = value ?? false;
                    });
                    _notifyFilterChange();
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          CheckboxListTile(
            title: const Text('Gluten Free'),
            value: _glutenFreeOnly,
            onChanged: (bool? value) {
              setState(() {
                _glutenFreeOnly = value ?? false;
              });
              _notifyFilterChange();
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  void _notifyFilterChange() {
    final filterOptions = {
      'cuisineType': _selectedCuisine != 'All' ? _selectedCuisine : null,
      'minRating': _selectedRating > 0 ? _selectedRating : null,
      'maxDeliveryTime': _getMaxDeliveryTime(),
      'vegetarianOnly': _vegetarianOnly,
      'veganOnly': _veganOnly,
      'glutenFreeOnly': _glutenFreeOnly,
    };

    widget.onFilterChanged(filterOptions);
  }

  int? _getMaxDeliveryTime() {
    switch (_selectedDeliveryTime) {
      case 'Under 15 min':
        return 15;
      case 'Under 30 min':
        return 30;
      case 'Under 45 min':
        return 45;
      default:
        return null;
    }
  }
}
