import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/services/api_service.dart';
import '../../models/simple_flight_model.dart';
import 'flight_detail.dart';

class FlightListPage extends StatefulWidget {
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
  State<FlightListPage> createState() => _FlightListPageState();
}

class _FlightListPageState extends State<FlightListPage> {
  bool _isLoading = true;
  List<SimpleFlightModel> _flights = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchFlights();
  }

  Future<void> _fetchFlights() async {
    try {
      final date = widget.departureDate ?? DateTime.now().add(const Duration(days: 1));
      
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

        return SimpleFlightModel(
          origin: firstSegment.departure.iataCode,
          destination: lastSegment.arrival.iataCode,
          airline: firstSegment.carrierCode, // In a real app, map code to name
          flightNumber: '${firstSegment.carrierCode}${firstSegment.number}',
          departureTime: firstSegment.departure.at ?? DateTime.now(),
          arrivalTime: lastSegment.arrival.at ?? DateTime.now().add(const Duration(hours: 2)),
          price: offer.price.total.toInt(),
          currency: offer.price.currency,
          aircraft: firstSegment.aircraft ?? 'Unknown',
          duration: firstSegment.duration ?? 'Unknown',
          bookingCode: offer.id, // Using ID as booking code reference
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Flight',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.origin} → ${widget.destination}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                'Failed to load flights',
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
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_flights.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flight_takeoff, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No flights found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Try changing your dates or route.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
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
          onTap: () async {
            final result = await Navigator.push<Map<String, dynamic>>(
              context,
              MaterialPageRoute(
                builder: (_) => FlightBookingDetailsPage(
                  flight: flight,
                  passengers: widget.passengers,
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

  const _FlightListTile({
    required this.flight,
    required this.onTap,
  });

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
                    '${flight.origin} → ${flight.destination}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${flight.airline} • ${flight.flightNumber} • ${flight.aircraft}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimeRange(flight.departureTime, flight.arrivalTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
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
