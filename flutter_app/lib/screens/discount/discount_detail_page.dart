import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/discount_providers.dart';

class DiscountDetailPage extends ConsumerStatefulWidget {
  const DiscountDetailPage({
    super.key,
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.imageUrl,
    required this.isClaimed,
    this.discountPercentage,
    this.discountType,
  });

  final String id;
  final String title;
  final String code;
  final String description;
  final String imageUrl;
  final bool isClaimed;
  final double? discountPercentage;
  final String? discountType;

  @override
  ConsumerState<DiscountDetailPage> createState() => _DiscountDetailPageState();
}

class _DiscountDetailPageState extends ConsumerState<DiscountDetailPage> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize claimed state from provider
    final currentState = ref.read(discountStateProvider);
    if (currentState[widget.id] == true) {
      // Already claimed, no need to update
    }

    // Add scroll listener
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleClaim() {
    // Update provider state
    ref.read(discountStateProvider.notifier).claimDiscount(widget.id);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher ${widget.code} berhasil diklaim!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isClaimed = ref.watch(isDiscountClaimedProvider(widget.id));

    // Calculate border radius based on scroll offset
    final borderRadius = (_scrollOffset / 100 * 28).clamp(0.0, 28.0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
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
      ),
      body: Stack(
        children: [
          // Image Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 300,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryLight3,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // Spacer to push content below image
                  const SizedBox(height: 260),
                  // Content Section with dynamic rounded top
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(borderRadius),
                        topRight: Radius.circular(borderRadius),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Code Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight3,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.code,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark1,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray5,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Description
                          Text(
                            widget.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.gray4,
                              fontWeight: FontWeight.w400,
                              height: 1.5,
                            ),
                          ),
                          if (widget.discountPercentage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight3,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.percent,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Diskon',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray4,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${widget.discountPercentage!.toInt()}%',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryDark1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 32),
                          // Divider
                          Divider(color: AppColors.gray1, thickness: 1),
                          const SizedBox(height: 32),
                          // Terms & Conditions
                          const Text(
                            'Syarat & Ketentuan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTermItem(
                            'Voucher berlaku untuk pemesanan baru',
                          ),
                          _buildTermItem(
                            'Tidak dapat digabungkan dengan promo lain',
                          ),
                          _buildTermItem('Berlaku hingga tanggal yang tertera'),
                          _buildTermItem(
                            'Syarat dan ketentuan dapat berubah sewaktu-waktu',
                          ),
                          const SizedBox(height: 40),
                          // Claim Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isClaimed ? null : _handleClaim,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isClaimed
                                    ? AppColors.gray2
                                    : AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: isClaimed ? 0 : 4,
                              ),
                              child: Text(
                                isClaimed
                                    ? 'Voucher Sudah Diklaim'
                                    : 'Klaim Voucher',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray4,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
