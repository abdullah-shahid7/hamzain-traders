import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';

/// A single destination in [FloatingBottomNav].
class NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Premium floating pill-shaped bottom navigation bar: solid primary
/// blue, white icons/labels, a visible gap from every screen edge,
/// elevation/shadow, and a smooth animated selection indicator that
/// "floats" the active item slightly upward.
///
/// This is a purely presentational, stateless-from-the-outside
/// widget — [currentIndex] and [onTap] are owned by the parent
/// (MainShell), matching a standard BottomNavigationBar contract so
/// it's simple to wire up.
class FloatingBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavDestination> destinations;

  const FloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 16),
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final selected = index == currentIndex;
            return Expanded(
              child: _NavItem(
                destination: destinations[index],
                selected: selected,
                onTap: () => onTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(34),
        onTap: onTap,
        child: SizedBox(
          // A fixed, explicitly-budgeted height (rather than
          // "vertical padding + intrinsic content size" fighting the
          // outer 76px container) is what actually guarantees no
          // overflow here: icon circle (~38px) + spacing (3px) + text
          // (~15px) + minimal 6px top/bottom padding comfortably fits
          // 76, with margin for font-metric variance across devices.
          height: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // The "floating" effect: the active icon lifts up on a
                // small pill behind it, and settles with an overshoot
                // curve for a lively-but-not-cheap feel.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: selected ? 1 : 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, t, child) {
                    return Transform.translate(
                      offset: Offset(0, -3 * t),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16 * t),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          selected ? destination.activeIcon : destination.icon,
                          color: Colors.white,
                          size: 22 + (2 * t),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    color: Colors.white.withOpacity(selected ? 1 : 0.72),
                    fontSize: selected ? 11 : 10.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    height: 1.0,
                  ),
                  child: Text(
                    destination.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
