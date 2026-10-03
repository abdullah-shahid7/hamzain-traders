import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';

/// Large, elegant "Thank You" banner shown at the bottom of the order
/// confirmation / receipt experience. Purely presentational — carries
/// no data dependency and changes no functionality, so it can be
/// dropped into any post-checkout screen safely.
class ThankYouBanner extends StatefulWidget {
  const ThankYouBanner({super.key});

  @override
  State<ThankYouBanner> createState() => _ThankYouBannerState();
}

class _ThankYouBannerState extends State<ThankYouBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );
    _glow = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
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
        return Opacity(
          opacity: _fadeIn.value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - _slideIn.value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 34),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDeep, AppColors.primary, AppColors.bgSoft],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _glow,
              builder: (context, child) {
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold
                            .withOpacity(0.25 + 0.2 * _glow.value),
                        blurRadius: 24 + 10 * _glow.value,
                        spreadRadius: 1 + 2 * _glow.value,
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.accentGold,
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'THANK YOU FOR CHOOSING',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.78),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 10),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Colors.white, AppColors.accentGoldSoft, Colors.white],
              ).createShader(rect),
              child: Text(
                'Hamza & Traders',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 46,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.accentGold,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'We truly appreciate your trust and your order.\nYour satisfaction means everything to us.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                height: 1.6,
                color: Colors.white.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
