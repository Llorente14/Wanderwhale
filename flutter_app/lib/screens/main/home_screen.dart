import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/screens/user/profile_screens.dart';
import 'package:flutter_app/screens/wishlist/wishlist_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/models/destination_master_model.dart';
import 'package:flutter_app/models/flight_booking_model.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/models/hotel_booking_model.dart';
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/models/wishlist_model.dart';
import 'package:flutter_app/providers/flight_providers.dart';
import 'package:flutter_app/providers/hotel_providers.dart';
import 'package:flutter_app/providers/providers.dart';
import 'package:flutter_app/providers/wishlist_providers.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_app/widgets/login_required_popup.dart';

import '../discount/discount_page.dart';
import '../explore/search_page.dart';
import '../flight/flight_recommendation.dart';
import '../hotel/hotel_recommendations.dart';
import '../notification/notification_screen.dart';
import '../trip/trip_list.dart';
import '../destination/destination_detail.dart';
import '../tips/tipstravel.dart';

const _homeHotelFilter = HotelBookingFilter(status: 'CONFIRMED', limit: 5);
const _homeFlightBookingFilter = FlightBookingFilter(
  status: 'CONFIRMED',
  limit: 3,
);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightSearchParams = _buildHomeFlightSearchParams();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryLight3, AppColors.white],
              stops: [0.0, 0.45],
            ),
          ),
          child: RefreshIndicator(
            onRefresh: () => _refreshHomeData(ref, flightSearchParams),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _HeaderSection(),
                  const SizedBox(height: 18),
                  const _HeroSummaryBanner(),
                  const SizedBox(height: 24),
                  const _SearchBar(),
                  const SizedBox(height: 18),
                  const _QuickMenuRow(),
                  const SizedBox(height: 18),
                  const _WishlistPeekSection(),
                  const SizedBox(height: 24),
                  const _UpcomingTripsSection(),
                  const SizedBox(height: 24),
                  const _HotelDealsSection(),
                  const SizedBox(height: 24),
                  const _TopRecommendationSection(),
                  const SizedBox(height: 24),
                  _RecommendedFlightsSection(params: flightSearchParams),
                  const SizedBox(height: 24),
                  const _DestinationByCountrySection(),
                  const SizedBox(height: 24),
                  const _TravelTipsCarouselSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

FlightSearchParams _buildHomeFlightSearchParams() {
  final departureDate = DateTime.now().add(const Duration(days: 14));
  final returnDate = departureDate.add(const Duration(days: 4));
  final dateFormatter = DateFormat('yyyy-MM-dd');

  return FlightSearchParams({
    'currencyCode': 'IDR',
    'originDestinations': [
      {
        'id': '1',
        'originLocationCode': 'CGK',
        'destinationLocationCode': 'DPS',
        'departureDateTimeRange': {'date': dateFormatter.format(departureDate)},
      },
      {
        'id': '2',
        'originLocationCode': 'DPS',
        'destinationLocationCode': 'CGK',
        'departureDateTimeRange': {'date': dateFormatter.format(returnDate)},
      },
    ],
    'travelers': [
      {'id': '1', 'travelerType': 'ADULT'},
    ],
    'sources': ['GDS'],
    'searchCriteria': {'maxFlightOffers': 20},
  });
}

Future<void> _refreshHomeData(
  WidgetRef ref,
  FlightSearchParams flightParams,
) async {
  // Refresh semua data dengan error handling untuk mencegah crash
  // Menggunakan eagerError: false agar tidak crash jika salah satu gagal
  try {
    await Future.wait([
      ref.refresh(userProvider.future),
      ref.refresh(userLocationTextProvider.future),
      ref.refresh(tripsProvider.future),
      ref.refresh(popularDestinationsProvider.future),
      ref.refresh(wishlistItemsProvider.future),
      ref.refresh(notificationsProvider.future),
      ref.refresh(unreadNotificationsProvider.future),
      ref.refresh(hotelBookingsProvider(_homeHotelFilter).future),
      ref.refresh(flightBookingsProvider(_homeFlightBookingFilter).future),
      ref.refresh(flightOffersProvider(flightParams).future),
    ], eagerError: false);
  } catch (e) {
    // Log error di debug mode, tapi jangan crash app
    debugPrint('Warning: Some data failed to refresh: $e');
  }
}

String _formatDateLabel(DateTime? date) {
  if (date == null) return 'Tanggal belum ditentukan';
  return DateFormat('EEE, dd MMM yyyy').format(date);
}

String _formatTime(DateTime? date) {
  if (date == null) return '--:--';
  return DateFormat('HH:mm').format(date);
}

String _formatIsoDuration(String? duration) {
  if (duration == null) return '-';
  final regex = RegExp(r'P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?');
  final match = regex.firstMatch(duration);
  if (match == null) return duration;
  final days = int.tryParse(match.group(1) ?? '0') ?? 0;
  final hours = int.tryParse(match.group(2) ?? '0') ?? 0;
  final minutes = int.tryParse(match.group(3) ?? '0') ?? 0;

  final buffer = StringBuffer();
  if (days > 0) buffer.write('${days}d ');
  if (hours > 0) buffer.write('${hours}h ');
  if (minutes > 0) buffer.write('${minutes}m');

  final result = buffer.toString().trim();
  return result.isEmpty ? '0m' : result;
}

String _durationBetween(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '-';
  final diff = end.difference(start);
  final hours = diff.inHours;
  final minutes = diff.inMinutes.remainder(60);
  if (hours == 0 && minutes == 0) return '-';
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}

// Helper function untuk menampilkan error feedback ke user
void _showErrorFeedback(BuildContext context, Object? error) {
  final errorMessage = error.toString();
  final isAuthError =
      errorMessage.contains('terautentikasi') ||
      errorMessage.contains('login') ||
      errorMessage.contains('Unauthorized') ||
      errorMessage.contains('401');

  if (isAuthError) {
    LoginRequiredPopup.show(
      context,
      message: 'Silakan login terlebih dahulu untuk mengakses fitur ini',
    );
    return;
  }

  // Handle 404 untuk profile (profile belum dibuat)
  final isProfileNotFound =
      errorMessage.contains('404') ||
      errorMessage.contains('Profile belum dibuat') ||
      errorMessage.contains('not found');

  if (isProfileNotFound) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Profile belum dibuat. Silakan lengkapi profil Anda.',
        ),
        backgroundColor: AppColors.warning,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
    return;
  }

  final message =
      'Terjadi kesalahan: ${errorMessage.length > 50 ? errorMessage.substring(0, 50) + "..." : errorMessage}';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
      duration: const Duration(seconds: 4),
    ),
  );
}

// ================= HEADER =================

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);

    return Row(
      children: [
        userAsync.when(
          data: (user) => GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreens()),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.white,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : const AssetImage('assets/images/avatar_placeholder.png')
                        as ImageProvider,
            ),
          ),
          loading: () => const CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.gray2,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (error, stackTrace) => GestureDetector(
            onTap: () {
              // Tampilkan feedback ke user
              _showErrorFeedback(context, error);

              // Tetap redirect ke profile screen (mungkin ada login option di sana)
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreens()),
              );
            },
            child: Tooltip(
              message: 'Tap untuk membuka profil atau login',
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gray2,
                child: const Icon(Icons.person, color: AppColors.gray4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userAsync.when(
                data: (user) => Text(
                  'Hello, ${user.displayName ?? 'Traveler'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                loading: () => const _HeaderLine(width: 140),
                error: (_, __) => const Text(
                  'Hello, Traveler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: locationAsync.when(
                      data: (text) => Text(
                        text,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      loading: () => const Text(
                        'Mengambil lokasi...',
                        style: TextStyle(fontSize: 12, color: AppColors.gray3),
                      ),
                      error: (_, __) => const Text(
                        'Lokasi tidak tersedia',
                        style: TextStyle(fontSize: 12, color: AppColors.gray3),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.notifications_none),
                color: AppColors.gray5,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationScreen(),
                    ),
                  );
                },
              ),
            ),
            unreadAsync.when(
              data: (items) => items.isEmpty
                  ? const SizedBox.shrink()
                  : Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      decoration: BoxDecoration(
        color: AppColors.gray1,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ================= SEARCH BAR =================

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    if (query.trim().isEmpty) return;

    // Update search query provider
    ref.read(searchQueryProvider.notifier).state = query.trim();

    // Navigate to search page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.gray3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Mau jalan ke mana?',
                hintStyle: TextStyle(color: AppColors.gray3),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              // Hanya redirect saat user tekan enter (onSubmitted)
              onSubmitted: _handleSearch,
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight1, AppColors.primaryDark1],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 20, color: Colors.white),
              padding: EdgeInsets.zero,
              onPressed: () {
                // TODO: Open filter options
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ================= HERO SUMMARY BANNER =================
class _HeroSummaryBanner extends ConsumerWidget {
  const _HeroSummaryBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flightsAsync = ref.watch(
      flightBookingsProvider(_homeFlightBookingFilter),
    );

    return flightsAsync.when(
      data: (flights) {
        if (flights.isEmpty) {
          return const _HeroSummaryEmptyState();
        }
        final booking = flights.first;
        return _HeroSummaryContent(booking: booking);
      },
      loading: () => const _HeroSummaryShimmer(),
      error: (_, __) => const _HeroSummaryEmptyState(),
    );
  }
}

class _HeroSummaryContent extends StatelessWidget {
  const _HeroSummaryContent({required this.booking});

  final FlightBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return _HeroSummaryShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flight_takeoff, color: Colors.white70, size: 22),
              const SizedBox(width: 8),
              Text(
                booking.airline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                booking.flightNumber,
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FlightPoint(
                code: booking.origin,
                city: booking.origin,
                time: _formatTime(booking.departureDate),
              ),
              const Icon(Icons.flight, color: Colors.white, size: 26),
              _FlightPoint(
                code: booking.destination,
                city: booking.destination,
                time: _formatTime(booking.arrivalDate),
                alignRight: true,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDateLabel(booking.departureDate),
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Durasi • ${_durationBetween(booking.departureDate, booking.arrivalDate)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroSummaryShell extends StatelessWidget {
  const _HeroSummaryShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F6DC2), Color(0xFF0BC5EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F6DC2).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroSummaryShimmer extends StatelessWidget {
  const _HeroSummaryShimmer();

  @override
  Widget build(BuildContext context) {
    return _HeroSummaryShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _HeaderLine(width: 180),
          SizedBox(height: 16),
          _HeaderLine(width: 220),
        ],
      ),
    );
  }
}

class _HeroSummaryEmptyState extends StatelessWidget {
  const _HeroSummaryEmptyState();

  @override
  Widget build(BuildContext context) {
    return _HeroSummaryShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Belum ada penerbangan aktif',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Cari penerbangan terbaikmu di WanderWhale.',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _FlightPoint extends StatelessWidget {
  const _FlightPoint({
    required this.code,
    required this.city,
    required this.time,
    this.alignRight = false,
  });

  final String code;
  final String city;
  final String time;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(city, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(
          code,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

// ================= QUICK MENU =================
class _QuickMenuRow extends StatelessWidget {
  const _QuickMenuRow();

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItemData(
        icon: Icons.flight_takeoff,
        label: 'Flight',
        gradient: const [Color(0xFF0F6DC2), Color(0xFF00B2FF)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FlightRecommendation(),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.hotel,
        label: 'Hotel',
        gradient: const [Color(0xFF0BB5D4), Color(0xFF00E0B6)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HotelRecommendations(),
            ),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.favorite,
        label: 'Wishlist',
        gradient: const [Color(0xFF6A4CFF), Color(0xFF9D7CFF)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WishlistScreen()),
          );
        },
      ),
      _MenuItemData(
        icon: Icons.explore,
        label: 'Trip',
        gradient: const [Color(0xFF005C97), Color(0xFF363795)],
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TripListScreen()),
          );
        },
      ),
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _QuickMenuItem(data: item),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback? onTap;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.gradient,
    this.onTap,
  });
}

class _QuickMenuItem extends StatelessWidget {
  final _MenuItemData data;

  const _QuickMenuItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: data.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: data.gradient.last.withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              data.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistPeekSection extends ConsumerWidget {
  const _WishlistPeekSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistAsync = ref.watch(wishlistItemsProvider);

    return wishlistAsync.when(
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        final topItems = items.take(5).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Wishlist Kamu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topItems.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = topItems[index];
                  return _WishlistCard(item: item);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const _WishlistSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({required this.item});

  final WishlistModel item;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Create destination object from wishlist data for navigation
        // Use default values for missing fields
        final destination = DestinationMasterModel(
          destinationId: item.destinationId,
          name: item.destinationName,
          city: item.destinationCity ?? '',
          country: item.destinationCountry ?? '',
          continent: '', // Not available in wishlist
          description: '', // Not available in wishlist
          imageUrl: item.destinationImageUrl ?? '',
          images: item.destinationImageUrl != null
              ? [item.destinationImageUrl!]
              : [],
          rating: item.destinationRating ?? 0.0,
          reviewsCount: 0, // Not available in wishlist
          averageBudget: 0.0, // Not available in wishlist
          isPopular: false, // Not available in wishlist
          tags: item.destinationTags,
          popularActivities: [], // Not available in wishlist
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF6A4CFF), Color(0xFF9D7CFF)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A4CFF).withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.destinationName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${item.destinationCity ?? '-'}, ${item.destinationCountry ?? '-'}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Ditambahkan ${DateFormat('dd MMM').format(item.addedAt)}',
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _WishlistSkeleton extends StatelessWidget {
  const _WishlistSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.gray1,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: Row(
            children: List.generate(
              2,
              (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gray1,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ================= TOP RECOMMENDATION =================

class _UpcomingTripsSection extends ConsumerWidget {
  const _UpcomingTripsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(upcomingTripsProvider);

    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return const _EmptySectionMessage(
            title: 'Upcoming Trips',
            message: 'Belum ada rencana perjalanan. Mulai buat trip baru yuk!',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Trips',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: trips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    _TripTicketCard(trip: trips[index]),
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 210,
        child: Row(
          children: List.generate(
            2,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray1,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const _EmptySectionMessage(
        title: 'Upcoming Trips',
        message: 'Gagal memuat trip. Tarik untuk refresh.',
      ),
    );
  }
}

// ================= HOTEL DEALS =================

class _HotelDealsSection extends ConsumerWidget {
  const _HotelDealsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(hotelBookingsProvider(_homeHotelFilter));

    return bookingsAsync.when(
      data: (bookings) {
        if (bookings.isEmpty) {
          return const _EmptySectionMessage(
            title: 'Hotel Pilihan',
            message: 'Belum ada hotel yang dipesan. Temukan promo terbaik!',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hotel Pilihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: bookings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    _HotelCard(booking: bookings[index]),
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 190,
        child: Row(
          children: List.generate(
            2,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray1,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const _EmptySectionMessage(
        title: 'Hotel Pilihan',
        message: 'Gagal memuat data hotel.',
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  const _HotelCard({required this.booking});

  final HotelBookingModel booking;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to hotel recommendations page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HotelRecommendations()),
        );
      },
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E44AD).withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8E44AD), Color(0xFF3498DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  booking.hotelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.city ?? '-'}, ${booking.country ?? ''}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${booking.checkInDate != null ? DateFormat('dd MMM').format(booking.checkInDate!) : '?'} • ${booking.numberOfGuests} tamu',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${booking.totalPrice.toIDR()} • ${booking.currency}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TripTicketCard extends StatelessWidget {
  const _TripTicketCard({required this.trip});

  final TripModel trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + lokasi
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gray1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.tripName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${trip.totalDestinations} destinasi • ${trip.totalHotels} hotel',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.gray3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Mulai',
                style: TextStyle(fontSize: 10, color: AppColors.gray3),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Divider(
                  color: AppColors.gray2,
                  thickness: 1,
                  indent: 8,
                  endIndent: 8,
                ),
              ),
              const Icon(Icons.location_on, size: 16, color: AppColors.error),
              const SizedBox(width: 4),
              const Text(
                'Selesai',
                style: TextStyle(fontSize: 10, color: AppColors.gray3),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // When + Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${trip.durationInDays} hari',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy').format(trip.startDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray4,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy').format(trip.endDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.gray4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to trip list screen
                  // TODO: Replace with trip detail page when available
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TripListScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySectionMessage extends StatelessWidget {
  const _EmptySectionMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.gray3),
          ),
        ],
      ),
    );
  }
}

class _TopRecommendationSection extends ConsumerWidget {
  const _TopRecommendationSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(popularDestinationsProvider);

    return destinationsAsync.when(
      data: (destinations) {
        if (destinations.isEmpty) {
          return const _EmptySectionMessage(
            title: 'Rekomendasi Teratas',
            message: 'Belum ada destinasi populer yang bisa ditampilkan.',
          );
        }
        final top = destinations.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekomendasi Teratas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: top.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
                itemBuilder: (context, index) =>
                    _RecommendationCard(destination: top[index]),
              ),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 210,
        child: Row(
          children: List.generate(
            3,
            (_) => Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.gray1,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
      ),
      error: (_, __) => const _EmptySectionMessage(
        title: 'Rekomendasi Teratas',
        message: 'Gagal memuat destinasi.',
      ),
    );
  }
}

// ================= RECOMMENDED FLIGHTS =================

class _RecommendedFlightsSection extends ConsumerStatefulWidget {
  const _RecommendedFlightsSection({required this.params});

  final FlightSearchParams params;

  @override
  ConsumerState<_RecommendedFlightsSection> createState() =>
      _RecommendedFlightsSectionState();
}

class _RecommendedFlightsSectionState
    extends ConsumerState<_RecommendedFlightsSection> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9);
    _pageController.addListener(_handleScroll);
  }

  void _handleScroll() {
    final page = _pageController.page ?? 0;
    if ((page - _currentPage).abs() > 0.01) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handleScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(flightOffersProvider(widget.params));

    return offersAsync.when(
      data: (offers) {
        if (offers.isEmpty) {
          return const _EmptySectionMessage(
            title: 'Penerbangan Rekomendasi',
            message: 'Data rekomendasi kosong. Coba ubah tanggal pencarian.',
          );
        }

        final tickets = offers.map(_FlightTicketData.fromOffer).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penerbangan Rekomendasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                itemCount: tickets.length,
                itemBuilder: (context, index) {
                  final data = tickets[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index == tickets.length - 1 ? 0 : 16,
                      left: index == 0 ? 4 : 0,
                    ),
                    child: _OceanTicketCard(
                      data: data,
                      onDetailTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FlightDetailPage(ticket: data),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(tickets.length, (index) {
                final isActive = (index - _currentPage).abs() < 0.5;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 20 : 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0F7EC8)
                        : AppColors.gray3.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ],
        );
      },
      loading: () => SizedBox(
        height: 250,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.gray1,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      error: (_, __) => const _EmptySectionMessage(
        title: 'Penerbangan Rekomendasi',
        message: 'Gagal memuat data penerbangan.',
      ),
    );
  }
}

class _FlightTicketData {
  final String airline;
  final String travelClass;
  final String dateText;
  final String priceText;
  final String durationText;
  final String fromCode;
  final String toCode;
  final String departureTime;
  final String arrivalTime;

  const _FlightTicketData({
    required this.airline,
    required this.travelClass,
    required this.dateText,
    required this.priceText,
    required this.durationText,
    required this.fromCode,
    required this.toCode,
    required this.departureTime,
    required this.arrivalTime,
  });

  factory _FlightTicketData.fromOffer(FlightOfferModel offer) {
    final itinerary = offer.itineraries.isNotEmpty
        ? offer.itineraries.first
        : FlightItinerary(segments: []);
    final segments = itinerary.segments;
    if (segments.isEmpty) {
      return const _FlightTicketData(
        airline: 'Unknown Airline',
        travelClass: 'Economy',
        dateText: '-',
        priceText: '-',
        durationText: '-',
        fromCode: '-',
        toCode: '-',
        departureTime: '--:--',
        arrivalTime: '--:--',
      );
    }

    final firstSegment = segments.first;
    final lastSegment = segments.last;
    final departure = firstSegment.departure.at;
    final arrival = lastSegment.arrival.at;
    final airlineCode = offer.validatingAirlineCodes.isNotEmpty
        ? offer.validatingAirlineCodes.first
        : firstSegment.carrierCode;

    final currencySymbol = offer.price.currency == 'IDR'
        ? 'Rp '
        : '${offer.price.currency} ';
    final priceText = NumberFormat.currency(
      locale: 'id_ID',
      symbol: currencySymbol,
      decimalDigits: 0,
    ).format(offer.price.total);

    final duration = firstSegment.duration ?? lastSegment.duration;

    return _FlightTicketData(
      airline: airlineCode,
      travelClass: firstSegment.pricing?.travelClass ?? 'Economy',
      dateText: departure != null ? _formatDateLabel(departure) : '-',
      priceText: priceText,
      durationText: _formatIsoDuration(duration),
      fromCode: firstSegment.departure.iataCode,
      toCode: lastSegment.arrival.iataCode,
      departureTime: _formatTime(departure),
      arrivalTime: _formatTime(arrival),
    );
  }
}

class _OceanTicketCard extends StatelessWidget {
  final _FlightTicketData data;
  final VoidCallback onDetailTap;

  const _OceanTicketCard({required this.data, required this.onDetailTap});

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B8BD9).withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B8BD9), Color(0xFF0F7EC8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.flight_takeoff,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.airline,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.dateText,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B8BD9).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data.travelClass,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0B8BD9),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Flight Route Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TicketCityCode(
                      code: data.fromCode,
                      label: '${data.departureTime} • Depart',
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.airplanemode_active,
                              color: Color(0xFF64748B),
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data.durationText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TicketCityCode(
                      code: data.toCode,
                      label: '${data.arrivalTime} • Arrive',
                      alignRight: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Dashed Line
                const _TicketDashedLine(),
                const SizedBox(height: 18),

                // Footer Section
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Harga',
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data.priceText,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B8BD9), Color(0xFF0F7EC8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B8BD9).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onDetailTap,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            child: const Text(
                              'Detail Flight',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Circle Notches
          Positioned(
            left: -14,
            top: 95,
            child: _TicketCircleNotch(color: scaffoldColor),
          ),
          Positioned(
            right: -14,
            top: 95,
            child: _TicketCircleNotch(color: scaffoldColor),
          ),
        ],
      ),
    );
  }
}

class _TicketCircleNotch extends StatelessWidget {
  final Color color;

  const _TicketCircleNotch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

class _TicketDashedLine extends StatelessWidget {
  const _TicketDashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 8.0;
        const dashSpace = 6.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return Container(
              width: dashWidth,
              height: 2.5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _TicketCityCode extends StatelessWidget {
  final String code;
  final String label;
  final bool alignRight;

  const _TicketCityCode({
    required this.code,
    required this.label,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = alignRight
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          code,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
            letterSpacing: -1,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class FlightDetailPage extends StatelessWidget {
  final _FlightTicketData ticket;

  const FlightDetailPage({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flight Detail'),
        backgroundColor: const Color(0xFF0B8BD9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ticket.airline,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              '${ticket.fromCode} → ${ticket.toCode}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelas: ${ticket.travelClass} • Durasi ${ticket.durationText}',
              style: const TextStyle(color: AppColors.gray4),
            ),
            const SizedBox(height: 8),
            Text(
              '${ticket.departureTime} - ${ticket.arrivalTime}',
              style: const TextStyle(color: AppColors.gray4),
            ),
            const Divider(height: 32),
            Text(
              'Harga Tiket: ${ticket.priceText}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text(
              'Detail lengkap penerbangan akan ditampilkan di sini.',
              style: TextStyle(color: AppColors.gray4),
            ),
          ],
        ),
      ),
    );
  }
}
// ================= DESTINATIONS BY COUNTRY =================

class _DestinationByCountrySection extends ConsumerWidget {
  const _DestinationByCountrySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsAsync = ref.watch(popularDestinationsProvider);

    return destinationsAsync.when(
      data: (destinations) {
        if (destinations.isEmpty) return const SizedBox.shrink();

        final grouped = <String, List<DestinationMasterModel>>{};
        for (final destination in destinations) {
          grouped.putIfAbsent(destination.country, () => []).add(destination);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Destinasi Pilihan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.gray5,
              ),
            ),
            const SizedBox(height: 14),
            ...grouped.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: _CountryHighlightColumn(
                  country: entry.key,
                  highlights: entry.value.take(3).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _CountryHighlightColumn extends StatelessWidget {
  final String country;
  final List<DestinationMasterModel> highlights;

  const _CountryHighlightColumn({
    required this.country,
    required this.highlights,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          country,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray5,
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: highlights
              .map(
                (highlight) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DestinationHighlightCard(destination: highlight),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DestinationHighlightCard extends StatelessWidget {
  const _DestinationHighlightCard({required this.destination});

  final DestinationMasterModel destination;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DestinationDetailPage(destination: destination),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                destination.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.gray1,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.gray3,
                    size: 32,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${destination.city}, ${destination.country}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CAROUSEL ACTION SECTIONS =================

class _ActionCardData {
  final String title;
  final String description;
  final Widget Function() destinationBuilder;
  final List<Color> gradientColors;

  const _ActionCardData({
    required this.title,
    required this.description,
    required this.destinationBuilder,
    this.gradientColors = const [
      AppColors.primaryLight1,
      AppColors.primaryDark2,
    ],
  });
}

class _GradientActionCarousel extends StatefulWidget {
  final String title;
  final List<_ActionCardData> cards;

  const _GradientActionCarousel({required this.title, required this.cards});

  @override
  State<_GradientActionCarousel> createState() =>
      _GradientActionCarouselState();
}

class _GradientActionCarouselState extends State<_GradientActionCarousel> {
  late final PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.78);
    _pageController.addListener(_handlePageScroll);
  }

  void _handlePageScroll() {
    final page = _pageController.page ?? 0;
    if ((page - _currentPage).abs() > 0.01) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_handlePageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.gray5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == cards.length - 1 ? 0 : 16,
                  left: index == 0 ? 4 : 0,
                ),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => card.destinationBuilder(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: card.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: card.gradientColors.last.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          card.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          card.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (index) {
            final isActive = (index - _currentPage).abs() < 0.5;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 18 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive
                    ? cards[index].gradientColors.first
                    : AppColors.gray3.withOpacity(0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TravelTipsCarouselSection extends StatelessWidget {
  const _TravelTipsCarouselSection();

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCardData(
        title: 'Travel Tips',
        description: 'Packing hacks & itinerary ideas untuk liburanmu.',
        destinationBuilder: () => const TipsTravelPage(),
      ),
      _ActionCardData(
        title: 'Diskon Hotel 30%',
        description: 'Klaim voucher akomodasi favoritmu sekarang.',
        destinationBuilder: () => const DiscountPage(),
        gradientColors: const [Color(0xFF4FACFE), Color(0xFF00F2FE)],
      ),
      _ActionCardData(
        title: 'Flash Sale Flight',
        description: 'Terbang murah ke kota impian setiap weekend.',
        destinationBuilder: () => const DiscountPage(),
        gradientColors: const [Color(0xFFFFA948), Color(0xFFFF5F6D)],
      ),
      _ActionCardData(
        title: 'Explore Your Journey',
        description: 'Cari destinasi baru dan buat rencana perjalanan.',
        destinationBuilder: () => const SearchPage(),
        gradientColors: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
    ];

    return _GradientActionCarousel(title: 'Sekedar info', cards: cards);
  }
}

class _RecommendationCard extends ConsumerStatefulWidget {
  const _RecommendationCard({required this.destination});

  final DestinationMasterModel destination;

  @override
  ConsumerState<_RecommendationCard> createState() =>
      _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<_RecommendationCard> {
  bool _isToggling = false;

  Future<void> _handleToggle() async {
    if (_isToggling) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      LoginRequiredPopup.show(
        context,
        message: 'Silakan login terlebih dahulu untuk menggunakan wishlist.',
      );
      return;
    }

    setState(() => _isToggling = true);
    final manager = ref.read(wishlistManagerProvider);
    try {
      await manager.toggle(widget.destination.destinationId);
      // Refresh wishlist setelah toggle
      ref.invalidate(wishlistItemsProvider);
      ref.invalidate(wishlistStatusProvider(widget.destination.destinationId));
      // Trigger refresh untuk memastikan UI update
      ref.refresh(wishlistItemsProvider);
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      final message = status == 401
          ? 'Sesi kamu berakhir. Silakan login ulang.'
          : 'Gagal mengubah wishlist: ${error.message}';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah wishlist: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(
      wishlistStatusProvider(widget.destination.destinationId),
    );

    return Container(
      width: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.destination.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.gray1,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.gray3,
                    size: 32,
                  ),
                );
              },
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    widget.destination.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.destination.city}, ${widget.destination.country}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: statusAsync.when(
                data: (isWishlisted) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isWishlisted
                        ? const Color(0xFFFF4D6A).withOpacity(0.85)
                        : Colors.white.withOpacity(0.2),
                    border: Border.all(
                      color: isWishlisted
                          ? const Color(0xFFFF4D6A)
                          : Colors.white70,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    onPressed: _isToggling ? null : _handleToggle,
                    icon: Icon(
                      isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: isWishlisted ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                loading: () => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(color: Colors.white38),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: IconButton(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: _isToggling ? null : _handleToggle,
                    icon: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
