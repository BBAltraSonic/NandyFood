# NandyFood Theme System Guide

This guide explains how to use the comprehensive design system and theme infrastructure implemented for the NandyFood application.

## 🎨 Design System Overview

The NandyFood theme system consists of:

1. **Design Tokens** (`lib/shared/theme/design_tokens.dart`) - All design values in one place
2. **Theme Configuration** (`lib/shared/theme/app_theme.dart`) - Complete ThemeData setup
3. **Theme Extensions** (`lib/shared/theme/theme_extensions.dart`) - Custom theme extensions
4. **Theme Showcase** (`lib/shared/widgets/theme_showcase_widget.dart`) - Demonstration widget

## 🚀 Quick Start

### Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';
import 'package:food_delivery_app/shared/theme/theme_extensions.dart';

MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // or ThemeMode.light/dark
  home: MyHomePage(),
)
```

### Accessing Theme Values

```dart
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  // Access design tokens via extensions
  final brandColors = theme.brandColors;
  final semanticColors = theme.semanticColors;
  final spacing = theme.spacing;
  final borderRadius = theme.borderRadius;
  final shadows = theme.shadows;

  return Container(
    padding: EdgeInsets.all(spacing.lg),
    decoration: BoxDecoration(
      color: brandColors.primary,
      borderRadius: borderRadius.borderRadiusLg,
      boxShadow: shadows.md,
    ),
    child: Text(
      'Hello NandyFood',
      style: theme.textTheme.titleLarge,
    ),
  );
}
```

## 🎯 Design Tokens

### Brand Colors

```dart
// Access via theme extension
final brandColors = Theme.of(context).brandColors;

Container(
  color: brandColors.primary,           // Main olive green
  // brandColors.primaryLight
  // brandColors.primaryDark
  // brandColors.secondary               // Warm orange
  // brandColors.accent                 // Muted green
)
```

### Semantic Colors

```dart
final semanticColors = Theme.of(context).semanticColors;

// Status colors
Container(color: semanticColors.success)     // Green
Container(color: semanticColors.warning)     // Orange
Container(color: semanticColors.error)       // Red
Container(color: semanticColors.info)         // Blue

// Order status colors
Container(color: semanticColors.orderPlaced)      // Blue
Container(color: semanticColors.orderPreparing)   // Orange
Container(color: semanticColors.orderDelivered)   // Green
```

### Meal Time Colors

```dart
final mealTimeColors = Theme.of(context).mealTimeColors;

Container(color: mealTimeColors.breakfast)      // Warm yellow
Container(color: mealTimeColors.lunch)          // Fresh green
Container(color: mealTimeColors.dinner)        // Blue-indigo
Container(color: mealTimeColors.supper)        // Deep orange
```

### Spacing System

```dart
final spacing = Theme.of(context).spacing;

Padding(
  padding: EdgeInsets.all(spacing.lg),  // 16px
  // spacing.xs  // 4px
  // spacing.sm  // 8px
  // spacing.md  // 12px
  // spacing.lg  // 16px
  // spacing.xl  // 20px
  // spacing.xxl // 24px
)
```

### Border Radius

```dart
final borderRadius = Theme.of(context).borderRadius;

Container(
  decoration: BoxDecoration(
    borderRadius: borderRadius.borderRadiusLg,  // 12px
    // borderRadius.borderRadiusXs   // 2px
    // borderRadius.borderRadiusSm   // 4px
    // borderRadius.borderRadiusMd   // 8px
    // borderRadius.borderRadiusLg   // 12px
    // borderRadius.borderRadiusXl   // 16px
    // borderRadius.borderRadiusXxl  // 24px
  ),
)
```

### Shadows

```dart
final shadows = Theme.of(context).shadows;

Container(
  decoration: BoxDecoration(
    boxShadow: shadows.md,  // Medium shadow
    // shadows.xs  // Extra small shadow
    // shadows.sm  // Small shadow
    // shadows.md  // Medium shadow
    // shadows.lg  // Large shadow
    // shadows.xl  // Extra large shadow
    // shadows.primaryShadow    // Brand-colored shadow
    // shadows.secondaryShadow  // Secondary-colored shadow
  ),
)
```

## 🎨 Component Styling

### Buttons

```dart
// Elevated button with brand colors
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: brandColors.primary,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: borderRadius.borderRadiusLg,
    ),
  ),
  child: Text('Order Now'),
)

// Outlined button
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: brandColors.primary),
    shape: RoundedRectangleBorder(
      borderRadius: borderRadius.borderRadiusLg,
    ),
  ),
  child: Text('Learn More'),
)
```

### Cards

```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: borderRadius.borderRadiusLg,
  ),
  child: Padding(
    padding: EdgeInsets.all(spacing.md),
    child: Column(
      children: [
        Text(
          'Restaurant Name',
          style: theme.textTheme.titleLarge,
        ),
        SizedBox(height: spacing.sm),
        Text(
          'Description here...',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    ),
  ),
)
```

### Input Fields

```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Email Address',
    hintText: 'Enter your email',
    prefixIcon: Icon(Icons.email),
    border: OutlineInputBorder(
      borderRadius: borderRadius.borderRadiusLg,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius.borderRadiusLg,
      borderSide: BorderSide(color: brandColors.primary, width: 2),
    ),
  ),
)
```

### Status Indicators

```dart
Container(
  padding: EdgeInsets.symmetric(
    horizontal: spacing.md,
    vertical: spacing.sm,
  ),
  decoration: BoxDecoration(
    color: semanticColors.success.withOpacity(0.1),
    borderRadius: borderRadius.borderRadiusLg,
    border: Border.all(
      color: semanticColors.success.withOpacity(0.3),
    ),
  ),
  child: Row(
    children: [
      Icon(
        Icons.check_circle,
        color: semanticColors.success,
        size: 20,
      ),
      SizedBox(width: spacing.sm),
      Text(
        'Order Delivered',
        style: TextStyle(
          color: semanticColors.success,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  ),
)
```

## 🌓 Dark Mode

The theme system automatically supports dark mode. The design tokens are optimized for both light and dark themes:

```dart
// Light mode
MaterialApp(theme: AppTheme.lightTheme, ...)

// Dark mode
MaterialApp(theme: AppTheme.darkTheme, ...)

// System mode (follows device settings)
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system,
  ...
)
```

## 🎭 Typography

Use the semantic typography scale for consistent text styling:

```dart
Text(
  'Restaurant Title',
  style: theme.textTheme.headlineLarge,  // 24px, bold
)

Text(
  'Menu item description',
  style: theme.textTheme.bodyLarge,     // 16px, regular
)

Text(
  'Price',
  style: theme.textTheme.titleMedium,   // 14px, semi-bold
)
```

## 🎪 Theme Showcase

To see all theme values in action, use the `ThemeShowcaseWidget`:

```dart
import 'package:food_delivery_app/shared/widgets/theme_showcase_widget.dart';

// In your navigation or as a standalone screen
ThemeShowcaseWidget()
```

This widget demonstrates:
- All color palettes (brand, semantic, meal-time)
- Typography scale
- Button variations
- Input field styles
- Cards with shadows
- Status indicators
- Chip components

## 📱 Responsive Design

Use the breakpoint tokens for responsive layouts:

```dart
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

LayoutBuilder(
  builder: (context, constraints) {
    if (BreakpointTokens.isMobile(constraints.maxWidth)) {
      // Mobile layout
      return Column(children: [...]);
    } else if (BreakpointTokens.isTablet(constraints.maxWidth)) {
      // Tablet layout
      return Row(children: [...]);
    } else {
      // Desktop layout
      return GridView.count(children: [...]);
    }
  },
)
```

## 🔧 Custom Theme Extensions

You can extend the theme system for your specific needs:

```dart
@immutable
class CustomColorsExtension extends ThemeExtension<CustomColorsExtension> {
  const CustomColorsExtension({
    this.specialColor = Colors.purple,
    this.accentColor = Colors.amber,
  });

  final Color specialColor;
  final Color accentColor;

  // ... copyWith and lerp implementations

  static CustomColorsExtension of(BuildContext context) {
    return Theme.of(context).extension<CustomColorsExtension>() ??
        const CustomColorsExtension();
  }
}
```

## 🎯 Best Practices

### DO:
- ✅ Use theme extensions for consistent styling
- ✅ Leverage semantic colors for status indicators
- ✅ Use spacing tokens for consistent margins/padding
- ✅ Apply border radius tokens for consistent shapes
- ✅ Test your UI in both light and dark modes
- ✅ Use semantic typography for text hierarchy

### DON'T:
- ❌ Hardcode colors directly in widgets
- ❌ Use arbitrary spacing values
- ❌ Skip testing in dark mode
- ❌ Override theme values unnecessarily
- ❌ Use inconsistent border radius values

## 🐛 Troubleshooting

### Theme Extension Not Found
```dart
// Wrong - might return null
final brandColors = Theme.of(context).brandColors;

// Right - always has a value
final brandColors = Theme.of(context).extension<BrandColorsExtension>() ??
    const BrandColorsExtension();
```

### Colors Not Updating in Dark Mode
Ensure you're using theme extensions rather than hardcoded colors:

```dart
// Wrong - won't update in dark mode
Container(color: Color(0xFF4A7B59))

// Right - will update in dark mode
Container(color: Theme.of(context).brandColors.primary)
```

### Spacing Issues
Use the spacing extension for consistent spacing:

```dart
// Wrong - arbitrary values
Padding(padding: EdgeInsets.all(17.0))

// Right - uses design tokens
Padding(padding: EdgeInsets.all(Theme.of(context).spacing.lg))
```

## 📚 Additional Resources

- [Flutter Material 3 Design System](https://m3.material.io/)
- [Design Tokens Documentation](lib/shared/theme/design_tokens.dart)
- [Theme Showcase Widget](lib/shared/widgets/theme_showcase_widget.dart)

## 🔄 Migration Guide

If you're migrating from the old theme system:

1. Replace hardcoded colors with theme extensions
2. Update spacing to use spacing tokens
3. Replace arbitrary border radius with border radius tokens
4. Update shadows to use shadow tokens
5. Test thoroughly in both light and dark modes

The new theme system maintains backward compatibility with existing color constants like `AppTheme.oliveGreen`, but you should migrate to the new extension-based system for better consistency.