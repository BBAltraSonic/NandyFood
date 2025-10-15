import 'package:flutter/material.dart';

/// A shimmer effect widget that creates a loading animation
/// 
/// Displays an animated gradient that moves across child widgets
/// to indicate loading state.
class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Duration period;
  final LinearGradient gradient;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1500),
    LinearGradient? gradient,
  }) : gradient = gradient ??
            const LinearGradient(
              colors: [
                Color(0xFFE0E0E0),
                Color(0xFFF5F5F5),
                Color(0xFFE0E0E0),
              ],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            );

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.period,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: widget.gradient.colors,
              stops: widget.gradient.stops,
              begin: Alignment(-1.0 - _controller.value * 2, -1.0),
              end: Alignment(1.0 + _controller.value * 2, 1.0),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
      child: widget.child,
    );
  }
}

/// A simple shimmer box used as a building block for skeleton screens
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ShimmerWidget(
      gradient: isDark
          ? const LinearGradient(
              colors: [
                Color(0xFF2C2C2C),
                Color(0xFF3A3A3A),
                Color(0xFF2C2C2C),
              ],
              stops: [0.0, 0.5, 1.0],
            )
          : null,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0),
          borderRadius: shape == BoxShape.rectangle ? (borderRadius ?? BorderRadius.circular(8)) : null,
          shape: shape,
        ),
      ),
    );
  }
}
