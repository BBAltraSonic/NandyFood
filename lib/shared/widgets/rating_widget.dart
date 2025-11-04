import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  final double rating;
  final int maxRating;
  final int reviewCount;
  final bool showReviewCount;
  final double size;
  final Color? color;

  const RatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.reviewCount = 0,
    this.showReviewCount = true,
    this.size = 16,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star icons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(maxRating, (index) {
            return Icon(
              index < rating.floor()
                  ? Icons.star
                  : (index < rating.ceil()
                        ? Icons.star_half
                        : Icons.star_border),
              color: color ?? Colors.black54,
              size: size,
            );
          }),
        ),
        const SizedBox(width: 4),
        // Rating text
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w500,
            color: color ?? Colors.black54,
          ),
        ),
        if (showReviewCount && reviewCount > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($reviewCount)',
            style: TextStyle(fontSize: size * 0.8, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
