import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/hotel_providers.dart';
import '../../providers/flight_providers.dart'; // For locationSearchProvider
import '../../providers/providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../../core/theme/app_colors.dart';
import '../main/main_navigation_screen.dart';
import '../user/profile_screens.dart';
import '../notification/notification_screen.dart';
import 'hotel_rooms.dart';

class HotelRecommendations extends ConsumerStatefulWidget {
  final String? destination;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;

  const HotelRecommendations({
    super.key,
    this.destination,
    this.checkIn,
    this.checkOut,
    this.guests,
  });

  @override
  ConsumerState<HotelRecommendations> createState() =>
      _HotelRecommendationsState();
}

class _HotelRecommendationsState extends ConsumerState<HotelRecommendations> {
  bool isNational = true;

  // Nullable to indicate no search performed yet
  String? selectedCityCode;
  String selectedCityName = '';

  final Map<String, String> _hotelImages = {
    'JKT001':
        'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=900&q=60',
    'JKT002':
        'https://images.unsplash.com/photo-1501117716987-c8e1ecb210cc?auto=format&fit=crop&w=900&q=60',
    'DPS001':
        'https://images.unsplash.com/photo-1505691938895-1758d7feb511?auto=format&fit=crop&w=900&q=60',
  };

  static const _fallbackImage =
      'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=900&q=60';

  @override
  void initState() {
    super.initState();
    // If destination is provided (from trip creation), try to search for it
    if (widget.destination != null && widget.destination!.isNotEmpty) {
      _searchDestination(widget.destination!);
    } else {
      selectedCityCode = null;
    }
  }

  Future<void> _searchDestination(String destination) async {
    try {
      // Search for the destination using location search
      final results = await ref.read(
        locationSearchProvider(destination).future,
      );
      if (results.isNotEmpty) {
        final firstResult = results.first;
        final code = firstResult['iataCode'];
        final address = firstResult['address'] ?? {};
        final city = address['cityName'] ?? firstResult['name'] ?? destination;

        if (code != null && mounted) {
          setState(() {
            selectedCityCode = code;
            selectedCityName = city;
          });
        }
      }
    } catch (e) {
      // If search fails, just set the name without code
      if (mounted) {
        setState(() {
          selectedCityName = destination;
        });
      }
    }
  }

  void _updateCity(String code, String name) {
    setState(() {
      selectedCityCode = code;
      selectedCityName = name;
    });
  }

  HotelOffer? _primaryOffer(HotelOfferGroup group) {
    return group.offers.isNotEmpty ? group.offers.first : null;
  }

  String _imageFor(HotelOfferGroup group) {
    return _hotelImages[group.hotel.hotelId] ?? _fallbackImage;
  }

  String _cityOf(HotelOfferGroup group) {
    return group.hotel.address?.cityName ?? 'Unknown City';
  }

  @override
  Widget build(BuildContext context) {
    // Build search params with check-in, check-out, and guests from widget
    final searchParams = selectedCityCode != null
        ? HotelSearchByCityParams(
            cityCode: selectedCityCode!,
            checkIn: widget.checkIn,
            checkOut: widget.checkOut,
            adults: widget.guests,
          )
        : null;

    final offersAsync = searchParams != null
        ? ref.watch(hotelSearchByCityProvider(searchParams))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: offersAsync == null
                  ? _buildEmptyState()
                  : offersAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) {
                        print('❌ Hotel search error: $err');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Gagal memuat hotel',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  err.toString(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  // Refresh the provider
                                  if (searchParams != null) {
                                    ref.invalidate(
                                      hotelSearchByCityProvider(searchParams),
                                    );
                                  }
                                },
                                child: const Text('Coba Lagi'),
                              ),
                            ],
                          ),
                        );
                      },
                      data: (hotels) {
                        if (hotels.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hotel_outlined,
                                    size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                Text(
                                  'Tidak ada hotel ditemukan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Coba cari kota lain atau ubah tanggal',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildJustForYouSection(hotels),
                              const SizedBox(height: 24),
                              _buildBestPriceSection(hotels),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Where do you want to stay?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a city to see hotel offers',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final latestFlightAsync = ref.watch(latestFlightFromTripsProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          userAsync.when(
            data: (user) => GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreens(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.white,
                backgroundImage:
                    user.photoURL != null && user.photoURL!.isNotEmpty
                    ? NetworkImage(user.photoURL!)
                    : null,
                child: user.photoURL == null || user.photoURL!.isEmpty
                    ? const Icon(Icons.person, color: AppColors.gray4)
                    : null,
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
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreens(),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.gray2,
                child: const Icon(Icons.person, color: AppColors.gray4),
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
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey[500]),
            const SizedBox(width: 12),
            Expanded(
              child: Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.length < 3) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  return ref.read(
                    locationSearchProvider(textEditingValue.text).future,
                  );
                },
                displayStringForOption: (Map<String, dynamic> option) {
                  final address = option['address'] ?? {};
                  final city = address['cityName'] ?? option['name'] ?? '';
                  final code = option['iataCode'] ?? '';
                  return '$city ($code)';
                },
                onSelected: (Map<String, dynamic> selection) {
                  final code =
                      selection['iataCode']; // This is usually City Code for cities
                  final address = selection['address'] ?? {};
                  final city = address['cityName'] ?? selection['name'] ?? '';

                  if (code != null) {
                    _updateCity(code, city);
                  }
                },
                fieldViewBuilder:
                    (
                      context,
                      textEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      return TextField(
                        controller: textEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search city (e.g. Bali, Paris)...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          border: InputBorder.none,
                        ),
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width - 32,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final option = options.elementAt(index);
                            final address = option['address'] ?? {};
                            final city =
                                address['cityName'] ?? option['name'] ?? '';
                            final code = option['iataCode'] ?? '';
                            return ListTile(
                              title: Text('$city ($code)'),
                              subtitle: Text(address['countryName'] ?? ''),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F1FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.tune, color: Colors.blue[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJustForYouSection(List<HotelOfferGroup> hotels) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Just For You',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return _buildHotelCard(hotel);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(HotelOfferGroup group) {
    final offer = _primaryOffer(group);
    final imageUrl = _imageFor(group);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelRooms(
              hotelGroup: group,
              imageUrl: imageUrl,
              isSelectionMode: widget.checkIn != null,
              checkIn: widget.checkIn,
              checkOut: widget.checkOut,
              guests: widget.guests,
            ),
          ),
        ).then((result) {
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[300]);
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.yellow,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (group.hotel.rating ?? 0).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.hotel.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _cityOf(group),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    offer != null
                        ? '${offer.price.total.toIDR()} / night'
                        : 'No offer',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
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

  Widget _buildBestPriceSection(List<HotelOfferGroup> hotels) {
    // Sort by price
    final sorted = [...hotels];
    sorted.sort((a, b) {
      final priceA = _primaryOffer(a)?.price.total ?? double.infinity;
      final priceB = _primaryOffer(b)?.price.total ?? double.infinity;
      return priceA.compareTo(priceB);
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Best Price This Month',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hotel = sorted[index];
                return _buildPriceCard(hotel);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(HotelOfferGroup group) {
    final offer = _primaryOffer(group);
    final imageUrl = _imageFor(group);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelRooms(
              hotelGroup: group,
              imageUrl: imageUrl,
              isSelectionMode: widget.checkIn != null,
              checkIn: widget.checkIn,
              checkOut: widget.checkOut,
              guests: widget.guests,
            ),
          ),
        ).then((result) {
          if (result != null && mounted) {
            Navigator.pop(context, result);
          }
        });
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A2A6C), Color(0xFF93CEF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _cityOf(group),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.hotel.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      offer != null ? offer.price.total.toIDR() : 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18),
                ),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.white.withOpacity(0.2));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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
