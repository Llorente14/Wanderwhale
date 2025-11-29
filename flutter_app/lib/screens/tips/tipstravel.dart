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
            'Siapkan pakaian multifungsi, obat pribadi, dan dokumen penting dalam satu tas. Pastikan semua barang penting mudah diakses saat perjalanan.',
        'icon': Icons.luggage,
      },
      {
        'title': 'Atur Itinerary',
        'description':
            'Susun jadwal fleksibel dengan jeda istirahat agar perjalanan lebih santai. Jangan terlalu padat agar bisa menikmati setiap momen.',
        'icon': Icons.calendar_today,
      },
      {
        'title': 'Gunakan Travel Insurance',
        'description':
            'Proteksi perjalananmu dari risiko keterlambatan, kehilangan bagasi, hingga kesehatan. Investasi kecil untuk ketenangan pikiran.',
        'icon': Icons.shield,
      },
      {
        'title': 'Simpan Dokumen Digital',
        'description':
            'Foto semua dokumen penting dan simpan di cloud storage. Ini akan sangat membantu jika dokumen fisik hilang atau tertinggal.',
        'icon': Icons.cloud_upload,
      },
      {
        'title': 'Pelajari Budaya Lokal',
        'description':
            'Pelajari adat istiadat dan bahasa dasar destinasi yang akan dikunjungi. Ini akan membuat perjalanan lebih menyenangkan dan menghormati budaya setempat.',
        'icon': Icons.language,
      },
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F6DC2), Color(0xFF0BC5EA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const _TipsHeader(),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    itemBuilder: (context, index) {
                      final tip = tips[index];
                      return _TipCard(
                        title: tip['title'] as String,
                        description: tip['description'] as String,
                        icon: tip['icon'] as IconData,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: tips.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER SECTION
// ============================================================================

class _TipsHeader extends StatelessWidget {
  const _TipsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Tips',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tips dan trik untuk perjalanan yang lebih baik',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TIP CARD
// ============================================================================

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Section
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight3,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          // Content Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gray4,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
