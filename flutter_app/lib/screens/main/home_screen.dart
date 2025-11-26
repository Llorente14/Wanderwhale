import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/utils/constants.dart';
import 'package:flutter_app/providers/providers.dart';
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/models/booking_model.dart'; // <-- Pastikan import BookingModel
import 'package:flutter_app/widgets/homepage/home_header.dart';
import 'package:flutter_app/widgets/common/custom_search_bar.dart';
import 'package:flutter_app/widgets/homepage/quick_menu.dart';
import 'package:flutter_app/widgets/homepage/upcoming_trip_card.dart'; // <-- Gunakan card yang benar
import 'package:flutter_app/widgets/common/custom_bottom_nav.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingTripsAsync = ref.watch(upcomingTripsProvider);
    final upcomingFlightsAsync = ref.watch(upcomingFlightsProvider);

    return Scaffold(
      backgroundColor: AppColors.gray0,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const HomeHeader(),

              const SizedBox(height: 16),

              // Search Bar
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: CustomSearchBar(),
              ),

              const SizedBox(height: 20),

              // Quick Menu
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: QuickMenu(),
              ),

              const SizedBox(height: 24),

              // Upcoming Trips Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.upcomingTrips,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all trips
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Upcoming Trips List
              Container(
                height: 170, // Sesuaikan tinggi dengan UpcomingTripCard
                child: upcomingTripsAsync.when(
                  data: (trips) {
                    if (trips.isEmpty) {
                      return _buildEmptyState(
                        icon: Icons.beach_access,
                        message: 'No upcoming trips yet',
                        onAction: () {
                          // TODO: Navigasi ke halaman 'Plan Trip'
                        },
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: trips.length,
                      itemBuilder: (context, index) {
                        return UpcomingTripCard(trip: trips[index]);
                      },
                    );
                  },
                  loading: () => _buildTripShimmerList(),
                  error: (err, stack) => _buildErrorState(
                    message: 'Failed to load trips',
                    onRetry: () {
                      ref.invalidate(tripsProvider);
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Upcoming Flight Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.upcomingFlight,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray5,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to all flights
                      },
                      child: const Text(
                        'See All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // --- INI FUNGSI YANG BARU SAJA KITA PERBAIKI ---
              // Upcoming Flights List
              _buildUpcomingFlightsList(upcomingFlightsAsync, ref),

              // --- AKHIR PERBAIKAN ---
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }

  // ===================================================================
  // --- FUNGSI HELPER (YANG HILANG SEBELUMNYA) ---
  // ===================================================================

  /// Widget builder untuk 'Upcoming Flights'
  Widget _buildUpcomingFlightsList(
    AsyncValue<List<BookingModel>> asyncValue,
    WidgetRef ref,
  ) {
    return Container(
      height: 120, // Sesuaikan tinggi
      child: asyncValue.when(
        data: (flights) {
          if (flights.isEmpty) {
            return _buildEmptyState(
              icon: Icons.flight_takeoff,
              message: 'No upcoming flights',
              showButton: false, // Tidak perlu tombol
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: flights.length,
            itemBuilder: (context, index) {
              // 1. Ambil objek 'booking'
              final booking = flights[index];

              // 2. Akses 'details' (Map) menggunakan tanda titik (.)
              //    lalu baca 'flightNumber' dari Map menggunakan ['...']
              final flightNumber =
                  booking.details?['flightNumber'] as String? ?? 'N/A';
              final airline =
                  booking.details?['airlineName'] as String? ?? 'Flight';

              // TODO: Buat 'UpcomingFlightCard' yang bagus
              return Card(
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          airline,
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(flightNumber),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => _buildFlightShimmerList(),
        error: (err, stack) => _buildErrorState(
          message: 'Failed to load flights',
          onRetry: () {
            ref.invalidate(upcomingFlightsProvider);
          },
        ),
      ),
    );
  }

  /// Helper untuk tampilan Error
  Widget _buildErrorState({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: AppColors.gray3)),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  /// Helper untuk tampilan Kosong
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    VoidCallback? onAction,
    bool showButton = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 120, // Beri tinggi agar konsisten
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray1, width: 1),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: AppColors.gray2),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(color: AppColors.gray3, fontSize: 14),
              ),
              if (showButton) ...[
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Plan Your Trip'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Shimmer Loading untuk Trip Card
  Widget _buildTripShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 2, // Tampilkan 2 placeholder
      itemBuilder: (context, index) {
        return Container(
          width: 280, // Sesuaikan dengan 'UpcomingTripCard'
          height: 170, // Sesuaikan dengan 'UpcomingTripCard'
          margin: const EdgeInsets.only(right: 16),
          child: Shimmer.fromColors(
            baseColor: AppColors.gray1,
            highlightColor: AppColors.white,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shimmer Loading untuk Flight Card
  Widget _buildFlightShimmerList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 3, // Tampilkan 3 placeholder
      itemBuilder: (context, index) {
        return Container(
          width: 150, // Lebar placeholder flight
          height: 120, // Tinggi placeholder flight
          margin: const EdgeInsets.only(right: 16),
          child: Shimmer.fromColors(
            baseColor: AppColors.gray1,
            highlightColor: AppColors.white,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
