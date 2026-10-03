import 'package:flutter/material.dart';

/// Centralized color palette for HamZain Traders.
///
/// Keeping all brand colors in one place makes the app easy to theme
/// consistently and update in the future without hunting through
/// individual widgets.
///
/// Note: this file merges what were previously two separate,
/// conflicting `AppColors` definitions (`theme/app_colors.dart` and
/// `core/constants/app_colors.dart`). `surface` and `primarySoft` were
/// defined as `null`-returning getters in one copy; they've been
/// restored to their real values here so every screen renders the
/// intended colors.
class AppColors {
  AppColors._();

  /// Primary brand color - used as the background for Splash & Onboarding.
  static const Color primary = Color(0xFF243C94);

  /// A deeper shade of the primary color, used for gradients and depth
  /// so a flat background feels richer and more premium.
  static const Color primaryDark = Color(0xFF162663);

  /// A lighter shade of the primary color, used for gradients.
  static const Color primaryLight = Color(0xFF2E4BB8);

  /// Elegant gold accent - communicates a "premium / luxury" feel and
  /// is used sparingly for highlights, icons and the CTA button.
  static const Color accentGold = Color(0xFFE7B75F);

  /// Soft gold used for subtle glows, gradients and secondary highlights.
  static const Color accentGoldSoft = Color(0xFFF3D9A4);

  /// Pure white, used for primary typography on the dark background.
  static const Color white = Color(0xFFFFFFFF);

  /// Muted white used for secondary / descriptive text (70% opacity).
  static const Color whiteMuted = Color(0xB3FFFFFF);

  /// Faint white used for decorative dividers & inactive indicators (20%).
  static const Color whiteFaint = Color(0x33FFFFFF);

  /// Background fill used for glassmorphism-style icon containers (10%).
  static const Color glassFill = Color(0x1AFFFFFF);

  /// Border color used for glassmorphism-style containers (25%).
  static const Color glassBorder = Color(0x40FFFFFF);

  /// Default light surface / scaffold background color used across
  /// the main app screens (orders, profile, settings, etc.).
  static const Color surface = Colors.white;

  /// Soft primary tint used for subtle backgrounds and icon containers
  /// across the main app screens.
  static const Color primarySoft = Color(0xFFEFF1FA);

  // ---------------------------------------------------------------------
  // Premium blue-dominant redesign palette (Home screen onward).
  //
  // The redesign brief calls for every post-auth screen to read as
  // roughly 70-80% blue / 20-30% white, with white reserved for cards,
  // text and contrast elements. These tokens back that system without
  // touching the values above (which the untouched Splash/Onboarding/
  // Auth screens and the Bottom Nav already depend on).
  // ---------------------------------------------------------------------

  /// Deepest tone in the premium background gradient (top of screen).
  static const Color bgDeep = Color(0xFF101C4D);

  /// Mid tone in the premium background gradient.
  static const Color bgMid = Color(0xFF1E2F82);

  /// Lightest tone in the premium background gradient (bottom of screen).
  static const Color bgSoft = Color(0xFF2E4BB8);

  /// Cyan-leaning highlight used sparingly for glows and accents on the
  /// blue-dominant screens, layered alongside [accentGold].
  static const Color accentCyan = Color(0xFF5AD1E6);

  /// Frosted glass fill for cards/panels that sit on the blue gradient.
  static const Color glassOnBlueFill = Color(0x1FFFFFFF);

  /// Frosted glass border for cards/panels that sit on the blue gradient.
  static const Color glassOnBlueBorder = Color(0x33FFFFFF);
}
