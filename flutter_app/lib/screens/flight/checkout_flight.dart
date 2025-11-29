import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/booking_providers.dart';
import '../../providers/checkout_provider.dart';
import '../../providers/app_providers.dart';
import '../../utils/formatters.dart';
import '../../screens/main/home_screen.dart';
import '../../services/api_service.dart';

// Import Widget Reusable (Common)
import '../../widgets/common/section_title.dart';
import '../../widgets/common/contact_info_tile.dart';
import '../../widgets/common/payment_option_card.dart';
import '../../widgets/common/promo_code_field.dart';

// Import Widget Khusus Flight
import '../../widgets/flight/flight_ticket_card.dart';

class CheckoutFlightScreen extends ConsumerStatefulWidget {
  const CheckoutFlightScreen({super.key});

  @override
  ConsumerState<CheckoutFlightScreen> createState() =>
      _CheckoutFlightScreenState();
}

class _CheckoutFlightScreenState extends ConsumerState<CheckoutFlightScreen> {
  final TextEditingController _promoController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(flightBookingProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final userAsync = ref.watch(userProvider);

    // Jika tidak ada booking data, redirect back
    if (bookingState.offer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pop(context);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final offer = bookingState.offer!;
    final firstSegment = offer.itineraries.first.segments.first;
    final lastSegment = offer.itineraries.last.segments.last;
    final origin = firstSegment.departure.iataCode;
    final destination = lastSegment.arrival.iataCode;
    final departureTime = firstSegment.departure.at;
    final arrivalTime = lastSegment.arrival.at;
    
    // Get passenger name from first passenger
    final primaryPassenger = bookingState.passengers.isNotEmpty
        ? bookingState.passengers.first
        : null;
    final passengerName = primaryPassenger != null
        ? '${primaryPassenger.firstName} ${primaryPassenger.lastName}'.trim()
        : '';

    // Get contact info from user or first passenger
    final contactName = checkoutState.contactName ??
        (bookingState.passengers.isNotEmpty
            ? '${bookingState.passengers.first.firstName} ${bookingState.passengers.first.lastName}'
            : '');
    final contactEmail = checkoutState.contactEmail ??
        (bookingState.passengers.isNotEmpty
            ? bookingState.passengers.first.email
            : '');
    final contactPhone = checkoutState.contactPhone ??
        (bookingState.passengers.isNotEmpty
            ? bookingState.passengers.first.phone
            : '');

    // Use user data if available
    final userContactName = userAsync.value?.displayName ?? contactName;
    final userContactEmail = userAsync.value?.email ?? contactEmail;
    final userContactPhone = userAsync.value?.phoneNumber ?? contactPhone;

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
            const Text("Flight Checkout", style: AppTextStyles.headingS),
            Text(
              "Step 2 of 3",
              style: AppTextStyles.baseXS.copyWith(color: AppColors.gray3),
            ),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomBar(),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TICKET CARD (Widget Terpisah)
            const SectionTitle(title: "Your Ticket"),
            FlightTicketCard(
              offer: offer,
              origin: origin,
              destination: destination,
              departureTime: departureTime,
              arrivalTime: arrivalTime,
              passengerName: passengerName.isNotEmpty ? passengerName : contactName,
            ),

            const SizedBox(height: 25),

            // 2. CONTACT DETAILS (Widget Reusable)
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

            // 3. PROMO CODE (Widget Reusable)
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

            // 4. PRICE BREAKDOWN WITH DISCOUNT
            const SectionTitle(title: "Price Summary"),
            _PriceBreakdownSection(
              originalPrice: bookingState.totalPrice,
              discountAmount: checkoutState.discountAmount,
              currency: offer.price.currency,
            ),

            const SizedBox(height: 25),

            // 5. PAYMENT (Widget Reusable)
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayment() async {
    final bookingState = ref.read(flightBookingProvider);
    final checkoutState = ref.read(checkoutProvider);

    if (checkoutState.paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
        ),
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
      final transaction = Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'flight',
        title: '${bookingState.offer!.itineraries.first.segments.first.departure.iataCode} → ${bookingState.offer!.itineraries.last.segments.last.arrival.iataCode}',
        totalPrice: finalPrice, // Gunakan harga setelah diskon
        currency: bookingState.offer!.price.currency,
        paymentMethod: checkoutState.paymentMethod!,
        status: 'completed',
        createdAt: DateTime.now(),
        description: 'Flight booking for ${bookingState.passengerCount} passenger(s)${checkoutState.discountAmount > 0 ? ' (Discounted: ${checkoutState.discountAmount.toIDR()})' : ''}',
      );

      ref.read(transactionHistoryProvider.notifier).addTransaction(transaction);

      // Reset booking and checkout state
      ref.read(flightBookingProvider.notifier).reset();
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
    final bookingState = ref.watch(flightBookingProvider);
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
