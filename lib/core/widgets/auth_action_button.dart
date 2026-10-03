import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/constants/app_durations.dart';
import 'package:hamzain_traders/core/constants/app_text_styles.dart';

/// Visual style of an [AuthActionButton].
///
/// [primary] is a solid gold-gradient button used for the main call
/// to action (e.g. "Login"). [secondary] is a subtle glass/outline
/// button used for the alternate action (e.g. "Sign Up").
enum AuthButtonVariant { primary, secondary }

/// A premium, animated authentication action button used on the
/// Register / auth-selection screen.
///
/// Provides a smooth press-scale micro-interaction, an animated
/// shadow/elevation shift, and a native ripple via [InkWell] for a
/// tactile, high-end feel on every tap.
class AuthActionButton extends StatefulWidget {
  const AuthActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AuthButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final AuthButtonVariant variant;
  final IconData? icon;

  @override
  State<AuthActionButton> createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  bool _isPressed = false;

  void _setPressed(bool pressed) => setState(() => _isPressed = pressed);

  bool get _isPrimary => widget.variant == AuthButtonVariant.primary;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        _isPrimary ? AppColors.primaryDark : AppColors.white;
    final Color rippleColor =
        (_isPrimary ? AppColors.primaryDark : AppColors.accentGold)
            .withOpacity(0.15);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: AppDurations.microInteraction,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: AppDurations.microInteraction,
          curve: Curves.easeOut,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: _isPrimary
                ? const LinearGradient(
                    colors: [AppColors.accentGoldSoft, AppColors.accentGold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _isPrimary ? null : AppColors.glassFill,
            border: _isPrimary
                ? null
                : Border.all(
                    color: AppColors.accentGold.withOpacity(0.55),
                    width: 1.4,
                  ),
            boxShadow: _isPrimary
                ? [
                    BoxShadow(
                      color: AppColors.accentGold
                          .withOpacity(_isPressed ? 0.22 : 0.4),
                      blurRadius: _isPressed ? 12 : 22,
                      offset: Offset(0, _isPressed ? 4 : 10),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              splashColor: rippleColor,
              highlightColor: Colors.transparent,
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.buttonLabel.copyWith(
                        color: textColor,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.icon, size: 18, color: textColor),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
