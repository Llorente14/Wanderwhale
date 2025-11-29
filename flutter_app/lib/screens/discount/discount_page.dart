import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class DiscountPage extends StatelessWidget {
  const DiscountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final discounts = [
      {
        'title': 'Diskon Hotel Hingga 40%',
        'code': 'STAYCOZY40',
        'description': 'Berlaku untuk minimal 2 malam di seluruh Asia Tenggara.',
      },
      {
        'title': 'Flash Sale Penerbangan',
        'code': 'FLYFAST25',
        'description': 'Promo akhir pekan untuk rute domestik pilihan.',
      },
      {
        'title': 'Voucher Aktivitas 15%',
        'code': 'FUNTRIP15',
        'description': 'Nikmati tur lokal, kuliner, hingga tiket atraksi.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diskon & Voucher'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final item = discounts[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item['description']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray4,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight3,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['code']!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark1,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: Integrate with global discount claim state (e.g., DiscountClaimNotifier).
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Voucher ${item['code']} siap dipakai!'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Claim'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: discounts.length,
      ),
    );
  }
}

