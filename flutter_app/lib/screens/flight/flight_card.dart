import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:intl/intl.dart';

import 'flight_detail.dart';

class FlightsCardScreen extends StatelessWidget {
  const FlightsCardScreen({super.key, required this.offers});

  final List<FlightOfferModel> offers;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd MMM yyyy, HH:mm');
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => Navigator.pop(context)),
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
                                      FlightDetailScreen(offer: offer),
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
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
            color: Colors.grey[700],
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    const Text(
                      'Jakarta, ID',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
            onPressed: () {},
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
    final airline = _airlineNames[firstSegment.carrierCode] ??
        firstSegment.carrierCode;
    final departure = firstSegment.departure.at != null
        ? formatter.format(firstSegment.departure.at!)
        : '-';
    final travelClass =
        firstSegment.pricing?.travelClass ?? 'ECONOMY';

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
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
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
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
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

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(icon: Icons.home, label: 'Home', active: true),
              _NavItem(icon: Icons.favorite_border, label: 'Favorite'),
              _NavItem(icon: Icons.add_circle_outline, label: 'Planning'),
              _NavItem(icon: Icons.auto_awesome_outlined, label: 'AI Chat'),
              _NavItem(icon: Icons.settings_outlined, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, this.active = false});

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? Colors.blue[700] : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.blue[700] : Colors.grey[600],
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
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
