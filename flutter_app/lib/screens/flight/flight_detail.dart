import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight_booking_model.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:intl/intl.dart';

class FlightDetailScreen extends StatefulWidget {
  const FlightDetailScreen({super.key, required this.offer});

  final FlightOfferModel offer;

  @override
  State<FlightDetailScreen> createState() => _FlightDetailScreenState();
}

class _FlightDetailScreenState extends State<FlightDetailScreen> {
  Set<String> selectedSeats = {};
  String? selectedSeatType; // 'economy', 'business', 'first'

  // Seat layout: rows and columns
  final int rows = 30;
  final int seatsPerRow = 6; // A, B, C, aisle, D, E, F
  final List<String> seatLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  // Occupied seats (dummy data)
  final Set<String> occupiedSeats = {
    '1A', '1B', '2C', '3D', '5E', '5F', '7A', '8B', '10C', '12D', '15E', '20F'
  };

  late final FlightBookingModel booking;
  final DateFormat _routeDateFormat = DateFormat('EEE, dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    booking = _buildBooking(widget.offer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Flight Image
                    _buildFlightImage(),
                    // Flight Route Info
                    _buildFlightRouteInfo(),
                    const SizedBox(height: 16),
                    // Flight Details Card
                    _buildFlightDetailsCard(),
                    const SizedBox(height: 24),
                    // Seat Selection Section
                    _buildSeatSelectionSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Book Button
            _buildBookButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
            color: Colors.grey[700],
          ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
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

  Widget _buildFlightImage() {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color.fromARGB(255, 54, 19, 169),
            Colors.blue[100]!,
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.flight,
              size: 80,
              color: Colors.grey[600],
            ),
          ),
          // Decorative elements
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                booking.flightNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightRouteInfo() {
    final originLabel = _airportLabels[booking.origin] ?? booking.origin;
    final destinationLabel =
        _airportLabels[booking.destination] ?? booking.destination;
    final departureDate = booking.departureDate != null
        ? _routeDateFormat.format(booking.departureDate!)
        : '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            '$originLabel - $destinationLabel',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${booking.airline} • ${booking.flightNumber}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            departureDate,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlightDetailsCard() {
    final departureSegment = widget.offer.itineraries.first.segments.first;
    final arrivalSegment = widget.offer.itineraries.last.segments.last;
    final departureCode =
        '${_cityLabel(departureSegment.departure.iataCode)} (${departureSegment.departure.iataCode})';
    final arrivalCode =
        '${_cityLabel(arrivalSegment.arrival.iataCode)} (${arrivalSegment.arrival.iataCode})';
    final departureTerminal =
        departureSegment.departure.terminal?.code ?? 'Terminal';
    final arrivalTerminal = arrivalSegment.arrival.terminal?.code ?? 'Terminal';
    final departureAirport =
        _airportFullNames[departureSegment.departure.iataCode] ??
            'Departure airport';
    final arrivalAirport =
        _airportFullNames[arrivalSegment.arrival.iataCode] ??
            'Arrival airport';
    final departureTime = _formatTime(departureSegment.departure.at);
    final arrivalTime = _formatTime(arrivalSegment.arrival.at);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Departure
          _buildLocationSection(
            departureCode,
            departureTerminal,
            departureAirport,
            departureTime,
            Icons.flight_takeoff,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          // Inclusions
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text(
                '30kg baggage allowance for one passenger',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              const Text(
                'Meals on purchase',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Arrival
          _buildLocationSection(
            arrivalCode,
            arrivalTerminal,
            arrivalAirport,
            arrivalTime,
            Icons.flight_land,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection(
    String code,
    String terminal,
    String airport,
    String time,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          code,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          terminal,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                airport,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildSeatSelectionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Seats',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Seat Type Selection
          Row(
            children: [
              _buildSeatTypeButton('Economy', 'economy'),
              const SizedBox(width: 12),
              _buildSeatTypeButton('Business', 'business'),
              const SizedBox(width: 12),
              _buildSeatTypeButton('First', 'first'),
            ],
          ),
          const SizedBox(height: 24),
          // Seat Map
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                // Screen indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'FRONT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Seat Grid
                _buildSeatGrid(),
                const SizedBox(height: 16),
                // Legend
                _buildSeatLegend(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatTypeButton(String label, String type) {
    final isSelected = selectedSeatType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedSeatType = type;
            selectedSeats.clear(); // Clear selection when changing class
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[100] : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildSeatGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          // Seat labels row
          Row(
            children: [
              const SizedBox(width: 30), // Row number space
              ...seatLabels.map((label) => SizedBox(
                    width: 35,
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 8),
          // Seat rows
          ...List.generate(rows, (rowIndex) {
            final rowNumber = rowIndex + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                children: [
                  // Row number
                  SizedBox(
                    width: 30,
                    child: Text(
                      rowNumber.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Seats
                  ...List.generate(seatsPerRow, (colIndex) {
                    final seatLabel = seatLabels[colIndex];
                    final seatId = '$rowNumber$seatLabel';
                    final isOccupied = occupiedSeats.contains(seatId);
                    final isSelected = selectedSeats.contains(seatId);
                    final isAisle = colIndex == 3; // Middle aisle

                    if (isAisle) {
                      return const SizedBox(width: 15);
                    }

                    return GestureDetector(
                      onTap: isOccupied
                          ? null
                          : () {
                              setState(() {
                                if (isSelected) {
                                  selectedSeats.remove(seatId);
                                } else {
                                  selectedSeats.add(seatId);
                                }
                              });
                            },
                      child: Container(
                        width: 35,
                        height: 35,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: isOccupied
                              ? Colors.red[300]
                              : isSelected
                                  ? Colors.blue[400]
                                  : Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue[700]!
                                : Colors.grey[400]!,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: isOccupied
                              ? const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(Colors.grey[300]!, 'Available'),
        _buildLegendItem(Colors.blue[400]!, 'Selected'),
        _buildLegendItem(Colors.red[300]!, 'Occupied'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[400]!),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedSeats.isEmpty
                ? null
                : () {
                    final seatList = selectedSeats.toList()..sort();
                    final message =
                        'Booking ${seatList.join(', ')} • ${booking.totalPrice.toIDR()}';
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(
              'Book Flight (${booking.totalPrice.toIDR()})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
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
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, 'Home', true),
              _buildNavItem(Icons.favorite_border, 'Favorite', false),
              _buildNavItem(Icons.add_circle_outline, 'Planning', false),
              _buildNavItem(Icons.auto_awesome_outlined, 'AI Chat', false),
              _buildNavItem(Icons.settings_outlined, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? Colors.blue[700] : Colors.grey[600],
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue[700] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  FlightBookingModel _buildBooking(FlightOfferModel offer) {
    final firstSegment = offer.itineraries.first.segments.first;
    final lastSegment = offer.itineraries.last.segments.last;
    return FlightBookingModel(
      bookingId: 'TEMP-${offer.id}',
      userId: 'demo-user',
      tripId: 'trip-${offer.id}',
      bookingType: 'flight',
      confirmationNumber: 'PNR-${offer.id}',
      bookingStatus: 'PENDING',
      origin: firstSegment.departure.iataCode,
      destination: lastSegment.arrival.iataCode,
      departureDate: firstSegment.departure.at,
      arrivalDate: lastSegment.arrival.at,
      airline: _airlineNames[firstSegment.carrierCode] ??
          firstSegment.carrierCode,
      flightNumber: '${firstSegment.carrierCode}${firstSegment.number}',
      numberOfPassengers: offer.travelerPricings.length,
      primaryPassengerName: 'Traveler One',
      primaryPassengerEmail: 'traveler@example.com',
      totalPrice: offer.price.total,
      basePrice: offer.price.base,
      currency: offer.price.currency,
      paymentMethod: 'credit_card',
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      passengers: offer.travelerPricings
          .map(
            (pricing) => {
              'travelerId': pricing.travelerId,
              'travelerType': pricing.travelerType,
            },
          )
          .toList(),
      segments: offer.itineraries
          .expand((itinerary) => itinerary.segments)
          .map(
            (segment) => {
              'carrierCode': segment.carrierCode,
              'number': segment.number,
              'departure': segment.departure.iataCode,
              'arrival': segment.arrival.iataCode,
              'duration': segment.duration,
            },
          )
          .toList(),
      selectedSeats: const <Map<String, dynamic>>[],
    );
  }

  String _cityLabel(String code) => _airportLabels[code] ?? code;

  String _formatTime(DateTime? value) {
    if (value == null) return '-';
    return '${_timeFormat.format(value)} local';
  }
}

const Map<String, String> _airportLabels = {
  'CGK': 'Jakarta',
  'HND': 'Tokyo',
  'SIN': 'Singapore',
  'DPS': 'Bali',
};

const Map<String, String> _airportFullNames = {
  'CGK': 'Soekarno-Hatta International Airport',
  'HND': 'Haneda Airport',
  'SIN': 'Changi Airport',
  'DPS': 'Ngurah Rai International Airport',
};

const Map<String, String> _airlineNames = {
  'GA': 'Garuda Indonesia',
  'SQ': 'Singapore Airlines',
};

