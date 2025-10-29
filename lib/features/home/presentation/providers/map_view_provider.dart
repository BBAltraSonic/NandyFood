import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'map_view_state.dart';

class MapViewNotifier extends StateNotifier<MapViewState> {
  MapViewNotifier() : super(const MapViewState());

  void toggleMapView() {
    state = state.copyWith(
      isMapView: !state.isMapView,
      isSearchBarIntegrated: !state.isMapView,
      isLoading: !state.isMapView,
    );

    // Simulate loading completion for map view
    if (state.isMapView) {
      Future.delayed(const Duration(milliseconds: 500), () {
        state = state.copyWith(isLoading: false);
      });
    }
  }

  void showListView() {
    state = state.copyWith(
      isMapView: false,
      isSearchBarIntegrated: false,
    );
  }

  void showMapView() {
    state = state.copyWith(
      isMapView: true,
      isSearchBarIntegrated: true,
      isLoading: true,
    );

    // Simulate loading completion
    Future.delayed(const Duration(milliseconds: 500), () {
      state = state.copyWith(isLoading: false);
    });
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for the map view state
final mapViewProvider = StateNotifierProvider<MapViewNotifier, MapViewState>((ref) {
  return MapViewNotifier();
});