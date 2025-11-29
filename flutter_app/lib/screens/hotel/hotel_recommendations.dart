import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/hotel_providers.dart';
import '../../providers/flight_providers.dart'; // For locationSearchProvider
import 'hotel_rooms.dart';

class HotelRecommendations extends ConsumerStatefulWidget {
  const HotelRecommendations({super.key});

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
    selectedCityCode = null;
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
    final AsyncValue<List<HotelOfferGroup>>? offersAsync = selectedCityCode != null
        ? ref.watch(hotelSearchByCityProvider(selectedCityCode!))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
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
                      error: (err, stack) =>
                          Center(child: Text('Error: $err')),
                      data: (hotels) {
                        if (hotels.isEmpty) {
                          return const Center(
                              child: Text('No hotels found in this city.'));
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
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    Text(
                      selectedCityName.isNotEmpty ? selectedCityName : 'Select Location',
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
            icon: Icon(Icons.notifications_none, color: Colors.grey[700]),
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
                  return ref.read(locationSearchProvider(textEditingValue.text).future);
                },
                displayStringForOption: (Map<String, dynamic> option) {
                  final address = option['address'] ?? {};
                  final city = address['cityName'] ?? option['name'] ?? '';
                  final code = option['iataCode'] ?? '';
                  return '$city ($code)';
                },
                onSelected: (Map<String, dynamic> selection) {
                  final code = selection['iataCode']; // This is usually City Code for cities
                  final address = selection['address'] ?? {};
                  final city = address['cityName'] ?? selection['name'] ?? '';
                  
                  if (code != null) {
                    _updateCity(code, city);
                  }
                },
                fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
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
                            final city = address['cityName'] ?? option['name'] ?? '';
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Filter buttons removed for simplicity in search-first flow, 
          // or can be re-added to filter the RESULT list.
          // For now, just show the results.
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
            ),
          ),
        );
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
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.yellow, size: 14),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
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
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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
            ),
          ),
        );
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF0A2A6C),
              Color(0xFF93CEF5),
            ],
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
}
