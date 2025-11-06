import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

class DietaryPreferencesSection extends StatelessWidget {
  const DietaryPreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dietary Preferences',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: NeutralColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Choose your preferred options',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: NeutralColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Open dietary preferences settings
                },
                child: Text(
                  'Customize',
                  style: TextStyle(
                    color: BrandColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dietary preference categories
          _buildDietaryGrid(context, theme),
        ],
      ),
    );
  }

  Widget _buildDietaryGrid(BuildContext context, ThemeData theme) {
    final dietaryOptions = [
      {
        'icon': Icons.egg_outlined,
        'label': 'Vegetarian',
        'color': Colors.green.shade400,
        'count': '245 items',
      },
      {
        'icon': Icons.egg_alt_outlined,
        'label': 'Vegan',
        'color': Colors.teal.shade400,
        'count': '189 items',
      },
      {
        'icon': Icons.set_meal_outlined,
        'label': 'Gluten-Free',
        'color': Colors.amber.shade600,
        'count': '312 items',
      },
      {
        'icon': Icons.local_fire_department_outlined,
        'label': 'Keto',
        'color': Colors.red.shade400,
        'count': '156 items',
      },
      {
        'icon': Icons.water_drop_outlined,
        'label': 'Low-Carb',
        'color': Colors.blue.shade400,
        'count': '278 items',
      },
      {
        'icon': Icons.fitness_center_outlined,
        'label': 'High-Protein',
        'color': Colors.purple.shade400,
        'count': '198 items',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: dietaryOptions.length,
      itemBuilder: (context, index) {
        final option = dietaryOptions[index];
        return _buildDietaryCard(context, option, theme);
      },
    );
  }

  Widget _buildDietaryCard(BuildContext context, Map<String, dynamic> option, ThemeData theme) {
    final color = option['color'] as Color;

    return Container(
      decoration: BoxDecoration(
        color: NeutralColors.surface,
        borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
        boxShadow: ShadowTokens.shadowSm,
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(BorderRadiusTokens.lg),
          onTap: () {
            // Handle dietary preference selection
            _showDietaryFilterDialog(context, option['label'] as String);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    option['icon'] as IconData,
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  option['label'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  option['count'] as String,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: NeutralColors.textSecondary,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDietaryFilterDialog(BuildContext context, String preference) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$preference Filter'),
          content: Text('Would you like to filter restaurants and dishes that are $preference?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Apply dietary filter
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$preference filter applied'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Apply Filter'),
            ),
          ],
        );
      },
    );
  }
}