import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/constants/order_constants.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/cart_model.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/screens/checkout/checkout_screen.dart';
import 'package:hamzain_traders/services/cart_service.dart';
import 'package:hamzain_traders/services/session_service.dart';

/// Real cart screen backed by getcart.php / updatecartquantity.php /
/// removecartitem.php / clearcart.php for the current logged-in user.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  UserModel? _user;
  Future<CartData>? _cartFuture;

  /// Tracks which cart_item ids currently have an in-flight
  /// update/remove request, so their controls can be disabled and
  /// duplicate taps prevented.
  final Set<int> _busyItemIds = {};
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    setState(() {
      _user = user;
      _cartFuture = user != null
          ? _cartService.getCart(userId: user.id)
          : Future.value(CartData.empty);
    });
  }

  Future<void> _refresh() async {
    final user = _user;
    if (user == null) return;
    final future = _cartService.getCart(userId: user.id);
    // A block body here is required, not `() => _cartFuture = future`:
    // that arrow form's body is the assignment expression itself,
    // which evaluates to (and so returns) `future` — a live
    // Future<CartData> — making the closure passed to setState()
    // literally return a Future. Flutter explicitly rejects that
    // ("setState() callback argument returned a Future") since
    // setState callbacks must run synchronously.
    setState(() {
      _cartFuture = future;
    });
    await future;
  }

  Future<void> _updateQuantity(CartItemModel item, int newQuantity) async {
    final user = _user;
    if (user == null) return;
    if (newQuantity < 1) return;
    if (item.stock > 0 && newQuantity > item.stock) {
      _showSnack('Only ${item.stock} left in stock.', isError: true);
      return;
    }
    setState(() => _busyItemIds.add(item.id));
    try {
      await _cartService.updateCartQuantity(
        cartItemId: item.id,
        userId: user.id,
        quantity: newQuantity,
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  Future<void> _removeItem(CartItemModel item) async {
    final user = _user;
    if (user == null) return;
    setState(() => _busyItemIds.add(item.id));
    try {
      await _cartService.removeCartItem(cartItemId: item.id, userId: user.id);
      await _refresh();
      if (mounted) _showSnack('Item removed from cart.', isError: false);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyItemIds.remove(item.id));
    }
  }

  Future<void> _clearCart() async {
    final user = _user;
    if (user == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isClearing = true);
    try {
      await _cartService.clearCart(userId: user.id);
      await _refresh();
      if (mounted) _showSnack('Your cart is empty.', isError: false);
    } catch (e) {
      if (mounted) {
        _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          FutureBuilder<CartData>(
            future: _cartFuture,
            builder: (context, snapshot) {
              final data = snapshot.data;
              if (data == null || data.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: _isClearing ? null : _clearCart,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Clear Cart',
              );
            },
          ),
        ],
      ),
      body: PremiumScreenBackground(
        child: _cartFuture == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: FutureBuilder<CartData>(
                  future: _cartFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildMessageState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load cart',
                        subtitle: 'Please check your connection and try again',
                        showRetry: true,
                      );
                    }
                    final data = snapshot.data ?? CartData.empty;
                    if (data.isEmpty) {
                      return _buildMessageState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Your cart is empty',
                        subtitle: 'Browse products and add something you love',
                        showContinueShopping: true,
                      );
                    }
                    return _buildCartContent(data);
                  },
                ),
              ),
      ),
      bottomNavigationBar: FutureBuilder<CartData>(
        future: _cartFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null || data.isEmpty) return const SizedBox.shrink();
          return _buildSummaryBar(data);
        },
      ),
    );
  }

  Widget _buildCartContent(CartData data) {
    return ListView.separated(
      physics:
          const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      itemCount: data.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final item = data.items[index];
        final busy = _busyItemIds.contains(item.id);
        return _CartItemCard(
          item: item,
          busy: busy,
          onIncrement: () => _updateQuantity(item, item.quantity + 1),
          onDecrement: () => _updateQuantity(item, item.quantity - 1),
          onRemove: () => _removeItem(item),
        );
      },
    );
  }

  Widget _buildSummaryBar(CartData data) {
    final subtotal = data.subtotal;
    const delivery = OrderConstants.flatDeliveryCharge;
    final total = subtotal + delivery;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SummaryRow(
                label: 'Total Quantity', value: '${data.totalQuantity}'),
            const SizedBox(height: 6),
            _SummaryRow(label: 'Subtotal', value: 'Rs. ${_fmt(subtotal)}'),
            const SizedBox(height: 6),
            _SummaryRow(
                label: 'Delivery Charges', value: 'Rs. ${_fmt(delivery)}'),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _SummaryRow(
              label: 'Total',
              value: 'Rs. ${_fmt(total)}',
              emphasize: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    PremiumPageRoute(page: const CheckoutScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
    bool showContinueShopping = false,
  }) {
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
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: Colors.white.withOpacity(0.75)),
                    ),
                    if (showRetry) ...[
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: _refresh,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                    if (showContinueShopping) ...[
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Continue Shopping',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItemModel item;
  final bool busy;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.busy,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final bool atMaxStock = item.stock > 0 && item.quantity >= item.stock;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 68,
              height: 68,
              child: item.productImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.productImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: AppColors.primarySoft),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primarySoft,
                        child: const Icon(Icons.broken_image_outlined,
                            color: AppColors.primary),
                      ),
                    )
                  : Container(
                      color: AppColors.primarySoft,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.primary),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName.isNotEmpty ? item.productName : 'Product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${_fmt(item.unitPrice)}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MiniStepper(
                      quantity: item.quantity,
                      busy: busy,
                      canDecrement: item.quantity > 1,
                      canIncrement: !atMaxStock,
                      onDecrement: onDecrement,
                      onIncrement: onIncrement,
                    ),
                    const Spacer(),
                    Text(
                      'Rs. ${_fmt(item.itemTotal)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: busy ? null : onRemove,
            icon: Icon(Icons.close_rounded,
                color: Colors.grey.shade500, size: 20),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}

class _MiniStepper extends StatelessWidget {
  final int quantity;
  final bool busy;
  final bool canDecrement;
  final bool canIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _MiniStepper({
    required this.quantity,
    required this.busy,
    required this.canDecrement,
    required this.canIncrement,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: (!busy && canDecrement) ? onDecrement : null,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(Icons.remove_rounded,
                  size: 15,
                  color: (!busy && canDecrement)
                      ? AppColors.primary
                      : Colors.grey.shade400),
            ),
          ),
          SizedBox(
            width: 22,
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: (!busy && canIncrement) ? onIncrement : null,
            child: Padding(
              padding: const EdgeInsets.all(7),
              child: Icon(Icons.add_rounded,
                  size: 15,
                  color: (!busy && canIncrement)
                      ? AppColors.primary
                      : Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _SummaryRow(
      {required this.label, required this.value, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            color: emphasize ? AppColors.primaryDark : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 17 : 13,
            fontWeight: FontWeight.w800,
            color: emphasize ? AppColors.primary : AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
