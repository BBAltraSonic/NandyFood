import 'package:flutter/material.dart';
import 'package:food_delivery_app/shared/theme/design_tokens.dart';

/// A custom loading animation with Grandfood branding
class GrandfoodLoadingAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const GrandfoodLoadingAnimation({
    super.key,
    this.size = 48.0,
    this.color,
  });

  @override
  State<GrandfoodLoadingAnimation> createState() => _GrandfoodLoadingAnimationState();
}

class _GrandfoodLoadingAnimationState extends State<GrandfoodLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.3,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? BrandColors.primary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Rotating circle
              Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color,
                      width: 3,
                    ),
                  ),
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      margin: EdgeInsets.all(widget.size * 0.1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: _opacityAnimation.value),
                      ),
                    ),
                  ),
                ),
              ),
              // Center icon
              Icon(
                Icons.restaurant_rounded,
                size: widget.size * 0.4,
                color: color,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A pulsing dot loading animation
class PulsingDotAnimation extends StatefulWidget {
  final double size;
  final Color? color;
  final int dotCount;

  const PulsingDotAnimation({
    super.key,
    this.size = 8.0,
    this.color,
    this.dotCount = 3,
  });

  @override
  State<PulsingDotAnimation> createState() => _PulsingDotAnimationState();
}

class _PulsingDotAnimationState extends State<PulsingDotAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.dotCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Start animations with staggered delays
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? BrandColors.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.dotCount,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: _animations[index].value),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// A skeleton loading animation for cards
class SkeletonLoadingAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const SkeletonLoadingAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<SkeletonLoadingAnimation> createState() => _SkeletonLoadingAnimationState();
}

class _SkeletonLoadingAnimationState extends State<SkeletonLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// A heartbeat animation for cart items or favorites
class HeartbeatAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleAmount;

  const HeartbeatAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 800),
    this.scaleAmount = 1.2,
  });

  @override
  State<HeartbeatAnimation> createState() => _HeartbeatAnimationState();
}

class _HeartbeatAnimationState extends State<HeartbeatAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleAmount,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    ));

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.onTap != null) {
          widget.onTap!();
        }
        // Trigger heartbeat animation on tap
        _controller.reset();
        _controller.forward();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}