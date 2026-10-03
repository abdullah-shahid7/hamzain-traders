import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_text_styles.dart';
import 'package:hamzain_traders/core/widgets/floating_icon_container.dart';
import 'package:hamzain_traders/core/widgets/orbiting_icon.dart';
import 'package:hamzain_traders/screens/onboarding/data/onboarding_data.dart';

/// Renders a single onboarding page: a floating hero icon (with small
/// orbiting accent icons), an animated headline and description.
///
/// [isActive] drives the entrance animation so text and icons animate
/// in only when the page becomes the current page in the [PageView].
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    super.key,
    required this.item,
    required this.isActive,
  });

  final OnboardingItem item;
  final bool isActive;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconScale =
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    if (widget.isActive) _controller.forward();
  }

  @override
  void didUpdateWidget(covariant OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    // LayoutBuilder + a scrollable, min-height-constrained column lets
    // the content stay perfectly centered on tall screens while
    // gracefully scrolling instead of overflowing on short ones
    // (small phones, split-screen, landscape, large text scale, etc).
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 32,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _iconScale,
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (int i = 0; i < item.secondaryIcons.length; i++)
                          OrbitingIcon(
                            icon: item.secondaryIcons[i],
                            radius: 85,
                            angleOffset: i * 3.4,
                          ),
                        FloatingIconContainer(
                          icon: item.icon,
                          size: 130,
                          iconSize: 58,
                          floatRange: 8,
                          duration: const Duration(seconds: 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      children: [
                        Text(
                          item.headline,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.onboardingHeadline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.onboardingBody,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
