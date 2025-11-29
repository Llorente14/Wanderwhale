// ============================================================================
// DISCOUNT HELPER UTILITIES
// ============================================================================

/// Helper class untuk menghitung discount dan price
class DiscountHelper {
  /// Calculate discount amount from original price
  static double calculateDiscountAmount({
    required double originalPrice,
    required double discountPercentage,
  }) {
    return originalPrice * (discountPercentage / 100);
  }

  /// Calculate final price after discount
  static double calculateFinalPrice({
    required double originalPrice,
    required double discountPercentage,
  }) {
    final discountAmount = calculateDiscountAmount(
      originalPrice: originalPrice,
      discountPercentage: discountPercentage,
    );
    return originalPrice - discountAmount;
  }

  /// Format discount percentage untuk display
  static String formatDiscountPercentage(double percentage) {
    return '${percentage.toInt()}%';
  }

  /// Format currency untuk display
  static String formatCurrency(double amount, {String symbol = 'Rp'}) {
    return '$symbol ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}';
  }
}

// ============================================================================
// EXAMPLE: How to use discount in checkout/payment
// ============================================================================

/*
// Contoh penggunaan di checkout/payment page:

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/discount_providers.dart';
import '../utils/discount_helper.dart';

class CheckoutPage extends ConsumerWidget {
  final double originalPrice = 1000000; // Harga asli

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get selected discount
    final selectedDiscount = ref.watch(selectedDiscountProvider);
    
    // Calculate final price
    final finalPrice = ref.watch(
      priceWithDiscountProvider(originalPrice),
    );
    
    // Atau manual calculation:
    double finalPriceManual = originalPrice;
    if (selectedDiscount != null) {
      finalPriceManual = selectedDiscount.calculateFinalPrice(originalPrice);
    }

    return Scaffold(
      body: Column(
        children: [
          // Display original price
          Text('Harga: ${DiscountHelper.formatCurrency(originalPrice)}'),
          
          // Display discount if selected
          if (selectedDiscount != null) ...[
            Text('Diskon: ${selectedDiscount.discountPercentage}%'),
            Text('Potongan: ${DiscountHelper.formatCurrency(
              DiscountHelper.calculateDiscountAmount(
                originalPrice: originalPrice,
                discountPercentage: selectedDiscount.discountPercentage,
              ),
            )}'),
          ],
          
          // Display final price
          Text('Total: ${DiscountHelper.formatCurrency(finalPrice)}'),
          
          // Button to select discount
          ElevatedButton(
            onPressed: () {
              // Navigate to discount selection page
              // Set selected discount:
              ref.read(selectedDiscountProvider.notifier).state = discountModel;
            },
            child: Text('Pilih Voucher'),
          ),
        ],
      ),
    );
  }
}
*/

