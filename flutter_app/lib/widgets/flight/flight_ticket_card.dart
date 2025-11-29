import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class FlightTicketCard extends StatelessWidget {
  const FlightTicketCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- BAGIAN ATAS TIKET ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Airline Header
                Row(
                  children: [
                    const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "TURKISH AIRLINES",
                      style: AppTextStyles.baseM.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "Boeing-762825",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.gray3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Info Kursi & Flight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTicketInfo("Seat", "3A", isLarge: true),
                    _buildTicketInfo("Class", "Economy"),
                    _buildTicketInfo("Flight Number", "LA-5678"),
                  ],
                ),
              ],
            ),
          ),

          // --- GARIS PUTUS-PUTUS & LENGKUNGAN (CUTOUT) ---
          SizedBox(
            height: 30,
            child: Stack(
              children: [
                // Garis Putus-putus
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (index) => SizedBox(
                            width: 5,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: AppColors.gray2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Lingkaran Kiri
                Positioned(
                  left: -15,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.gray0,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Lingkaran Kanan
                Positioned(
                  right: -15,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.gray0,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BAGIAN BAWAH TIKET ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. Rute
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRouteInfo(
                      "From",
                      "LAS",
                      "Las Vegas, USA",
                      "07:47, 31 Oct, Tue",
                    ),
                    const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.gray3,
                      size: 30,
                    ),
                    _buildRouteInfo(
                      "To",
                      "HND",
                      "Tokyo, Japan",
                      "16:30, 31 Oct, Tue",
                      alignRight: true,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. Passenger & Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Passengers",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Brooklyn Jannete",
                          style: AppTextStyles.baseM.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Dummy Barcode
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        15,
                        (index) => Container(
                          width: index % 2 == 0 ? 4 : 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: isLarge
              ? AppTextStyles.headingM.copyWith(color: AppColors.black)
              : AppTextStyles.baseM.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(
    String label,
    String code,
    String city,
    String time, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 2),
        Text(
          code,
          style: AppTextStyles.headingL.copyWith(
            color: AppColors.black,
            height: 1.0,
          ),
        ),
        Text(
          city,
          style: AppTextStyles.baseXS.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: AppTextStyles.baseXS.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
