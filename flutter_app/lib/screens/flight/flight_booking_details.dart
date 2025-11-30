import 'package:flutter/material.dart';
import 'package:flutter_app/models/flight_offer_model.dart';
import 'package:flutter_app/providers/booking_providers.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'checkout_flight.dart';

class FlightBookingDetailsScreen extends ConsumerStatefulWidget {
  const FlightBookingDetailsScreen({super.key, required this.offer});

  final FlightOfferModel offer;

  @override
  ConsumerState<FlightBookingDetailsScreen> createState() =>
      _FlightBookingDetailsScreenState();
}

class _FlightBookingDetailsScreenState
    extends ConsumerState<FlightBookingDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(flightBookingProvider.notifier);
      notifier.setOffer(widget.offer);
      final currentState = ref.read(flightBookingProvider);
      if (currentState.passengers.isEmpty) {
        notifier.setPassengers(_buildInitialPassengers(widget.offer));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(flightBookingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flight Booking Details')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FlightOverview(
                offer: widget.offer,
                dateFormat: _dateFormat,
                timeFormat: _timeFormat,
              ),
              const SizedBox(height: 16),
              _DatePickerSection(
                selectedDate: bookingState.departureDate,
                onDateSelected: ref
                    .read(flightBookingProvider.notifier)
                    .setDepartureDate,
              ),
              const SizedBox(height: 16),
              _TripNoteField(currentValue: bookingState.tripId),
              const SizedBox(height: 24),
              _PassengerSection(passengers: bookingState.passengers),
              const SizedBox(height: 24),
              _SeatSelectionSection(
                selectedSeats: bookingState.selectedSeats,
                onToggle: ref.read(flightBookingProvider.notifier).toggleSeat,
              ),
              const SizedBox(height: 24),
              _BookingSummary(
                totalPrice: bookingState.totalPrice,
                passengerCount: bookingState.passengerCount,
                selectedSeats: bookingState.selectedSeats.length,
                currency: widget.offer.price.currency,
                unitPrice: bookingState.passengerUnitPrice,
                seatPrice: bookingState.seatPrice,
                seatsTotalPrice: bookingState.seatsTotalPrice,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _CheckoutButton(
        enabled: bookingState.isReadyForCheckout,
        onTap: () => _handleCheckout(context, bookingState),
        label: 'Proceed to Checkout (${bookingState.totalPrice.toIDR()})',
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    FlightBookingState state,
  ) async {
    final payload = state.buildPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data penumpang terlebih dahulu.'),
        ),
      );
      return;
    }

    // Navigate ke checkout screen
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CheckoutFlightScreen()),
    );
  }

  List<FlightPassengerForm> _buildInitialPassengers(FlightOfferModel offer) {
    final travelerPricings = offer.travelerPricings;
    if (travelerPricings.isEmpty) {
      return const [FlightPassengerForm()];
    }
    return travelerPricings
        .map((pricing) => FlightPassengerForm(type: pricing.travelerType))
        .toList();
  }
}

class _FlightOverview extends StatelessWidget {
  const _FlightOverview({
    required this.offer,
    required this.dateFormat,
    required this.timeFormat,
  });

  final FlightOfferModel offer;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final firstSegment = offer.itineraries.first.segments.first;
    final lastSegment = offer.itineraries.last.segments.last;
    final outboundDestination = offer.itineraries.first.segments.last;
    final departureDate = firstSegment.departure.at != null
        ? dateFormat.format(firstSegment.departure.at!)
        : '-';
    final departureTime = firstSegment.departure.at != null
        ? timeFormat.format(firstSegment.departure.at!)
        : '--:--';
    final arrivalTime = lastSegment.arrival.at != null
        ? timeFormat.format(lastSegment.arrival.at!)
        : '--:--';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${firstSegment.departure.iataCode} → ${outboundDestination.arrival.iataCode}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(departureDate, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 16),
          Row(
            children: [
              _TimeTile(label: 'Departure', value: departureTime),
              const SizedBox(width: 16),
              _TimeTile(label: 'Arrival', value: arrivalTime),
              const Spacer(),
              Text(
                offer.price.total.toIDR(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripNoteField extends ConsumerStatefulWidget {
  const _TripNoteField({required this.currentValue});

  final String? currentValue;

  @override
  ConsumerState<_TripNoteField> createState() => _TripNoteFieldState();
}

class _TripNoteFieldState extends ConsumerState<_TripNoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue ?? '');
  }

  @override
  void didUpdateWidget(covariant _TripNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = widget.currentValue ?? '';
    if (newValue != _controller.text) {
      _controller.text = newValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Reference',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Contoh: Liburan Bali Desember',
          ),
          onChanged: (value) =>
              ref.read(flightBookingProvider.notifier).setTrip(value),
        ),
        const SizedBox(height: 6),
        Text(
          'Catatan ini hanya disimpan sementara di perangkat ini.',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}

class _DatePickerSection extends StatelessWidget {
  const _DatePickerSection({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime? selectedDate;
  final void Function(DateTime?) onDateSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Departure Date',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  selectedDate != null
                      ? DateFormat('EEE, dd MMM yyyy').format(selectedDate!)
                      : 'Select departure date',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedDate != null
                        ? Colors.black
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _PassengerSection extends ConsumerWidget {
  const _PassengerSection({required this.passengers});

  final List<FlightPassengerForm> passengers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Passenger Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () =>
                  ref.read(flightBookingProvider.notifier).addPassenger(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (passengers.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Belum ada penumpang. Tambahkan minimal 1.'),
          )
        else
          ...List.generate(
            passengers.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PassengerCard(index: index, passenger: passengers[index]),
            ),
          ),
      ],
    );
  }
}

class _PassengerCard extends ConsumerStatefulWidget {
  const _PassengerCard({required this.index, required this.passenger});

  final int index;
  final FlightPassengerForm passenger;

  @override
  ConsumerState<_PassengerCard> createState() => _PassengerCardState();
}

class _PassengerCardState extends ConsumerState<_PassengerCard> {
  final List<String> passengerTypes = const ['ADULT', 'CHILD', 'INFANT'];

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(flightBookingProvider.notifier);
    final passenger = widget.passenger;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Passenger ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (widget.index > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.removePassenger(widget.index),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: passenger.type,
            items: passengerTypes
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              notifier.updatePassenger(
                widget.index,
                passenger.copyWith(type: value),
              );
            },
            decoration: const InputDecoration(labelText: 'Passenger Type'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: passenger.firstName,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (value) => notifier.updatePassenger(
                    widget.index,
                    passenger.copyWith(firstName: value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: passenger.lastName,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (value) => notifier.updatePassenger(
                    widget.index,
                    passenger.copyWith(lastName: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: passenger.dateOfBirth ?? DateTime(1990, 1, 1),
                firstDate: DateTime(1930),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                notifier.updatePassenger(
                  widget.index,
                  passenger.copyWith(dateOfBirth: picked),
                );
              }
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
              ),
              child: Text(
                passenger.dateOfBirth != null
                    ? DateFormat('dd MMM yyyy').format(passenger.dateOfBirth!)
                    : 'Select date',
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: passenger.email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => notifier.updatePassenger(
              widget.index,
              passenger.copyWith(email: value),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: passenger.phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
            onChanged: (value) => notifier.updatePassenger(
              widget.index,
              passenger.copyWith(phone: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeatSelectionSection extends StatelessWidget {
  const _SeatSelectionSection({
    required this.selectedSeats,
    required this.onToggle,
  });

  final List<String> selectedSeats;
  final void Function(String seatId) onToggle;

  static const seatLabels = ['A', 'B', 'C', 'D', 'E', 'F'];
  static const occupiedSeats = {
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
  static const rows = 30;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seat Selection (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'FRONT',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 360,
                child: SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 30),
                            ...seatLabels.map(
                              (label) => SizedBox(
                                width: 36,
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
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
                        ...List.generate(rows, (rowIndex) {
                          final rowNumber = rowIndex + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    rowNumber.toString().padLeft(2, '0'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                ...List.generate(seatLabels.length, (colIndex) {
                                  final seatId =
                                      '$rowNumber${seatLabels[colIndex]}';
                                  final isAisle = colIndex == 3;
                                  if (isAisle) {
                                    return const SizedBox(width: 18);
                                  }
                                  final isOccupied = occupiedSeats.contains(
                                    seatId,
                                  );
                                  final isSelected = selectedSeats.contains(
                                    seatId,
                                  );
                                  return GestureDetector(
                                    onTap: isOccupied
                                        ? null
                                        : () => onToggle(seatId),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isOccupied
                                            ? Colors.red[300]
                                            : isSelected
                                            ? Colors.blue[400]
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.blue[800]!
                                              : Colors.grey[400]!,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          seatId,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isOccupied || isSelected
                                                ? Colors.white
                                                : Colors.grey[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const _SeatLegend(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _LegendItem(color: Color(0xFFD6D6D6), label: 'Available'),
        _LegendItem(color: Color(0xFF1D82F0), label: 'Selected'),
        _LegendItem(color: Color(0xFFE57373), label: 'Occupied'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: Colors.grey[700])),
      ],
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({
    required this.totalPrice,
    required this.passengerCount,
    required this.selectedSeats,
    required this.currency,
    required this.unitPrice,
    required this.seatPrice,
    required this.seatsTotalPrice,
  });

  final double totalPrice;
  final int passengerCount;
  final int selectedSeats;
  final String currency;
  final double unitPrice;
  final double seatPrice;
  final double seatsTotalPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Passengers', value: '$passengerCount pax'),
          _SummaryRow(
            label: 'Selected seats',
            value: selectedSeats > 0 ? '$selectedSeats seats' : 'Not selected',
          ),
          _SummaryRow(label: 'Fare per passenger', value: unitPrice.toIDR()),
          if (selectedSeats > 0)
            _SummaryRow(
              label: 'Seat price (${seatPrice.toIDR()} × $selectedSeats)',
              value: seatsTotalPrice.toIDR(),
            ),
          const Divider(height: 24),
          _SummaryRow(
            label: 'Total ($currency)',
            value: totalPrice.toIDR(),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  final bool enabled;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
