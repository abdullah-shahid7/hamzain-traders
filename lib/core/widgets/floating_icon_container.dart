import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// A reusable "glass" circular container that gently floats up and
/// down while pulsing in scale. Used to house the hero icon on the
/// Splash and Onboarding screens so it feels light, premium and alive.
class FloatingIconContainer extends StatefulWidget {
  const FloatingIconContainer({
    super.key,
    required this.icon,
    this.size = 120,
    this.iconSize = 56,
    this.floatRange = 12,
    this.duration = const Duration(seconds: 3),
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final double floatRange;
  final Duration duration;

  @override
  State<FloatingIconContainer> createState() => _FloatingIconContainerState();
}

class _FloatingIconContainerState extends State<FloatingIconContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -widget.floatRange,
      end: widget.floatRange,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.18),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(
          widget.icon,
          size: widget.iconSize,
          color: AppColors.accentGold,
        ),
      ),
    );
  }
}
