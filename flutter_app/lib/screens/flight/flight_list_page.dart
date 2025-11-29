import 'package:flutter/material.dart';

import '../../models/simple_flight_model.dart';
import 'flight_detail.dart';

class FlightListPage extends StatelessWidget {
  final String originCity;
  final String destinationCity;
  final DateTime? departureDate;

  final int passengers;

  const FlightListPage({
    super.key,
    required this.originCity,
    required this.destinationCity,
    required this.passengers,
    this.departureDate,
  });

  List<SimpleFlightModel> get _mockFlights {
    final baseDate = departureDate ?? DateTime.now().add(const Duration(days: 7));
    return [
      SimpleFlightModel(
        origin: originCity,
        destination: destinationCity,
        airline: 'AirFast',
        flightNumber: 'AF120',
        departureTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 8, 0),
        arrivalTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0),
        price: 120,
        aircraft: 'Boeing 737-800',
      ),
      SimpleFlightModel(
        origin: originCity,
        destination: destinationCity,
        airline: 'SkyWings',
        flightNumber: 'SW330',
        departureTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 13, 30),
        arrivalTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 16, 5),
        price: 150,
        aircraft: 'Airbus A320',
      ),
      SimpleFlightModel(
        origin: originCity,
        destination: destinationCity,
        airline: 'FlyGo',
        flightNumber: 'FG987',
        departureTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 18, 45),
        arrivalTime: DateTime(baseDate.year, baseDate.month, baseDate.day, 21, 10),
        price: 99,
        aircraft: 'Boeing 737-MAX',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final flights = _mockFlights;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Flight',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: flights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final flight = flights[index];
          return _FlightListTile(
            flight: flight,
            onTap: () async {
              final result = await Navigator.push<Map<String, dynamic>>(
                context,
                MaterialPageRoute(
                  builder: (_) => FlightBookingDetailsPage(
                    flight: flight,
                    passengers: passengers,
                  ),
                ),
              );
              if (result != null && context.mounted) {
                Navigator.pop(context, result);
              }
            },
          );
        },
      ),
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
            Text(
              '\$${flight.price}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2C3E50),
              ),
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



