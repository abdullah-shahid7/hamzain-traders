import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/models/order_model.dart';
import 'package:hamzain_traders/services/order_service.dart';
import 'package:hamzain_traders/services/session_service.dart';
import 'package:hamzain_traders/widgets/thank_you_banner.dart';

/// Receipt screen backed by getorderreceipt.php. Purely a formatted
/// representation of `orders` + `order_items` — there is no
/// `receipts` database table.
class ReceiptScreen extends StatefulWidget {
  final String orderId;

  const ReceiptScreen({super.key, required this.orderId});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final OrderService _orderService = OrderService();
  late Future<OrderModel> _receiptFuture;

  @override
  void initState() {
    super.initState();
    _receiptFuture = _load();
  }

  // getorderreceipt.php requires BOTH order_id and user_id (confirmed
  // from its source) — fetched here rather than passed in by every
  // caller.
  Future<OrderModel> _load() async {
    final user = await SessionService.instance.getUser();
    if (user == null || user.id.isEmpty) {
      throw Exception('Please log in to view this receipt.');
    }
    return _orderService.getOrderReceipt(
        orderId: widget.orderId, userId: user.id);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _receiptFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
        child: FutureBuilder<OrderModel>(
          future: _receiptFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            return _buildReceipt(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildReceipt(OrderModel order) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                    color: AppColors.primaryDark.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12))
              ],
            ),
            child: Column(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 32),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('HamZainTraders',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text('Order Receipt',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                        letterSpacing: 1)),
                const SizedBox(height: 18),
                const DashedDivider(),
                const SizedBox(height: 14),
                _ReceiptRow(
                    'Order Number',
                    order.orderNumber.isNotEmpty
                        ? '#${order.orderNumber}'
                        : '—'),
                _ReceiptRow('Order Date',
                    order.createdAt.isNotEmpty ? order.createdAt : '—'),
                _ReceiptRow(
                    'Status', order.status.isNotEmpty ? order.status : '—'),
                _ReceiptRow(
                    'Estimated Delivery',
                    order.estimatedDeliveryDate.isNotEmpty
                        ? order.estimatedDeliveryDate
                        : '—'),
                const SizedBox(height: 14),
                const DashedDivider(),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Customer',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.75))),
                ),
                const SizedBox(height: 8),
                _ReceiptRow('Name',
                    order.customerName.isNotEmpty ? order.customerName : '—'),
                _ReceiptRow(
                    'Phone', order.phone.isNotEmpty ? order.phone : '—'),
                _ReceiptRow(
                    'Email', order.email.isNotEmpty ? order.email : '—'),
                _ReceiptRow(
                  'Address',
                  [order.address, order.area, order.city]
                          .where((s) => s.isNotEmpty)
                          .join(', ')
                          .isEmpty
                      ? '—'
                      : [order.address, order.area, order.city]
                          .where((s) => s.isNotEmpty)
                          .join(', '),
                ),
                const SizedBox(height: 14),
                const DashedDivider(),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Products',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withOpacity(0.75))),
                ),
                const SizedBox(height: 10),
                if (order.items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('No items found for this order.',
                        style: TextStyle(color: Colors.white)),
                  )
                else
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.productName.isNotEmpty
                                    ? item.productName
                                    : 'Product',
                                style: const TextStyle(
                                    fontSize: 12.5, color: Colors.white),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('x${item.quantity}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white.withOpacity(0.75))),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Rs. ${_fmt(item.unitPrice)}',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.white.withOpacity(0.75))),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('Rs. ${_fmt(item.itemTotal)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 8),
                const DashedDivider(),
                const SizedBox(height: 14),
                _ReceiptRow('Subtotal', 'Rs. ${_fmt(order.subtotal)}'),
                _ReceiptRow(
                    'Delivery Charges', 'Rs. ${_fmt(order.deliveryCharges)}'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.white)),
                    Text('Rs. ${_fmt(order.totalAmount)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.accentGold)),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Thank you for shopping with HamZainTraders!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.65))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const ThankYouBanner(),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
                      child: const Icon(Icons.error_outline_rounded,
                          color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text('Unable to load receipt',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(message.replaceFirst('Exception: ', ''),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75))),
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
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Retry',
                          style: TextStyle(fontWeight: FontWeight.w600)),
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
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReceiptRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12.5, color: Colors.white.withOpacity(0.75))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashGap = 4.0;
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashGap)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                  decoration:
                      BoxDecoration(color: Colors.white.withOpacity(0.35))),
            ),
          ),
        );
      },
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
