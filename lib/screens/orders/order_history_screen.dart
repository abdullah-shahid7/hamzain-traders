import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/models/order_model.dart';
import 'package:hamzain_traders/screens/orders/order_details_screen.dart';
import 'package:hamzain_traders/services/order_service.dart';
import 'package:hamzain_traders/services/session_service.dart';

/// Order History screen (existing screen, kept as-is in the Drawer),
/// now connected to real data via getorderhistory.php for the
/// current logged-in user.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderService = OrderService();
  Future<List<OrderModel>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    setState(() {
      _historyFuture = (user != null && user.id.isNotEmpty)
          ? _orderService.getOrderHistory(userId: user.id)
          : Future.error('Please log in to view your order history.');
    });
  }

  Future<void> _refresh() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    final future = (user != null && user.id.isNotEmpty)
        ? _orderService.getOrderHistory(userId: user.id)
        : Future<List<OrderModel>>.error(
            'Please log in to view your order history.');
    setState(() {
      _historyFuture = future;
    });
    await future.catchError((_) => <OrderModel>[]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Order History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
        child: _historyFuture == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: FutureBuilder<List<OrderModel>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary),
                      );
                    }
                    if (snapshot.hasError) {
                      return _buildMessage(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load order history',
                        subtitle: snapshot.error
                            .toString()
                            .replaceFirst('Exception: ', ''),
                        showRetry: true,
                      );
                    }
                    final history = snapshot.data ?? const <OrderModel>[];
                    if (history.isEmpty) {
                      return _buildMessage(
                        icon: Icons.history_rounded,
                        title: 'No order history found',
                        subtitle:
                            'Your completed and past orders will show up here',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(20),
                      physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics()),
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = history[index];
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => Navigator.push(
                              context,
                              PremiumPageRoute(
                                  page: OrderDetailsScreen(orderId: order.id)),
                            ),
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: AppColors.primary,
                                        size: 20),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          order.orderNumber.isNotEmpty
                                              ? '#${order.orderNumber}'
                                              : 'Order',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryDark),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          order.createdAt.isNotEmpty
                                              ? order.createdAt
                                              : '—',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          order.status.isNotEmpty
                                              ? order.status
                                              : '',
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rs. ${_fmt(order.totalAmount)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                      Icon(Icons.chevron_right_rounded,
                                          color: Colors.grey.shade400,
                                          size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showRetry = false,
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
