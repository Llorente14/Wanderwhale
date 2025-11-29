import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/flight_offer_model.dart';

class FlightTicketCard extends StatelessWidget {
  const FlightTicketCard({
    super.key,
    this.offer,
    this.origin,
    this.destination,
    this.departureTime,
    this.arrivalTime,
    this.passengerName,
  });

  final FlightOfferModel? offer;
  final String? origin;
  final String? destination;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? passengerName;

  @override
  Widget build(BuildContext context) {
    // Use provided data or fallback to defaults
    final dateFormat = DateFormat('dd MMM, EEE');
    final timeFormat = DateFormat('HH:mm');
    
    if (offer == null) {
      // Fallback jika tidak ada offer
      return const SizedBox.shrink();
    }

    final firstSegment = offer!.itineraries.first.segments.first;
    final lastSegment = offer!.itineraries.last.segments.last;
    
    // Get airline name from mapping
    final carrierCode = firstSegment.carrierCode;
    final airlineName = _airlineNames[carrierCode] ?? carrierCode;
    
    // Get flight number
    final flightNumber = "${carrierCode}-${firstSegment.number}";
    
    // Get seat (use first selected seat if available, otherwise default)
    final seat = "3A"; // TODO: Get from selectedSeats in booking state
    
    // Get travel class from pricing
    final travelClass = firstSegment.pricing?.travelClass ?? "ECONOMY";
    final travelClassLabel = _formatTravelClass(travelClass);
    
    // Get airport codes and city names
    final fromCode = origin ?? firstSegment.departure.iataCode;
    final fromCity = _airportLabels[fromCode] ?? fromCode;
    final toCode = destination ?? lastSegment.arrival.iataCode;
    final toCity = _airportLabels[toCode] ?? toCode;
    
    // Get times
    final depTime = departureTime ?? firstSegment.departure.at;
    final arrTime = arrivalTime ?? lastSegment.arrival.at;
    
    final depTimeStr = depTime != null
        ? "${timeFormat.format(depTime)}, ${dateFormat.format(depTime)}"
        : "N/A";
    final arrTimeStr = arrTime != null
        ? "${timeFormat.format(arrTime)}, ${dateFormat.format(arrTime)}"
        : "N/A";
    
    final paxName = passengerName ?? "Passenger";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- BAGIAN ATAS TIKET ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Airline Header
                Row(
                  children: [
                    const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.error,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      airlineName,
                      style: AppTextStyles.baseM.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (firstSegment.aircraft != null)
                      Text(
                        firstSegment.aircraft!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray3,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Info Kursi & Flight
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildTicketInfo("Seat", seat, isLarge: true),
                    _buildTicketInfo("Class", travelClassLabel),
                    _buildTicketInfo("Flight", flightNumber),
                  ],
                ),
              ],
            ),
          ),

          // --- GARIS PUTUS-PUTUS & LENGKUNGAN (CUTOUT) ---
          SizedBox(
            height: 30,
            child: Stack(
              children: [
                // Garis Putus-putus
                Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Flex(
                        direction: Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: List.generate(
                          (constraints.constrainWidth() / 10).floor(),
                          (index) => SizedBox(
                            width: 5,
                            height: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: AppColors.gray2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Lingkaran Kiri
                Positioned(
                  left: -15,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.gray0,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Lingkaran Kanan
                Positioned(
                  right: -15,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 30,
                    decoration: const BoxDecoration(
                      color: AppColors.gray0,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BAGIAN BAWAH TIKET ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3. Rute
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRouteInfo(
                      "From",
                      fromCode,
                      fromCity,
                      depTimeStr,
                    ),
                    const Icon(
                      Icons.flight_takeoff,
                      color: AppColors.gray3,
                      size: 30,
                    ),
                    _buildRouteInfo(
                      "To",
                      toCode,
                      toCity,
                      arrTimeStr,
                      alignRight: true,
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // 4. Passenger & Barcode
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Passengers",
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paxName,
                          style: AppTextStyles.baseM.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    // Dummy Barcode
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        15,
                        (index) => Container(
                          width: index % 2 == 0 ? 4 : 2,
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketInfo(String label, String value, {bool isLarge = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: isLarge
              ? AppTextStyles.headingM.copyWith(color: AppColors.black)
              : AppTextStyles.baseM.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(
    String label,
    String code,
    String city,
    String time, {
    bool alignRight = false,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 2),
        Text(
          code,
          style: AppTextStyles.headingL.copyWith(
            color: AppColors.black,
            height: 1.0,
          ),
        ),
        Text(
          city,
          style: AppTextStyles.baseXS.copyWith(color: AppColors.gray3),
        ),
        const SizedBox(height: 4),
        Text(
          time,
          style: AppTextStyles.baseXS.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Helper methods
  String _formatTravelClass(String travelClass) {
    switch (travelClass.toUpperCase()) {
      case 'ECONOMY':
        return 'Economy';
      case 'PREMIUM_ECONOMY':
        return 'Premium Economy';
      case 'BUSINESS':
        return 'Business';
      case 'FIRST':
        return 'First Class';
      default:
        return travelClass;
    }
  }
}

// Airport and Airline mappings
const Map<String, String> _airportLabels = {
  'CGK': 'Jakarta',
  'BDO': 'Bandung',
  'SUB': 'Surabaya',
  'DPS': 'Bali',
  'HND': 'Tokyo',
  'NRT': 'Tokyo',
  'SIN': 'Singapore',
  'KUL': 'Kuala Lumpur',
  'BKK': 'Bangkok',
  'SGN': 'Ho Chi Minh',
  'LAS': 'Las Vegas',
  'LAX': 'Los Angeles',
  'JFK': 'New York',
  'LHR': 'London',
  'CDG': 'Paris',
  'DXB': 'Dubai',
  'DOH': 'Doha',
  'ICN': 'Seoul',
  'PEK': 'Beijing',
  'PVG': 'Shanghai',
};

const Map<String, String> _airlineNames = {
  'GA': 'Garuda Indonesia',
  'SQ': 'Singapore Airlines',
  'MH': 'Malaysia Airlines',
  'TG': 'Thai Airways',
  'JL': 'Japan Airlines',
  'NH': 'ANA',
  'KE': 'Korean Air',
  'CX': 'Cathay Pacific',
  'QF': 'Qantas',
  'EK': 'Emirates',
  'QR': 'Qatar Airways',
  'TK': 'Turkish Airlines',
  'LH': 'Lufthansa',
  'AF': 'Air France',
  'BA': 'British Airways',
  'AA': 'American Airlines',
  'DL': 'Delta Air Lines',
  'UA': 'United Airlines',
};
