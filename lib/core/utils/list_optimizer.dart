import 'package:flutter/material.dart';

/// List optimization utilities for better performance with large lists
class ListOptimizer {
  /// Create an optimized list view with proper recycling and performance settings
  static Widget optimizedListView({
    required List<Widget> items,
    required ScrollController? scrollController,
    EdgeInsetsGeometry? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    double? itemExtent,
    bool shrinkWrap = false,
    bool reverse = false,
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
    int? itemCount,
    IndexedWidgetBuilder? itemBuilder,
    Widget? separatorBuilder,
  }) {
    // Use ListView.builder for better performance with large lists
    if (itemBuilder != null) {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final item = itemBuilder(context, index);
          return _wrapItem(
            item: item,
            index: index,
            addAutomaticKeepAlives: addAutomaticKeepAlives,
            addRepaintBoundaries: addRepaintBoundaries,
            addSemanticIndexes: addSemanticIndexes,
          );
        },
        controller: scrollController,
        padding: padding,
        itemExtent: itemExtent,
        shrinkWrap: shrinkWrap,
        reverse: reverse,
        scrollDirection: scrollDirection,
        physics: physics,
      );
    }

    // For fixed lists, use ListView with proper optimization
    return ListView(
      children: items
          .asMap()
          .map(
            (index, item) => MapEntry(
              index,
              _wrapItem(
                item: item,
                index: index,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes,
              ),
            ),
          )
          .values
          .toList(),
      controller: scrollController,
      padding: padding,
      itemExtent: itemExtent,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      scrollDirection: scrollDirection,
      physics: physics,
    );
  }

  /// Create an optimized list view with separators
  static Widget optimizedListViewSeparated({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required IndexedWidgetBuilder separatorBuilder,
    ScrollController? scrollController,
    EdgeInsetsGeometry? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    bool reverse = false,
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
  }) {
    return ListView.separated(
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final item = itemBuilder(context, index);
        return _wrapItem(
          item: item,
          index: index,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        );
      },
      separatorBuilder: separatorBuilder,
      controller: scrollController,
      padding: padding,
      reverse: reverse,
      scrollDirection: scrollDirection,
      physics: physics,
    );
  }

  /// Wrap item with performance optimization widgets
  static Widget _wrapItem({
    required Widget item,
    required int index,
    required bool addAutomaticKeepAlives,
    required bool addRepaintBoundaries,
    required bool addSemanticIndexes,
  }) {
    Widget wrappedItem = item;

    // Add repaint boundary for better performance
    if (addRepaintBoundaries) {
      wrappedItem = RepaintBoundary(child: wrappedItem);
    }

    // Add automatic keep alive for better performance
    if (addAutomaticKeepAlives) {
      wrappedItem = KeyedSubtree(
        key: ValueKey('keep_alive_$index'),
        child: wrappedItem,
      );
    }

    // Add semantic indexes for better accessibility
    if (addSemanticIndexes) {
      wrappedItem = IndexedSemantics(index: index, child: wrappedItem);
    }

    return wrappedItem;
  }

  /// Create a grid view with optimized performance settings
  static Widget optimizedGridView({
    required List<Widget> items,
    required int crossAxisCount,
    double childAspectRatio = 1.0,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    ScrollController? scrollController,
    EdgeInsetsGeometry? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    bool shrinkWrap = false,
    bool reverse = false,
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      controller: scrollController,
      padding: padding,
      shrinkWrap: shrinkWrap,
      reverse: reverse,
      scrollDirection: scrollDirection,
      physics: physics,
      children: items
          .asMap()
          .map(
            (index, item) => MapEntry(
              index,
              _wrapGridItem(
                item: item,
                index: index,
                addAutomaticKeepAlives: addAutomaticKeepAlives,
                addRepaintBoundaries: addRepaintBoundaries,
                addSemanticIndexes: addSemanticIndexes,
              ),
            ),
          )
          .values
          .toList(),
    );
  }

  /// Wrap grid item with performance optimization widgets
  static Widget _wrapGridItem({
    required Widget item,
    required int index,
    required bool addAutomaticKeepAlives,
    required bool addRepaintBoundaries,
    required bool addSemanticIndexes,
  }) {
    Widget wrappedItem = item;

    // Add repaint boundary for better performance
    if (addRepaintBoundaries) {
      wrappedItem = RepaintBoundary(child: wrappedItem);
    }

    // Add automatic keep alive for better performance
    if (addAutomaticKeepAlives) {
      wrappedItem = KeyedSubtree(
        key: ValueKey('grid_keep_alive_$index'),
        child: wrappedItem,
      );
    }

    // Add semantic indexes for better accessibility
    if (addSemanticIndexes) {
      wrappedItem = IndexedSemantics(index: index, child: wrappedItem);
    }

    return wrappedItem;
  }

  /// Create a lazy loading list for infinite scrolling
  static Widget lazyLoadingList({
    required Future<List<Widget>> Function(int page) onLoadMore,
    required Widget Function(bool isLoading) loadingIndicator,
    int pageSize = 20,
    ScrollController? scrollController,
    EdgeInsetsGeometry? padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    bool reverse = false,
    Axis scrollDirection = Axis.vertical,
    ScrollPhysics? physics,
  }) {
    return _LazyLoadingListView(
      onLoadMore: onLoadMore,
      loadingIndicator: loadingIndicator,
      pageSize: pageSize,
      scrollController: scrollController,
      padding: padding,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      addSemanticIndexes: addSemanticIndexes,
      reverse: reverse,
      scrollDirection: scrollDirection,
      physics: physics,
    );
  }
}

/// Lazy loading list view for infinite scrolling
class _LazyLoadingListView extends StatefulWidget {
  final Future<List<Widget>> Function(int page) onLoadMore;
  final Widget Function(bool isLoading) loadingIndicator;
  final int pageSize;
  final ScrollController? scrollController;
  final EdgeInsetsGeometry? padding;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final bool reverse;
  final Axis scrollDirection;
  final ScrollPhysics? physics;

  const _LazyLoadingListView({
    required this.onLoadMore,
    required this.loadingIndicator,
    required this.pageSize,
    this.scrollController,
    this.padding,
    required this.addAutomaticKeepAlives,
    required this.addRepaintBoundaries,
    required this.addSemanticIndexes,
    required this.reverse,
    required this.scrollDirection,
    this.physics,
  });

  @override
  _LazyLoadingListViewState createState() => _LazyLoadingListViewState();
}

class _LazyLoadingListViewState extends State<_LazyLoadingListView> {
  final List<Widget> _items = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_scrollListener);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newItems = await widget.onLoadMore(_currentPage + 1);

      if (newItems.isEmpty) {
        setState(() {
          _hasMoreData = false;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading more items: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      padding: widget.padding,
      reverse: widget.reverse,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      children: [
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return ListOptimizer._wrapItem(
            item: item,
            index: index,
            addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
            addRepaintBoundaries: widget.addRepaintBoundaries,
            addSemanticIndexes: widget.addSemanticIndexes,
          );
        }).toList(),
        if (_isLoading || _hasMoreData) widget.loadingIndicator(_isLoading),
      ],
    );
  }
}
