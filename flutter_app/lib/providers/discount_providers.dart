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

// ============================================================================
// MOCK DATA
// ============================================================================

final List<DiscountModel> mockDiscounts = [
  DiscountModel(
    id: '1',
    title: 'Diskon Hotel Hingga 40%',
    code: 'STAYCOZY40',
    description: 'Berlaku untuk minimal 2 malam di seluruh Asia Tenggara.',
    imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',
    discountPercentage: 40.0,
    discountType: 'hotel',
  ),
  DiscountModel(
    id: '2',
    title: 'Flash Sale Penerbangan',
    code: 'FLYFAST25',
    description: 'Promo akhir pekan untuk rute domestik pilihan.',
    imageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800&q=80',
    discountPercentage: 25.0,
    discountType: 'flight',
  ),
  DiscountModel(
    id: '3',
    title: 'Voucher Aktivitas 15%',
    code: 'FUNTRIP15',
    description: 'Nikmati tur lokal, kuliner, hingga tiket atraksi.',
    imageUrl: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&q=80',
    discountPercentage: 15.0,
    discountType: 'activity',
  ),
];

final availableDiscountsProvider = Provider<List<DiscountModel>>((ref) {
  return mockDiscounts;
});
