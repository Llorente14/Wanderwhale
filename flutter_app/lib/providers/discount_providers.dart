import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================================
// DISCOUNT MODEL
// ============================================================================

class DiscountModel {
  final String id;
  final String title;
  final String code;
  final String description;
  final String imageUrl;
  final double discountPercentage; // Percentage discount (e.g., 40 for 40%)
  final String? discountType; // 'hotel', 'flight', 'activity', etc.
  final DateTime? validUntil;

  DiscountModel({
    required this.id,
    required this.title,
    required this.code,
    required this.description,
    required this.imageUrl,
    required this.discountPercentage,
    this.discountType,
    this.validUntil,
  });

  // Calculate discount amount from original price
  double calculateDiscount(double originalPrice) {
    return originalPrice * (discountPercentage / 100);
  }

  // Calculate final price after discount
  double calculateFinalPrice(double originalPrice) {
    return originalPrice - calculateDiscount(originalPrice);
  }
}

// ============================================================================
// DISCOUNT STATE NOTIFIER
// ============================================================================

class DiscountStateNotifier extends StateNotifier<Map<String, bool>> {
  DiscountStateNotifier() : super({});

  // Claim a discount
  void claimDiscount(String discountId) {
    state = {...state, discountId: true};
  }

  // Check if discount is claimed
  bool isClaimed(String discountId) {
    return state[discountId] ?? false;
  }

  // Get claimed discount codes
  List<String> getClaimedDiscountIds() {
    return state.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final discountStateProvider =
    StateNotifierProvider<DiscountStateNotifier, Map<String, bool>>((ref) {
  return DiscountStateNotifier();
});

// Provider untuk check apakah discount sudah di-claim
final isDiscountClaimedProvider = Provider.family<bool, String>((ref, discountId) {
  final state = ref.watch(discountStateProvider);
  return state[discountId] ?? false;
});

// Provider untuk selected discount (yang sedang digunakan di checkout)
final selectedDiscountProvider = StateProvider<DiscountModel?>((ref) => null);

// Provider untuk calculate price dengan discount
final priceWithDiscountProvider = Provider.family<double, double>((ref, originalPrice) {
  final selectedDiscount = ref.watch(selectedDiscountProvider);
  if (selectedDiscount == null) {
    return originalPrice;
  }
  return selectedDiscount.calculateFinalPrice(originalPrice);
});

