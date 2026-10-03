import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/core/widgets/animated_gradient_background.dart';
import 'package:hamzain_traders/core/widgets/auth_action_button.dart';
import 'package:hamzain_traders/core/widgets/floating_icon_container.dart';
import 'package:hamzain_traders/widgets/auth_bottom_link.dart';
import 'package:hamzain_traders/widgets/auth_text_field.dart';
import 'package:hamzain_traders/screens/auth/login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  static const _insertSignUpUrl =
      'https://devtechnical.com/Abdullah.Shahid/HamZainTraders/insertsignup.php';

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entranceController;
  late final Animation<double> _iconFade;
  late final Animation<double> _formFade;
  late final Animation<Offset> _formSlide;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _iconFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _formFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Please enter your full name';
    if (name.length < 3) return 'Name must be at least 3 characters';
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(name)) {
      return 'Name can only contain letters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return 'Please enter your phone number';
    if (phone.length != 10) return 'Enter a valid 10-digit number';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) return 'Digits only, please';
    if (!phone.startsWith('3')) {
      return 'Enter a valid Pakistani mobile number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Please enter a password';
    if (password.length < 6) return 'At least 6 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add at least one uppercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) return 'Add at least one number';
    return null;
  }

  Future<void> _handleSignUp() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final phoneNumber = '+92${_phoneController.text.trim()}';
    final password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse(_insertSignUpUrl),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'full_name': fullName,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
        },
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Map<String, dynamic>? decoded;
        try {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {
          decoded = null;
        }

        // Backend responses vary; treat a 200 with no explicit failure
        // flag as success so this keeps working regardless of exact
        // response shape.
        final failed = decoded != null &&
            (decoded['status'] == false ||
                decoded['status'] == 'error' ||
                decoded['success'] == false);

        if (!failed) {
          _showSnack('Account created! Please log in.', isError: false);
          await Future.delayed(const Duration(milliseconds: 700));
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            PremiumPageRoute(page: const LoginScreen()),
          );
        } else {
          final message = decoded['message']?.toString() ??
              'Could not create your account. Please try again.';
          _showSnack(message, isError: true);
        }
      } else {
        _showSnack(
          'Server error (${response.statusCode}). Please try again.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(
        'Network error. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFB3261E) : AppColors.primaryDark,
        content: Text(
          message,
          style: const TextStyle(
              color: AppColors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: true,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedGradientBackground(),
            SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FadeTransition(
                        opacity: _iconFade,
                        child: const FloatingIconContainer(
                          icon: Icons.person_add_alt_1_rounded,
                          size: 88,
                          iconSize: 38,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Create Your Account',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Join HumZain Traders for a premium shopping experience.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.75),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Column(
                            children: [
                              AuthTextField(
                                label: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                controller: _fullNameController,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                validator: _validateFullName,
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                label: 'Phone Number',
                                icon: Icons.phone_iphone_rounded,
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                prefixText: '+92  ',
                                maxLength: 10,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                label: 'Email',
                                icon: Icons.alternate_email_rounded,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 18),
                              AuthTextField(
                                label: 'Password',
                                icon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                validator: _validatePassword,
                                onFieldSubmitted: (_) => _handleSignUp(),
                              ),
                              const SizedBox(height: 30),
                              AuthActionButton(
                                label: _isSubmitting
                                    ? 'Creating Account...'
                                    : 'Sign Up',
                                icon: _isSubmitting
                                    ? null
                                    : Icons.arrow_forward_rounded,
                                variant: AuthButtonVariant.primary,
                                onPressed:
                                    _isSubmitting ? () {} : _handleSignUp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: AuthBottomLink(
                          leadingText: 'Already have an account? ',
                          actionText: 'Login',
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              PremiumPageRoute(page: const LoginScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: AppColors.primary.withOpacity(0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGold,
                      ),
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
