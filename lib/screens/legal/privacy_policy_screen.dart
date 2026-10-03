import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      const _PolicySection(
        title: 'Information We Collect',
        body:
            'We collect information you provide directly, such as your full name, '
            'email address, phone number, and delivery address, in order to create '
            'and manage your account and process your orders.',
      ),
      const _PolicySection(
        title: 'Order and Payment Information',
        body:
            'When you place an order, we collect order details and, where applicable, '
            'payment method preferences. Sensitive payment credentials are handled by '
            'the relevant payment provider and are not stored directly within the app '
            'unless explicitly required for the payment method you choose.',
      ),
      const _PolicySection(
        title: 'How We Use Your Data',
        body:
            'Your information is used to process orders, manage your account, provide '
            'customer support, and improve the overall shopping experience within the app.',
      ),
      const _PolicySection(
        title: 'Data Protection',
        body:
            'We take reasonable measures to protect your personal information from '
            'unauthorized access, alteration, disclosure, or destruction.',
      ),
      const _PolicySection(
        title: 'Third-Party Services',
        body:
            'Certain features, such as payment processing, may involve trusted third-party '
            'services. These providers only receive the information necessary to perform '
            'their specific function.',
      ),
      const _PolicySection(
        title: 'Changes to This Policy',
        body:
            'This Privacy Policy may be updated from time to time. Continued use of the '
            'app after changes are made constitutes acceptance of the updated policy.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: sections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final section = sections[index];
          return Container(
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
                Text(section.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        fontSize: 14.5)),
                const SizedBox(height: 8),
                Text(section.body,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade700,
                        height: 1.5)),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _PolicySection {
  final String title;
  final String body;

  const _PolicySection({required this.title, required this.body});
}
