import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Widget optimization utilities for performance improvements
class WidgetOptimizer {
  /// Create a const widget when possible to avoid rebuilds
  static const Widget empty = SizedBox.shrink();

  /// Create a cached widget with equality check
  static Widget cached({required Widget child, List<Object?> keys = const []}) {
    return _CachedWidget(child: child, keys: keys);
  }

  /// Create a widget that only rebuilds when specific conditions change
  static Widget conditionalRebuild({
    required Widget child,
    required bool Function() shouldRebuild,
    List<Object?> dependencies = const [],
  }) {
    return _ConditionalRebuildWidget(
      child: child,
      shouldRebuild: shouldRebuild,
      dependencies: dependencies,
    );
  }

  /// Create a widget with debounced rebuilds
  static Widget debouncedRebuild({
    required Widget child,
    Duration debounceDuration = const Duration(milliseconds: 100),
    List<Object?> keys = const [],
  }) {
    return _DebouncedRebuildWidget(
      child: child,
      debounceDuration: debounceDuration,
      keys: keys,
    );
  }

  /// Optimize list rendering with proper keys and recycling
  static Widget optimizedListView({
    required List<Widget> children,
    required Axis scrollDirection,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView(
      scrollDirection: scrollDirection,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
      children: children
          .asMap()
          .map(
            (index, child) => MapEntry(
              index,
              KeyedSubtree(
                key: ValueKey('$index-${child.hashCode}'),
                child: child,
              ),
            ),
          )
          .values
          .toList(),
    );
  }

  /// Create a widget that renders heavy content progressively
  static Widget progressiveRender({
    required List<Widget> items,
    required int batchSize,
    Duration batchDelay = const Duration(milliseconds: 50),
  }) {
    return _ProgressiveRenderWidget(
      items: items,
      batchSize: batchSize,
      batchDelay: batchDelay,
    );
  }
}

/// Cached widget that only rebuilds when keys change
class _CachedWidget extends StatefulWidget {
  final Widget child;
  final List<Object?> keys;

  const _CachedWidget({required this.child, required this.keys});

  @override
  State<_CachedWidget> createState() => _CachedWidgetState();
}

class _CachedWidgetState extends State<_CachedWidget> {
  late Widget _cachedChild;

  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
  }

  @override
  void didUpdateWidget(covariant _CachedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update child if keys have changed
    if (!listEquals(oldWidget.keys, widget.keys)) {
      _cachedChild = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}

/// Conditional rebuild widget
class _ConditionalRebuildWidget extends StatefulWidget {
  final Widget child;
  final bool Function() shouldRebuild;
  final List<Object?> dependencies;

  const _ConditionalRebuildWidget({
    required this.child,
    required this.shouldRebuild,
    required this.dependencies,
  });

  @override
  State<_ConditionalRebuildWidget> createState() =>
      _ConditionalRebuildWidgetState();
}

class _ConditionalRebuildWidgetState extends State<_ConditionalRebuildWidget> {
  late Widget _cachedChild;

  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
  }

  @override
  void didUpdateWidget(covariant _ConditionalRebuildWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we should rebuild based on the condition
    if (widget.shouldRebuild()) {
      _cachedChild = widget.child;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}

/// Debounced rebuild widget
class _DebouncedRebuildWidget extends StatefulWidget {
  final Widget child;
  final Duration debounceDuration;
  final List<Object?> keys;

  const _DebouncedRebuildWidget({
    required this.child,
    required this.debounceDuration,
    required this.keys,
  });

  @override
  State<_DebouncedRebuildWidget> createState() =>
      _DebouncedRebuildWidgetState();
}

class _DebouncedRebuildWidgetState extends State<_DebouncedRebuildWidget> {
  late Widget _cachedChild;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cachedChild = widget.child;
  }

  @override
  void didUpdateWidget(covariant _DebouncedRebuildWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final now = DateTime.now();
    final timeSinceLastUpdate = now.difference(_lastUpdate);

    // Only update if enough time has passed
    if (timeSinceLastUpdate >= widget.debounceDuration) {
      // Check if keys have changed
      if (!listEquals(oldWidget.keys, widget.keys)) {
        _lastUpdate = now;
        _cachedChild = widget.child;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _cachedChild;
  }
}

/// Progressive render widget for large lists
class _ProgressiveRenderWidget extends StatefulWidget {
  final List<Widget> items;
  final int batchSize;
  final Duration batchDelay;

  const _ProgressiveRenderWidget({
    required this.items,
    required this.batchSize,
    required this.batchDelay,
  });

  @override
  State<_ProgressiveRenderWidget> createState() =>
      _ProgressiveRenderWidgetState();
}

class _ProgressiveRenderWidgetState extends State<_ProgressiveRenderWidget> {
  List<Widget> _renderedItems = [];
  int _currentIndex = 0;
  bool _isRendering = false;

  @override
  void initState() {
    super.initState();
    _renderNextBatch();
  }

  void _renderNextBatch() {
    if (_isRendering || _currentIndex >= widget.items.length) return;

    setState(() {
      _isRendering = true;
    });

    // Render next batch
    final endIndex = (_currentIndex + widget.batchSize).clamp(
      0,
      widget.items.length,
    );
    final newItems = widget.items.sublist(_currentIndex, endIndex);

    setState(() {
      _renderedItems = [..._renderedItems, ...newItems];
      _currentIndex = endIndex;
      _isRendering = false;
    });

    // Schedule next batch if there are more items
    if (_currentIndex < widget.items.length) {
      Future.delayed(widget.batchDelay, _renderNextBatch);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._renderedItems,
        if (_currentIndex < widget.items.length)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
