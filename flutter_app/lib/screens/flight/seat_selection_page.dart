import 'package:flutter/material.dart';
import '../../models/simple_flight_model.dart';

class SeatSelectionPage extends StatefulWidget {
  final SimpleFlightModel flight;
  final int passengers;

  const SeatSelectionPage({
    super.key,
    required this.flight,
    required this.passengers,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  List<String> _selectedSeats = [];

  // Mock seat layout: 6 rows (A-F), 4 seats per row (1-4)
  final List<String> _availableSeats = [
    'A1', 'A2', 'A3', 'A4',
    'B1', 'B2', 'B3', 'B4',
    'C1', 'C2', 'C3', 'C4',
    'D1', 'D2', 'D3', 'D4',
    'E1', 'E2', 'E3', 'E4',
    'F1', 'F2', 'F3', 'F4',
  ];

  final List<String> _occupiedSeats = ['A2', 'B3', 'D1', 'E4', 'F2']; // Mock occupied seats

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select ${widget.passengers} Seat(s)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2C3E50),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flight info header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.flight.origin} → ${widget.flight.destination}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.flight.airline} • ${widget.flight.flightNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Seat map legend
                  _buildLegend(),
                  const SizedBox(height: 20),
                  
                  // Seat map
                  _buildSeatMap(),
                  
                  const SizedBox(height: 20),
                  
                  // Selected seat info
                  if (_selectedSeats.isNotEmpty) _buildSelectedSeatInfo(),
                ],
              ),
            ),
          ),
          
          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(20),
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
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _selectedSeats.length == widget.passengers
                      ? () {
                          Navigator.pop(context, _selectedSeats);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _selectedSeats.length == widget.passengers
                        ? 'Confirm Seats'
                        : 'Select ${widget.passengers - _selectedSeats.length} more',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(
          color: const Color(0xFF2196F3),
          label: 'Available',
        ),
        _buildLegendItem(
          color: Colors.grey[400]!,
          label: 'Occupied',
        ),
        _buildLegendItem(
          color: const Color(0xFFFFC107),
          label: 'Selected',
        ),
      ],
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
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

  Widget _buildSeatMap() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          // Cabin class label
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Economy Class',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2196F3),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Seat grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _availableSeats.length,
            itemBuilder: (context, index) {
              final seat = _availableSeats[index];
              final isOccupied = _occupiedSeats.contains(seat);
              final isSelected = _selectedSeats.contains(seat);
              
              return _SeatButton(
                seatCode: seat,
                isOccupied: isOccupied,
                isSelected: isSelected,
                onTap: isOccupied
                    ? null
                    : () {
                        setState(() {
                          if (_selectedSeats.contains(seat)) {
                            _selectedSeats.remove(seat);
                          } else if (_selectedSeats.length < widget.passengers) {
                            _selectedSeats.add(seat);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('You can only select ${widget.passengers} seats'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        });
                      },
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Aisle indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 2,
                color: Colors.grey[300],
              ),
              const Text(
                'Aisle',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Container(
                width: 40,
                height: 2,
                color: Colors.grey[300],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2196F3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF2196F3),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Seats',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2196F3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedSeats.join(', '),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
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

class _SeatButton extends StatelessWidget {
  final String seatCode;
  final bool isOccupied;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SeatButton({
    required this.seatCode,
    required this.isOccupied,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    if (isOccupied) {
      backgroundColor = Colors.grey[400]!;
      textColor = Colors.white;
      borderColor = Colors.grey[400]!;
    } else if (isSelected) {
      backgroundColor = const Color(0xFFFFC107);
      textColor = Colors.white;
      borderColor = const Color(0xFFFFC107);
    } else {
      backgroundColor = const Color(0xFF2196F3);
      textColor = Colors.white;
      borderColor = const Color(0xFF2196F3);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            seatCode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

