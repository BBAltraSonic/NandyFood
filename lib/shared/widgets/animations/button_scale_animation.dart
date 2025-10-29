import 'package:flutter/material.dart';

/// A button wrapper that adds scale animation on tap
class AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleDown;
  final bool enabled;

  const AnimatedScaleButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scaleDown = 0.95,
    this.enabled = true,
  });

  @override
  State<AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<AnimatedScaleButton>
    with SingleTickerProviderStateMixin {
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
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
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

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onPressed?.call();
  }
}

/// A button with scale and shadow animation
class AnimatedElevatedButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleDown;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const AnimatedElevatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scaleDown = 0.95,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.padding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      duration: duration,
      scaleDown: scaleDown,
      enabled: enabled && onPressed != null,
      onPressed: onPressed,
      child: AnimatedContainer(
        duration: duration,
        decoration: BoxDecoration(
          color: backgroundColor ?? (enabled && onPressed != null
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300),
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          boxShadow: enabled && onPressed != null
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: DefaultTextStyle(
          style: TextStyle(
            color: foregroundColor ?? (enabled && onPressed != null
                ? Colors.white
                : Colors.grey.shade600),
            fontWeight: FontWeight.w600,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// An icon button with scale animation
class AnimatedIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final Duration duration;
  final double scaleDown;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;
  final bool enabled;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.duration = const Duration(milliseconds: 150),
    this.scaleDown = 0.9,
    this.backgroundColor,
    this.iconColor,
    this.size = 56.0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScaleButton(
      duration: duration,
      scaleDown: scaleDown,
      enabled: enabled && onPressed != null,
      onPressed: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? (enabled && onPressed != null
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300),
          shape: BoxShape.circle,
          boxShadow: enabled && onPressed != null
              ? [
                  BoxShadow(
                    color: (backgroundColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: iconColor ?? (enabled && onPressed != null
                ? Colors.white
                : Colors.grey.shade600),
            size: size * 0.4,
          ),
          child: icon,
        ),
      ),
    );
  }
}