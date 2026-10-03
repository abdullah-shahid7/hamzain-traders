import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/constants/app_durations.dart';
import 'package:hamzain_traders/core/constants/app_text_styles.dart';
import 'package:hamzain_traders/core/widgets/animated_gradient_background.dart';
import 'package:hamzain_traders/core/widgets/floating_icon_container.dart';
import 'package:hamzain_traders/screens/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _iconFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _iconFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _textFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
    ));

    _loaderFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
    );

    _entranceController.forward();

    // Automatically navigate to Onboarding after exactly 5 seconds.
    Future.delayed(AppDurations.splashTotal, _goToOnboarding);
  }

  void _goToOnboarding() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppDurations.pageTransition,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(fade);
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      // SizedBox.expand forces this subtree to fill 100% of the
      // available width and height, guaranteeing a single seamless
      // edge-to-edge background with no split panels, strips, or
      // unused space on any device or resolution.
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedGradientBackground(),
            SafeArea(
              child: SizedBox.expand(
                // A single Center widget guarantees the entire content
                // group (icon, title, subtitle, loader) is perfectly
                // centered as one block, both horizontally and
                // vertically, on every screen size.
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeTransition(
                        opacity: _iconFade,
                        child: const FloatingIconContainer(
                          icon: Icons.shopping_bag_rounded,
                          size: 130,
                          iconSize: 60,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: FadeTransition(
                          opacity: _textFade,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: AppTextStyles.brandName,
                                      children: const [
                                        TextSpan(text: 'HumZain '),
                                        TextSpan(
                                          text: 'Traders',
                                          style: TextStyle(
                                            color: AppColors.accentGold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'PREMIUM SHOPPING EXPERIENCE',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.tagline,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 56),
                      FadeTransition(
                        opacity: _loaderFade,
                        child: const _PremiumLoader(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumLoader extends StatefulWidget {
  const _PremiumLoader();

  @override
  State<_PremiumLoader> createState() => _PremiumLoaderState();
}

class _PremiumLoaderState extends State<_PremiumLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: RotationTransition(
        turns: _controller,
        child: CustomPaint(painter: _LoaderPainter()),
      ),
    );
  }
}

/// Custom painter that draws a gold gradient arc for the loading
/// indicator, avoiding the plain default [CircularProgressIndicator]
/// look in favor of a more premium sweep effect.
class _LoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          AppColors.accentGold.withOpacity(0.0),
          AppColors.accentGold,
        ],
      ).createShader(
        Rect.fromCircle(
          center: size.center(Offset.zero),
          radius: size.width / 2,
        ),
      );

    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      0,
      4.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
