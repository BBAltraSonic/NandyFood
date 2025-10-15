import 'package:flutter/material.dart';

/// UI rendering optimization utilities
class UIOptimization {
  /// Wrap expensive widgets with RepaintBoundary to isolate repaints
  static Widget withRepaintBoundary(Widget child) {
    return RepaintBoundary(child: child);
  }

  /// Create optimized list with const items where possible
  static ListView buildOptimizedList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    EdgeInsets? padding,
    double? itemExtent,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemExtent: itemExtent, // Helps performance when items have same height
      itemBuilder: itemBuilder,
    );
  }

  /// Create optimized grid with const items where possible
  static GridView buildOptimizedGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    EdgeInsets? padding,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      itemBuilder: itemBuilder,
    );
  }

  /// Wrap scrollable content with performance optimization
  static Widget optimizedScrollView({
    required Widget child,
    ScrollController? controller,
  }) {
    return SingleChildScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(), // Better performance than default
      child: child,
    );
  }

  /// Performance-optimized animated switcher
  static Widget optimizedAnimatedSwitcher({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: child,
    );
  }
}

/// Const wrapper for improved performance
/// 
/// Use this to wrap parts of your widget tree that never change
class ConstWidget extends StatelessWidget {
  final Widget child;

  const ConstWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

/// Performance-optimized list item wrapper
class OptimizedListItem extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  const OptimizedListItem({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        child: content,
      );
    }

    // Wrap with RepaintBoundary to isolate repaints
    return RepaintBoundary(child: content);
  }
}

/// Performance metrics display (debug mode only)
class PerformanceOverlay extends StatelessWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showOverlay) return child;

    return Stack(
      children: [
        child,
        const Positioned(
          top: 100,
          right: 10,
          child: PerformanceOverlayWidget(
            checkerboardRasterCacheImages: true,
            checkerboardOffscreenLayers: true,
          ),
        ),
      ],
    );
  }
}

/// Extensions for widget optimization
extension WidgetOptimizationExtension on Widget {
  /// Wrap widget with RepaintBoundary
  Widget get isolated => RepaintBoundary(child: this);

  /// Make widget const if possible
  Widget get asConst => ConstWidget(child: this);

  /// Wrap with SingleChildScrollView
  Widget get scrollable => SingleChildScrollView(child: this);

  /// Add padding optimization
  Widget paddingAll(double value) => Padding(
    padding: EdgeInsets.all(value),
    child: this,
  );

  /// Add symmetric padding
  Widget paddingSymmetric({double? horizontal, double? vertical}) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: horizontal ?? 0,
      vertical: vertical ?? 0,
    ),
    child: this,
  );
}
