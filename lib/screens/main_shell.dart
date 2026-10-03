import 'package:flutter/material.dart';

import 'package:hamzain_traders/screens/cart/cart_screen.dart';
import 'package:hamzain_traders/screens/home/home_screen.dart';
import 'package:hamzain_traders/screens/products/all_products_screen.dart';
import 'package:hamzain_traders/screens/profile/my_profile_screen.dart';
import 'package:hamzain_traders/widgets/floating_bottom_nav.dart';

/// Notifies [MainShell] whenever the active tab's own navigation
/// stack changes, so the floating bottom nav can be hidden the
/// instant something is pushed on top of a tab root (Checkout, Order
/// Success, Receipt, Order Details, Product Details, etc. should
/// never show it) and shown again the instant that tab returns to
/// its root screen. A plain [NavigatorObserver] is the correct tool
/// for this — Scaffold's `bottomNavigationBar` is structurally
/// separate from whatever is pushed inside `body`, so without this,
/// pushing a screen in a tab's nested Navigator does nothing to hide
/// chrome that lives on the outer Scaffold.
class _TabRouteObserver extends NavigatorObserver {
  final VoidCallback onStackChanged;
  _TabRouteObserver(this.onStackChanged);

  @override
  void didPush(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didPop(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didRemove(Route route, Route? previousRoute) => onStackChanged();

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => onStackChanged();
}

/// Hosts the app's four primary sections (Home, Products, Cart,
/// Profile) behind the floating bottom navigation bar.
///
/// Each tab gets its own nested [Navigator] so pushing a screen
/// (e.g. Product Details from the Products tab) doesn't disturb the
/// other tabs' navigation state, and switching tabs doesn't lose
/// whatever was pushed on a tab that isn't currently visible —
/// standard "Instagram-style" tab navigation. [IndexedStack] keeps
/// every tab's widget subtree alive (not rebuilt) across switches.
///
/// The floating bottom nav is shown ONLY when the active tab is at
/// its own root (Home/Products/Cart/Profile with nothing pushed on
/// top) and hidden the moment anything is pushed on top of it —
/// Product Details, Add/Select Address, Checkout, Order Success,
/// Receipt, Order Details all correctly hide it, matching standard
/// e-commerce UX where the floating nav is for jumping between
/// primary sections, not a persistent chrome on every screen.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _showBottomNav = true;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    4,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<_TabRouteObserver> _observers = List.generate(
    4,
    (_) => _TabRouteObserver(_refreshBottomNavVisibility),
  );

  static const _destinations = [
    NavDestination(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    NavDestination(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Products',
    ),
    NavDestination(
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Cart',
    ),
    NavDestination(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  static const List<WidgetBuilder> _tabBuilders = [
    _homeBuilder,
    _productsBuilder,
    _cartBuilder,
    _profileBuilder,
  ];

  static Widget _homeBuilder(BuildContext context) => const HomeScreen();
  static Widget _productsBuilder(BuildContext context) => const AllProductsScreen();
  static Widget _cartBuilder(BuildContext context) => const CartScreen();
  static Widget _profileBuilder(BuildContext context) => const MyProfileScreen();

  void _refreshBottomNavVisibility() {
    // Deferred a frame: NavigatorObserver callbacks can fire mid-build
    // (e.g. during the very first didPush for the initial route), and
    // calling setState synchronously in that window throws.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canPop = _navigatorKeys[_currentIndex].currentState?.canPop() ?? false;
      if (_showBottomNav == !canPop) return;
      setState(() => _showBottomNav = !canPop);
    });
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) {
      // Tapping the already-active tab again pops that tab's stack
      // back to its root — the conventional behaviour for this kind
      // of navigation.
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _currentIndex = index;
      _showBottomNav = !(_navigatorKeys[index].currentState?.canPop() ?? false);
    });
  }

  Future<bool> _onWillPop() async {
    // Let the CURRENT tab's own navigator handle back navigation
    // first (e.g. popping Product Details back to the product grid).
    final currentNavigator = _navigatorKeys[_currentIndex].currentState;
    if (currentNavigator != null && currentNavigator.canPop()) {
      currentNavigator.pop();
      return false;
    }
    // Already at a tab's root: if not already on Home, jump to Home
    // instead of exiting the app, matching common e-commerce app
    // behaviour.
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
        _showBottomNav = !(_navigatorKeys[0].currentState?.canPop() ?? false);
      });
      return false;
    }
    // At Home's root with nothing to pop — allow the app to exit.
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          // Nothing left to handle internally — let the platform's
          // normal "exit app" behaviour proceed.
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(4, (index) {
            return Navigator(
              key: _navigatorKeys[index],
              observers: [_observers[index]],
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder: _tabBuilders[index],
                  settings: settings,
                );
              },
            );
          }),
        ),
        bottomNavigationBar: _showBottomNav
            ? FloatingBottomNav(
                currentIndex: _currentIndex,
                onTap: _onNavTap,
                destinations: _destinations,
              )
            : null,
      ),
    );
  }
}
