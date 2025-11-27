// lib/widgets/home/home_header.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/providers.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        children: [
          // Profile Picture
          userAsync.when(
            data: (user) => GestureDetector(
              onTap: () {
                // Navigate to profile
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: ClipOval(
                  child: user.photoURL != null
                      ? CachedNetworkImage(
                          imageUrl: user.photoURL!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.gray1,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: Center(
                              child: Text(
                                user.initials,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Text(
                              user.initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
            loading: () => const CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.gray1,
            ),
            error: (err, stack) => const CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.gray1,
              child: Icon(Icons.person, color: AppColors.gray3),
            ),
          ),

          const SizedBox(width: 12),

          // Location Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Lokasi',
                  style: TextStyle(fontSize: 12, color: AppColors.gray3),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment
                      .center, // Item diatur ke tengah secara horizontal
                  mainAxisSize: MainAxisSize
                      .min, // Row hanya mengambil space yang dibutuhkan
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    locationAsync.when(
                      data: (locationText) => Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        'Mencari lokasi...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      error: (_, __) => const Text(
                        'Lokasi tidak tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Notification Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gray1, width: 1.5),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              color: AppColors.gray5,
              onPressed: () {
                // Navigate to notifications
              },
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
