import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_booking_model.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_app/widgets/common/custom_bottom_nav.dart';
import 'package:flutter_app/screens/main/main_navigation_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/providers/providers.dart';

class HotelDetail extends ConsumerWidget {
  const HotelDetail({
    super.key,
    required this.hotelGroup,
    required this.offer,
    required this.imageUrl,
  });

  final HotelOfferGroup hotelGroup;
  final HotelOffer offer;
  final String imageUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booking = _createBookingSummary();
    final taxes = _calculateTaxes();
    final total = booking.totalPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F3F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF1F3F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Hotel Confirmation',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You picked',
              style: TextStyle(
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              booking.roomType ?? 'Room',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _ConfirmationCard(
              booking: booking,
              offer: offer,
              imageUrl: imageUrl,
              taxes: taxes,
              total: total,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F8CFF),
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Confirm Booking',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
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
        // Navigate to MainNavigationScreen with the selected index
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) {
              // Set the index before navigating
              ref.read(bottomNavIndexProvider.notifier).state = index;
              return const MainNavigationScreen();
            },
          ),
          (route) => false, // Remove all previous routes
        );
      },
    );
  }

  HotelBookingModel _createBookingSummary() {
    final guestsCount = offer.guests.adults + (offer.guests.children ?? 0);
    final guestDetails = <Map<String, dynamic>>[
      {'type': 'ADULT', 'count': offer.guests.adults},
      if (offer.guests.children != null)
        {'type': 'CHILD', 'count': offer.guests.children},
    ];
    return HotelBookingModel(
      bookingId: 'TEMP-${offer.id}',
      userId: 'demo-user',
      tripId: hotelGroup.hotel.hotelId,
      offerId: offer.id,
      bookingStatus: 'PENDING',
      hotelName: hotelGroup.hotel.name,
      hotelAddress: hotelGroup.hotel.address?.lines,
      city: hotelGroup.hotel.address?.cityName,
      country: hotelGroup.hotel.address?.countryCode,
      latitude: hotelGroup.hotel.latitude,
      longitude: hotelGroup.hotel.longitude,
      continent: null,
      checkInDate: offer.checkInDate,
      checkOutDate: offer.checkOutDate,
      roomType: offer.room?.type,
      roomDescription: offer.room?.description,
      numberOfGuests: guestsCount,
      primaryGuestName: 'Guest Traveler',
      totalPrice: offer.price.total,
      basePrice: offer.price.base,
      currency: offer.price.currency,
      paymentMethod: offer.paymentPolicy ?? 'credit_card',
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      bookedAt: null,
      policies: offer.policies,
      guests: guestDetails,
    );
  }

  double _calculateTaxes() {
    final taxes = offer.price.taxes;
    if (taxes.isEmpty) {
      final derived = offer.price.total - offer.price.base;
      return derived > 0 ? derived : 0;
    }
    return taxes.fold<double>(0, (sum, tax) {
      final rawAmount = tax['amount'];
      final parsed = double.tryParse(rawAmount?.toString() ?? '0') ?? 0;
      return sum + parsed;
    });
  }
}

class _ConfirmationCard extends StatelessWidget {
  const _ConfirmationCard({
    required this.booking,
    required this.offer,
    required this.imageUrl,
    required this.taxes,
    required this.total,
  });

  final HotelBookingModel booking;
  final HotelOffer offer;
  final String imageUrl;
  final double taxes;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.hotelName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.hotelAddress ?? '-',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      booking.city ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _InfoRow(label: 'Room type', value: booking.roomType ?? '-'),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Guests',
            value: '${booking.numberOfGuests} pax',
          ),
          const SizedBox(height: 8),
          _InfoRow(
            label: 'Board',
            value: offer.boardType ?? 'Room only',
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFE8EAF0)),
          _InfoRow(
            label: 'Room price',
            value: booking.basePrice.toIDR(),
            emphasize: true,
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Tax & service',
            value: taxes.toIDR(),
          ),
          const SizedBox(height: 6),
          _InfoRow(
            label: 'Total',
            value: total.toIDR(),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.label, required this.value, this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 16 : 14,
            fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            color: emphasize ? Colors.black87 : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}