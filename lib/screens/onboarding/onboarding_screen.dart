import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/constants/app_durations.dart';
import 'package:hamzain_traders/core/constants/app_text_styles.dart';
import 'package:hamzain_traders/core/widgets/animated_gradient_background.dart';
import 'package:hamzain_traders/core/widgets/page_indicator.dart';
import 'package:hamzain_traders/core/widgets/premium_button.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/screens/auth/login_screen.dart';
import 'package:hamzain_traders/screens/auth/register_screen.dart';
import 'package:hamzain_traders/screens/auth/signup_screen.dart';
import 'package:hamzain_traders/screens/onboarding/data/onboarding_data.dart';
import 'package:hamzain_traders/screens/onboarding/widgets/onboarding_page.dart';

/// The Onboarding flow: three premium, animated pages that introduce
/// HumZain Traders to a first-time user, followed by a "Get Started"
/// call to action that transitions into the Register Screen.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  bool get _isLastPage => _currentIndex == onboardingItems.length - 1;

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _goToNextPage() {
    if (_isLastPage) {
      _navigateToRegister();
    } else {
      _pageController.nextPage(
        duration: AppDurations.pageTransition,
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    _pageController.animateToPage(
      onboardingItems.length - 1,
      duration: AppDurations.pageTransition,
      curve: Curves.easeOutCubic,
    );
  }

  void _navigateToRegister() {
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppDurations.pageTransition,
        pageBuilder: (context, animation, secondaryAnimation) =>
            RegisterScreen(
          onLoginPressed: () => navigator.push(
            PremiumPageRoute(page: const LoginScreen()),
          ),
          onSignUpPressed: () => navigator.push(
            PremiumPageRoute(page: const SignUpScreen()),
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeInOut);
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedGradientBackground()),
          SafeArea(
            child: Column(
              children: [
                // Top bar with a Skip button, hidden on the last page.
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedOpacity(
                        duration: AppDurations.microInteraction,
                        opacity: _isLastPage ? 0.0 : 1.0,
                        child: IgnorePointer(
                          ignoring: _isLastPage,
                          child: TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Skip',
                              style: AppTextStyles.skipLabel,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: onboardingItems.length,
                    itemBuilder: (context, index) {
                      return OnboardingPage(
                        item: onboardingItems[index],
                        isActive: index == _currentIndex,
                      );
                    },
                  ),
                ),
                PremiumPageIndicator(
                  count: onboardingItems.length,
                  currentIndex: _currentIndex,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
                  child: AnimatedSwitcher(
                    duration: AppDurations.pageTransition,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: PremiumButton(
                      key: ValueKey(_isLastPage),
                      label: _isLastPage ? 'Get Started' : 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _goToNextPage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
