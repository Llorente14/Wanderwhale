import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/flight_providers.dart';
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
  String selectedDestination = '';
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm');

  // Nullable to indicate no search performed yet
  FlightSearchParams? searchParams;

  @override
  void initState() {
    super.initState();
    // Start with no search params (empty state)
    searchParams = null;
  }

  void _updateDestination(String newDestinationCode) {
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
      selectedDestination = ''; // Reset filter
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
                          return const Center(child: Text('No flights found.'));
                        }

                        final destinations = _buildDestinations(offers);

                        // Auto-select first destination if none selected
                        if (selectedDestination.isEmpty &&
                            destinations.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {
                                selectedDestination = destinations.first;
                              });
                            }
                          });
                        }

                        final filtered = _getFilteredOffers(offers);

                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildJustForYouSection(filtered, destinations),
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

  List<String> _buildDestinations(List<FlightOfferModel> offers) {
    final codes = offers
        .map((offer) => _destinationCode(offer))
        .toSet()
        .toList();
    codes.sort();
    return codes;
  }

  List<FlightOfferModel> _getFilteredOffers(List<FlightOfferModel> offers) {
    final regionFiltered = offers.where((offer) {
      final domestic = _isDomestic(offer);
      return isNational ? domestic : !domestic;
    }).toList();

    final destinationMatches = regionFiltered.where((offer) {
      return selectedDestination.isEmpty
          ? true
          : _destinationCode(offer) == selectedDestination;
    }).toList();

    if (destinationMatches.isNotEmpty) {
      return destinationMatches;
    }
    if (regionFiltered.isNotEmpty) {
      return regionFiltered;
    }
    return offers;
  }

  bool _isDomestic(FlightOfferModel offer) {
    final destination = _destinationCode(offer);
    return _indonesianAirports.contains(destination);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
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
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final code = destinations[index];
                final isSelected = selectedDestination == code;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => selectedDestination = code);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue[100] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          _cityLabel(code),
                          style: TextStyle(
                            color: isSelected
                                ? Colors.blue[700]
                                : Colors.grey[700],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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
