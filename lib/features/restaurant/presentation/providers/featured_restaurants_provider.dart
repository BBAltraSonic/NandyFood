import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/core/results/result.dart';
import 'package:food_delivery_app/features/restaurant/data/repositories/restaurant_repository_result.dart';
import 'package:food_delivery_app/shared/models/restaurant.dart';

final featuredRestaurantsProvider = AutoDisposeAsyncNotifierProvider<FeaturedRestaurantsNotifier, List<Restaurant>>(
  () => FeaturedRestaurantsNotifier(),
);

class FeaturedRestaurantsNotifier extends AutoDisposeAsyncNotifier<List<Restaurant>> {
  late final RestaurantRepositoryR _repo;

  @override
  Future<List<Restaurant>> build() async {
    _repo = RestaurantRepositoryR();
    final res = await _repo.fetchFeatured(limit: 5);
    return res.when(
      success: (value) => value,
      failure: (f) => Future.error(f),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final res = await _repo.fetchFeatured(limit: 5);
      return res.when(
        success: (value) => value,
        failure: (f) => Future.error(f),
      );
    });
  }
}

