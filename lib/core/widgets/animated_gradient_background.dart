import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// A decorative animated background made of soft glowing orbs that
/// slowly drift across the screen, giving the Splash and Onboarding
/// screens a premium, "alive" feeling without distracting from the
/// main content in the foreground.
class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 2 * math.pi;
        return Stack(
          children: [
            // Base gradient for subtle depth beneath the orbs.
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryDark,
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
            _buildOrb(
              size,
              top: size.height * 0.08 + math.sin(t) * 14,
              left: size.width * 0.65 + math.cos(t) * 10,
              diameter: size.width * 0.55,
              color: AppColors.accentGold.withOpacity(0.10),
            ),
            _buildOrb(
              size,
              top: size.height * 0.62 + math.cos(t) * 16,
              left: -size.width * 0.25 + math.sin(t) * 10,
              diameter: size.width * 0.75,
              color: AppColors.primaryLight.withOpacity(0.35),
            ),
            _buildOrb(
              size,
              top: size.height * 0.32 + math.sin(t + 1.2) * 10,
              left: size.width * 0.10 + math.cos(t + 1.2) * 8,
              diameter: size.width * 0.35,
              color: AppColors.accentGoldSoft.withOpacity(0.05),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrb(
    Size screenSize, {
    required double top,
    required double left,
    required double diameter,
    required Color color,
  }) {
    return Positioned(
      top: top,
      left: left,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [color, color.withOpacity(0.0)],
            ),
          ),
        ),
      ),
    );
  }
}
