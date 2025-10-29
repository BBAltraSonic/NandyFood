import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

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

    return Container(
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(BorderRadiusTokens.xxl),
        ),
        boxShadow: ShadowTokens.shadowLg,
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
              color: NeutralColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Enhanced Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [BrandColors.primary, BrandColors.primaryLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Restaurants',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Customize your search',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: NeutralColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Filter options
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sort By Section
                  _buildSectionHeader('Sort By', Icons.sort_rounded),
                  const SizedBox(height: 12),
                  _buildSortOptions(theme),

                  const SizedBox(height: 32),

                  // Dietary Restrictions Section
                  _buildSectionHeader('Dietary Preferences', Icons.restaurant_rounded),
                  const SizedBox(height: 12),
                  _buildDietaryOptions(theme),

                  const SizedBox(height: 32),

                  // Price Range Section
                  _buildSectionHeader('Price Range', Icons.attach_money_rounded),
                  const SizedBox(height: 12),
                  _buildPriceRangeSlider(theme),

                  const SizedBox(height: 32),

                  // Minimum Rating Section
                  _buildSectionHeader('Minimum Rating', Icons.star_rounded),
                  const SizedBox(height: 12),
                  _buildRatingSlider(theme),

                  const SizedBox(height: 32),

                  // Delivery Time Section
                  _buildSectionHeader('Max Delivery Time', Icons.schedule_rounded),
                  const SizedBox(height: 12),
                  _buildDeliveryTimeSlider(theme),

                  const SizedBox(height: 32),

                  // Distance Section
                  _buildSectionHeader('Max Distance', Icons.location_on_rounded),
                  const SizedBox(height: 12),
                  _buildDistanceSlider(theme),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(BorderRadiusTokens.xl),
                  ),
                  elevation: 4,
                  shadowColor: BrandColors.primary.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Apply Filters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: BrandColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: BrandColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: NeutralColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSortOptions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortOptions.map((option) {
        final isSelected = _sortBy == option['value'];
        return FilterChip(
          label: Text(option['label']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _sortBy = selected ? option['value'] : null;
            });
          },
          backgroundColor: NeutralColors.surface,
          selectedColor: BrandColors.primary,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : NeutralColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? BrandColors.primary : NeutralColors.gray300,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDietaryOptions(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: dietaryOptions.map((option) {
        final isSelected = _selectedDietaryRestrictions.contains(option);
        IconData icon;
        Color color;

        switch (option.toLowerCase()) {
          case 'vegetarian':
            icon = Icons.eco;
            color = BrandColors.secondary;
            break;
          case 'vegan':
            icon = Icons.spa;
            color = BrandColors.secondaryDark;
            break;
          case 'gluten-free':
            icon = Icons.grain;
            color = Colors.blue;
            break;
          case 'dairy-free':
            icon = Icons.no_food;
            color = Colors.lightBlue;
            break;
          case 'nut-free':
            icon = Icons.egg;
            color = Colors.amber;
            break;
          case 'halal':
            icon = Icons.nights_stay_rounded;
            color = Colors.green;
            break;
          case 'kosher':
            icon = Icons.star_rounded;
            color = Colors.blue.shade800;
            break;
          default:
            icon = Icons.info;
            color = Colors.grey;
        }

        return FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(option),
            ],
          ),
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
          backgroundColor: NeutralColors.surface,
          selectedColor: color,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : NeutralColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? color : NeutralColors.gray300,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceRangeSlider(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$' * _priceRange.start.toInt(),
                style: TextStyle(
                  color: BrandColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BrandColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '\$' * _priceRange.end.toInt(),
                style: TextStyle(
                  color: BrandColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        RangeSlider(
          values: _priceRange,
          min: 1,
          max: 4,
          divisions: 3,
          activeColor: BrandColors.primary,
          inactiveColor: BrandColors.primary.withValues(alpha: 0.3),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildRatingSlider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: BrandColors.primary,
              inactiveTrackColor: BrandColors.primary.withValues(alpha: 0.3),
              thumbColor: BrandColors.primary,
              overlayColor: BrandColors.primary.withValues(alpha: 0.2),
              valueIndicatorColor: BrandColors.primary,
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _minRating,
              min: 0,
              max: 5,
              divisions: 10,
              label: _minRating == 0 ? 'Any Rating' : '${_minRating.toStringAsFixed(1)}+ ⭐',
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BrandColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _minRating == 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}+',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BrandColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTimeSlider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: BrandColors.secondary,
              inactiveTrackColor: BrandColors.secondary.withValues(alpha: 0.3),
              thumbColor: BrandColors.secondary,
              overlayColor: BrandColors.secondary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _maxDeliveryTime,
              min: 15,
              max: 90,
              divisions: 5,
              label: '${_maxDeliveryTime.toInt()} min',
              onChanged: (value) {
                setState(() {
                  _maxDeliveryTime = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BrandColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_maxDeliveryTime.toInt()} min',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: BrandColors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue,
              inactiveTrackColor: Colors.blue.withValues(alpha: 0.3),
              thumbColor: Colors.blue,
              overlayColor: Colors.blue.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _maxDistance,
              min: 1,
              max: 20,
              divisions: 19,
              label: '${_maxDistance.toInt()} km',
              onChanged: (value) {
                setState(() {
                  _maxDistance = value;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_maxDistance.toInt()} km',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}