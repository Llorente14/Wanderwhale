import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';

import 'hotel_rooms.dart';

class HotelRecommendations extends StatefulWidget {
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
  State<HotelRecommendations> createState() => _HotelRecommendationsState();
}

class _HotelRecommendationsState extends State<HotelRecommendations> {
  bool isNational = true;
  late String selectedCity;

  late final List<HotelOfferGroup> hotels = _mockHotelOfferGroups
      .map((json) => HotelOfferGroup.fromJson(json))
      .toList();

  late final List<String> cities = _buildCityFilters();

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
    if (widget.destination != null && widget.destination!.isNotEmpty) {
      // Try to match destination with available cities
      final match = cities.firstWhere(
        (city) =>
            city.toLowerCase().contains(widget.destination!.toLowerCase()),
        orElse: () => cities.isNotEmpty ? cities.first : '',
      );
      selectedCity = match;
    } else {
      selectedCity = cities.isNotEmpty ? cities.first : '';
    }
  }

  List<String> _buildCityFilters() {
    final uniqueCities = <String>{};
    for (final group in hotels) {
      final city = group.hotel.address?.cityName;
      if (city != null && city.isNotEmpty) {
        uniqueCities.add(city);
      }
    }
    final sorted = uniqueCities.toList()..sort();
    return sorted.isNotEmpty ? sorted : ['Jakarta'];
  }

  List<HotelOfferGroup> get filteredHotels {
    return hotels.where((group) {
      final city = _cityOf(group);
      final matchesCity = selectedCity.isEmpty
          ? true
          : city.toLowerCase() == selectedCity.toLowerCase();
      final matchesRegion = isNational
          ? _isNational(group)
          : !_isNational(group);
      return matchesCity && matchesRegion;
    }).toList();
  }

  bool _isNational(HotelOfferGroup group) {
    return (group.hotel.address?.countryCode ?? 'ID').toUpperCase() == 'ID';
  }

  String _cityOf(HotelOfferGroup group) {
    return group.hotel.address?.cityName ?? 'Unknown City';
  }

  HotelOffer? _primaryOffer(HotelOfferGroup group) {
    return group.offers.isNotEmpty ? group.offers.first : null;
  }

  String _imageFor(HotelOfferGroup group) {
    return _hotelImages[group.hotel.hotelId] ?? _fallbackImage;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildJustForYouSection(),
                    const SizedBox(height: 24),
                    _buildBestPriceSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.blue[400]),
                    const SizedBox(width: 4),
                    const Text(
                      'Jakarta, NY 112',
                      style: TextStyle(
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
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search hotels...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                ),
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

  Widget _buildJustForYouSection() {
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
          Row(
            children: [
              _buildToggleButton('National', isNational, () {
                setState(() => isNational = true);
              }),
              const SizedBox(width: 10),
              _buildToggleButton('International', !isNational, () {
                setState(() => isNational = false);
              }),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cities.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final city = cities[index];
                final isSelected = selectedCity == city;
                return GestureDetector(
                  onTap: () => setState(() => selectedCity = city),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFE5F0FF)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        city,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.blue[700]
                              : Colors.grey[700],
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filteredHotels.length,
            itemBuilder: (context, index) {
              final hotel = filteredHotels[index];
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
                    Image.network(imageUrl, fit: BoxFit.cover),
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

  Widget _buildBestPriceSection() {
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
              itemCount: hotels.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hotel = hotels[index];
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    bool selected,
    VoidCallback onPressed,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            color: selected ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.blue[700] : Colors.grey[700],
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
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
              _NavItem(icon: Icons.home, label: 'Home', isActive: true),
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

final List<Map<String, dynamic>> _mockHotelOfferGroups = [
  {
    'hotel': {
      'hotelId': 'JKT001',
      'name': 'Hotel Borobudur Jakarta',
      'cityCode': 'JKT',
      'latitude': -6.1702,
      'longitude': 106.8326,
      'rating': 4.8,
      'address': {
        'lines': 'Jl. Lapangan Banteng Selatan No.1',
        'cityName': 'Jakarta',
        'postalCode': '10710',
        'countryCode': 'ID',
        'stateCode': 'JK',
      },
      'contact': {'phone': '+62 21 1234 5678'},
    },
    'available': true,
    'offers': [
      {
        'id': 'JKT001-OFFER1',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 9))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Superior Twin',
          'description': {'text': 'Paket populer termasuk sarapan'},
          'typeEstimated': {
            'category': 'SUPERIOR',
            'beds': 2,
            'bedType': 'TWIN',
          },
        },
        'guests': {'adults': 2},
        'price': {
          'currency': 'IDR',
          'base': '1100000',
          'total': '1250000',
          'taxes': [
            {'currency': 'IDR', 'amount': '150000'},
          ],
        },
        'boardType': 'Breakfast Included',
        'policies': {'cancellation': 'Gratis hingga 24 jam sebelum check-in'},
        'paymentPolicy': 'PREPAID',
      },
      {
        'id': 'JKT001-OFFER2',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 10))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Deluxe King',
          'description': {'text': 'Kamar luas dengan city view'},
          'typeEstimated': {'category': 'DELUXE', 'beds': 1, 'bedType': 'KING'},
        },
        'guests': {'adults': 2},
        'price': {
          'currency': 'IDR',
          'base': '1350000',
          'total': '1520000',
          'taxes': [
            {'currency': 'IDR', 'amount': '170000'},
          ],
        },
        'boardType': 'Club Access',
        'paymentPolicy': 'PAY_LATER',
      },
    ],
  },
  {
    'hotel': {
      'hotelId': 'JKT002',
      'name': 'The Langham Jakarta',
      'cityCode': 'JKT',
      'latitude': -6.2297,
      'longitude': 106.8082,
      'rating': 4.9,
      'address': {
        'lines': 'District 8 SCBD Lot 28',
        'cityName': 'Jakarta',
        'postalCode': '12190',
        'countryCode': 'ID',
        'stateCode': 'JK',
      },
      'contact': {'phone': '+62 21 9876 5432'},
    },
    'available': true,
    'offers': [
      {
        'id': 'JKT002-OFFER1',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 14))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 16))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Executive Suite',
          'description': {'text': 'Termasuk akses lounge eksklusif'},
          'typeEstimated': {'category': 'SUITE', 'beds': 1, 'bedType': 'KING'},
        },
        'guests': {'adults': 3},
        'price': {
          'currency': 'IDR',
          'base': '2350000',
          'total': '2580000',
          'taxes': [
            {'currency': 'IDR', 'amount': '230000'},
          ],
        },
        'boardType': 'Executive Lounge',
        'policies': {'cancellation': '50% fee jika dibatalkan <48 jam'},
        'paymentPolicy': 'PREPAID',
      },
      {
        'id': 'JKT002-OFFER2',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 14))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 17))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Premier Twin',
          'description': {'text': 'Pilihan favorit pebisnis'},
          'typeEstimated': {
            'category': 'PREMIUM',
            'beds': 2,
            'bedType': 'TWIN',
          },
        },
        'guests': {'adults': 2},
        'price': {
          'currency': 'IDR',
          'base': '1985000',
          'total': '2130000',
          'taxes': [
            {'currency': 'IDR', 'amount': '145000'},
          ],
        },
        'boardType': 'Breakfast Included',
        'paymentPolicy': 'PAY_LATER',
      },
    ],
  },
  {
    'hotel': {
      'hotelId': 'DPS001',
      'name': 'Alila Villas Uluwatu',
      'cityCode': 'DPS',
      'latitude': -8.8283,
      'longitude': 115.092,
      'rating': 4.7,
      'address': {
        'lines': 'Jl. Belimbing Sari, Uluwatu',
        'cityName': 'Bali',
        'postalCode': '80364',
        'countryCode': 'ID',
        'stateCode': 'BA',
      },
    },
    'available': true,
    'offers': [
      {
        'id': 'DPS001-OFFER1',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 21))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 24))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Ocean View Villa',
          'description': {'text': 'Vila privat dengan pemandangan laut'},
          'typeEstimated': {'category': 'VILLA', 'beds': 1, 'bedType': 'KING'},
        },
        'guests': {'adults': 2},
        'price': {
          'currency': 'IDR',
          'base': '3150000',
          'total': '3450000',
          'taxes': [
            {'currency': 'IDR', 'amount': '300000'},
          ],
        },
        'boardType': 'Breakfast & Butler',
        'policies': {'cancellation': 'Non refundable'},
        'paymentPolicy': 'PREPAID',
      },
      {
        'id': 'DPS001-OFFER2',
        'checkInDate': DateTime.now()
            .add(const Duration(days: 21))
            .toIso8601String()
            .split('T')[0],
        'checkOutDate': DateTime.now()
            .add(const Duration(days: 25))
            .toIso8601String()
            .split('T')[0],
        'room': {
          'type': 'Family Villa',
          'description': {'text': 'Pilihan terbaik untuk keluarga'},
          'typeEstimated': {'category': 'VILLA', 'beds': 3, 'bedType': 'KING'},
        },
        'guests': {'adults': 4},
        'price': {
          'currency': 'IDR',
          'base': '3350000',
          'total': '3670000',
          'taxes': [
            {'currency': 'IDR', 'amount': '320000'},
          ],
        },
        'boardType': 'Half Board',
        'paymentPolicy': 'PAY_LATER',
      },
    ],
  },
];

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: isActive ? Colors.blue[700] : Colors.grey[500]),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue[700] : Colors.grey[500],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
