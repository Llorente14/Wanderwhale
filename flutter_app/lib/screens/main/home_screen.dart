import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/widgets/common/custom_bottom_nav.dart';

import '../discount/discount_page.dart';
import '../explore/search_page.dart';
import '../tips/tipstravel.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          child: SingleChildScrollView(
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
                const SizedBox(height: 24),
                const _UpcomingTripsSection(),
                const SizedBox(height: 24),
                const _HotelDealsSection(),
                const SizedBox(height: 24),
                const _TopRecommendationSection(),
                const SizedBox(height: 24),
                const _RecommendedFlightsSection(),
                const SizedBox(height: 24),
                const _DestinationByCountrySection(),
                const SizedBox(height: 24),
                const _TravelTipsCarouselSection(),
                const SizedBox(height: 24),
                const _DiscountCarouselSection(),
                const SizedBox(height: 24),
                const _ExploreCarouselSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}

// ================= HEADER =================

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 46,
          height: 46,
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
          child: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/avatar_placeholder.png'),
          ),
        ),
        const SizedBox(width: 12),
        // Greeting & location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Hello, Traveler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray5,
                ),
              ),
              SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Jakarta, Indonesia',
                    style: TextStyle(fontSize: 12, color: AppColors.gray3),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Notification button
        Container(
          width: 40,
          height: 40,
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
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ================= SEARCH BAR =================

class _SearchBar extends StatelessWidget {
  const _SearchBar();

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
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search, color: AppColors.gray3),
          const SizedBox(width: 8),
          const Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Mau jalan ke mana?',
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, size: 20, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ================= HERO SUMMARY BANNER =================

class _HeroSummaryBanner extends StatelessWidget {
  const _HeroSummaryBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryLight1, AppColors.primaryDark1],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark1.withOpacity(0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.flight_takeoff, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Rencana Penerbanganmu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _FlightPoint(code: 'DPS', city: 'Bali'),
              Icon(Icons.flight, color: Colors.white70, size: 18),
              _FlightPoint(code: 'CGK', city: 'Jakarta'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '04 Jan 2025',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Durasi • 1h 45m',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlightPoint extends StatelessWidget {
  final String code;
  final String city;

  const _FlightPoint({required this.code, required this.city});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}

// ================= QUICK MENU =================

class _QuickMenuRow extends StatelessWidget {
  const _QuickMenuRow();

  @override
  Widget build(BuildContext context) {
    final totalWidth =
        MediaQuery.of(context).size.width - 40; // padding horizontal 20+20
    final itemWidth = (totalWidth - 2 * 12) / 3; // 3 item, 2 gap @12

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: itemWidth,
          child: const _QuickMenuItem(
            icon: Icons.flight_takeoff,
            label: 'Trip',
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: itemWidth,
          child: const _QuickMenuItem(
            icon: Icons.hotel,
            label: 'Hotel',
            color: AppColors.primaryLight1,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: itemWidth,
          child: const _QuickMenuItem(
            icon: Icons.favorite,
            label: 'Wishlist',
            color: AppColors.primaryDark1,
          ),
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TOP RECOMMENDATION =================

class _UpcomingTripsSection extends StatelessWidget {
  const _UpcomingTripsSection();

  @override
  Widget build(BuildContext context) {
    // Dummy data untuk sekarang
    final trips = [
      const _TripTicketCard(
        country: 'Indonesia',
        city: 'Bali',
        distanceKm: 2.9,
        dateTimeText: '27 Oct 2025 09:00',
      ),
      const _TripTicketCard(
        country: 'Japan',
        city: 'Tokyo',
        distanceKm: 5.1,
        dateTimeText: '01 Nov 2025 08:30',
      ),
    ];

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
            itemBuilder: (context, index) => trips[index],
          ),
        ),
      ],
    );
  }
}

// ================= HOTEL DEALS =================

class _HotelDealsSection extends StatelessWidget {
  const _HotelDealsSection();

  @override
  Widget build(BuildContext context) {
    final hotels = [
      const _HotelCard(
        name: 'Sunrise Resort',
        location: 'Bali, Indonesia',
        priceText: 'IDR 950K / night',
        imageUrl: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb',
        accentColor: Color(0xFF8E44AD),
      ),
      const _HotelCard(
        name: 'City Lights Hotel',
        location: 'Tokyo, Japan',
        priceText: 'IDR 1.2M / night',
        imageUrl: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa',
        accentColor: Color(0xFF16A085),
      ),
    ];

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
            itemCount: hotels.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => hotels[index],
          ),
        ),
      ],
    );
  }
}

class _HotelCard extends StatelessWidget {
  final String name;
  final String location;
  final String priceText;
  final String imageUrl;
  final Color accentColor;

  const _HotelCard({
    required this.name,
    required this.location,
    required this.priceText,
    required this.imageUrl,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.35),
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
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.gray1,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.bed,
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
                    name,
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
                    location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      priceText,
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
          ],
        ),
      ),
    );
  }
}

class _TripTicketCard extends StatelessWidget {
  final String country;
  final String city;
  final double distanceKm;
  final String dateTimeText;

  const _TripTicketCard({
    required this.country,
    required this.city,
    required this.distanceKm,
    required this.dateTimeText,
  });

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    country,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray5,
                    ),
                  ),
                  Text(
                    city,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Distance + route line
          Center(
            child: Text(
              '${distanceKm.toStringAsFixed(1)} Km',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.gray4,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              const Text(
                'Starting\nLocation',
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
                'Destination',
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
                    child: const Text(
                      'When',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    dateTimeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray4,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
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

class _TopRecommendationSection extends StatelessWidget {
  const _TopRecommendationSection();

  @override
  Widget build(BuildContext context) {
    final cards = [
      const _RecommendationCard(
        title: 'Lake Pukaki',
        subtitle: 'New Zealand',
        imageUrl:
            'https://images.unsplash.com/photo-1508261306211-45a1c5c2a5c5',
      ),
      const _RecommendationCard(
        title: 'Passo Rolle, TN',
        subtitle: 'Italy',
        imageUrl:
            'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee',
      ),
      const _RecommendationCard(
        title: 'Santorini',
        subtitle: 'Greece',
        imageUrl:
            'https://images.unsplash.com/photo-1505739771678-bbdb7e92aef1',
      ),
    ];

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
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => cards[index],
          ),
        ),
      ],
    );
  }
}

// ================= RECOMMENDED FLIGHTS =================

class _RecommendedFlightsSection extends StatelessWidget {
  const _RecommendedFlightsSection();

  @override
  Widget build(BuildContext context) {
    final flights = [
      const _RecommendedFlightCard(
        route: 'CGK → DPS',
        airline: 'Garuda Indonesia',
        priceText: 'IDR 1.500.000',
        chipText: 'Direct • 1h 50m',
      ),
      const _RecommendedFlightCard(
        route: 'CGK → NRT',
        airline: 'Japan Airlines',
        priceText: 'IDR 7.200.000',
        chipText: '1 stop • 10h 30m',
      ),
    ];

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
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: flights.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => flights[index],
          ),
        ),
      ],
    );
  }
}

class _RecommendedFlightCard extends StatelessWidget {
  final String route;
  final String airline;
  final String priceText;
  final String chipText;

  const _RecommendedFlightCard({
    required this.route,
    required this.airline,
    required this.priceText,
    required this.chipText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flight_takeoff,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gray5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            airline,
            style: const TextStyle(fontSize: 12, color: AppColors.gray3),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight3,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  chipText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryDark1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ================= DESTINATIONS BY COUNTRY =================

class _DestinationByCountrySection extends StatelessWidget {
  const _DestinationByCountrySection();

  @override
  Widget build(BuildContext context) {
    final highlightsByCountry = {
      'Indonesia': const [
        _DestinationHighlight(
          title: 'Sunrise Resort',
          city: 'Bali',
          country: 'Indonesia',
          imageUrl:
              'https://images.unsplash.com/photo-1501117716987-c8e1ecb210cc?auto=format&fit=crop&w=800&q=80',
        ),
        _DestinationHighlight(
          title: 'Hidden Bay Villa',
          city: 'Lombok',
          country: 'Indonesia',
          imageUrl:
              'https://images.unsplash.com/photo-1470246973918-29a93221c455?auto=format&fit=crop&w=800&q=80',
        ),
      ],
      'Japan': const [
        _DestinationHighlight(
          title: 'City Lights Hotel',
          city: 'Tokyo',
          country: 'Japan',
          imageUrl:
              'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
        ),
        _DestinationHighlight(
          title: 'Osaka Sky Suites',
          city: 'Osaka',
          country: 'Japan',
          imageUrl:
              'https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&w=800&q=80',
        ),
      ],
      'Italy': const [
        _DestinationHighlight(
          title: 'Venetian Escape',
          city: 'Venice',
          country: 'Italy',
          imageUrl:
              'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=800&q=80',
        ),
        _DestinationHighlight(
          title: 'Tuscan Dreams',
          city: 'Florence',
          country: 'Italy',
          imageUrl:
              'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?auto=format&fit=crop&w=800&q=80',
        ),
      ],
    };

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
        const SizedBox(height: 14),
        ...highlightsByCountry.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: _CountryHighlightColumn(
              country: entry.key,
              highlights: entry.value,
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryHighlightColumn extends StatelessWidget {
  final String country;
  final List<_DestinationHighlight> highlights;

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
                  child: _DestinationHighlightCard(data: highlight),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DestinationHighlight {
  final String title;
  final String city;
  final String country;
  final String imageUrl;

  const _DestinationHighlight({
    required this.title,
    required this.city,
    required this.country,
    required this.imageUrl,
  });
}

class _DestinationHighlightCard extends StatelessWidget {
  final _DestinationHighlight data;

  const _DestinationHighlightCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              data.imageUrl,
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
                    data.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data.city}, ${data.country}',
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

class _GradientActionCarousel extends StatelessWidget {
  final String title;
  final List<_ActionCardData> cards;

  const _GradientActionCarousel({required this.title, required this.cards});

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final card = cards[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => card.destinationBuilder(),
                    ),
                  );
                },
                child: Container(
                  width: 260,
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
              );
            },
          ),
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
        title: 'Solo Traveler Guide',
        description: 'Belajar cara eksplor dunia dengan aman & seru.',
        destinationBuilder: () => const TipsTravelPage(),
      ),
    ];

    return _GradientActionCarousel(title: 'Travel Tips Carousel', cards: cards);
  }
}

class _DiscountCarouselSection extends StatelessWidget {
  const _DiscountCarouselSection();

  @override
  Widget build(BuildContext context) {
    final cards = [
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
    ];

    return _GradientActionCarousel(title: 'Diskon & Voucher', cards: cards);
  }
}

class _ExploreCarouselSection extends StatelessWidget {
  const _ExploreCarouselSection();

  @override
  Widget build(BuildContext context) {
    final cards = [
      _ActionCardData(
        title: 'Explore Your Journey',
        description: 'Cari destinasi baru dan buat rencana perjalanan.',
        destinationBuilder: () => const SearchPage(),
        gradientColors: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
      ),
      _ActionCardData(
        title: 'Inspire Me',
        description: 'Temukan rekomendasi unik dari WanderWhale.',
        destinationBuilder: () => const SearchPage(),
        gradientColors: const [Color(0xFFFA8BFF), Color(0xFF2BD2FF)],
      ),
    ];

    return _GradientActionCarousel(title: 'Explore Lebih Jauh', cards: cards);
  }
}

class _RecommendationCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;

  const _RecommendationCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
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
              imageUrl,
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
                    title,
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
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
