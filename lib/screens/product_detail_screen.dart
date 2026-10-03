import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/product.dart';
import 'package:hamzain_traders/models/product_image.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/screens/cart/cart_screen.dart';
import 'package:hamzain_traders/screens/main_shell.dart';
import 'package:hamzain_traders/services/api_service.dart';
import 'package:hamzain_traders/services/cart_service.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/widgets/shimmer_card.dart';

class _ProductDetailData {
  final Product product;
  final List<ProductImage> images;
  _ProductDetailData(this.product, this.images);
}

/// Single reusable product detail screen for all products. Receives
/// [productId], loads that product's full info plus every image
/// belonging to it (sorted by sort_order), and presents them in a
/// swipeable, ultra-premium gallery with a blue-dominant design
/// language, layered glass surfaces and smooth, staggered
/// entrance/micro-interaction animations.
///
/// NOTE: this is a pure UI/UX rewrite. Every data source, API call,
/// and model field relied on elsewhere is untouched — only
/// presentation changed.
class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();
  late Future<_ProductDetailData> _detailFuture;
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _entranceController;

  int _currentPage = 0;
  int _quantity = 1;
  bool _isAddingToCart = false;
  bool _descriptionExpanded = false;
  double _heroParallax = 0;

  static const double _heroHeight = 460;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scrollController.addListener(() {
      final offset =
          _scrollController.hasClients ? _scrollController.offset : 0.0;
      setState(() => _heroParallax = offset.clamp(0, _heroHeight));
    });
  }

  void _incrementQuantity(int stock) {
    if (_quantity >= stock) return;
    setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity <= 1) return;
    setState(() => _quantity--);
  }

  Future<void> _addToCart(Product product) async {
    if (product.stock <= 0) {
      _showSnack('This product is out of stock.', isError: true);
      return;
    }
    if (_quantity < 1 || _quantity > product.stock) {
      _showSnack('Please select a valid quantity.', isError: true);
      return;
    }

    final UserModel? user = await SessionService.instance.getUser();
    if (!mounted) return;
    if (user == null || user.id.isEmpty) {
      _showSnack('Please log in to add items to your cart.', isError: true);
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      await _cartService.addToCart(
        userId: user.id,
        productId: product.id,
        quantity: _quantity,
      );
      if (!mounted) return;
      _showAddedToCartDialog();
    } catch (e) {
      if (!mounted) return;
      _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor:
            isError ? const Color(0xFFD64545) : AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _showAddedToCartDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _AddedToCartSheet(
          onContinueShopping: () {
            Navigator.pop(context);
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              PremiumPageRoute(page: const MainShell()),
              (route) => false,
            );
          },
          onViewCart: () {
            Navigator.pop(context);
            Navigator.push(context, PremiumPageRoute(page: const CartScreen()));
          },
        );
      },
    );
  }

  Future<_ProductDetailData> _loadDetail() async {
    final results = await Future.wait([
      _apiService.getProducts(),
      _apiService.getProductImages(widget.productId),
    ]);

    final products = results[0] as List<Product>;
    final images = results[1] as List<ProductImage>;

    final product = products.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => throw ApiException('Product not found.'),
    );

    _entranceController.forward(from: 0);
    return _ProductDetailData(product, images);
  }

  Future<void> _onRetry() async {
    final future = _loadDetail();
    setState(() {
      _detailFuture = future;
      _currentPage = 0;
      _quantity = 1;
      _descriptionExpanded = false;
    });
    await future;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      extendBodyBehindAppBar: true,
      body: PremiumScreenBackground(
        child: FutureBuilder<_ProductDetailData>(
          future: _detailFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            final data = snapshot.data!;
            return _buildContent(data);
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<_ProductDetailData>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          return _buildBottomBar(snapshot.data!.product);
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // Bottom purchase bar
  // -------------------------------------------------------------------
  Widget _buildBottomBar(Product product) {
    final bool inStock = product.stock > 0;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: [
            if (inStock) ...[
              _QuantityStepper(
                quantity: _quantity,
                canIncrement: _quantity < product.stock,
                onDecrement: _decrementQuantity,
                onIncrement: () => _incrementQuantity(product.stock),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: _PulseCtaButton(
                enabled: inStock && !_isAddingToCart,
                loading: _isAddingToCart,
                label: inStock ? 'Add to Cart' : 'Out of Stock',
                icon: Icons.shopping_bag_rounded,
                onTap: () => _addToCart(product),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Main content
  // -------------------------------------------------------------------
  Widget _buildContent(_ProductDetailData data) {
    final product = data.product;
    // Gallery falls back to the product's main image if there are
    // no rows in product_images for this product yet.
    final List<String> gallery = data.images.isNotEmpty
        ? data.images.map((i) => i.imageUrl).toList()
        : [product.imageUrl];

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _HeroGallery(
            gallery: gallery,
            productId: product.id,
            pageController: _pageController,
            currentPage: _currentPage,
            parallax: _heroParallax,
            heroHeight: _heroHeight,
            onPageChanged: (index) => setState(() => _currentPage = index),
            onBack: () => Navigator.pop(context),
            onOpenFullscreen: () => _openFullscreenGallery(gallery, product.id),
          ),
        ),
        SliverToBoxAdapter(
          child: Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2A0B1440),
                    blurRadius: 30,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 30, 22, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag handle for a native bottom-sheet premium feel.
                    Center(
                      child: Container(
                        width: 44,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    _staggered(0, child: _StockBadge(stock: product.stock)),
                    const SizedBox(height: 12),
                    _staggered(
                      1,
                      child: Text(
                        product.name,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 25,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          height: 1.24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _staggered(
                      2,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ShaderMask(
                            shaderCallback: (rect) => const LinearGradient(
                              colors: [AppColors.primary, AppColors.bgSoft],
                            ).createShader(rect),
                            child: Text(
                              'Rs. ${_formatPrice(product.price)}',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'per unit',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    _staggered(3, child: const _TrustBadgeRow()),
                    const SizedBox(height: 26),
                    _staggered(4, child: _sectionDivider()),
                    const SizedBox(height: 22),
                    _staggered(
                      5,
                      child: _sectionHeading('Description'),
                    ),
                    const SizedBox(height: 12),
                    _staggered(
                      6,
                      child: _ExpandableDescription(
                        text: product.description.isNotEmpty
                            ? product.description
                            : 'No description available for this product.',
                        expanded: _descriptionExpanded,
                        onToggle: () => setState(
                          () => _descriptionExpanded = !_descriptionExpanded,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _staggered(7, child: _sectionDivider()),
                    const SizedBox(height: 22),
                    _staggered(
                      8,
                      child: _sectionHeading('Product Information'),
                    ),
                    const SizedBox(height: 14),
                    _staggered(
                      9,
                      child: _ProductInfoCard(product: product),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeading(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.bgSoft],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  /// Applies a subtle staggered fade + slide-up entrance to [child],
  /// timed against [_entranceController] so the whole content card
  /// reveals itself in a smooth premium cascade rather than popping
  /// in all at once.
  Widget _staggered(int index, {required Widget child}) {
    final start = (index * 0.06).clamp(0.0, 0.7);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _sectionDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primarySoft,
            AppColors.primary.withOpacity(0.18),
            AppColors.primarySoft,
          ],
        ),
      ),
    );
  }

  void _openFullscreenGallery(List<String> gallery, int productId) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withOpacity(0.95),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, __) => FadeTransition(
          opacity: animation,
          child: _FullscreenGallery(
            gallery: gallery,
            productId: productId,
            initialIndex: _currentPage,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Loading / error states
  // -------------------------------------------------------------------
  Widget _buildLoadingState() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackButton(onTap: () => Navigator.pop(context)),
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: const ShimmerCard(),
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: 200,
              height: 22,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const ShimmerCard(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 130,
              height: 26,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const ShimmerCard(),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const ShimmerCard(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const ShimmerCard(),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 220,
              height: 14,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const ShimmerCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _BackButton(onTap: () => Navigator.pop(context)),
            ),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.primary,
                          size: 42,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Unable to load product',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please check your connection and try again',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 26),
                    _PulseCtaButton(
                      enabled: true,
                      loading: false,
                      label: 'Retry',
                      icon: Icons.refresh_rounded,
                      onTap: _onRetry,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Hero image gallery
// ===========================================================================
class _HeroGallery extends StatelessWidget {
  final List<String> gallery;
  final int productId;
  final PageController pageController;
  final int currentPage;
  final double parallax;
  final double heroHeight;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final VoidCallback onOpenFullscreen;

  const _HeroGallery({
    required this.gallery,
    required this.productId,
    required this.pageController,
    required this.currentPage,
    required this.parallax,
    required this.heroHeight,
    required this.onPageChanged,
    required this.onBack,
    required this.onOpenFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Subtle parallax: the gallery scrolls slightly slower than
          // the sheet above it for a layered, premium depth effect.
          Transform.translate(
            offset: Offset(0, parallax * 0.35),
            child: GestureDetector(
              onTap: onOpenFullscreen,
              child: PageView.builder(
                controller: pageController,
                itemCount: gallery.length,
                onPageChanged: onPageChanged,
                itemBuilder: (context, index) {
                  return Hero(
                    tag: index == 0
                        ? 'product_image_$productId'
                        : 'product_image_${productId}_$index',
                    child: CachedNetworkImage(
                      imageUrl: gallery[index],
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      fadeInDuration: const Duration(milliseconds: 350),
                      placeholder: (context, url) => Container(
                        color: AppColors.bgMid,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.bgMid,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white.withOpacity(0.6),
                          size: 42,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Gradient scrim so the top glass controls and bottom
          // thumbnail rail stay legible over any photo.
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.32),
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.bgDeep.withOpacity(0.55),
                  ],
                  stops: const [0.0, 0.22, 0.62, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14,
            child: _BackButton(onTap: onBack),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 14,
            child: const _ZoomHintPill(),
          ),
          if (gallery.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(gallery.length, (index) {
                      final active = index == currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 3.5),
                        width: active ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 56,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final active = index == currentPage;
                        return GestureDetector(
                          onTap: () => pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: active
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.35),
                                width: active ? 2.2 : 1,
                              ),
                              boxShadow: active
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(11.5),
                              child: Opacity(
                                opacity: active ? 1 : 0.6,
                                child: CachedNetworkImage(
                                  imageUrl: gallery[index],
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) =>
                                      Container(color: AppColors.bgMid),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
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

class _ZoomHintPill extends StatelessWidget {
  const _ZoomHintPill();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.22),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child:
              const Icon(Icons.zoom_in_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ===========================================================================
// Fullscreen gallery viewer (tap-to-zoom premium touch)
// ===========================================================================
class _FullscreenGallery extends StatefulWidget {
  final List<String> gallery;
  final int productId;
  final int initialIndex;

  const _FullscreenGallery({
    required this.gallery,
    required this.productId,
    required this.initialIndex,
  });

  @override
  State<_FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<_FullscreenGallery> {
  late final PageController _controller =
      PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.gallery.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) {
                return Center(
                  child: Hero(
                    tag: index == 0
                        ? 'product_image_${widget.productId}'
                        : 'product_image_${widget.productId}_$index',
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: CachedNetworkImage(
                        imageUrl: widget.gallery[index],
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 10,
              left: 14,
              child: _BackButton(onTap: () => Navigator.pop(context)),
            ),
            if (widget.gallery.length > 1)
              Positioned(
                bottom: 26,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${widget.gallery.length}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ===========================================================================
// Small reusable pieces
// ===========================================================================
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.24),
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white38, width: 1),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final int stock;
  const _StockBadge({required this.stock});

  @override
  Widget build(BuildContext context) {
    final bool inStock = stock > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        gradient: inStock
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.bgSoft])
            : LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade300]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (inStock ? AppColors.primary : Colors.red).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            inStock ? Icons.check_circle_rounded : Icons.remove_circle_rounded,
            size: 13,
            color: Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            inStock ? '$stock in stock' : 'Out of stock',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeRow extends StatelessWidget {
  const _TrustBadgeRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.local_shipping_rounded, 'Fast Delivery'),
      (Icons.verified_rounded, 'Quality Assured'),
      (Icons.payments_rounded, 'Cash on Delivery'),
    ];
    return Row(
      children: [
        for (int i = 0; i < items.length; i++)
          Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == items.length - 1 ? 0 : 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(items[i].$1, color: AppColors.primary, size: 20),
                  const SizedBox(height: 6),
                  Text(
                    items[i].$2,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  const _ExpandableDescription({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  static const int _collapsedMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topLeft,
          child: Text(
            text,
            maxLines: expanded ? null : _collapsedMaxLines,
            overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.7,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        if (text.length > 120)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: GestureDetector(
              onTap: onToggle,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Show less' : 'Read more',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductInfoCard extends StatelessWidget {
  final Product product;
  const _ProductInfoCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String)>[
      (
        Icons.inventory_2_rounded,
        'Availability',
        product.stock > 0 ? 'In Stock' : 'Out of Stock',
      ),
      (
        Icons.tag_rounded,
        'Product ID',
        '#${product.id.toString().padLeft(4, '0')}'
      ),
      if (product.createdAt.isNotEmpty)
        (Icons.event_available_rounded, 'Listed On', product.createdAt),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primarySoft, width: 1.2),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(row.$1, size: 16, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      row.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        row.$3,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i != rows.length - 1)
                const Divider(height: 1, color: AppColors.primarySoft),
            ],
          );
        }),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _QuantityStepper({
    required this.quantity,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove_rounded,
            onTap: quantity > 1 ? onDecrement : null,
          ),
          SizedBox(
            width: 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                '$quantity',
                key: ValueKey(quantity),
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            onTap: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.primary : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }
}

/// Premium CTA button with a subtle press-scale micro-interaction and
/// gradient fill, used for both "Add to Cart" and "Retry".
class _PulseCtaButton extends StatefulWidget {
  final bool enabled;
  final bool loading;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool compact;

  const _PulseCtaButton({
    required this.enabled,
    required this.loading,
    required this.label,
    required this.icon,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_PulseCtaButton> createState() => _PulseCtaButtonState();
}

class _PulseCtaButtonState extends State<_PulseCtaButton> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.96 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = !widget.enabled;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapCancel: disabled ? null : () => _setPressed(false),
      onTapUp: disabled ? null : (_) => _setPressed(false),
      onTap: disabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.compact ? null : double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: 16,
            horizontal: widget.compact ? 30 : 0,
          ),
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [AppColors.primary, AppColors.bgSoft],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            color: disabled ? Colors.grey.shade300 : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: widget.loading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon,
                        size: 18,
                        color: disabled ? Colors.grey.shade500 : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: disabled ? Colors.grey.shade500 : Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Premium bottom sheet shown after a successful add-to-cart action.
class _AddedToCartSheet extends StatelessWidget {
  final VoidCallback onContinueShopping;
  final VoidCallback onViewCart;

  const _AddedToCartSheet({
    required this.onContinueShopping,
    required this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.3, end: 1.0),
                duration: const Duration(milliseconds: 550),
                curve: Curves.elasticOut,
                builder: (context, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.bgSoft],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Added to Cart',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your item has been added to the cart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onContinueShopping,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Continue Shopping',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.bgSoft],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: onViewCart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'View Cart',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrice(double price) {
  if (price == price.roundToDouble()) {
    return price.toStringAsFixed(0);
  }
  return price.toStringAsFixed(2);
}
