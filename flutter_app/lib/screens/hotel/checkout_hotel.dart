import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

// Import Widget Reusable
import '../../widgets/common/section_title.dart';
import '../../widgets/common/contact_info_tile.dart';
import '../../widgets/common/payment_option_card.dart';
import '../../widgets/common/promo_code_field.dart'; // <--- Widget Promo

class CheckoutHotelScreen extends StatefulWidget {
  const CheckoutHotelScreen({super.key});

  @override
  State<CheckoutHotelScreen> createState() => _CheckoutHotelScreenState();
}

class _CheckoutHotelScreenState extends State<CheckoutHotelScreen> {
  int _selectedPaymentIndex = 0;
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                          child: Image.asset(
                            'assets/images/destination_1.jpg',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hotel Borobudur",
                                style: AppTextStyles.baseM.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    size: 14,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "4.8 (2.3k Reviews)",
                                    style: AppTextStyles.baseXS.copyWith(
                                      color: AppColors.gray3,
                                    ),
                                  ),
                                ],
                              ),
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
                                  "Superior Twin Bed",
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
                        _buildDateInfo("Check-in", "12 Dec", "14:00"),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: AppColors.gray3,
                        ),
                        _buildDateInfo("Check-out", "14 Dec", "12:00"),
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
                              "2 Nights",
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
                  const ContactInfoTile(
                    label: "Full Name",
                    value: "John Doe",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  const ContactInfoTile(
                    label: "Email Address",
                    value: "john.doe@gmail.com",
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  const ContactInfoTile(
                    label: "Phone Number",
                    value: "+62 812 3456 7890",
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
              onApply: () {
                // Logika cek promo hotel disini
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Checking Hotel Promo...")),
                );
              },
            ),

            const SizedBox(height: 25),

            // ------------------------------------------
            // 4. PAYMENT METHODS (Widget Reusable)
            // ------------------------------------------
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
            PaymentOptionCard(
              title: "QRIS",
              subtitle: "Scan QR Code",
              icon: Icons.qr_code_scanner,
              isSelected: _selectedPaymentIndex == 3,
              onTap: () => setState(() => _selectedPaymentIndex = 3),
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

  Widget _buildBottomBar() {
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
                    "Rp 1.393.258",
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
                  const SnackBar(content: Text("Processing Hotel Payment...")),
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
