import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';
import 'package:hamzain_traders/core/navigation/premium_page_route.dart';
import 'package:hamzain_traders/screens/support/faq_screen.dart';
import 'package:hamzain_traders/screens/support/contact_support_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      _SupportSection(
        icon: Icons.help_outline_rounded,
        title: 'Frequently Asked Questions',
        subtitle: 'Quick answers to common questions',
        onTap: () => Navigator.of(context).push(
          PremiumPageRoute(
              page: const FaqScreen(category: FaqCategory.general)),
        ),
      ),
      _SupportSection(
        icon: Icons.shopping_bag_outlined,
        title: 'Order-related Help',
        subtitle: 'Tracking, delays, and order issues',
        onTap: () => Navigator.of(context).push(
          PremiumPageRoute(page: const FaqScreen(category: FaqCategory.orders)),
        ),
      ),
      _SupportSection(
        icon: Icons.payments_outlined,
        title: 'Payment-related Help',
        subtitle: 'Payment methods and billing questions',
        onTap: () => Navigator.of(context).push(
          PremiumPageRoute(
              page: const FaqScreen(category: FaqCategory.payments)),
        ),
      ),
      _SupportSection(
        icon: Icons.person_outline_rounded,
        title: 'Account-related Help',
        subtitle: 'Profile, login, and account settings',
        onTap: () => Navigator.of(context).push(
          PremiumPageRoute(
              page: const FaqScreen(category: FaqCategory.account)),
        ),
      ),
      _SupportSection(
        icon: Icons.support_agent_rounded,
        title: 'Contact Support',
        subtitle: 'Reach out to our team directly',
        onTap: () => Navigator.of(context).push(
          PremiumPageRoute(page: const ContactSupportScreen()),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Help and Support'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => sections[index],
      ),
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          fontSize: 14.5)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
