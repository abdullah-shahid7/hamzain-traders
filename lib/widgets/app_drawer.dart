import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/screens/about/about_us_screen.dart';
import 'package:hamzain_traders/screens/address/saved_address_screen.dart';
import 'package:hamzain_traders/screens/auth/login_screen.dart';
import 'package:hamzain_traders/screens/auth/register_screen.dart';
import 'package:hamzain_traders/screens/auth/signup_screen.dart';
import 'package:hamzain_traders/screens/legal/privacy_policy_screen.dart';
import 'package:hamzain_traders/screens/orders/my_orders_screen.dart';
import 'package:hamzain_traders/screens/orders/order_history_screen.dart';
import 'package:hamzain_traders/screens/payments/payment_methods_screen.dart';
import 'package:hamzain_traders/screens/profile/my_profile_screen.dart';
import 'package:hamzain_traders/screens/settings/settings_screen.dart';
import 'package:hamzain_traders/screens/support/help_support_screen.dart';

/// Premium blue-dominant Drawer (UI-only redesign — every navigation
/// destination, the logout flow, and all existing behavior below are
/// unchanged from the original AppDrawer).
class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _items = [
    (icon: Icons.person_outline_rounded, label: 'My Profile'),
    (icon: Icons.shopping_bag_outlined, label: 'My Orders'),
    (icon: Icons.history_rounded, label: 'Order History'),
    (icon: Icons.location_on_outlined, label: 'Saved Address'),
    (icon: Icons.credit_card_rounded, label: 'Payment Methods'),
    (icon: Icons.support_agent_rounded, label: 'Help and Support'),
    (icon: Icons.info_outline_rounded, label: 'About Us'),
    (icon: Icons.privacy_tip_outlined, label: 'Privacy Policy'),
    (icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _staggered(int index) {
    final start = (index / _items.length) * 0.6;
    final end = (start + 0.45).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  Widget _destinationFor(String label) {
    switch (label) {
      case 'My Profile':
        return const MyProfileScreen();
      case 'My Orders':
        return const MyOrdersScreen();
      case 'Order History':
        return const OrderHistoryScreen();
      case 'Saved Address':
        return const SavedAddressScreen();
      case 'Payment Methods':
        return const PaymentMethodsScreen();
      case 'Help and Support':
        return const HelpSupportScreen();
      case 'About Us':
        return const AboutUsScreen();
      case 'Privacy Policy':
        return const PrivacyPolicyScreen();
      default:
        return const SettingsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.bgDeep,
      width: MediaQuery.of(context).size.width * 0.82,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgDeep, AppColors.bgMid, AppColors.bgSoft],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -70,
              child: IgnorePointer(
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentCyan.withOpacity(0.08),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const _DrawerHeader(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return AnimatedBuilder(
                          animation: _staggered(index),
                          builder: (context, child) {
                            final v = _staggered(index).value.clamp(0.0, 1.0);
                            return Opacity(
                              opacity: v,
                              child: Transform.translate(
                                offset: Offset(-24 * (1 - v), 0),
                                child: child,
                              ),
                            );
                          },
                          child: _DrawerItem(
                            icon: item.icon,
                            label: item.label,
                            onTap: () =>
                                _navigate(context, _destinationFor(item.label)),
                          ),
                        );
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(height: 1, color: AppColors.glassOnBlueBorder),
                  ),
                  const SizedBox(height: 16),
                  _LogoutButton(onTap: () => _handleLogout(context)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.of(context).pop(); // close drawer first
    Navigator.of(context).push(PremiumPageRoute(page: page));
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SessionService.instance.clearSession();
    if (!context.mounted) return;
    // Uses the ROOT navigator (not the current tab's own nested one —
    // see MainShell) so logout actually leaves the whole tabbed shell
    // behind and lands on RegisterScreen, rather than just resetting
    // the current tab's local navigation stack.
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pushAndRemoveUntil(
      PremiumPageRoute(
        page: RegisterScreen(
          onLoginPressed: () => navigator.push(
            PremiumPageRoute(page: const LoginScreen()),
          ),
          onSignUpPressed: () => navigator.push(
            PremiumPageRoute(page: const SignUpScreen()),
          ),
        ),
      ),
      (route) => false,
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: SessionService.instance.getUser(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: AppColors.accentGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName.isNotEmpty == true
                          ? user!.fullName
                          : 'Welcome',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email.isNotEmpty == true
                          ? user!.email
                          : 'Sign in to see your account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DrawerItem extends StatefulWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_DrawerItem> createState() => _DrawerItemState();
}

class _DrawerItemState extends State<_DrawerItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: _pressed
                ? AppColors.glassOnBlueFill
                : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.label,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.5), size: 20),
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

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.primary, size: 19),
              SizedBox(width: 10),
              Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14.5,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
