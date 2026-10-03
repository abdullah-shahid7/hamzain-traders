import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// Centralized typography for HumZain Traders.
///
/// Playfair Display (an elegant serif) is used for display / brand
/// text to communicate luxury, while Poppins (a clean geometric
/// sans-serif) is used for readable body & UI text.
class AppTextStyles {
  AppTextStyles._();

  /// Luxury serif style used for the app name on the Splash Screen
  /// and the Register Screen headline.
  static TextStyle brandName = GoogleFonts.playfairDisplay(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    letterSpacing: 1.0,
    height: 1.2,
  );

  /// Small tagline shown underneath the brand name.
  static TextStyle tagline = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.whiteMuted,
    letterSpacing: 3,
  );

  /// Large headline used on onboarding pages.
  static TextStyle onboardingHeadline = GoogleFonts.playfairDisplay(
    fontSize: 27,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
    height: 1.3,
  );

  /// Body / description text used on onboarding pages.
  static TextStyle onboardingBody = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.whiteMuted,
    height: 1.6,
  );

  /// Style used for the primary CTA button label.
  static TextStyle buttonLabel = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryDark,
    letterSpacing: 0.4,
  );

  /// Style used for the "Skip" text button.
  static TextStyle skipLabel = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.whiteMuted,
    letterSpacing: 0.3,
  );

  /// Subtitle used on the Register / auth-selection screen, shown
  /// beneath the "Welcome to HumZain Traders" headline.
  static TextStyle welcomeSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.whiteMuted,
    height: 1.7,
    letterSpacing: 0.2,
  );
}
