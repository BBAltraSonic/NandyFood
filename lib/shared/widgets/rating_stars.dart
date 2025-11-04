import 'package:flutter/material.dart';

/// Interactive rating stars widget
class RatingStars extends StatefulWidget {
  final int rating;
  final Function(int)? onRatingChanged;
  final double size;
  final bool interactive;
  final Color? activeColor;
  final Color? inactiveColor;

  const RatingStars({
    Key? key,
    required this.rating,
    this.onRatingChanged,
    this.size = 24.0,
    this.interactive = false,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  State<RatingStars> createState() => _RatingStarsState();
}

class _RatingStarsState extends State<RatingStars> {
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.rating;
  }

  @override
  void didUpdateWidget(RatingStars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) {
      _currentRating = widget.rating;
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? Colors.black54;
    final inactiveColor = widget.inactiveColor ?? Colors.grey[300];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= _currentRating;

        return GestureDetector(
          onTap: widget.interactive && widget.onRatingChanged != null
              ? () {
                  setState(() {
                    _currentRating = starIndex;
                  });
                  widget.onRatingChanged!(starIndex);
                }
              : null,
          child: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: widget.size,
            color: isFilled ? activeColor : inactiveColor,
          ),
        );
      }),
    );
  }
}

/// Display-only rating with number
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? totalReviews;
  final double size;
  final bool showNumber;

  const RatingDisplay({
    Key? key,
    required this.rating,
    this.totalReviews,
    this.size = 16.0,
    this.showNumber = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: size,
          color: Colors.black54,
        ),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (totalReviews != null) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews)',
            style: TextStyle(
              fontSize: size * 0.7,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }
}
