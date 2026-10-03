import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';

/// Reusable premium text field for the HumZain Traders auth flow.
///
/// A frosted-glass style input, consistent with the primary blue +
/// gold brand identity already used on [RegisterScreen], shared by
/// the Sign Up and Login screens.
class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.prefixText,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final String label;
  final IconData icon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final String? prefixText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscure = widget.obscureText;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) => setState(() => _focused = hasFocus),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText ? _obscure : false,
        keyboardType: widget.keyboardType,
        maxLength: widget.maxLength,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: AppColors.accentGold,
        decoration: InputDecoration(
          counterText: '',
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _focused
                ? AppColors.accentGold
                : AppColors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixText: widget.prefixText,
          prefixStyle: const TextStyle(
            color: AppColors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            widget.icon,
            color: _focused
                ? AppColors.accentGold
                : AppColors.white.withOpacity(0.7),
            size: 20,
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          filled: true,
          fillColor: AppColors.white.withOpacity(0.08),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.white.withOpacity(0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.white.withOpacity(0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.accentGold, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.6),
          ),
          errorStyle: const TextStyle(
            color: Color(0xFFFFB4B4),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
