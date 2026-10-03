import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/constants/app_text_styles.dart';
import 'package:hamzain_traders/core/widgets/animated_gradient_background.dart';
import 'package:hamzain_traders/core/widgets/auth_action_button.dart';
import 'package:hamzain_traders/core/widgets/floating_icon_container.dart';

/// The Register Screen — a welcome / authentication-selection screen.
///
/// This is NOT the Login or Sign Up screen itself. It presents the
/// HumZain Traders brand identity and lets the user choose whether to
/// log in to an existing account or create a new one.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    this.onLoginPressed,
    this.onSignUpPressed,
  });

  /// Called when the user taps "Login". Defaults to a graceful
  /// in-app notice if no handler is supplied by the caller.
  final VoidCallback? onLoginPressed;

  /// Called when the user taps "Sign Up". Defaults to a graceful
  /// in-app notice if no handler is supplied by the caller.
  final VoidCallback? onSignUpPressed;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _iconFade;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _buttonsFade;
  late final Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _iconFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    _headlineFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOut),
    );
    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.6, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic),
    ));

    _buttonsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
    );
    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (widget.onLoginPressed != null) {
      widget.onLoginPressed!();
      return;
    }
    _showComingSoon(context, 'Login');
  }

  void _handleSignUp() {
    if (widget.onSignUpPressed != null) {
      widget.onSignUpPressed!();
      return;
    }
    _showComingSoon(context, 'Sign Up');
  }

  void _showComingSoon(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryDark,
        content: Text(
          '$action screen coming soon',
          style: AppTextStyles.skipLabel.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const AnimatedGradientBackground(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 4),
                    FadeTransition(
                      opacity: _iconFade,
                      child: const FloatingIconContainer(
                        icon: Icons.shopping_bag_rounded,
                        size: 120,
                        iconSize: 54,
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeTransition(
                      opacity: _headlineFade,
                      child: SlideTransition(
                        position: _headlineSlide,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.brandName,
                              children: const [
                                TextSpan(text: 'Welcome to\n'),
                                TextSpan(text: 'HumZain '),
                                TextSpan(
                                  text: 'Traders',
                                  style: TextStyle(
                                    color: AppColors.accentGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeTransition(
                      opacity: _subtitleFade,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Text(
                          'Discover premium products with a fast, secure, '
                          'and seamless shopping experience.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.welcomeSubtitle,
                        ),
                      ),
                    ),
                    const Spacer(flex: 5),
                    FadeTransition(
                      opacity: _buttonsFade,
                      child: SlideTransition(
                        position: _buttonsSlide,
                        child: Column(
                          children: [
                            AuthActionButton(
                              label: 'Login',
                              icon: Icons.arrow_forward_rounded,
                              variant: AuthButtonVariant.primary,
                              onPressed: _handleLogin,
                            ),
                            const SizedBox(height: 16),
                            AuthActionButton(
                              label: 'Sign Up',
                              variant: AuthButtonVariant.secondary,
                              onPressed: _handleSignUp,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
