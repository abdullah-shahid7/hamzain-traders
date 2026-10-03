import 'package:flutter/material.dart';

/// Simple data model describing a single onboarding page.
class OnboardingItem {
  const OnboardingItem({
    required this.icon,
    required this.headline,
    required this.description,
    required this.secondaryIcons,
  });

  final IconData icon;
  final String headline;
  final String description;

  /// A small set of supporting icons shown floating/orbiting around
  /// the main icon for extra visual richness on each page.
  final List<IconData> secondaryIcons;
}

/// The three onboarding pages shown to a new HumZain Traders user.
final List<OnboardingItem> onboardingItems = [
  const OnboardingItem(
    icon: Icons.storefront_rounded,
    headline: 'Welcome to\nHumZain Traders',
    description: 'Step into a refined shopping experience crafted for you — '
        'curated products, elegant design, and effortless browsing in '
        'one premium marketplace.',
    secondaryIcons: [Icons.favorite_rounded, Icons.star_rounded],
  ),
  const OnboardingItem(
    icon: Icons.shopping_bag_rounded,
    headline: 'Discover Thousands\nof Products',
    description: 'Explore a vast collection across every category. Powerful '
        'search and smart recommendations help you find exactly what '
        'you love, faster.',
    secondaryIcons: [Icons.category_rounded, Icons.bolt_rounded],
  ),
  const OnboardingItem(
    icon: Icons.local_shipping_rounded,
    headline: 'Fast, Secure &\nReliable Shopping',
    description: 'Shop with total peace of mind. Bank-grade secure payments, '
        'real-time order tracking, and swift delivery — every single '
        'time.',
    secondaryIcons: [Icons.verified_user_rounded, Icons.shield_rounded],
  ),
];
