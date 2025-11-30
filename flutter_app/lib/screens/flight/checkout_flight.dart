import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../providers/booking_providers.dart';
import '../../utils/formatters.dart';

// Import Widget Reusable (Common)
import '../../widgets/common/section_title.dart';
import '../../widgets/common/contact_info_tile.dart';
import '../../widgets/common/payment_option_card.dart';
import '../../widgets/common/promo_code_field.dart'; // Widget Promo yang tadi kita buat

// Import Widget Khusus Flight
import '../../widgets/flight/flight_ticket_card.dart';

class CheckoutFlightScreen extends ConsumerStatefulWidget {
  const CheckoutFlightScreen({super.key});

  @override
  ConsumerState<CheckoutFlightScreen> createState() => _CheckoutFlightScreenState();
}

class _CheckoutFlightScreenState extends ConsumerState<CheckoutFlightScreen> {
  int _selectedPaymentIndex = 0;
  final TextEditingController _promoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(flightBookingProvider);
    final firstPassenger = bookingState.passengers.isNotEmpty 
        ? bookingState.passengers.first 
        : null;
    
    final fullName = firstPassenger != null 
        ? '${firstPassenger.firstName} ${firstPassenger.lastName}'
        : 'N/A';
    final email = firstPassenger?.email ?? 'N/A';
    final phone = firstPassenger?.phone ?? 'N/A';
    final totalPrice = bookingState.totalPrice.toIDR();

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

      bottomNavigationBar: _buildBottomBar(totalPrice),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TICKET CARD (Widget Terpisah)
            const SectionTitle(title: "Your Ticket"),
            const FlightTicketCard(),

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
                    value: fullName,
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  ContactInfoTile(
                    label: "Email Address",
                    value: email,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  ContactInfoTile(
                    label: "Phone Number",
                    value: phone,
                    icon: Icons.phone_outlined,
                  ),
                  if (firstPassenger?.dateOfBirth != null) ...[
                    const SizedBox(height: 15),
                    ContactInfoTile(
                      label: "Date of Birth",
                      value: DateFormat('dd MMM yyyy').format(firstPassenger!.dateOfBirth!),
                      icon: Icons.cake_outlined,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 3. PROMO CODE (Widget Reusable)
            const SectionTitle(title: "Promo Code"),
            PromoCodeField(
              controller: _promoController,
              onApply: () {
                // Logika Apply Promo
              },
            ),

            const SizedBox(height: 25),

            // 4. PAYMENT (Widget Reusable)
            const SectionTitle(title: "Payment Method"),
            PaymentOptionCard(
              title: "Credit / Debit Card",
              subtitle: "Visa, Mastercard",
              icon: Icons.credit_card,
              isSelected: _selectedPaymentIndex == 0,
              onTap: () => setState(() => _selectedPaymentIndex = 0),
            ),
            PaymentOptionCard(
              title: "E-Wallet",
              subtitle: "GoPay, OVO, ShopeePay",
              icon: Icons.account_balance_wallet,
              isSelected: _selectedPaymentIndex == 1,
              onTap: () => setState(() => _selectedPaymentIndex = 1),
            ),
            PaymentOptionCard(
              title: "Bank Transfer",
              subtitle: "BCA, Mandiri, BRI",
              icon: Icons.account_balance,
              isSelected: _selectedPaymentIndex == 2,
              onTap: () => setState(() => _selectedPaymentIndex = 2),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(String totalPrice) {
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
                  Text(
                    totalPrice,
                    style: AppTextStyles.headingS.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Processing Flight Payment...")),
                );
              },
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
              child: Text(
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
