import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/booking_providers.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../screens/main/home_screen.dart';
import '../../services/api_service.dart';

// Import Widget Reusable
import '../../widgets/common/section_title.dart';
import '../../widgets/common/contact_info_tile.dart';
import '../../widgets/common/payment_option_card.dart';
import '../../widgets/common/promo_code_field.dart';

class CheckoutHotelScreen extends ConsumerStatefulWidget {
  const CheckoutHotelScreen({super.key});

  @override
  ConsumerState<CheckoutHotelScreen> createState() =>
      _CheckoutHotelScreenState();
}

class _CheckoutHotelScreenState extends ConsumerState<CheckoutHotelScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(hotelBookingProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final userAsync = ref.watch(userProvider);

    // Jika tidak ada booking data, redirect back
    if (bookingState.offer == null || bookingState.hotel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final offer = bookingState.offer!;
    final hotel = bookingState.hotel!;
    final dateFormat = DateFormat('dd MMM');

    // Get contact info from user or first guest
    final contactName =
        checkoutState.contactName ??
        (bookingState.guests.isNotEmpty
            ? '${bookingState.guests.first.firstName} ${bookingState.guests.first.lastName}'
            : '');
    final contactEmail =
        checkoutState.contactEmail ??
        (bookingState.guests.isNotEmpty ? bookingState.guests.first.email : '');
    final contactPhone =
        checkoutState.contactPhone ??
        (bookingState.guests.isNotEmpty ? bookingState.guests.first.phone : '');

    // Use user data if available
    final userContactName = userAsync.value?.displayName ?? contactName;
    final userContactEmail = userAsync.value?.email ?? contactEmail;
    final userContactPhone = userAsync.value?.phoneNumber ?? contactPhone;

    // Calculate duration
    final checkIn = bookingState.checkInDate ?? offer.checkInDate;
    final checkOut = bookingState.checkOutDate ?? offer.checkOutDate;
    final duration = checkIn != null && checkOut != null
        ? checkOut.difference(checkIn).inDays
        : 0;

    return Scaffold(
      backgroundColor: AppColors.gray0,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gray5),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text("Confirm & Pay", style: AppTextStyles.headingS),
            Text(
              "Step 2 of 3",
              style: AppTextStyles.baseXS.copyWith(color: AppColors.gray3),
            ),
          ],
        ),
      ),

      // BOTTOM BAR (Sticky)
      bottomNavigationBar: _buildBottomBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------
            // 1. HOTEL SUMMARY CARD (Spesifik Hotel)
            // ------------------------------------------
            const SectionTitle(title: "Your Trip"),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header Hotel
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: bookingState.imageUrl != null
                              ? Image.network(
                                  bookingState.imageUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.gray1,
                                      child: const Icon(
                                        Icons.hotel,
                                        color: AppColors.gray3,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 70,
                                  height: 70,
                                  color: AppColors.gray1,
                                  child: const Icon(
                                    Icons.hotel,
                                    color: AppColors.gray3,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                style: AppTextStyles.baseM.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hotel.address?.lines != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  hotel.address!.lines!,
                                  style: AppTextStyles.baseXS.copyWith(
                                    color: AppColors.gray3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 4),
                              if (hotel.rating != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      size: 14,
                                      color: AppColors.warning,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${hotel.rating!.toStringAsFixed(1)} Rating",
                                      style: AppTextStyles.baseXS.copyWith(
                                        color: AppColors.gray3,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const SizedBox.shrink(),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight3,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  offer.room?.type ??
                                      offer.room?.description ??
                                      "Room",
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.gray1),

                  // Check-in / Check-out
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildDateInfo(
                          "Check-in",
                          checkIn != null ? dateFormat.format(checkIn) : "N/A",
                          "14:00",
                        ),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.gray3,
                        ),
                        _buildDateInfo(
                          "Check-out",
                          checkOut != null
                              ? dateFormat.format(checkOut)
                              : "N/A",
                          "12:00",
                        ),
                        Container(height: 30, width: 1, color: AppColors.gray1),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Duration",
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.gray3,
                              ),
                            ),
                            Text(
                              "$duration Night${duration != 1 ? 's' : ''}",
                              style: AppTextStyles.baseS.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 2. CONTACT DETAILS (Widget Reusable)
            // ------------------------------------------
            const SectionTitle(title: "Contact Details"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ContactInfoTile(
                    label: "Full Name",
                    value: userContactName.isNotEmpty
                        ? userContactName
                        : "Not provided",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  ContactInfoTile(
                    label: "Email Address",
                    value: userContactEmail.isNotEmpty
                        ? userContactEmail
                        : "Not provided",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  ContactInfoTile(
                    label: "Phone Number",
                    value: userContactPhone?.isNotEmpty == true
                        ? userContactPhone!
                        : "Not provided",
                    icon: Icons.phone_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 3. PROMO CODE (Widget Reusable Baru!)
            // ------------------------------------------
            const SectionTitle(title: "Promo Code"),
            PromoCodeField(
              controller: _promoController,
              initialValue: checkoutState.promoCode,
              onApply: (code) {
                // Validasi: jika code kosong, jangan lakukan apa-apa
                if (code.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a promo code'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                  return;
                }

                // Apply promo code dan generate discount dalam satu operasi atomik
                final notifier = ref.read(checkoutProvider.notifier);
                notifier.applyPromoCode(code, bookingState.totalPrice);
                
                // Get updated state untuk menampilkan persentase diskon
                final updatedState = ref.read(checkoutProvider);
                final discountPercent = updatedState.getDiscountPercentage(bookingState.totalPrice);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Promo code applied! You got ${discountPercent.toStringAsFixed(0)}% discount'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 4. PRICE BREAKDOWN WITH DISCOUNT
            // ------------------------------------------
            const SectionTitle(title: "Price Summary"),
            _PriceBreakdownSection(
              originalPrice: bookingState.totalPrice,
              discountAmount: checkoutState.discountAmount,
              currency: offer.price.currency,
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 5. PAYMENT METHODS (Widget Reusable)
            // ------------------------------------------
            const SectionTitle(title: "Payment Method"),
            PaymentOptionCard(
              title: "Credit / Debit Card",
              subtitle: "Visa, Mastercard",
              icon: Icons.credit_card,
              isSelected: checkoutState.paymentMethod == "Credit / Debit Card",
              onTap: () => ref
                  .read(checkoutProvider.notifier)
                  .setPaymentMethod("Credit / Debit Card"),
            ),
            PaymentOptionCard(
              title: "E-Wallet",
              subtitle: "GoPay, OVO, ShopeePay",
              icon: Icons.account_balance_wallet,
              isSelected: checkoutState.paymentMethod == "E-Wallet",
              onTap: () => ref
                  .read(checkoutProvider.notifier)
                  .setPaymentMethod("E-Wallet"),
            ),
            PaymentOptionCard(
              title: "Bank Transfer",
              subtitle: "BCA, Mandiri, BRI",
              icon: Icons.account_balance,
              isSelected: checkoutState.paymentMethod == "Bank Transfer",
              onTap: () => ref
                  .read(checkoutProvider.notifier)
                  .setPaymentMethod("Bank Transfer"),
            ),
            PaymentOptionCard(
              title: "QRIS",
              subtitle: "Scan QR Code",
              icon: Icons.qr_code_scanner,
              isSelected: checkoutState.paymentMethod == "QRIS",
              onTap: () =>
                  ref.read(checkoutProvider.notifier).setPaymentMethod("QRIS"),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 5. CANCELLATION POLICY
            // ------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Free Cancellation",
                          style: AppTextStyles.baseS.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          "Cancel before 11 Dec to get a full refund.",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // --- LOCAL HELPER (Hanya dipakai di screen ini) ---

  Future<void> _handlePayment() async {
    final bookingState = ref.read(hotelBookingProvider);
    final checkoutState = ref.read(checkoutProvider);

    if (checkoutState.paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      // Calculate final price (dengan diskon jika ada)
      final finalPrice = checkoutState.getDiscountedPrice(bookingState.totalPrice);

      // Save transaction to state
      final hotel = bookingState.hotel!;
      final checkIn =
          bookingState.checkInDate ?? bookingState.offer!.checkInDate;
      final checkOut =
          bookingState.checkOutDate ?? bookingState.offer!.checkOutDate;
      final duration = checkIn != null && checkOut != null
          ? checkOut.difference(checkIn).inDays
          : 0;

      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'hotel',
        title: hotel.name,
        totalPrice: finalPrice, // Gunakan harga setelah diskon
        currency: bookingState.offer!.price.currency,
        paymentMethod: checkoutState.paymentMethod!,
        status: 'completed',
        createdAt: DateTime.now(),
        description: '$duration night(s) stay at ${hotel.name}${checkoutState.discountAmount > 0 ? ' (Discounted: ${checkoutState.discountAmount.toIDR()})' : ''}',
      );

      ref.read(transactionHistoryProvider.notifier).addTransaction(transaction);

      // Reset booking and checkout state
      ref.read(hotelBookingProvider.notifier).reset();
      ref.read(checkoutProvider.notifier).reset();

      if (!mounted) return;

      // Show success notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful! Your booking is confirmed.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a bit to ensure user sees the notification before navigation
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate back to home screen by popping screens
      // Pop checkout screen first
      Navigator.of(context).pop();
      
      // Wait a bit before popping booking details screen
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      
      // Pop booking details screen to return to HomeScreen
      // If we're already at HomeScreen, this will be a no-op
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (!mounted) return;
      final errorMessage = ApiService.getErrorMessage(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handlePayment(),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildBottomBar() {
    final bookingState = ref.watch(hotelBookingProvider);
    final checkoutState = ref.watch(checkoutProvider);

    final originalPrice = bookingState.totalPrice;
    final discountedPrice = checkoutState.getDiscountedPrice(originalPrice);
    final hasDiscount = checkoutState.discountAmount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Price",
                    style: AppTextStyles.baseXS.copyWith(
                      color: AppColors.gray3,
                    ),
                  ),
                  if (hasDiscount) ...[
                    // Harga sebelum diskon (dicoret)
                    Text(
                      originalPrice.toIDR(),
                      style: AppTextStyles.baseM.copyWith(
                        color: AppColors.gray3,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    // Harga setelah diskon
                    Text(
                      discountedPrice.toIDR(),
                      style: AppTextStyles.headingS.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    // Info diskon
                    Text(
                      'Save ${checkoutState.discountAmount.toIDR()}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ] else
                    Text(
                      originalPrice.toIDR(),
                      style: AppTextStyles.headingS.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: (_isProcessing || checkoutState.paymentMethod == null)
                  ? null
                  : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Pay Now",
                      style: AppTextStyles.baseM.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String date, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
        Text(
          date,
          style: AppTextStyles.baseS.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          time,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
      ],
    );
  }
}

// Price Breakdown Section with Discount
class _PriceBreakdownSection extends StatelessWidget {
  const _PriceBreakdownSection({
    required this.originalPrice,
    required this.discountAmount,
    required this.currency,
  });

  final double originalPrice;
  final double discountAmount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = discountAmount > 0;
    final finalPrice = hasDiscount ? (originalPrice - discountAmount) : originalPrice;
    final discountPercent = hasDiscount
        ? ((discountAmount / originalPrice) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gray1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: AppTextStyles.baseS.copyWith(
                  color: AppColors.gray4,
                ),
              ),
              Text(
                originalPrice.toIDR(),
                style: AppTextStyles.baseM.copyWith(
                  color: AppColors.gray5,
                ),
              ),
            ],
          ),
          if (hasDiscount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Promo Discount ($discountPercent%)',
                        style: AppTextStyles.baseS.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '-${discountAmount.toIDR()}',
                    style: AppTextStyles.baseM.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTextStyles.baseM.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray5,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount)
                    Text(
                      originalPrice.toIDR(),
                      style: AppTextStyles.baseS.copyWith(
                        color: AppColors.gray3,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  Text(
                    finalPrice.toIDR(),
                    style: AppTextStyles.headingM.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
