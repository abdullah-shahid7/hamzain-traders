import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/brand.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/screens/cart/cart_screen.dart';
import 'package:hamzain_traders/services/brand_service.dart';
import 'package:hamzain_traders/services/cart_service.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/widgets/app_drawer.dart';
import 'package:hamzain_traders/widgets/brand_card.dart';
import 'package:hamzain_traders/widgets/premium_app_bar.dart';
import 'package:hamzain_traders/widgets/shimmer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final BrandService _brandService = BrandService();
  final CartService _cartService = CartService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<List<Brand>> _brandsFuture;
  late final AnimationController _controller;
  String? _userName;
  UserModel? _currentUser;
  int _cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _brandsFuture = _loadBrands();
    _loadCurrentUser();
  }

  // ---- Unchanged data/business logic below ----

  Future<List<Brand>> _loadBrands() async {
    final brands = await _brandService.fetchBrands();
    if (mounted) {
      _controller.forward(from: 0);
    }
    return brands;
  }

  Future<void> _loadCurrentUser() async {
    final UserModel? user = await SessionService.instance.getUser();
    if (mounted) {
      setState(() {
        _userName = user?.fullName;
        _currentUser = user;
      });
    }
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final user = _currentUser;
    if (user == null || user.id.isEmpty) return;
    try {
      final cart = await _cartService.getCart(userId: user.id);
      if (mounted) setState(() => _cartItemCount = cart.totalQuantity);
    } catch (_) {
      // Cart badge is a convenience only — a failed fetch here
      // shouldn't disrupt the Home screen.
    }
  }

  Future<void> _openCart() async {
    await Navigator.push(
      context,
      PremiumPageRoute(page: const CartScreen()),
    );
    _loadCartCount();
  }

  Future<void> _onRefresh() async {
    final future = _loadBrands();
    setState(() {
      _brandsFuture = future;
    });
    await future;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _staggered(int index, int total) {
    final safeTotal = total.clamp(1, 20);
    final start = (index / safeTotal) * 0.5;
    final end = (start + 0.5).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
  }

  // ---- UI below ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.bgDeep,
      drawer: const AppDrawer(),
      appBar: PremiumAppBar(
        userName: _userName,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onCartTap: _openCart,
        cartItemCount: _cartItemCount,
      ),
      body: PremiumScreenBackground(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: Colors.white,
          onRefresh: _onRefresh,
          child: FutureBuilder<List<Brand>>(
            future: _brandsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }
              if (snapshot.hasError) {
                return _buildErrorState();
              }
              final brands = snapshot.data ?? const <Brand>[];
              if (brands.isEmpty) {
                return _buildEmptyState();
              }
              return _buildContent(brands);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Brand> brands) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: _WelcomeBanner(userName: _userName, brandCount: brands.length),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.accentGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Featured Brands',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${brands.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.70,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => BrandCard(
                brand: brands[index],
                entranceAnimation: _staggered(index, brands.length),
              ),
              childCount: brands.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: 0.70,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.18),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.primary,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Unable to load brands',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 26),
                    ElevatedButton(
                      onPressed: _onRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'No brands available yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Premium welcome hero banner shown at the top of the Home Screen,
/// above the Featured Brands grid. Purely presentational — reads
/// [userName] that HomeScreen already loads via SessionService and
/// simply displays a friendly greeting and a floating brand icon.
class _WelcomeBanner extends StatelessWidget {
  final String? userName;
  final int brandCount;

  const _WelcomeBanner({required this.userName, required this.brandCount});

  @override
  Widget build(BuildContext context) {
    final greetingName =
        (userName != null && userName!.trim().isNotEmpty) ? userName!.trim().split(' ').first : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgMid, AppColors.bgSoft],
          ),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.glassOnBlueBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.35),
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -18,
              right: -18,
              child: IgnorePointer(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentGold.withOpacity(0.16),
                  ),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greetingName != null ? 'Hi, $greetingName 👋' : 'Welcome 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        brandCount > 0
                            ? 'Explore $brandCount premium brands, curated for you'
                            : 'Discover premium products, curated for you',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.accentGold.withOpacity(0.7), width: 1.4),
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
