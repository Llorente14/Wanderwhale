import 'package:flutter/material.dart';
import 'package:flutter_app/models/simple_flight_model.dart';
import 'package:intl/intl.dart';

class FlightBookingDetailsPage extends StatefulWidget {
  const FlightBookingDetailsPage({
    super.key,
    required this.flight,
    required this.passengers,
    this.cityNameMap,
  });

  final SimpleFlightModel flight;
  final int passengers;
  final Map<String, String>? cityNameMap;

  @override
  State<FlightBookingDetailsPage> createState() =>
      _FlightBookingDetailsPageState();
}

class _FlightBookingDetailsPageState extends State<FlightBookingDetailsPage> {
  Set<String> selectedSeats = {};
  String? selectedSeatType = 'Economy'; // Default to Economy

  // Seat layout: rows and columns
  final int rows = 30;
  final int seatsPerRow = 6; // A, B, C, aisle, D, E, F
  final List<String> seatLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  // Occupied seats (dummy data)
  final Set<String> occupiedSeats = {
    '1A',
    '1B',
    '2C',
    '3D',
    '5E',
    '5F',
    '7A',
    '8B',
    '10C',
    '12D',
    '15E',
    '20F',
  };

  final DateFormat _routeDateFormat = DateFormat('EEE, dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

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
      // bottomNavigationBar: _buildBottomNavBar(), // Removed bottom nav as this is a sub-page
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
          const Spacer(),
          const Text(
            'Flight Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
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
          colors: [const Color.fromARGB(255, 54, 19, 169), Colors.blue[100]!],
        ),
      ),
      child: Stack(
        children: [
          Center(child: Icon(Icons.flight, size: 80, color: Colors.grey[600])),
          // Decorative elements
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.flight.flightNumber,
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
    // Get city name from map or use fallback
    final originCityName =
        widget.cityNameMap?[widget.flight.origin] ??
        _airportLabels[widget.flight.origin] ??
        widget.flight.origin;
    final destCityName =
        widget.cityNameMap?[widget.flight.destination] ??
        _airportLabels[widget.flight.destination] ??
        widget.flight.destination;
    final departureDate = _routeDateFormat.format(widget.flight.departureTime);

    // Get airline name dynamically
    final airlineName = _getAirlineName(widget.flight.airline);

    // Debug print
    print('🔍 Flight Detail Debug:');
    print('   Origin: ${widget.flight.origin} -> $originCityName');
    print('   Destination: ${widget.flight.destination} -> $destCityName');
    print('   City name map: ${widget.cityNameMap}');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            '$originCityName (${widget.flight.origin}) - $destCityName (${widget.flight.destination})',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$airlineName • ${widget.flight.flightNumber} • ${widget.flight.aircraft}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            departureDate,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  String _getAirlineName(String code) {
    const airlineNames = {
      'GA': 'Garuda Indonesia',
      'JT': 'Lion Air',
      'SJ': 'Sriwijaya Air',
      'ID': 'Batik Air',
      'QG': 'Citilink',
      'QZ': 'AirAsia',
      'SQ': 'Singapore Airlines',
      'MH': 'Malaysia Airlines',
      'TG': 'Thai Airways',
      'JL': 'Japan Airlines',
      'KE': 'Korean Air',
      'CX': 'Cathay Pacific',
      'QF': 'Qantas',
      'EK': 'Emirates',
      'QR': 'Qatar Airways',
      'LH': 'Lufthansa',
      'BA': 'British Airways',
      'AF': 'Air France',
      'KL': 'KLM',
      'DL': 'Delta Air Lines',
      'AA': 'American Airlines',
      'UA': 'United Airlines',
    };
    return airlineNames[code] ?? code;
  }

  Widget _buildFlightDetailsCard() {
    final departureCode =
        '${_cityLabel(widget.flight.origin)} (${widget.flight.origin})';
    final arrivalCode =
        '${_cityLabel(widget.flight.destination)} (${widget.flight.destination})';

    // Mock terminal info as it's not in SimpleFlightModel
    const departureTerminal = 'Terminal 1';
    const arrivalTerminal = 'Terminal 2';

    final departureAirport =
        _airportFullNames[widget.flight.origin] ?? 'Departure Airport';
    final arrivalAirport =
        _airportFullNames[widget.flight.destination] ?? 'Arrival Airport';

    final departureTime = _formatTime(widget.flight.departureTime);
    final arrivalTime = _formatTime(widget.flight.arrivalTime);

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
                '30kg baggage allowance',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Duration: ${widget.flight.duration}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.airplane_ticket, size: 16, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Booking Code: ${widget.flight.bookingCode}',
                style: const TextStyle(fontSize: 12),
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(terminal, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                airport,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Your Seats',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${selectedSeats.length}/${widget.passengers} Selected',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selectedSeats.length == widget.passengers
                      ? Colors.green
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Seat Type Selection
          Row(
            children: [
              _buildSeatTypeButton('Economy', 'Economy'),
              const SizedBox(width: 12),
              _buildSeatTypeButton('Business', 'Business'),
              const SizedBox(width: 12),
              _buildSeatTypeButton('First', 'First'),
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
              ...seatLabels.map(
                (label) => SizedBox(
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
                ),
              ),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                                  if (selectedSeats.length <
                                      widget.passengers) {
                                    selectedSeats.add(seatId);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'You can only select ${widget.passengers} seats',
                                        ),
                                      ),
                                    );
                                  }
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
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }

  Widget _buildBookButton() {
    final totalPrice = widget.flight.price * widget.passengers;
    final isReady = selectedSeats.length == widget.passengers;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
            onPressed: isReady
                ? () {
                    Navigator.pop(context, {
                      'flight': widget.flight,
                      'seats': selectedSeats.toList(),
                    });
                  }
                : null,
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
              isReady
                  ? 'Confirm Booking (\$${totalPrice})'
                  : 'Select ${widget.passengers - selectedSeats.length} more seat(s)',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
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
