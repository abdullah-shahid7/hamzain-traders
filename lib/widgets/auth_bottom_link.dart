import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';

/// The small bottom prompt shown on the Sign Up screen
/// ("Already have an account? Login") and the Login screen
/// ("Don't have an account? Sign Up"). Only [actionText] is tappable.
class AuthBottomLink extends StatelessWidget {
  const AuthBottomLink({
    super.key,
    required this.leadingText,
    required this.actionText,
    required this.onTap,
  });

  final String leadingText;
  final String actionText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leadingText,
          style: TextStyle(
            color: AppColors.white.withOpacity(0.75),
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              actionText,
              style: const TextStyle(
                color: AppColors.accentGold,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.accentGold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
