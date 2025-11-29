import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';

import 'hotel_booking_details.dart';

class HotelRooms extends StatelessWidget {
  const HotelRooms({
    super.key,
    required this.hotelGroup,
    required this.imageUrl,
  });

  final HotelOfferGroup hotelGroup;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final offers = hotelGroup.offers;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            _Header(city: hotelGroup.hotel.address?.cityName ?? 'Unknown'),
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                children: [
                  _HotelSummaryCard(
                    hotelGroup: hotelGroup,
                    imageUrl: imageUrl,
                  ),
                  const SizedBox(height: 24),
                  ...offers.map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _RoomTile(
                        room: room,
                        onBook: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HotelBookingDetailsScreen(
                                hotelGroup: hotelGroup,
                                offer: room,
                                imageUrl: imageUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
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
  const _Header({required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
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
                    Text(
                      '$city, NY 112',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.person_outline, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _HotelSummaryCard extends StatelessWidget {
  const _HotelSummaryCard({
    required this.hotelGroup,
    required this.imageUrl,
  });

  final HotelOfferGroup hotelGroup;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final tags = _extractTags();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              height: 190,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelGroup.hotel.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hotelGroup.hotel.address?.lines ?? '-',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF2FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractTags() {
    final boards = hotelGroup.offers
        .map((offer) => offer.boardType)
        .whereType<String>()
        .map((board) => board.trim())
        .where((board) => board.isNotEmpty);
    final categories = hotelGroup.offers
        .map((offer) => offer.room?.category)
        .whereType<String>()
        .map((category) => category.trim())
        .where((category) => category.isNotEmpty);
    return {...boards, ...categories}.take(4).toList();
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room, required this.onBook});

  final HotelOffer room;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final capacity = room.guests.adults + (room.guests.children ?? 0);
    final totalPrice = room.price.total;
    final taxes = _calculateTaxes();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.room?.type ?? 'Standard Room',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.room?.description ?? '-',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalPrice.toIDR(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB71C1C),
                    ),
                  ),
                  Text(
                    'Base ${room.price.base.toIDR()}\nTax ${taxes.toIDR()}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (room.boardType != null)
                _AmenityChip(label: room.boardType!),
              if (room.room?.category != null)
                _AmenityChip(label: room.room!.category!),
              if (room.policies?['cancellation'] != null)
                _AmenityChip(label: 'Flexible Policy'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${room.guests.adults} Adults',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$capacity Guests total',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F8CFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: onBook,
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Text(
                    'Book',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  double _calculateTaxes() {
    final taxes = room.price.taxes;
    if (taxes.isEmpty) {
      final derived = room.price.total - room.price.base;
      return derived > 0 ? derived : 0;
    }
    return taxes.fold<double>(0, (sum, tax) {
      final rawAmount = tax['amount'];
      final parsed = double.tryParse(rawAmount?.toString() ?? '0') ?? 0;
      return sum + parsed;
    });
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4A4A4A),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavIcon(icon: Icons.home, label: 'Home', active: true),
              _NavIcon(icon: Icons.favorite_border, label: 'Favorite'),
              _NavIcon(icon: Icons.add_circle_outline, label: 'Planning'),
              _NavIcon(icon: Icons.auto_awesome_outlined, label: 'AI Chat'),
              _NavIcon(icon: Icons.settings_outlined, label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.icon, required this.label, this.active = false});

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
          color: active ? Colors.blue[700] : Colors.grey[500],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.blue[700] : Colors.grey[500],
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
