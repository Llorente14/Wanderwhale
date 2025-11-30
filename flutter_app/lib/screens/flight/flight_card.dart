import 'package:flutter/material.dart';
import 'package:wanderwhale/models/flight_offer_model.dart';
import 'package:wanderwhale/utils/formatters.dart';
import 'package:wanderwhale/widgets/common/custom_bottom_nav.dart';
import 'package:wanderwhale/screens/main/main_navigation_screen.dart';
import 'package:wanderwhale/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'flight_booking_details.dart';
import '../main/home_screen.dart';

class FlightsCardScreen extends ConsumerWidget {
  const FlightsCardScreen({super.key, required this.offers});

  final List<FlightOfferModel> offers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const _HeaderSection(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: offers.isEmpty
                    ? const Center(child: Text('No flights available'))
                    : ListView.separated(
                        itemBuilder: (_, index) {
                          final offer = offers[index];
                          return _FlightCard(
                            offer: offer,
                            formatter: formatter,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FlightBookingDetailsScreen(offer: offer),
                                ),
                              );
                            },
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemCount: offers.length,
                      ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, ref),
    );
  }

  Widget _buildBottomNav(BuildContext context, WidgetRef ref) {
    return CustomBottomNav(
      onIndexChanged: (index) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) {
              ref.read(bottomNavIndexProvider.notifier).state = index;
              return const MainNavigationScreen();
            },
          ),
          (route) => false,
        );
      },
    );
  }
}

// Header section copied from home_screen.dart
class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final latestFlightAsync = ref.watch(latestFlightFromTripsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey[700],
          ),
          const SizedBox(width: 8),
          userAsync.when(
            data: (user) => GestureDetector(
              onTap: () {
                // Navigate to profile if needed
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
                backgroundImage: user.photoURL != null
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ),
            loading: () => const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userAsync.when(
                  data: (user) {
                    final displayText =
                        (user.displayName != null &&
                            user.displayName!.isNotEmpty)
                        ? user.displayName!
                        : (user.email.isNotEmpty
                              ? user.email.split('@').first
                              : 'Traveler');
                    return Text(
                      'Hello, $displayText',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                  loading: () => Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  error: (_, __) => const Text(
                    'Hello, Traveler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                latestFlightAsync.when(
                  data: (flight) {
                    if (flight != null && flight.departureDate != null) {
                      final dateFormat = DateFormat('dd MMM yyyy');
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flight_takeoff,
                            size: 16,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${flight.origin} → ${flight.destination} • ${dateFormat.format(flight.departureDate!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    }
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: locationAsync.when(
                            data: (text) => Text(
                              text,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            loading: () => const Text(
                              'Mengambil lokasi...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            error: (_, __) => const Text(
                              'Lokasi tidak tersedia',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: locationAsync.when(
                          data: (text) => Text(
                            text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text(
                            'Mengambil lokasi...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          error: (_, __) => const Text(
                            'Lokasi tidak tersedia',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: locationAsync.when(
                          data: (text) => Text(
                            text,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          loading: () => const Text(
                            'Mengambil lokasi...',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          error: (_, __) => const Text(
                            'Lokasi tidak tersedia',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  color: Colors.white,
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
                  color: Colors.black87,
                  onPressed: () {
                    // Navigate to notifications if needed
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
                            color: Colors.red,
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
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.offer,
    required this.formatter,
    required this.onTap,
  });

  final FlightOfferModel offer;
  final DateFormat formatter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstSegment = offer.itineraries.first.segments.first;
    final lastSegment = offer.itineraries.last.segments.last;
    final route =
        '${_airportLabels[firstSegment.departure.iataCode] ?? firstSegment.departure.iataCode} '
        '(${firstSegment.departure.iataCode}) → '
        '${_airportLabels[lastSegment.arrival.iataCode] ?? lastSegment.arrival.iataCode} '
        '(${lastSegment.arrival.iataCode})';
    final airline =
        _airlineNames[firstSegment.carrierCode] ?? firstSegment.carrierCode;
    final departure = firstSegment.departure.at != null
        ? formatter.format(firstSegment.departure.at!)
        : '-';
    final travelClass = firstSegment.pricing?.travelClass ?? 'ECONOMY';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.blue[400],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flight, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        airline,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${offer.validatingAirlineCodes.join(', ')} • ${_titleCase(travelClass)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Text(
                  offer.price.total.toIDR(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              route,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  departure,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const Map<String, String> _airportLabels = {
  'CGK': 'Jakarta',
  'HND': 'Tokyo',
  'SIN': 'Singapore',
  'DPS': 'Bali',
};

const Map<String, String> _airlineNames = {
  'GA': 'Garuda Indonesia',
  'SQ': 'Singapore Airlines',
};

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}
