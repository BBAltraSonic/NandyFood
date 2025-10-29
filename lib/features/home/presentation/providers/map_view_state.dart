class MapViewState {
  final bool isMapView;
  final bool isLoading;
  final String? error;
  final bool isSearchBarIntegrated;

  const MapViewState({
    this.isMapView = false,
    this.isLoading = false,
    this.error,
    this.isSearchBarIntegrated = false,
  });

  MapViewState copyWith({
    bool? isMapView,
    bool? isLoading,
    String? error,
    bool? isSearchBarIntegrated,
  }) {
    return MapViewState(
      isMapView: isMapView ?? this.isMapView,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isSearchBarIntegrated: isSearchBarIntegrated ?? this.isSearchBarIntegrated,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapViewState &&
          runtimeType == other.runtimeType &&
          isMapView == other.isMapView &&
          isLoading == other.isLoading &&
          error == other.error &&
          isSearchBarIntegrated == other.isSearchBarIntegrated;

  @override
  int get hashCode =>
      isMapView.hashCode ^
      isLoading.hashCode ^
      error.hashCode ^
      isSearchBarIntegrated.hashCode;
}