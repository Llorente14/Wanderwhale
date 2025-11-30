import 'package:flutter/material.dart';
import 'package:wanderwhale/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/simple_flight_model.dart';
import '../../providers/providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../../core/theme/app_colors.dart';
import '../main/main_navigation_screen.dart';
import '../user/profile_screens.dart';
import 'flight_detail.dart';

class FlightListPage extends ConsumerStatefulWidget {
  final String origin;
  final String destination;
  final DateTime? departureDate;
  final int passengers;

  const FlightListPage({
    super.key,
    required this.origin,
    required this.destination,
    required this.passengers,
    this.departureDate,
  });

  @override
  ConsumerState<FlightListPage> createState() => _FlightListPageState();
}

class _FlightListPageState extends ConsumerState<FlightListPage> {
  bool _isLoading = true;
  List<SimpleFlightModel> _flights = [];
  String? _errorMessage;
  final Map<String, String> _cityNameMap = {};

  @override
  void initState() {
    super.initState();
    _fetchFlights();
  }

  Future<void> _fetchFlights() async {
    try {
      final date =
          widget.departureDate ?? DateTime.now().add(const Duration(days: 1));

      // Call API
      final flightOffers = await ApiService().searchFlights(
        origin: widget.origin,
        destination: widget.destination,
        date: date,
        travelers: widget.passengers,
      );

      // Map to SimpleFlightModel
      final mappedFlights = flightOffers.map((offer) {
        final itinerary = offer.itineraries.first;
        final firstSegment = itinerary.segments.first;
        final lastSegment = itinerary.segments.last;

        final originCode = firstSegment.departure.iataCode;
        final destCode = lastSegment.arrival.iataCode;

        // Store city names for later use
        if (!_cityNameMap.containsKey(originCode)) {
          _cityNameMap[originCode] = _getCityName(originCode);
        }
        if (!_cityNameMap.containsKey(destCode)) {
          _cityNameMap[destCode] = _getCityName(destCode);
        }

        // Debug print
        print('🔍 Flight List Debug:');
        print('   Widget origin: ${widget.origin}');
        print('   Widget destination: ${widget.destination}');
        print('   Flight origin: $originCode');
        print('   Flight destination: $destCode');

        return SimpleFlightModel(
          origin: originCode,
          destination: destCode,
          airline: firstSegment.carrierCode,
          flightNumber: '${firstSegment.carrierCode}${firstSegment.number}',
          departureTime: firstSegment.departure.at ?? DateTime.now(),
          arrivalTime:
              lastSegment.arrival.at ??
              DateTime.now().add(const Duration(hours: 2)),
          price: offer.price.total.toInt(),
          currency: offer.price.currency,
          aircraft: firstSegment.aircraft ?? 'Unknown',
          duration: firstSegment.duration ?? 'Unknown',
          bookingCode: offer.id,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _flights = mappedFlights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getCityName(String code) {
    const cityNames = {
      'CGK': 'Jakarta',
      'DPS': 'Bali',
      'SUB': 'Surabaya',
      'BDO': 'Bandung',
      'LON': 'London',
      'LHR': 'London',
      'LGW': 'London',
      'STN': 'London',
      'PAR': 'Paris',
      'CDG': 'Paris',
      'SIN': 'Singapore',
      'BKK': 'Bangkok',
      'KUL': 'Kuala Lumpur',
      'HND': 'Tokyo',
      'NRT': 'Tokyo',
      'ICN': 'Seoul',
      'DXB': 'Dubai',
      'JFK': 'New York',
      'LAX': 'Los Angeles',
    };
    return cityNames[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    final originCityName =
        _cityNameMap[widget.origin] ?? _getCityName(widget.origin);
    final destCityName =
        _cityNameMap[widget.destination] ?? _getCityName(widget.destination);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: _buildBottomNav(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(originCityName, destCityName)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final userAsync = ref.watch(userProvider);
    final originCityName =
        _cityNameMap[widget.origin] ?? _getCityName(widget.origin);
    final destCityName =
        _cityNameMap[widget.destination] ?? _getCityName(widget.destination);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                color: Colors.grey[700],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Flight',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$originCityName (${widget.origin}) → $destCityName (${widget.destination})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
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
                    radius: 20,
                    backgroundColor: AppColors.white,
                    backgroundImage:
                        user.photoURL != null && user.photoURL!.isNotEmpty
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null || user.photoURL!.isEmpty
                        ? const Icon(
                            Icons.person,
                            color: AppColors.gray4,
                            size: 20,
                          )
                        : null,
                  ),
                ),
                loading: () => const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gray2,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.gray2,
                  child: Icon(Icons.person, color: AppColors.gray4, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
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

  Widget _buildBody(String originCityName, String destCityName) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat penerbangan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _fetchFlights();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flights.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flight_land, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'Tidak ada penerbangan ditemukan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada penerbangan dari $originCityName ke $destCityName pada tanggal yang dipilih.\nCoba ubah tanggal atau tujuan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _flights.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final flight = _flights[index];
        return _FlightListTile(
          flight: flight,
          cityNameMap: _cityNameMap,
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => FlightBookingDetailsPage(
                  flight: flight,
                  passengers: widget.passengers,
                  cityNameMap: _cityNameMap,
                ),
              ),
            );
            if (result != null && context.mounted) {
              Navigator.pop(context, result);
            }
          },
        );
      },
    );
  }
}

class _FlightListTile extends StatelessWidget {
  final SimpleFlightModel flight;
  final VoidCallback onTap;
  final Map<String, String>? cityNameMap;

  const _FlightListTile({
    required this.flight,
    required this.onTap,
    this.cityNameMap,
  });

  String _getCityName(String code) {
    const cityNames = {
      'CGK': 'Jakarta',
      'DPS': 'Bali',
      'SUB': 'Surabaya',
      'BDO': 'Bandung',
      'LON': 'London',
      'LHR': 'London',
      'LGW': 'London',
      'STN': 'London',
      'PAR': 'Paris',
      'CDG': 'Paris',
      'SIN': 'Singapore',
      'BKK': 'Bangkok',
      'KUL': 'Kuala Lumpur',
      'HND': 'Tokyo',
      'NRT': 'Tokyo',
      'ICN': 'Seoul',
      'DXB': 'Dubai',
      'JFK': 'New York',
      'LAX': 'Los Angeles',
    };
    return cityNames[code] ?? code;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.flight_takeoff, color: Color(0xFF2196F3)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cityNameMap?[flight.origin] ?? _getCityName(flight.origin)} (${flight.origin}) → ${cityNameMap?[flight.destination] ?? _getCityName(flight.destination)} (${flight.destination})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${flight.airline} • ${flight.flightNumber} • ${flight.aircraft}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeRange(flight.departureTime, flight.arrivalTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${flight.currency} ${flight.price}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                if (flight.duration.isNotEmpty)
                  Text(
                    flight.duration.replaceFirst('PT', '').toLowerCase(),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeRange(DateTime departure, DateTime arrival) {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(departure)} – ${fmt(arrival)}';
  }
}
