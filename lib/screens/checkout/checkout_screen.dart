import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/constants/order_constants.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/address_model.dart';
import 'package:hamzain_traders/models/cart_model.dart';
import 'package:hamzain_traders/models/user_model.dart';
import 'package:hamzain_traders/screens/address/saved_address_screen.dart';
import 'package:hamzain_traders/screens/checkout/order_success_screen.dart';
import 'package:hamzain_traders/services/address_service.dart';
import 'package:hamzain_traders/services/cart_service.dart';
import 'package:hamzain_traders/services/order_service.dart';
import 'package:hamzain_traders/services/session_service.dart';

/// Checkout screen: shows the real cart, lets the user pick a real
/// saved address (or add a new one), confirms Cash on Delivery as
/// the payment method, and places the order via placeorder.php.
///
/// There is no `checkout` database table — this screen is purely a
/// review/confirmation step over `cart` + `cart_items` + `address`.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final AddressService _addressService = AddressService();
  final OrderService _orderService = OrderService();

  UserModel? _user;
  CartData _cart = CartData.empty;
  List<AddressModel> _addresses = const [];
  AddressModel? _selectedAddress;

  bool _isLoading = true;
  String? _loadError;
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    final user = await SessionService.instance.getUser();
    if (!mounted) return;

    if (user == null || user.id.isEmpty) {
      setState(() {
        _loadError = 'Please log in to continue to checkout.';
        _isLoading = false;
      });
      return;
    }

    _user = user;

    // Cart and addresses are loaded independently — a real cart is
    // required to check out at all, so a cart failure is fatal to
    // this screen. A saved-address lookup failing is NOT fatal: a
    // user with zero saved addresses (or a temporarily-failing
    // getaddresses.php) should still be able to open Checkout and
    // add a new address from here, rather than being blocked
    // entirely by a call that isn't strictly required to render the
    // screen. Gating the whole screen on both calls succeeding was
    // the actual bug — this fixes it independently of whatever the
    // address API's specific failure reason turns out to be.
    CartData cart;
    try {
      cart = await _cartService.getCart(userId: user.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;

    List<AddressModel> addresses = const [];
    try {
      addresses = await _addressService.getAddresses(userId: user.id);
    } catch (_) {
      // Non-fatal: proceed with an empty address list so the person
      // can still review their cart and add a delivery address
      // manually via "Select a delivery address" below — that screen
      // (not this one) is where a failed/empty address fetch gets a
      // proper, polished state instead of a raw backend message.
    }
    if (!mounted) return;

    setState(() {
      _cart = cart;
      _addresses = addresses;
      _selectedAddress = addresses.isNotEmpty ? addresses.first : null;
      _isLoading = false;
    });
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.push<AddressModel>(
      context,
      PremiumPageRoute(page: const SavedAddressScreen(selectionMode: true)),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result;
        if (!_addresses.any((a) => a.id == result.id)) {
          _addresses = [result, ..._addresses];
        }
      });
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

  Future<void> _placeOrder() async {
    final user = _user;
    final address = _selectedAddress;

    if (user == null) {
      _showSnack('Please log in to place your order.', isError: true);
      return;
    }
    if (_cart.isEmpty) {
      _showSnack('Your cart is empty.', isError: true);
      return;
    }
    if (address == null) {
      _showSnack('Please select a delivery address.', isError: true);
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final subtotal = _cart.subtotal;
      const delivery = OrderConstants.flatDeliveryCharge;
      final total = subtotal + delivery;

      final result = await _orderService.placeOrder(
        userId: user.id,
        address: address,
        items: _cart.items,
        subtotal: subtotal,
        deliveryCharges: delivery,
        totalAmount: total,
        cartId: _cart.cartId,
        paymentMethod: 'Cash on Delivery',
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PremiumPageRoute(
          page: OrderSuccessScreen(
            orderId: result.orderId,
            orderNumber: result.orderNumber,
            totalAmount: result.totalAmount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(child: _buildBody()),
      bottomNavigationBar: (_isLoading || _loadError != null || _cart.isEmpty)
          ? null
          : _buildPlaceOrderBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_loadError != null) {
      return _buildMessage(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load checkout',
        subtitle: _loadError!,
        onRetry: _init,
      );
    }
    if (_cart.isEmpty) {
      return _buildMessage(
        icon: Icons.shopping_cart_outlined,
        title: 'Your cart is empty',
        subtitle: 'Add products to your cart before checking out',
      );
    }

    final subtotal = _cart.subtotal;
    const delivery = OrderConstants.flatDeliveryCharge;
    final total = subtotal + delivery;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _init,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          const _SectionTitle('Delivery Address'),
          const SizedBox(height: 10),
          _buildAddressSection(),
          const SizedBox(height: 24),
          _SectionTitle('Order Items (${_cart.totalQuantity})'),
          const SizedBox(height: 10),
          ..._cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderItemRow(item: item),
              )),
          const SizedBox(height: 24),
          const _SectionTitle('Payment Method'),
          const SizedBox(height: 10),
          _buildPaymentMethodSection(),
          const SizedBox(height: 24),
          const _SectionTitle('Order Summary'),
          const SizedBox(height: 10),
          _buildSummaryCard(subtotal, delivery, total),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final address = _selectedAddress;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _pickAddress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.location_on_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: address == null
                    ? const Text(
                        'Select a delivery address',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${address.fullName} · ${address.addressType}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            address.oneLineSummary,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 2),
                          Text(address.phone,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary, width: 1.4),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.payments_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash on Delivery',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                        fontSize: 14)),
                SizedBox(height: 2),
                Text('Pay when your order arrives',
                    style: TextStyle(fontSize: 12.5, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double subtotal, double delivery, double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _SummaryLine(label: 'Subtotal', value: 'Rs. ${_fmt(subtotal)}'),
          const SizedBox(height: 8),
          _SummaryLine(
              label: 'Delivery Charges', value: 'Rs. ${_fmt(delivery)}'),
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1)),
          _SummaryLine(
              label: 'Total Amount',
              value: 'Rs. ${_fmt(total)}',
              emphasize: true),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _isPlacingOrder
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.4),
                  )
                : const Text('Place Order',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
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
                          color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: Icon(icon, color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75))),
                    if (onRetry != null) ...[
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: onRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Retry',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final CartItemModel item;
  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.productName} x${item.quantity}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                  fontSize: 13.5),
            ),
          ),
          Text(
            'Rs. ${_fmt(item.itemTotal)}',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 13.5),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;
  const _SummaryLine(
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
