import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dotted_line/dotted_line.dart'; // Anda perlu 'npm install dotted_line'
import 'package:intl/intl.dart'; // Anda perlu 'npm install intl'
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/core/theme/app_colors.dart';

class UpcomingTripCard extends StatelessWidget {
  final TripModel trip;
  const UpcomingTripCard({Key? key, required this.trip}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format tanggal sesuai desain: "27 Oct 2025 09:00"
    final formattedDate = DateFormat('d MMM yyyy HH:mm').format(trip.startDate);

    return Container(
      width: 280, // Lebar sesuai desain
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bagian Atas (Info Destinasi)
          Row(
            children: [
              ClipOval(
                child: trip.coverImage != null
                    ? CachedNetworkImage(
                        imageUrl: trip.coverImage!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        placeholder: (c, u) =>
                            Container(color: AppColors.gray1),
                        errorWidget: (c, u, e) => Container(
                          color: AppColors.gray1,
                          child: Icon(Icons.public, color: AppColors.gray3),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: AppColors.gray1,
                        child: Icon(Icons.public, color: AppColors.gray3),
                      ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.tripName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.gray5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "Indonesia, Bali", // TODO: Ganti dengan data asli
                    style: TextStyle(
                      color: AppColors.gray3,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bagian Tengah (Garis Lokasi)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.radio_button_checked,
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                "Mulai",
                style: TextStyle(
                  color: AppColors.gray3,
                  fontSize: 12,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DottedLine(dashColor: AppColors.gray2),
                ),
              ),
              const Icon(Icons.location_on, color: AppColors.error, size: 14),
              const SizedBox(width: 4),
              const Text(
                "Tujuan",
                style: TextStyle(
                  color: AppColors.gray3,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(), // Dorong ke bawah
          // Bagian Bawah (Tanggal & Tombol)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.primaryDark1,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryDark1,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigasi ke Detail Trip
                  // Navigator.push(... TripDetailScreen(tripId: trip.tripId) ...)
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gray5,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                child: const Text("Detail"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
