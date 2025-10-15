import 'package:flutter/material.dart';

/// Generic lazy loading list widget with infinite scroll
/// 
/// Automatically loads more items when user scrolls near the bottom.
class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final double loadMoreThreshold; // Load when scrolled to this percentage
  final ScrollController? controller;
  final EdgeInsets? padding;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
    this.loadingWidget,
    this.emptyWidget,
    this.loadMoreThreshold = 0.8, // Load at 80% scroll
    this.controller,
    this.padding,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore || !widget.hasMore) return;

    final threshold = _scrollController.position.maxScrollExtent * widget.loadMoreThreshold;
    
    if (_scrollController.position.pixels >= threshold) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? const Center(child: Text('No items'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.items.length) {
          // Loading indicator at the end
          return widget.loadingWidget ?? 
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
        }

        return widget.itemBuilder(context, widget.items[index]);
      },
    );
  }
}

/// Pagination state for managing lazy loading
class PaginationState<T> {
  final List<T> items;
  final int currentPage;
  final int pageSize;
  final bool hasMore;
  final bool isLoading;
  final String? error;

  const PaginationState({
    this.items = const [],
    this.currentPage = 1,
    this.pageSize = 20,
    this.hasMore = true,
    this.isLoading = false,
    this.error,
  });

  PaginationState<T> copyWith({
    List<T>? items,
    int? currentPage,
    int? pageSize,
    bool? hasMore,
    bool? isLoading,
    String? error,
  }) {
    return PaginationState<T>(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Helper to add new items from a page
  PaginationState<T> addPage(List<T> newItems) {
    return copyWith(
      items: [...items, ...newItems],
      currentPage: currentPage + 1,
      hasMore: newItems.length >= pageSize,
      isLoading: false,
    );
  }

  /// Helper to reset pagination
  PaginationState<T> reset() {
    return const PaginationState();
  }

  /// Helper to set loading state
  PaginationState<T> setLoading(bool loading) {
    return copyWith(isLoading: loading);
  }

  /// Helper to set error state
  PaginationState<T> setError(String errorMessage) {
    return copyWith(error: errorMessage, isLoading: false);
  }
}
