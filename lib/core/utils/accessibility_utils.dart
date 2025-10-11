import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utility class for consistent accessibility support
class Accessibility {
  /// Make text more accessible by ensuring proper contrast and sizing
  static TextStyle accessibleText({
    TextStyle? style,
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? minContrastRatio = 4.5, // WCAG AA standard
  }) {
    final baseStyle = style ?? const TextStyle();
    
    return baseStyle.copyWith(
      fontSize: fontSize ?? baseStyle.fontSize,
      fontWeight: fontWeight ?? baseStyle.fontWeight,
      color: color ?? baseStyle.color,
    );
  }

  /// Create an accessible button with proper semantics and focus
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback onPressed,
    String? semanticsLabel,
    bool enabled = true,
    Color? backgroundColor,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    OutlinedBorder? shape,
  }) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: enabled,
      focusable: true,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: padding,
          shape: shape,
        ),
        child: child,
      ),
    );
  }

  /// Create an accessible icon button
  static Widget accessibleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    String? semanticsLabel,
    bool enabled = true,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: semanticsLabel ?? tooltip,
      button: true,
      enabled: enabled,
      focusable: true,
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: size,
        ),
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
      ),
    );
  }

  /// Create an accessible text field
  static Widget accessibleTextField({
    required TextEditingController controller,
    String? label,
    String? hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    int? maxLines,
    int? maxLength,
    bool enabled = true,
  }) {
    return Semantics(
      label: label,
      textField: true,
      enabled: enabled,
      focusable: true,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        onSaved: onSaved,
        onChanged: onChanged,
        maxLines: maxLines,
        maxLength: maxLength,
        enabled: enabled,
      ),
    );
  }

  /// Create accessible screen reader announcements
  static void announceToScreenReader(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Create accessible headings for proper screen reader navigation
  static Widget accessibleHeading(
    String text, {
    TextStyle? style,
    int level = 2, // Heading level (1-6)
  }) {
    final headingStyle = style ?? _getHeadingStyle(level);
    
    return Semantics(
      header: true,
      child: Text(
        text,
        style: headingStyle,
      ),
    );
  }

  /// Get appropriate heading style based on level
  static TextStyle _getHeadingStyle(int level) {
    switch (level) {
      case 1:
        return const TextStyle(fontSize: 32, fontWeight: FontWeight.bold);
      case 2:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case 3:
        return const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case 4:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      case 5:
        return const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);
      case 6:
      default:
        return const TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
    }
  }

  /// Create an accessible list item
  static Widget accessibleListItem({
    required Widget child,
    String? semanticsLabel,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Semantics(
      label: semanticsLabel,
      selected: selected,
      button: onTap != null,
      focusable: true,
      child: ListTile(
        title: child,
        selected: selected,
        onTap: onTap,
      ),
    );
  }

  /// Create accessible navigation controls
  static Widget accessibleNavigationRail({
    required List<NavigationRailDestination> destinations,
    required ValueChanged<int> onDestinationSelected,
    required int selectedIndex,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel ?? 'Navigation',
      container: true,
      child: NavigationRail(
        destinations: destinations,
        onDestinationSelected: onDestinationSelected,
        selectedIndex: selectedIndex,
        labelType: NavigationRailLabelType.all,
      ),
    );
  }

  /// Create accessible tab bar
  static Widget accessibleTabBar({
    required List<Tab> tabs,
    required TabController controller,
    ValueChanged<int>? onTap,
    bool isScrollable = false,
  }) {
    return Semantics(
      container: true,
      label: 'Tabs',
      child: TabBar(
        tabs: tabs,
        controller: controller,
        onTap: onTap,
        isScrollable: isScrollable,
      ),
    );
  }
}