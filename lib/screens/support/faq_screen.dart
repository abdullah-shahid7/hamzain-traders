import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';

enum FaqCategory { general, orders, payments, account }

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key, required this.category});

  final FaqCategory category;

  String get _title {
    switch (category) {
      case FaqCategory.general:
        return 'FAQs';
      case FaqCategory.orders:
        return 'Order Help';
      case FaqCategory.payments:
        return 'Payment Help';
      case FaqCategory.account:
        return 'Account Help';
    }
  }

  List<MapEntry<String, String>> get _items {
    switch (category) {
      case FaqCategory.general:
        return const [
          MapEntry('How do I place an order?',
              'Browse a brand, add products to your cart, and complete checkout from the cart screen.'),
          MapEntry('Can I change my order after placing it?',
              'Contact support as soon as possible after placing an order — changes may not be possible once processing begins.'),
        ];
      case FaqCategory.orders:
        return const [
          MapEntry('How do I track my order?',
              'Open My Orders from the menu to see the current status of each order.'),
          MapEntry('What if my order is delayed?',
              'Reach out via Contact Support with your order number and our team will look into it.'),
        ];
      case FaqCategory.payments:
        return const [
          MapEntry('What payment methods are supported?',
              'Cash on Delivery is available now. PayPal, Apple Pay, and Google Pay are shown as upcoming options.'),
          MapEntry('Is Cash on Delivery available everywhere?',
              'Availability may vary by location — this will be confirmed at checkout.'),
        ];
      case FaqCategory.account:
        return const [
          MapEntry('How do I update my profile information?',
              'Go to My Profile from the menu to view your account details.'),
          MapEntry('I forgot my password, what do I do?',
              'Use the password reset option on the login screen, or contact support for help.'),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _FaqTile(question: item.key, answer: item.value);
        },
      ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                      fontSize: 14.5,
                    ),
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
            Text(
              widget.answer,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
