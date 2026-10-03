import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hamzain_traders/models/brand.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/screens/products_screen.dart';

class BrandCard extends StatefulWidget {
  final Brand brand;
  final Animation<double> entranceAnimation;

  const BrandCard({
    super.key,
    required this.brand,
    required this.entranceAnimation,
  });

  @override
  State<BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<BrandCard> {
  double _scale = 1.0;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? 0.95 : 1.0);
  }

  void _openProducts(BuildContext context) {
    final int brandId = int.tryParse(widget.brand.id) ?? 0;
    Navigator.push(
      context,
      PremiumPageRoute(
        page: ProductsScreen(
          brandId: brandId,
          brandName: widget.brand.brandName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.entranceAnimation,
      builder: (context, child) {
        final value = widget.entranceAnimation.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: () => _openProducts(context),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                // Solid white card body instead of AppColors.surface —
                // gives a cleaner premium contrast against the blue-tinted
                // page background added in HomeScreen.
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.12),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.14),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: AppColors.primary.withOpacity(0.08),
                highlightColor: AppColors.primary.withOpacity(0.04),
                onTap: () => _openProducts(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        // Stack + Positioned.fill forces the image to occupy
                        // every pixel of the box, edge to edge, regardless of
                        // the image's own dimensions or the box's aspect
                        // ratio. No padding, no letterboxing, no gaps —
                        // BoxFit.cover then scales the image up/down
                        // (cropping only the excess, never leaving empty
                        // space) to guarantee full coverage.
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Shows only for the brief moment before the
                            // image finishes loading — once loaded it's
                            // fully covered, so it never reads as empty
                            // white space.
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.primarySoft,
                                    AppColors.primarySoft.withOpacity(0.55),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Hero(
                                tag: 'brand_${widget.brand.id}',
                                child: CachedNetworkImage(
                                  imageUrl: widget.brand.brandImage,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  fadeInDuration:
                                      const Duration(milliseconds: 400),
                                  placeholder: (context, url) => const Center(
                                    child: SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.primary.withOpacity(0.6),
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.brand.brandName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.brand.brandDescription,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
