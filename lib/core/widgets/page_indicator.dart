import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// A premium animated page indicator: the active dot smoothly expands
/// into a pill shape filled with a gold gradient, while inactive dots
/// remain small faint circles.
class PremiumPageIndicator extends StatelessWidget {
  const PremiumPageIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 26 : 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: isActive
                ? const LinearGradient(
                    colors: [AppColors.accentGoldSoft, AppColors.accentGold],
                  )
                : null,
            color: isActive ? null : AppColors.whiteFaint,
          ),
        );
      }),
    );
  }
}
