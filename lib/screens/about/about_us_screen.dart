// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:hamzain_traders/core/constants/app_colors.dart';
import 'package:hamzain_traders/core/widgets/premium_screen_background.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      const _ProductCategory(
        icon: Icons.pest_control_outlined,
        title: 'Lizard Killer & Pest Control',
        description:
            'Effective solutions for lizards, bed bugs, and mosquitoes to keep your home pest-free.',
      ),
      const _ProductCategory(
        icon: Icons.bug_report_outlined,
        title: 'Bed Bug & Mosquito Products',
        description:
            'Reliable products designed to tackle common household pest problems.',
      ),
      const _ProductCategory(
        icon: Icons.handyman_outlined,
        title: 'Woodcut Pro',
        description:
            'Professional-grade tools and solutions for woodcutting needs.',
      ),
      const _ProductCategory(
        icon: Icons.local_drink_outlined,
        title: 'Modern Tumblers',
        description:
            'Stylish, modern tumblers built for everyday use and durability.',
      ),
      const _ProductCategory(
        icon: Icons.eco_outlined,
        title: 'Doctor Organic',
        description:
            'Organic personal care products, including baby shampoo, made with care.',
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bgDeep,
      appBar: AppBar(
        title: const Text('About Us'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: PremiumScreenBackground(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hum Zen Traders',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Hum Zen Traders brings together a curated range of '
                  'household, personal care, and lifestyle brands — from '
                  'pest control to organic care products — under one '
                  'trusted, easy-to-shop platform.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Our Product Categories',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...categories.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(c.icon, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(c.description,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: Colors.grey.shade600,
                                  height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
      ),
    );
  }
}

class _ProductCategory {
  final IconData icon;
  final String title;
  final String description;

  const _ProductCategory({
    required this.icon,
    required this.title,
    required this.description,
  });
}
