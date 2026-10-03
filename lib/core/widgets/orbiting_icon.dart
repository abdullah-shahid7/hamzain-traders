import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// A small accent icon that slowly orbits around a central point,
/// adding a subtle premium "living" quality to hero illustrations on
/// the onboarding pages.
class OrbitingIcon extends StatefulWidget {
  const OrbitingIcon({
    super.key,
    required this.icon,
    required this.radius,
    this.angleOffset = 0,
    this.duration = const Duration(seconds: 9),
  });

  final IconData icon;
  final double radius;
  final double angleOffset;
  final Duration duration;

  @override
  State<OrbitingIcon> createState() => _OrbitingIconState();
}

class _OrbitingIconState extends State<OrbitingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
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
        final angle = widget.angleOffset + (_controller.value * 2 * math.pi);
        final dx = math.cos(angle) * widget.radius;
        final dy = math.sin(angle) * widget.radius;
        return Transform.translate(offset: Offset(dx, dy), child: child);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.glassFill,
          border: Border.all(color: AppColors.glassBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.2),
              blurRadius: 12,
            ),
          ],
        ),
        child: Icon(widget.icon, size: 18, color: AppColors.white),
      ),
    );
  }
}
