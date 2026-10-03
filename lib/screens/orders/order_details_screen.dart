import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/order_model.dart';
import 'package:hamzain_traders/screens/orders/receipt_screen.dart';
import 'package:hamzain_traders/services/order_service.dart';
import 'package:hamzain_traders/services/session_service.dart';

/// Full order details screen backed by getorderdetails.php. Reused
/// from My Orders, Order History, and Order Success — always driven
/// by a real order id, never hardcoded.
class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final OrderService _orderService = OrderService();
  late Future<OrderModel> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _load();
  }

  // getorderdetails.php requires BOTH order_id and user_id (confirmed
  // from its source) — the real logged-in user's id is fetched here
  // rather than being passed in by every caller, so this screen keeps
  // working correctly regardless of which screen navigated to it.
  Future<OrderModel> _load() async {
    final user = await SessionService.instance.getUser();
    if (user == null || user.id.isEmpty) {
      throw Exception('Please log in to view this order.');
    }
    return _orderService.getOrderDetails(orderId: widget.orderId, userId: user.id);
  }

  Future<void> _refresh() async {
    final future = _load();
    setState(() {
      _orderFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: FutureBuilder<OrderModel>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }
          final order = snapshot.data!;
          return _buildContent(order);
        },
      ),
      ),
    );
  }

  Widget _buildContent(OrderModel order) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        children: [
          _StatusBanner(status: order.status, orderNumber: order.orderNumber),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Order Information',
            rows: [
              _Row('Order Number', order.orderNumber.isNotEmpty ? '#${order.orderNumber}' : '—'),
              _Row('Order Date', order.createdAt.isNotEmpty ? order.createdAt : '—'),
              _Row('Order Status', order.status.isNotEmpty ? order.status : '—'),
              _Row('Estimated Delivery', order.estimatedDeliveryDate.isNotEmpty ? order.estimatedDeliveryDate : '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Customer Information',
            rows: [
              _Row('Name', order.customerName.isNotEmpty ? order.customerName : '—'),
              _Row('Phone', order.phone.isNotEmpty ? order.phone : '—'),
              _Row('Email', order.email.isNotEmpty ? order.email : '—'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Address',
            rows: [
              _Row('Address', order.address.isNotEmpty ? order.address : '—'),
              _Row('City', order.city.isNotEmpty ? order.city : '—'),
              _Row('Area', order.area.isNotEmpty ? order.area : '—'),
              if (order.addressNotes.isNotEmpty) _Row('Notes', order.addressNotes),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Products', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 10),
          if (order.items.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
              child: const Text('No items found for this order.', style: TextStyle(color: AppColors.primaryDark)),
            )
          else
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProductRow(item: item),
                )),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Summary',
            rows: [
              _Row('Subtotal', 'Rs. ${_fmt(order.subtotal)}'),
              _Row('Delivery Charges', 'Rs. ${_fmt(order.deliveryCharges)}'),
              _Row('Total Amount', 'Rs. ${_fmt(order.totalAmount)}', emphasize: true),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(
                context,
                PremiumPageRoute(page: ReceiptScreen(orderId: widget.orderId)),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.08),
                side: const BorderSide(color: Colors.white, width: 1.4),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
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
                      decoration: const BoxDecoration(color: AppColors.primarySoft, shape: BoxShape.circle),
                      child: const Icon(Icons.error_outline_rounded, color: AppColors.primary, size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text('Unable to load order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primaryDark)),
                    const SizedBox(height: 8),
                    Text(message.replaceFirst('Exception: ', ''), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: _refresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
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

class _StatusBanner extends StatelessWidget {
  final String status;
  final String orderNumber;
  const _StatusBanner({required this.status, required this.orderNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orderNumber.isNotEmpty ? '#$orderNumber' : 'Order', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(status.isNotEmpty ? status : 'Processing', style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _SectionCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
          const SizedBox(height: 12),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(r.label, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        r.value,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: r.emphasize ? 15 : 13,
                          fontWeight: r.emphasize ? FontWeight.w800 : FontWeight.w600,
                          color: r.emphasize ? AppColors.primary : AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;
  final bool emphasize;
  _Row(this.label, this.value, {this.emphasize = false});
}

class _ProductRow extends StatelessWidget {
  final OrderItemModel item;
  const _ProductRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: item.productImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.productImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.primarySoft),
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.primarySoft,
                        child: const Icon(Icons.broken_image_outlined, color: AppColors.primary, size: 18),
                      ),
                    )
                  : Container(color: AppColors.primarySoft, child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName.isNotEmpty ? item.productName : 'Product', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text('Rs. ${_fmt(item.unitPrice)} x ${item.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text('Rs. ${_fmt(item.itemTotal)}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 13.5)),
        ],
      ),
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
