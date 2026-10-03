import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hamzain_traders/screens/main_shell.dart';
import 'package:http/http.dart' as http;

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/core/widgets/animated_gradient_background.dart';
import 'package:hamzain_traders/core/widgets/auth_action_button.dart';
import 'package:hamzain_traders/core/widgets/floating_icon_container.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/widgets/auth_bottom_link.dart';
import 'package:hamzain_traders/widgets/auth_text_field.dart';
import 'package:hamzain_traders/screens/auth/signup_screen.dart';

/// Successful login lands on [MainShell] (Home/Products/Cart/Profile
/// behind the floating bottom nav) via a full pushAndRemoveUntil, so
/// the auth flow can't be reached again with the system back button.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  static const _getLoginUrl =
      'https://devtechnical.com/Abdullah.Shahid/HamZainTraders/getlogin.php';

  final _formKey = GlobalKey<FormState>();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Please enter your email';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Please enter your password';
    return null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      final response = await http
          .get(Uri.parse(_getLoginUrl))
          .timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        // The API may return either a raw list of user rows, or an
        // object wrapping the list (e.g. {"users": [...]})  — handle
        // both shapes without needing a separate parsing layer.
        final List<dynamic> users = decoded is List
            ? decoded
            : (decoded is Map && decoded['data'] is List)
                ? decoded['data'] as List
                : (decoded is Map && decoded['users'] is List)
                    ? decoded['users'] as List
                    : const [];

        final match = users.cast<Map<String, dynamic>>().firstWhere(
              (user) =>
                  (user['email']?.toString().trim().toLowerCase() ?? '') ==
                      email.toLowerCase() &&
                  (user['password']?.toString() ?? '') == password,
              orElse: () => const {},
            );

        if (match.isNotEmpty) {
          final user = UserModel.fromJson(match);

          if (user.id.isEmpty) {
            // The matched user row didn't carry a usable id — saving
            // this session would silently break every screen that
            // needs user_id (cart, addresses, orders) later. Fail
            // loudly here instead so it's obvious immediately.
            _showSnack(
              'Logged in, but your account ID could not be verified. '
              'Please try again or contact support.',
              isError: true,
            );
            setState(() => _isSubmitting = false);
            return;
          }

          // Persist the logged-in user's session so the rest of the app
          // (drawer header, My Profile, etc.) can read it back later.
          await SessionService.instance.saveUser(user);

          _showSnack('Welcome back!', isError: false);
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            PremiumPageRoute(page: const MainShell()),
            (route) => false,
          );
        } else {
          _showSnack('Incorrect email or password.', isError: true);
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
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _iconFade,
                        child: const FloatingIconContainer(
                          icon: Icons.lock_outline_rounded,
                          size: 96,
                          iconSize: 42,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Log in to continue shopping with HumZain Traders.',
                        style: TextStyle(
                          color: AppColors.white.withOpacity(0.75),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      FadeTransition(
                        opacity: _formFade,
                        child: SlideTransition(
                          position: _formSlide,
                          child: Column(
                            children: [
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
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 30),
                              AuthActionButton(
                                label:
                                    _isSubmitting ? 'Logging In...' : 'Login',
                                icon: _isSubmitting
                                    ? null
                                    : Icons.arrow_forward_rounded,
                                variant: AuthButtonVariant.primary,
                                onPressed: _isSubmitting ? () {} : _handleLogin,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: AuthBottomLink(
                          leadingText: "Don't have an account? ",
                          actionText: 'Sign Up',
                          onTap: () {
                            Navigator.of(context).pushReplacement(
                              PremiumPageRoute(page: const SignUpScreen()),
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
