import 'package:flutter/material.dart';
import 'package:wanderwhale/models/simple_flight_model.dart';
import 'package:wanderwhale/core/theme/app_colors.dart';
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
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

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
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate border radius based on scroll offset
    final borderRadius = (_scrollOffset / 100 * 28).clamp(0.0, 28.0);

    // Get city names
    final originCityName =
        widget.cityNameMap?[widget.flight.origin] ??
        _airportLabels[widget.flight.origin] ??
        widget.flight.origin;
    final destCityName =
        widget.cityNameMap?[widget.flight.destination] ??
        _airportLabels[widget.flight.destination] ??
        widget.flight.destination;
    final airlineName = _getAirlineName(widget.flight.airline);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ),
        title: Text(
          '$originCityName → $destCityName',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Hero Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _HeroImage(
              airlineName: airlineName,
              flightNumber: widget.flight.flightNumber,
            ),
          ),
          // Scrollable Content
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) => true,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Spacer to push content below image
                    const SizedBox(height: 300),
                    // Content Section with dynamic rounded top
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(borderRadius),
                          topRight: Radius.circular(borderRadius),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Flight Route Header
                            _buildFlightRouteHeader(
                              originCityName,
                              destCityName,
                              airlineName,
                            ),
                            const SizedBox(height: 24),
                            // Flight Details Card
                            _buildFlightDetailsCard(),
                            const SizedBox(height: 24),
                            // Seat Selection Section
                            _buildSeatSelectionSection(),
                            const SizedBox(height: 100), // Space for button
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Book Button (Fixed at bottom)
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBookButton()),
        ],
      ),
    );
  }

  Widget _buildFlightRouteHeader(
    String originCityName,
    String destCityName,
    String airlineName,
  ) {
    final departureDate = _routeDateFormat.format(widget.flight.departureTime);
    final departureTime = _timeFormat.format(widget.flight.departureTime);
    final arrivalTime = _timeFormat.format(widget.flight.arrivalTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$originCityName → $destCityName',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.gray5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.flight, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              '$airlineName • ${widget.flight.flightNumber}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLight3,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departureTime,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    originCityName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray4,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.flight, color: AppColors.primary, size: 24),
                  Text(
                    widget.flight.duration,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.gray3,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    arrivalTime,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    destCityName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.gray4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          departureDate,
          style: const TextStyle(fontSize: 13, color: AppColors.gray3),
        ),
      ],
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
    final originCityName =
        widget.cityNameMap?[widget.flight.origin] ??
        _airportLabels[widget.flight.origin] ??
        widget.flight.origin;
    final destCityName =
        widget.cityNameMap?[widget.flight.destination] ??
        _airportLabels[widget.flight.destination] ??
        widget.flight.destination;

    final departureAirport =
        _airportFullNames[widget.flight.origin] ?? 'Departure Airport';
    final arrivalAirport =
        _airportFullNames[widget.flight.destination] ?? 'Arrival Airport';

    final departureTime = _formatTime(widget.flight.departureTime);
    final arrivalTime = _formatTime(widget.flight.arrivalTime);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Flight Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.gray5,
            ),
          ),
          const SizedBox(height: 20),
          // Departure
          _buildLocationSection(
            '${originCityName} (${widget.flight.origin})',
            'Terminal 1',
            departureAirport,
            departureTime,
            Icons.flight_takeoff,
            AppColors.primary,
          ),
          const SizedBox(height: 24),
          // Divider with flight icon
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.gray2)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.flight, color: AppColors.primary, size: 20),
              ),
              Expanded(child: Divider(color: AppColors.gray2)),
            ],
          ),
          const SizedBox(height: 24),
          // Arrival
          _buildLocationSection(
            '${destCityName} (${widget.flight.destination})',
            'Terminal 2',
            arrivalAirport,
            arrivalTime,
            Icons.flight_land,
            AppColors.error,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          // Flight Details
          _buildInfoRow(
            Icons.airplane_ticket,
            'Booking Code',
            widget.flight.bookingCode,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.check_circle, 'Baggage Allowance', '30kg'),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.airplanemode_active,
            'Aircraft',
            widget.flight.aircraft,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.gray4),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.gray5,
          ),
        ),
      ],
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
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    terminal,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.gray3,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            airport,
            style: const TextStyle(fontSize: 13, color: AppColors.gray4),
          ),
        ),
      ],
    );
  }

  Widget _buildSeatSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select Your Seats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.gray5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: selectedSeats.length == widget.passengers
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.gray1,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${selectedSeats.length}/${widget.passengers} Selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selectedSeats.length == widget.passengers
                      ? AppColors.success
                      : AppColors.gray4,
                ),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Screen indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.gray2,
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
            color: isSelected ? AppColors.primaryLight3 : AppColors.gray1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray2,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.gray4,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isReady)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Select ${widget.passengers - selectedSeats.length} more seat(s)',
                  style: const TextStyle(fontSize: 13, color: AppColors.gray3),
                ),
              ),
            SizedBox(
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: AppColors.gray2,
                  elevation: 0,
                ),
                child: Text(
                  isReady
                      ? 'Confirm Booking (${totalPrice.toStringAsFixed(0)} ${widget.flight.currency})'
                      : 'Select Seats',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '--:--';
    return _timeFormat.format(value);
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.airlineName, required this.flightNumber});

  final String airlineName;
  final String flightNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark1],
              ),
            ),
          ),
          // Decorative pattern
          Positioned.fill(child: CustomPaint(painter: _FlightPatternPainter())),
          // Content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flight_takeoff,
                  size: 80,
                  color: Colors.white.withOpacity(0.9),
                ),
                const SizedBox(height: 16),
                Text(
                  airlineName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    flightNumber,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw flight path lines
    for (int i = 0; i < 5; i++) {
      final y = size.height * (0.2 + i * 0.15);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw circles
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.12);
      final y = size.height * (0.3 + (i % 3) * 0.2);
      canvas.drawCircle(Offset(x, y), 20, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
