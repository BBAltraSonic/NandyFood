import 'package:flutter/material.dart';

/// Advanced filter options for restaurant search
class RestaurantFilters {
  final Set<String> dietaryRestrictions;
  final RangeValues? priceRange;
  final double? minRating;
  final int? maxDeliveryTime; // in minutes
  final double? maxDistance; // in kilometers
  final String? sortBy;

  const RestaurantFilters({
    this.dietaryRestrictions = const {},
    this.priceRange,
    this.minRating,
    this.maxDeliveryTime,
    this.maxDistance,
    this.sortBy,
  });

  RestaurantFilters copyWith({
    Set<String>? dietaryRestrictions,
    RangeValues? priceRange,
    double? minRating,
    int? maxDeliveryTime,
    double? maxDistance,
    String? sortBy,
  }) {
    return RestaurantFilters(
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      priceRange: priceRange ?? this.priceRange,
      minRating: minRating ?? this.minRating,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      maxDistance: maxDistance ?? this.maxDistance,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters {
    return dietaryRestrictions.isNotEmpty ||
        priceRange != null ||
        minRating != null ||
        maxDeliveryTime != null ||
        maxDistance != null ||
        sortBy != null;
  }

  int get activeFilterCount {
    int count = 0;
    if (dietaryRestrictions.isNotEmpty) count++;
    if (priceRange != null) count++;
    if (minRating != null) count++;
    if (maxDeliveryTime != null) count++;
    if (maxDistance != null) count++;
    return count;
  }
}

/// Bottom sheet for advanced restaurant filtering
class AdvancedFilterSheet extends StatefulWidget {
  final RestaurantFilters initialFilters;
  final Function(RestaurantFilters) onApply;

  const AdvancedFilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<AdvancedFilterSheet> createState() => _AdvancedFilterSheetState();
}

class _AdvancedFilterSheetState extends State<AdvancedFilterSheet> {
  late Set<String> _selectedDietaryRestrictions;
  late RangeValues _priceRange;
  late double _minRating;
  late double _maxDeliveryTime;
  late double _maxDistance;
  String? _sortBy;

  // Available options
  static const List<String> dietaryOptions = [
    'Vegetarian',
    'Vegan',
    'Gluten-Free',
    'Halal',
    'Kosher',
    'Dairy-Free',
    'Nut-Free',
  ];

  static const List<Map<String, String>> sortOptions = [
    {'value': 'recommended', 'label': 'Recommended'},
    {'value': 'rating', 'label': 'Highest Rated'},
    {'value': 'delivery_time', 'label': 'Fastest Delivery'},
    {'value': 'distance', 'label': 'Nearest'},
    {'value': 'popular', 'label': 'Most Popular'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDietaryRestrictions = Set.from(widget.initialFilters.dietaryRestrictions);
    _priceRange = widget.initialFilters.priceRange ?? const RangeValues(1, 4);
    _minRating = widget.initialFilters.minRating ?? 0;
    _maxDeliveryTime = widget.initialFilters.maxDeliveryTime?.toDouble() ?? 60;
    _maxDistance = widget.initialFilters.maxDistance ?? 10;
    _sortBy = widget.initialFilters.sortBy;
  }

  void _applyFilters() {
    final filters = RestaurantFilters(
      dietaryRestrictions: _selectedDietaryRestrictions,
      priceRange: _priceRange,
      minRating: _minRating > 0 ? _minRating : null,
      maxDeliveryTime: _maxDeliveryTime < 60 ? _maxDeliveryTime.toInt() : null,
      maxDistance: _maxDistance < 10 ? _maxDistance : null,
      sortBy: _sortBy,
    );
    widget.onApply(filters);
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      _selectedDietaryRestrictions.clear();
      _priceRange = const RangeValues(1, 4);
      _minRating = 0;
      _maxDeliveryTime = 60;
      _maxDistance = 10;
      _sortBy = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filters',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By
                  _buildSectionTitle('Sort By'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortOptions.map((option) {
                      final isSelected = _sortBy == option['value'];
                      return ChoiceChip(
                        label: Text(option['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _sortBy = selected ? option['value'] : null;
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Dietary Restrictions
                  _buildSectionTitle('Dietary Restrictions'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: dietaryOptions.map((option) {
                      final isSelected = _selectedDietaryRestrictions.contains(option);
                      return FilterChip(
                        label: Text(option),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDietaryRestrictions.add(option);
                            } else {
                              _selectedDietaryRestrictions.remove(option);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Price Range
                  _buildSectionTitle('Price Range'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('\$' * _priceRange.start.toInt()),
                      Text('\$' * _priceRange.end.toInt()),
                    ],
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 1,
                    max: 4,
                    divisions: 3,
                    labels: RangeLabels(
                      '\$' * _priceRange.start.toInt(),
                      '\$' * _priceRange.end.toInt(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Minimum Rating
                  _buildSectionTitle('Minimum Rating'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minRating,
                          min: 0,
                          max: 5,
                          divisions: 10,
                          label: _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+ ⭐',
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: Text(
                          _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Delivery Time
                  _buildSectionTitle('Max Delivery Time'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxDeliveryTime,
                          min: 15,
                          max: 60,
                          divisions: 9,
                          label: _maxDeliveryTime == 60 
                              ? 'Any' 
                              : '${_maxDeliveryTime.toInt()} min',
                          onChanged: (value) {
                            setState(() {
                              _maxDeliveryTime = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: Text(
                          _maxDeliveryTime == 60 ? 'Any' : '${_maxDeliveryTime.toInt()} min',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Distance
                  _buildSectionTitle('Max Distance'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _maxDistance,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _maxDistance == 10 
                              ? 'Any' 
                              : '${_maxDistance.toStringAsFixed(0)} km',
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 60,
                        child: Text(
                          _maxDistance == 10 
                              ? 'Any' 
                              : '${_maxDistance.toStringAsFixed(0)} km',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _applyFilters,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
