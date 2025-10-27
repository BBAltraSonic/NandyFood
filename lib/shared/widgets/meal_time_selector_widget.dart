import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/app_theme.dart';

enum MealTime {
  breakfast,
  lunch,
  supper,
  dinner,
}

class MealTimeSelector extends StatelessWidget {
  final MealTime? selectedMealTime;
  final ValueChanged<MealTime>? onMealTimeSelected;

  const MealTimeSelector({
    super.key,
    this.selectedMealTime,
    this.onMealTimeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MealTimeCard(
          mealTime: MealTime.breakfast,
          label: 'Breakfast',
          timeRange: '7 am - 11 pm',
          color: AppTheme.breakfastColor,
          isSelected: selectedMealTime == MealTime.breakfast,
          onTap: () => onMealTimeSelected?.call(MealTime.breakfast),
        ),
        const SizedBox(height: 12),
        MealTimeCard(
          mealTime: MealTime.lunch,
          label: 'Lunch',
          timeRange: '11 am - 4 pm',
          color: AppTheme.lunchColor,
          isSelected: selectedMealTime == MealTime.lunch,
          onTap: () => onMealTimeSelected?.call(MealTime.lunch),
        ),
        const SizedBox(height: 12),
        MealTimeCard(
          mealTime: MealTime.supper,
          label: 'Supper',
          timeRange: '4 pm - 7 pm',
          color: AppTheme.supperColor,
          isSelected: selectedMealTime == MealTime.supper,
          onTap: () => onMealTimeSelected?.call(MealTime.supper),
        ),
        const SizedBox(height: 12),
        MealTimeCard(
          mealTime: MealTime.dinner,
          label: 'Dinner',
          timeRange: '7 pm - 10 pm',
          color: AppTheme.dinnerColor,
          isSelected: selectedMealTime == MealTime.dinner,
          onTap: () => onMealTimeSelected?.call(MealTime.dinner),
        ),
      ],
    );
  }
}

class MealTimeCard extends StatelessWidget {
  final MealTime mealTime;
  final String label;
  final String timeRange;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const MealTimeCard({
    super.key,
    required this.mealTime,
    required this.label,
    required this.timeRange,
    required this.color,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                color.withValues(alpha: 0.3),
                color.withValues(alpha: 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppTheme.oliveGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Icon/Emoji for meal time
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _getMealIcon(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeRange,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.oliveGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMealIcon() {
    switch (mealTime) {
      case MealTime.breakfast:
        return '🌅';
      case MealTime.lunch:
        return '☀️';
      case MealTime.supper:
        return '🌆';
      case MealTime.dinner:
        return '🌙';
    }
  }
}
