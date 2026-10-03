import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/order_model.dart';
import 'package:hamzain_traders/screens/orders/order_details_screen.dart';
import 'package:hamzain_traders/services/order_service.dart';
import 'package:hamzain_traders/services/session_service.dart';

/// My Orders screen (existing screen, kept as-is in the Drawer),
/// now connected to real data via getmyorders.php for the current
/// logged-in user.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final _orderService = OrderService();
  Future<List<OrderModel>>? _ordersFuture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    setState(() {
      _ordersFuture = (user != null && user.id.isNotEmpty)
          ? _orderService.getMyOrders(userId: user.id)
          : Future.error('Please log in to view your orders.');
    });
  }

  Future<void> _refresh() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    final future = (user != null && user.id.isNotEmpty)
        ? _orderService.getMyOrders(userId: user.id)
        : Future<List<OrderModel>>.error('Please log in to view your orders.');
    setState(() {
      _ordersFuture = future;
    });
    await future.catchError((_) => <OrderModel>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: _ordersFuture == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _refresh,
              child: FutureBuilder<List<OrderModel>>(
                future: _ordersFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return _StateMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Unable to load orders',
                      subtitle: snapshot.error.toString().replaceFirst('Exception: ', ''),
                      showRetry: true,
                      onRetry: _refresh,
                    );
                  }
                  final orders = snapshot.data ?? const <OrderModel>[];
                  if (orders.isEmpty) {
                    return const _StateMessage(
                      icon: Icons.shopping_bag_outlined,
                      title: 'No orders found',
                      subtitle: 'Your placed orders will appear here',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) => _OrderCard(
                      order: orders[index],
                      onTap: () => Navigator.push(
                        context,
                        PremiumPageRoute(
                          page: OrderDetailsScreen(orderId: orders[index].id),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber.isNotEmpty ? '#${order.orderNumber}' : 'Order',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 15,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.isNotEmpty ? order.status : 'Processing',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(order.createdAt.isNotEmpty ? order.createdAt : '—',
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
              if (order.estimatedDeliveryDate.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Est. delivery: ${order.estimatedDeliveryDate}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: Rs. ${_fmt(order.totalAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showRetry = false,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showRetry;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
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
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                    if (showRetry) ...[
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
                            borderRadius: BorderRadius.circular(14),
                          ),
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

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
