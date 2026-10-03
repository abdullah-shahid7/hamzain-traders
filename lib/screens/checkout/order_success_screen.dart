import 'package:flutter/material.dart';

import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/screens/main_shell.dart';
import 'package:hamzain_traders/screens/orders/order_details_screen.dart';
import 'package:hamzain_traders/screens/orders/receipt_screen.dart';
import 'package:hamzain_traders/widgets/thank_you_banner.dart';

/// Shown only after placeorder.php confirms the order was actually
/// created — never navigated to speculatively. Displays the real
/// returned order_number / total_amount.
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  final String orderNumber;
  final double totalAmount;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      body: PremiumScreenBackground(
      child: SafeArea(
        // A LayoutBuilder + ConstrainedBox(minHeight) + scroll view
        // replaces the previous Spacer()-based Column: Spacer() needs
        // a bounded height to flex within, so on any screen where the
        // content is taller than available space (a smaller device,
        // longer text, or — as happened here — an external element
        // like the bottom nav eating into that space) there was
        // nowhere for the overflow to go but the classic yellow/black
        // warning. This version centers content when there's room and
        // scrolls gracefully when there isn't, with no fixed-height
        // assumption at all.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.4, end: 1.0),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.elasticOut,
                      builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 10)),
                          ],
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 62),
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Order Placed!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Thank you for shopping with HamZainTraders.\nYour order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.78), height: 1.5),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 5)),
                      ]),
                      child: Column(
                        children: [
                          _InfoRow(label: 'Order Number', value: orderNumber.isNotEmpty ? '#$orderNumber' : '—'),
                          const SizedBox(height: 10),
                          _InfoRow(label: 'Total Amount', value: 'Rs. ${_fmt(totalAmount)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: orderId.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  PremiumPageRoute(page: OrderDetailsScreen(orderId: orderId)),
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('View Order', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: orderId.isEmpty
                            ? null
                            : () => Navigator.push(
                                  context,
                                  PremiumPageRoute(page: ReceiptScreen(orderId: orderId)),
                                ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 1.4),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('View Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                          PremiumPageRoute(page: const MainShell()),
                          (route) => false,
                        ),
                        style: TextButton.styleFrom(foregroundColor: Colors.white),
                        child: const Text('Continue Shopping', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const ThankYouBanner(),
                  ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
      ],
    );
  }
}

String _fmt(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(2);
}
