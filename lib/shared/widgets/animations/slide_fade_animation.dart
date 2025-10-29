import 'package:flutter/material.dart';

/// A widget that animates its child with slide and fade effects
class SlideFadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset begin;
  final Offset end;
  final Curve curve;

  const SlideFadeAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = Duration.zero,
    this.begin = const Offset(0, 0.3),
    this.end = Offset.zero,
    this.curve = Curves.easeOut,
  });

  @override
  State<SlideFadeAnimation> createState() => _SlideFadeAnimationState();
}

class _SlideFadeAnimationState extends State<SlideFadeAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.8, curve: widget.curve),
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
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
        return Opacity(
          opacity: _fadeAnimation.value,
          child: FractionalTranslation(
            translation: Offset.lerp(
              widget.begin,
              widget.end,
              _slideAnimation.value,
            )!,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A list widget that animates its children in sequence
class AnimatedList extends StatelessWidget {
  final List<Widget> children;
  final Duration duration;
  final Duration staggerDelay;
  final SlideDirection slideDirection;

  const AnimatedList({
    super.key,
    required this.children,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.slideDirection = SlideDirection.up,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final delay = Duration(
          milliseconds: staggerDelay.inMilliseconds * index,
        );

        return SlideFadeAnimation(
          delay: delay,
          duration: duration,
          begin: _getBeginOffset(slideDirection),
          child: child,
        );
      }).toList(),
    );
  }

  Offset _getBeginOffset(SlideDirection direction) {
    switch (direction) {
      case SlideDirection.up:
        return const Offset(0, 0.3);
      case SlideDirection.down:
        return const Offset(0, -0.3);
      case SlideDirection.left:
        return const Offset(0.3, 0);
      case SlideDirection.right:
        return const Offset(-0.3, 0);
    }
  }
}

enum SlideDirection { up, down, left, right }

/// A widget that provides staggered animation for a list of items
class StaggeredAnimation extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;
  final Duration staggerDelay;
  final Offset begin;

  const StaggeredAnimation({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 600),
    this.staggerDelay = const Duration(milliseconds: 100),
    this.begin = const Offset(0, 0.3),
  });

  @override
  Widget build(BuildContext context) {
    return SlideFadeAnimation(
      delay: Duration(
        milliseconds: staggerDelay.inMilliseconds * index,
      ),
      duration: duration,
      begin: begin,
      child: child,
    );
  }
}