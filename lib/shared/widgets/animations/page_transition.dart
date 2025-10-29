import 'package:flutter/material.dart';

/// Custom page transition animations for the Grandfood app
class GrandfoodPageTransitions {
  /// Slide and fade transition
  static PageRouteBuilder slideAndFade({
    required Widget child,
    required String routeName,
    Duration duration = const Duration(milliseconds: 300),
    SlideDirection direction = SlideDirection.right,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        Offset begin;
        switch (direction) {
          case SlideDirection.left:
            begin = const Offset(-1.0, 0.0);
            break;
          case SlideDirection.right:
            begin = const Offset(1.0, 0.0);
            break;
          case SlideDirection.up:
            begin = const Offset(0.0, 1.0);
            break;
          case SlideDirection.down:
            begin = const Offset(0.0, -1.0);
            break;
        }

        return SlideTransition(
          position: Tween<Offset>(
            begin: begin,
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Scale and fade transition
  static PageRouteBuilder scaleAndFade({
    required Widget child,
    required String routeName,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.elasticOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Rotate and fade transition
  static PageRouteBuilder rotateAndFade({
    required Widget child,
    required String routeName,
    Duration duration = const Duration(milliseconds: 500),
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return RotationTransition(
          turns: Tween<double>(
            begin: 0.2,
            end: 0.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOut,
          )),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }

  /// Size transition with fade
  static PageRouteBuilder sizeAndFade({
    required Widget child,
    required String routeName,
    Duration duration = const Duration(milliseconds: 300),
    double axisAlignment = 0.0,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => child,
      transitionDuration: duration,
      settings: RouteSettings(name: routeName),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          axisAlignment: axisAlignment,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
    );
  }
}

enum SlideDirection { left, right, up, down }

/// A custom slide transition widget for use within screens
class SlideTransitionWidget extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final SlideDirection direction;
  final Curve curve;

  const SlideTransitionWidget({
    super.key,
    required this.child,
    this.show = true,
    this.duration = const Duration(milliseconds: 300),
    this.direction = SlideDirection.up,
    this.curve = Curves.easeInOut,
  });

  @override
  State<SlideTransitionWidget> createState() => _SlideTransitionWidgetState();
}

class _SlideTransitionWidgetState extends State<SlideTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    Offset begin;
    Offset end;
    switch (widget.direction) {
      case SlideDirection.left:
        begin = const Offset(-1.0, 0.0);
        end = Offset.zero;
        break;
      case SlideDirection.right:
        begin = const Offset(1.0, 0.0);
        end = Offset.zero;
        break;
      case SlideDirection.up:
        begin = const Offset(0.0, 1.0);
        end = Offset.zero;
        break;
      case SlideDirection.down:
        begin = const Offset(0.0, -1.0);
        end = Offset.zero;
        break;
    }

    _offsetAnimation = Tween<Offset>(
      begin: widget.show ? begin : end,
      end: widget.show ? end : begin,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SlideTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: widget.child,
    );
  }
}

/// A fade transition widget for use within screens
class FadeTransitionWidget extends StatefulWidget {
  final Widget child;
  final bool show;
  final Duration duration;
  final Curve curve;

  const FadeTransitionWidget({
    super.key,
    required this.child,
    this.show = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  State<FadeTransitionWidget> createState() => _FadeTransitionWidgetState();
}

class _FadeTransitionWidgetState extends State<FadeTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: widget.show ? 0.0 : 1.0,
      end: widget.show ? 1.0 : 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    if (widget.show) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FadeTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.show != widget.show) {
      if (widget.show) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}