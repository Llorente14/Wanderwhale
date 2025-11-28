import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';
import '../../models/destination_master_model.dart';

/// Card destinasi populer untuk ditampilkan sebagai carousel di homepage.
class PopularDestinationCard extends ConsumerWidget {
  const PopularDestinationCard({
    super.key,
    required this.destination,
  });

  final DestinationMasterModel destination;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync =
        ref.watch(wishlistStatusProvider(destination.destinationId));

    return SizedBox(
      width: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Gambar destinasi
            CachedNetworkImage(
              imageUrl: destination.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AppColors.gray1,
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.gray2,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.white,
                ),
              ),
            ),
            // Gradient gelap di bagian bawah
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
              ),
            ),
            // Konten teks + icon
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nama destinasi di dalam pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            destination.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gray5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              destination.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  wishlistAsync.when(
                    data: (isWishlisted) {
                      return Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 18,
                          icon: Icon(
                            isWishlisted
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: AppColors.error,
                          ),
                          onPressed: () async {
                            final api = ref.read(apiServiceProvider);
                            try {
                              await api
                                  .toggleWishlist(destination.destinationId);
                              // Refresh status setelah toggle
                              ref.invalidate(wishlistStatusProvider(
                                  destination.destinationId));
                            } on DioException catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.response?.data['message'] ??
                                        'Gagal mengubah wishlist',
                                  ),
                                ),
                              );
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Gagal mengubah wishlist'),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                    loading: () => const SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    error: (_, __) => Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(
                          Icons.favorite_border,
                          color: AppColors.error,
                        ),
                        onPressed: () async {
                          final api = ref.read(apiServiceProvider);
                          try {
                            await api
                                .toggleWishlist(destination.destinationId);
                            ref.invalidate(wishlistStatusProvider(
                                destination.destinationId));
                          } catch (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengubah wishlist'),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


