import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/widgets/common/custom_bottom_nav.dart';
import 'package:flutter_app/screens/main/main_navigation_screen.dart';
import 'package:flutter_app/providers/providers.dart';
import 'package:flutter_app/core/theme/app_colors.dart';
import 'package:flutter_app/screens/user/profile_screens.dart';
import 'package:flutter_app/screens/notification/notification_screen.dart';
import 'package:intl/intl.dart';

import 'hotel_booking_details.dart';

class HotelRooms extends ConsumerWidget {
  const HotelRooms({
    super.key,
    required this.hotelGroup,
    required this.imageUrl,
    this.isSelectionMode = false,
    this.checkIn,
    this.checkOut,
    this.guests,
  });

  final HotelOfferGroup hotelGroup;
  final String imageUrl;
  final bool isSelectionMode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = hotelGroup.offers;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: _HeaderSection(),
            ),
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
                          if (isSelectionMode) {
                            Navigator.pop(context, {
                              'hotel': hotelGroup,
                              'room': room.copyWith(
                                checkInDate: checkIn,
                                checkOutDate: checkOut,
                                guests: guests != null ? HotelGuests(adults: guests!) : null,
                              ),
                            });
                          } else {
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
                          }
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

class _HeaderSection extends ConsumerWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final latestFlightAsync = ref.watch(latestFlightFromTripsProvider);

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
                  : const AssetImage('assets/image/avatar_placeholder.png')
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreens()),
              );
            },
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.gray2,
              child: Icon(Icons.person, color: AppColors.gray4),
            ),
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
                      (user.displayName != null && user.displayName!.isNotEmpty)
                      ? user.displayName!
                      : (user.email.isNotEmpty
                            ? user.email.split('@').first
                            : 'Traveler');
                  return Text(
                    'Hello, $displayText',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gray5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
                loading: () => Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.gray1,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
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
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${flight.origin} → ${flight.destination} • ${dateFormat.format(flight.departureDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray3,
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
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray3,
                            ),
                          ),
                          error: (_, __) => const Text(
                            'Lokasi tidak tersedia',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray3,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray3,
                          ),
                        ),
                        error: (_, __) => const Text(
                          'Lokasi tidak tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray3,
                          ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray3,
                          ),
                        ),
                        error: (_, __) => const Text(
                          'Lokasi tidak tersedia',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray3,
                          ),
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


