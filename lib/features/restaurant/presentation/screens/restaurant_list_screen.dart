import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_delivery_app/features/restaurant/presentation/providers/restaurant_provider.dart';
import 'package:food_delivery_app/features/restaurant/presentation/widgets/restaurant_card.dart';
import 'package:food_delivery_app/shared/widgets/loading_indicator.dart';
import 'package:food_delivery_app/shared/widgets/error_message_widget.dart';
import 'package:food_delivery_app/shared/widgets/filter_widget.dart';
import 'package:food_delivery_app/shared/widgets/empty_state_widget.dart';
import 'package:food_delivery_app/shared/widgets/skeleton_loading.dart';

class RestaurantListScreen extends ConsumerWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantState = ref.watch(restaurantProvider);

    // Define dietary restriction options
    final dietaryOptions = [
      FilterOption(
        id: 'vegetarian',
        label: 'Vegetarian',
        isSelected: restaurantState.selectedDietaryRestrictions.contains(
          'vegetarian',
        ),
      ),
      FilterOption(
        id: 'vegan',
        label: 'Vegan',
        isSelected: restaurantState.selectedDietaryRestrictions.contains(
          'vegan',
        ),
      ),
      FilterOption(
        id: 'gluten-free',
        label: 'Gluten-Free',
        isSelected: restaurantState.selectedDietaryRestrictions.contains(
          'gluten-free',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants'), centerTitle: true),
      body: Column(
        children: [
          // Filter widget for dietary restrictions
          FilterWidget(
            options: dietaryOptions,
            onFiltersChanged: (selectedOptions) {
              // Extract the selected dietary restrictions
              final selectedRestrictions = selectedOptions
                  .map((option) => option.id)
                  .toList();

              // Update the provider with the selected dietary restrictions
              // For this, we need to update the provider to handle multiple restrictions at once
              // For now, let's handle each change individually
              final currentRestrictions =
                  restaurantState.selectedDietaryRestrictions;
              final newRestrictions = selectedOptions
                  .map((option) => option.id)
                  .toList();

              // Find added restrictions
              for (final restriction in newRestrictions) {
                if (!currentRestrictions.contains(restriction)) {
                  ref
                      .read(restaurantProvider.notifier)
                      .toggleDietaryRestriction(restriction);
                }
              }

              // Find removed restrictions
              for (final restriction in currentRestrictions) {
                if (!newRestrictions.contains(restriction)) {
                  ref
                      .read(restaurantProvider.notifier)
                      .toggleDietaryRestriction(restriction);
                }
              }
            },
          ),
          const SizedBox(height: 8),
          // Expanded list of restaurants
          Expanded(
            child: restaurantState.isLoading
                ? const SkeletonList(
                    skeletonCard: RestaurantCardSkeleton(),
                    itemCount: 5,
                  )
                : restaurantState.errorMessage != null
                ? ErrorMessageWidget(
                    message: restaurantState.errorMessage!,
                    onRetry: () =>
                        ref.read(restaurantProvider.notifier).loadRestaurants(),
                  )
                : _buildRestaurantList(restaurantState, context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList(restaurantState, BuildContext context, WidgetRef ref) {
    // Use filtered restaurants from state
    final restaurants =
        restaurantState.filteredRestaurants.isEmpty &&
            restaurantState.selectedDietaryRestrictions.isNotEmpty
        ? [] // If filters are active but no results, show empty
        : restaurantState.filteredRestaurants.isEmpty
        ? restaurantState
              .restaurants // If no filters, show all
        : restaurantState
              .filteredRestaurants; // If filters and results, show filtered

    if (restaurants.isEmpty) {
      return EmptyStateWidget.noRestaurants(
        onRefresh: () {
          ref.read(restaurantProvider.notifier).loadRestaurants();
        },
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(
          const Duration(milliseconds: 500),
        ); // Simulate network delay
        await Future.microtask(
          () => ProviderScope.containerOf(
            context,
          ).read(restaurantProvider.notifier).loadRestaurants(),
        );
      },
      child: ListView.builder(
        itemCount: restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          return RestaurantCard(
            restaurant: restaurant,
            onTap: () {
              // Navigate to restaurant detail screen
              Navigator.of(context).pushNamed(
                '/restaurant/${restaurant.id}',
                arguments: restaurant,
              );
            },
          );
        },
      ),
    );
  }
}
