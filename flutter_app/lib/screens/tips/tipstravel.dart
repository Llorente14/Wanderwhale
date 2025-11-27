import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TipsTravelPage extends StatelessWidget {
  const TipsTravelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tips = [
      {
        'title': 'Packing Essentials',
        'description':
            'Siapkan pakaian multifungsi, obat pribadi, dan dokumen penting dalam satu tas.',
      },
      {
        'title': 'Atur Itinerary',
        'description':
            'Susun jadwal fleksibel dengan jeda istirahat agar perjalanan lebih santai.',
      },
      {
        'title': 'Gunakan Travel Insurance',
        'description':
            'Proteksi perjalananmu dari risiko keterlambatan, kehilangan bagasi, hingga kesehatan.',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel Tips'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemBuilder: (context, index) {
          final tip = tips[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                  tip['title']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tip['description']!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.gray4,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: tips.length,
      ),
    );
  }
}

