import 'package:flutter/material.dart';
import 'package:wanderwhale/models/flight_offer_model.dart';
import 'package:wanderwhale/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/flight_providers.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../../core/theme/app_colors.dart';
import '../main/main_navigation_screen.dart';
import '../user/profile_screens.dart';
import '../notification/notification_screen.dart';
import 'flight_booking_details.dart';
import 'flight_card.dart';

class FlightRecommendation extends ConsumerStatefulWidget {
  const FlightRecommendation({super.key});

  @override
  ConsumerState<FlightRecommendation> createState() =>
      _FlightRecommendationScreenState();
}

class _FlightRecommendationScreenState
    extends ConsumerState<FlightRecommendation> {
  bool isNational = true;
  // Removed selectedDestination filter - only using National/International
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  // Nullable to indicate no search performed yet
  FlightSearchParams? searchParams;

  // Store city name mappings (IATA code -> City name)
  final Map<String, String> _cityNameMap = {};

  @override
  void initState() {
    super.initState();
    // Start with no search params (empty state)
    searchParams = null;
  }

  void _updateDestination(String newDestinationCode) async {
    // Check if widget is still mounted before async operation
    if (!mounted) return;

    // Try to get city name from location search
    String? cityName;
    try {
      final results = await ref.read(
        locationSearchProvider(newDestinationCode).future,
      );

      // Check again after async operation
      if (!mounted) return;

      if (results.isNotEmpty) {
        final firstResult = results.first;
        final address = firstResult['address'] ?? {};
        cityName =
            address['cityName'] ?? firstResult['name'] ?? newDestinationCode;
      }
    } catch (e) {
      print('⚠️ Failed to get city name for $newDestinationCode: $e');
      // If error occurs, check mounted before setState
      if (!mounted) return;
    }

    // Final check before setState
    if (!mounted) return;

    setState(() {
      searchParams = FlightSearchParams({
        "originDestinations": [
          {
            "id": "1",
            "originLocationCode": "CGK",
            "destinationLocationCode": newDestinationCode,
            "departureDateTimeRange": {"date": "2025-12-14"},
          },
          {
            "id": "2",
            "originLocationCode": newDestinationCode,
            "destinationLocationCode": "CGK",
            "departureDateTimeRange": {"date": "2025-12-18"},
          },
        ],
        "travelers": [
          {"id": "1", "travelerType": "ADULT"},
        ],
        "sources": ["GDS"],
        "searchCriteria": {"maxFlightOffers": 20},
      });

      // Store city name mapping
      if (cityName != null) {
        _cityNameMap[newDestinationCode] = cityName;
        print('✅ Stored city mapping: $newDestinationCode -> $cityName');
      }

      // Also store CGK -> Jakarta mapping
      _cityNameMap['CGK'] = 'Jakarta';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Only watch provider if searchParams is not null
    final AsyncValue<List<FlightOfferModel>>? offersAsync = searchParams != null
        ? ref.watch(flightOffersProvider(searchParams!))
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
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
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (offers) {
                        if (offers.isEmpty) {
                          return _buildNoFlightsState();
                        }

                        // Extract and store city names from offers
                        _extractCityNames(offers);

                        // Debug: Check offers before filtering
                        print('🔍 Total offers from API: ${offers.length}');

                        // TEMPORARY: Don't filter - show all offers
                        // final filtered = _getFilteredOffers(offers);
                        final filtered =
                            offers; // Show all offers without filtering

                        print(
                          '🔍 Offers to display (after filter): ${filtered.length}',
                        );
                        print(
                          '🔍 Filter mode: ${isNational ? "National" : "International"}',
                        );

                        if (filtered.isEmpty) {
                          return _buildNoFlightsState(
                            message: isNational
                                ? 'Tidak ada penerbangan domestik ditemukan.\nCoba cari penerbangan internasional.'
                                : 'Tidak ada penerbangan internasional ditemukan.\nCoba cari penerbangan domestik.',
                          );
                        }

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildJustForYouSection(filtered, []),
                              const SizedBox(height: 24),
                              _buildBestPriceSection(offers),
                              const SizedBox(height: 24),
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
          Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Where do you want to go?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a destination to see flight offers',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFlightsState({String? message}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flight_land, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada penerbangan ditemukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Coba ubah tujuan atau tanggal pencarian Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  void _extractCityNames(List<FlightOfferModel> offers) {
    for (final offer in offers) {
      final originCode = _originCode(offer);
      final destCode = _destinationCode(offer);

      // Store origin city name if not exists
      if (!_cityNameMap.containsKey(originCode)) {
        _cityNameMap[originCode] = _cityLabel(originCode);
      }

      // Store destination city name if not exists
      if (!_cityNameMap.containsKey(destCode)) {
        _cityNameMap[destCode] = _cityLabel(destCode);
      }
    }

    if (_cityNameMap.isNotEmpty) {
      print('🔍 City name mappings: $_cityNameMap');
    }
  }

  // TEMPORARY: Filtering disabled - showing all offers
  // List<FlightOfferModel> _getFilteredOffers(List<FlightOfferModel> offers) {
  //   // Only filter by National/International, no destination filter
  //   return offers.where((offer) {
  //     final domestic = _isDomestic(offer);
  //     return isNational ? domestic : !domestic;
  //   }).toList();
  // }

  // bool _isDomestic(FlightOfferModel offer) {
  //   final destination = _destinationCode(offer);
  //   return _indonesianAirports.contains(destination);
  // }

  Widget _buildHeader() {
    final userAsync = ref.watch(userProvider);
    final locationAsync = ref.watch(userLocationTextProvider);
    final unreadAsync = ref.watch(unreadNotificationsProvider);
    final latestFlightAsync = ref.watch(latestFlightFromTripsProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Icons.search, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.length < 3) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  // Check if widget is still mounted before using ref
                  if (!mounted) {
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
                  final code = selection['iataCode'];
                  if (code != null) {
                    _updateDestination(code);
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
                          hintText: 'Search destination (e.g. Bali)...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
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
                        width:
                            MediaQuery.of(context).size.width -
                            32, // Match container width
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
            IconButton(
              icon: Icon(Icons.tune, color: Colors.grey[600]),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJustForYouSection(
    List<FlightOfferModel> cards,
    List<String> destinations,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Just For You',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildToggleButton('National', isNational, () {
                setState(() => isNational = true);
              }),
              const SizedBox(width: 12),
              _buildToggleButton('International', !isNational, () {
                setState(() => isNational = false);
              }),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              itemBuilder: (context, index) {
                return _buildRecommendationCard(cards[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(FlightOfferModel offer) {
    final route = _routeLabel(offer);
    final airline = _airlineLabel(offer);
    final price = offer.price.total.toIDR();
    final departure = _formatDeparture(offer);
    final travelClass =
        offer.itineraries.first.segments.first.pricing?.travelClass ??
        'ECONOMY';

    return GestureDetector(
      onTap: () {
        // Pass city name map to booking details screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlightBookingDetailsScreen(offer: offer),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A2A6C), Color(0xFF3F8EFC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.flight_takeoff,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    route,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$airline • ${_titleCase(travelClass)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    departure,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBestPriceSection(List<FlightOfferModel> offers) {
    final sorted = [...offers]
      ..sort((a, b) => a.price.total.compareTo(b.price.total));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Best Price This Month',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FlightsCardScreen(offers: offers),
                    ),
                  );
                },
                child: const Text('See all'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: sorted.length,
              itemBuilder: (context, index) {
                return _buildPriceCard(sorted[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(FlightOfferModel offer) {
    final route = _routeLabel(offer);
    final price = offer.price.total.toIDR();
    final departure = _formatDeparture(offer);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlightBookingDetailsScreen(offer: offer),
          ),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF132F7C), Color(0xFF4EB8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                departure,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _routeLabel(FlightOfferModel offer) {
    final origin = _cityLabel(_originCode(offer));
    final destination = _cityLabel(_destinationCode(offer));
    return '$origin → $destination';
  }

  String _originCode(FlightOfferModel offer) {
    return offer.itineraries.first.segments.first.departure.iataCode;
  }

  String _destinationCode(FlightOfferModel offer) {
    // Use the first itinerary (outbound) to determine the destination of the trip
    return offer.itineraries.first.segments.last.arrival.iataCode;
  }

  String _cityLabel(String code) {
    return _airportLabels[code] ?? code;
  }

  String _airlineLabel(FlightOfferModel offer) {
    final carrier = offer.itineraries.first.segments.first.carrierCode;
    return _airlineNames[carrier] ?? carrier;
  }

  String _formatDeparture(FlightOfferModel offer) {
    final date = offer.itineraries.first.segments.first.departure.at;
    if (date == null) return '-';
    return _dateFormat.format(date);
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Widget _buildBottomNav(BuildContext context) {
    return CustomBottomNav(
      onIndexChanged: (index) {
        // Check if widget is still mounted before using ref
        if (!mounted) return;

        // Navigate to MainNavigationScreen with the selected index
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) {
              // Set the index before navigating - safe because we're in builder
              if (mounted) {
                ref.read(bottomNavIndexProvider.notifier).state = index;
              }
              return const MainNavigationScreen();
            },
          ),
          (route) => false, // Remove all previous routes
        );
      },
    );
  }
}

const Set<String> _indonesianAirports = {
  'CGK',
  'BDO',
  'SUB',
  'DPS',
  'YIA',
  'LOP',
  'UPG',
};

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
