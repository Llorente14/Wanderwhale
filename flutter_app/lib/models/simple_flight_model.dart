class SimpleFlightModel {
  final String origin;
  final String destination;
  final String airline;
  final String flightNumber;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int price; // in chosen currency minor units or whole amount
  final String currency;

  final String aircraft;

  const SimpleFlightModel({
    required this.origin,
    required this.destination,
    required this.airline,
    required this.flightNumber,
    required this.departureTime,
    required this.arrivalTime,
    required this.price,
    this.currency = 'USD',
    this.aircraft = 'Boeing 737-800',
    this.duration = '3h 00m',
    this.bookingCode = 'BK-27819',
  });

  final String duration;
  final String bookingCode;
}


