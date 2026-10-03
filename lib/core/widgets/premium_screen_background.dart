import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// Shared blue-dominant premium background used by every screen from
/// the Home Screen onward (per the redesign brief: ~70-80% blue,
/// 20-30% white, white reserved for cards/text/contrast).
///
/// This is purely a presentational wrapper — it changes nothing about
/// navigation, state or business logic. Screens keep their existing
/// [Scaffold]/[AppBar]/body content; they simply wrap their `body` in
/// this widget instead of relying on a plain white
/// `backgroundColor: AppColors.surface`.
///
/// A couple of soft, static, decorative blur circles are layered in
/// for depth ("floating elements") without any animation controller
/// overhead — cheap, subtle, and never intercepts touches.
class PremiumScreenBackground extends StatelessWidget {
  final Widget child;

  /// When false, renders a flatter/lighter version of the gradient —
  /// useful for screens with dense white content (forms, long lists)
  /// where a very dark backdrop would fight for attention. Still
  /// clearly blue-dominant.
  final bool rich;

  const PremiumScreenBackground({
    super.key,
    required this.child,
    this.rich = true,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: rich
              ? const [AppColors.bgDeep, AppColors.bgMid, AppColors.bgSoft]
              : const [AppColors.primaryDark, AppColors.primary],
          stops: rich ? const [0.0, 0.45, 1.0] : const [0.0, 1.0],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -70,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentCyan.withOpacity(0.10),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -90,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGold.withOpacity(0.07),
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A frosted "glass" card for content that sits on top of
/// [PremiumScreenBackground] — used where a screen wants a section to
/// read as part of the blue surface rather than a solid white card.
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.glassOnBlueFill,
        borderRadius: borderRadius,
        border: Border.all(color: AppColors.glassOnBlueBorder, width: 1),
      ),
      child: child,
    );
  }
}
