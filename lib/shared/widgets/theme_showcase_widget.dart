import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';
import 'package:food_delivery_app/shared/theme/theme_extensions.dart';

/// Theme Showcase Widget
///
/// This widget demonstrates the comprehensive theme system with design tokens,
/// showing various UI components with consistent styling.
class ThemeShowcaseWidget extends StatelessWidget {
  const ThemeShowcaseWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brandColors = theme.brandColors;
    final semanticColors = theme.semanticColors;
    final mealTimeColors = theme.mealTimeColors;
    final spacing = theme.spacing;
    final borderRadius = theme.borderRadius;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Showcase'),
        backgroundColor: brandColors.primary,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Brand Colors'),
            _buildBrandColorsGrid(brandColors, spacing, borderRadius),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Semantic Colors'),
            _buildSemanticColorsGrid(semanticColors, spacing, borderRadius),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Meal Time Colors'),
            _buildMealTimeColorsGrid(mealTimeColors, spacing, borderRadius),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Typography'),
            _buildTypographyShowcase(theme.textTheme, spacing),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Buttons'),
            _buildButtonShowcase(spacing),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Input Fields'),
            _buildInputFieldShowcase(spacing),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Cards & Shadows'),
            _buildCardShowcase(theme, brandColors, spacing, borderRadius),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Order Status'),
            _buildOrderStatusShowcase(semanticColors, spacing),

            SizedBox(height: spacing.xl),
            _buildSectionHeader('Chips & Tags'),
            _buildChipShowcase(theme.chipTheme, spacing),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBrandColorsGrid(BrandColorsExtension brandColors, SpacingExtension spacing, BorderRadiusExtension borderRadius) {
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        _buildColorTile('Primary', brandColors.primary, borderRadius),
        _buildColorTile('Primary Light', brandColors.primaryLight, borderRadius),
        _buildColorTile('Primary Dark', brandColors.primaryDark, borderRadius),
        _buildColorTile('Secondary', brandColors.secondary, borderRadius),
        _buildColorTile('Secondary Light', brandColors.secondaryLight, borderRadius),
        _buildColorTile('Secondary Dark', brandColors.secondaryDark, borderRadius),
        _buildColorTile('Accent', brandColors.accent, borderRadius),
        _buildColorTile('Accent Light', brandColors.accentLight, borderRadius),
        _buildColorTile('Accent Dark', brandColors.accentDark, borderRadius),
      ],
    );
  }

  Widget _buildSemanticColorsGrid(SemanticColorsExtension semanticColors, SpacingExtension spacing, BorderRadiusExtension borderRadius) {
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        _buildColorTile('Success', semanticColors.success, borderRadius),
        _buildColorTile('Success Light', semanticColors.successLight, borderRadius),
        _buildColorTile('Warning', semanticColors.warning, borderRadius),
        _buildColorTile('Error', semanticColors.error, borderRadius),
        _buildColorTile('Info', semanticColors.info, borderRadius),
        _buildColorTile('Order Placed', semanticColors.orderPlaced, borderRadius),
        _buildColorTile('Order Preparing', semanticColors.orderPreparing, borderRadius),
        _buildColorTile('Order Delivered', semanticColors.orderDelivered, borderRadius),
      ],
    );
  }

  Widget _buildMealTimeColorsGrid(MealTimeColorsExtension mealTimeColors, SpacingExtension spacing, BorderRadiusExtension borderRadius) {
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        _buildColorTile('Breakfast', mealTimeColors.breakfast, borderRadius),
        _buildColorTile('Brunch', mealTimeColors.brunch, borderRadius),
        _buildColorTile('Lunch', mealTimeColors.lunch, borderRadius),
        _buildColorTile('Afternoon Tea', mealTimeColors.afternoonTea, borderRadius),
        _buildColorTile('Dinner', mealTimeColors.dinner, borderRadius),
        _buildColorTile('Supper', mealTimeColors.supper, borderRadius),
        _buildColorTile('Late Night', mealTimeColors.lateNight, borderRadius),
      ],
    );
  }

  Widget _buildColorTile(String label, Color color, BorderRadiusExtension borderRadius) {
    return Container(
      width: 100,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius.borderRadiusMd,
        boxShadow: ShadowTokens.shadowSm,
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: _getContrastColor(color),
          ),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    // Calculate luminance to determine if we should use black or white text
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildTypographyShowcase(TextTheme textTheme, SpacingExtension spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Display Large', style: textTheme.displayLarge),
        SizedBox(height: spacing.sm),
        Text('Display Medium', style: textTheme.displayMedium),
        SizedBox(height: spacing.sm),
        Text('Display Small', style: textTheme.displaySmall),
        SizedBox(height: spacing.sm),
        Text('Headline Large', style: textTheme.headlineLarge),
        SizedBox(height: spacing.sm),
        Text('Headline Medium', style: textTheme.headlineMedium),
        SizedBox(height: spacing.sm),
        Text('Headline Small', style: textTheme.headlineSmall),
        SizedBox(height: spacing.sm),
        Text('Title Large', style: textTheme.titleLarge),
        SizedBox(height: spacing.sm),
        Text('Title Medium', style: textTheme.titleMedium),
        SizedBox(height: spacing.sm),
        Text('Title Small', style: textTheme.titleSmall),
        SizedBox(height: spacing.sm),
        Text('Body Large', style: textTheme.bodyLarge),
        SizedBox(height: spacing.sm),
        Text('Body Medium', style: textTheme.bodyMedium),
        SizedBox(height: spacing.sm),
        Text('Body Small', style: textTheme.bodySmall),
        SizedBox(height: spacing.sm),
        Text('Label Large', style: textTheme.labelLarge),
        SizedBox(height: spacing.sm),
        Text('Label Medium', style: textTheme.labelMedium),
        SizedBox(height: spacing.sm),
        Text('Label Small', style: textTheme.labelSmall),
      ],
    );
  }

  Widget _buildButtonShowcase(SpacingExtension spacing) {
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: const Text('Elevated Button'),
        ),
        OutlinedButton(
          onPressed: () {},
          child: const Text('Outlined Button'),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Text Button'),
        ),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Icon Button'),
        ),
        ElevatedButton(
          onPressed: null,
          child: const Text('Disabled Button'),
        ),
      ],
    );
  }

  Widget _buildInputFieldShowcase(SpacingExtension spacing) {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Enter your email',
            prefixIcon: Icon(Icons.email),
          ),
        ),
        SizedBox(height: spacing.md),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            prefixIcon: Icon(Icons.lock),
            suffixIcon: Icon(Icons.visibility),
          ),
          obscureText: true,
        ),
        SizedBox(height: spacing.md),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Search restaurants...',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        SizedBox(height: spacing.md),
        TextField(
          decoration: InputDecoration(
            labelText: 'Error State',
            hintText: 'This field has an error',
            errorText: 'Please enter a valid value',
            prefixIcon: const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildCardShowcase(ThemeData theme, BrandColorsExtension brandColors, SpacingExtension spacing, BorderRadiusExtension borderRadius) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restaurant Card',
                  style: theme.textTheme.titleLarge,
                ),
                SizedBox(height: spacing.sm),
                Text(
                  'This is a sample card showing the theme\'s card styling with proper shadows and border radius.',
                  style: theme.textTheme.bodyMedium,
                ),
                SizedBox(height: spacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('VIEW MENU'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: spacing.md),
        Card(
          elevation: 4,
          shadowColor: brandColors.primary.withValues(alpha: 0.3),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius.borderRadiusLg,
              gradient: LinearGradient(
                colors: [brandColors.primary, brandColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Featured Restaurant',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Special offer available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStatusShowcase(SemanticColorsExtension semanticColors, SpacingExtension spacing) {
    return Column(
      children: [
        _buildStatusItem('Order Placed', semanticColors.orderPlaced, Icons.shopping_cart),
        SizedBox(height: spacing.sm),
        _buildStatusItem('Order Confirmed', semanticColors.orderConfirmed, Icons.check_circle),
        SizedBox(height: spacing.sm),
        _buildStatusItem('Preparing', semanticColors.orderPreparing, Icons.restaurant),
        SizedBox(height: spacing.sm),
        _buildStatusItem('Ready for Pickup', semanticColors.success, Icons.delivery_dining),
        SizedBox(height: spacing.sm),
        _buildStatusItem('Delivered', semanticColors.orderDelivered, Icons.done_all),
        SizedBox(height: spacing.sm),
        _buildStatusItem('Cancelled', semanticColors.error, Icons.cancel),
      ],
    );
  }

  Widget _buildStatusItem(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipShowcase(ChipThemeData chipTheme, SpacingExtension spacing) {
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: [
        Chip(
          label: const Text('Popular'),
          avatar: const Icon(Icons.star, size: 16),
        ),
        Chip(
          label: const Text('New'),
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          labelStyle: const TextStyle(color: Colors.blue),
        ),
        Chip(
          label: const Text('Healthy'),
          avatar: const Icon(Icons.favorite, size: 16),
        ),
        Chip(
          label: const Text('Fast Delivery'),
          deleteIcon: const Icon(Icons.close, size: 16),
          onDeleted: () {},
        ),
        ActionChip(
          label: const Text('Filter'),
          onPressed: () {},
          avatar: const Icon(Icons.filter_list, size: 16),
        ),
      ],
    );
  }
}