import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/discount_providers.dart';
import 'discount_detail_page.dart';

class DiscountPage extends ConsumerWidget {
  const DiscountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Simulasi data - dalam implementasi nyata, ini akan dari provider/API
    final discounts = [
      {
        'id': '1',
        'title': 'Diskon Hotel Hingga 40%',
        'code': 'STAYCOZY40',
        'description': 'Berlaku untuk minimal 2 malam di seluruh Asia Tenggara.',
        'image': 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
        'discountPercentage': 40.0,
        'discountType': 'hotel',
      },
      {
        'id': '2',
        'title': 'Flash Sale Penerbangan',
        'code': 'FLYFAST25',
        'description': 'Promo akhir pekan untuk rute domestik pilihan.',
        'image': 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
        'discountPercentage': 25.0,
        'discountType': 'flight',
      },
      {
        'id': '3',
        'title': 'Voucher Aktivitas 15%',
        'code': 'FUNTRIP15',
        'description': 'Nikmati tur lokal, kuliner, hingga tiket atraksi.',
        'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
        'discountPercentage': 15.0,
        'discountType': 'activity',
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
              const _DiscountHeader(),
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
                      final item = discounts[index];
                      final discountId = item['id'] as String;
                      return _DiscountCard(
                        id: discountId,
                        title: item['title'] as String,
                        code: item['code'] as String,
                        description: item['description'] as String,
                        imageUrl: item['image'] as String,
                        discountPercentage: item['discountPercentage'] as double,
                        discountType: item['discountType'] as String?,
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: discounts.length,
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

class _DiscountHeader extends StatelessWidget {
  const _DiscountHeader();

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
                  'Diskon & Voucher',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Dapatkan penawaran terbaik untuk perjalananmu',
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
// DISCOUNT CARD
// ============================================================================

class _DiscountCard extends ConsumerWidget {
  const _DiscountCard({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.imageUrl,
    required this.discountPercentage,
    this.discountType,
  });

  final String id;
  final String title;
  final String code;
  final String description;
  final String imageUrl;
  final double discountPercentage;
  final String? discountType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch claimed state - akan auto update ketika state berubah
    final isClaimed = ref.watch(isDiscountClaimedProvider(id));

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DiscountDetailPage(
              id: id,
              title: title,
              code: code,
              description: description,
              imageUrl: imageUrl,
              isClaimed: isClaimed,
              discountPercentage: discountPercentage,
              discountType: discountType,
            ),
          ),
        ).then((_) {
          // Refresh state setelah kembali dari detail page
          // State sudah auto update karena menggunakan watch, tapi kita bisa force rebuild
          ref.invalidate(isDiscountClaimedProvider(id));
        });
      },
      child: Container(
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
          children: [
            // Image Section
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: 120,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 120,
                      height: 140,
                      color: AppColors.primaryLight3,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primary,
                        size: 32,
                      ),
                    ),
                  ),
                  // Gradient overlay untuk readability
                  Container(
                    width: 120,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Code and Icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight3,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark1,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray5,
                                  letterSpacing: -0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Discount Icon with Yellow Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight3,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.local_offer,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            // Yellow badge indicator jika sudah claimed - AUTO UPDATE
                            if (isClaimed)
                              Positioned(
                                top: -4,
                                right: -4,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(
                                      BorderSide(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Description
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.gray4,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Bottom: Button
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DiscountDetailPage(
                                id: id,
                                title: title,
                                code: code,
                                description: description,
                                imageUrl: imageUrl,
                                isClaimed: isClaimed,
                                discountPercentage: discountPercentage,
                                discountType: discountType,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lihat Detail',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
