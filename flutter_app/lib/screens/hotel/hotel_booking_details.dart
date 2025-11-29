import 'package:flutter/material.dart';
import 'package:flutter_app/models/hotel_offer_model.dart';
import 'package:flutter_app/models/trip_model.dart';
import 'package:flutter_app/providers/booking_providers.dart';
import 'package:flutter_app/providers/providers.dart';
import 'package:flutter_app/utils/formatters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class HotelBookingDetailsScreen extends ConsumerStatefulWidget {
  const HotelBookingDetailsScreen({
    super.key,
    required this.hotelGroup,
    required this.offer,
    required this.imageUrl,
  });

  final HotelOfferGroup hotelGroup;
  final HotelOffer offer;
  final String imageUrl;

  @override
  ConsumerState<HotelBookingDetailsScreen> createState() =>
      _HotelBookingDetailsScreenState();
}

class _HotelBookingDetailsScreenState
    extends ConsumerState<HotelBookingDetailsScreen> {
  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(hotelBookingProvider.notifier);
      notifier.setContext(
        offer: widget.offer,
        hotel: widget.hotelGroup.hotel,
      );
      final currentState = ref.read(hotelBookingProvider);
      if (currentState.guests.isEmpty) {
        notifier.setGuests(_buildInitialGuests(widget.offer));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(hotelBookingProvider);
    final tripsAsync = ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Booking Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HotelSummaryCard(
                    hotelGroup: widget.hotelGroup,
                    offer: widget.offer,
                    imageUrl: widget.imageUrl,
                    dateFormat: _dateFormat,
                  ),
                  const SizedBox(height: 24),
                  _TripSelector(tripsAsync: tripsAsync, currentTrip: bookingState.tripId),
                  const SizedBox(height: 24),
                  _DateSelectionSection(
                    checkInDate: bookingState.checkInDate,
                    checkOutDate: bookingState.checkOutDate,
                    onCheckInSelected: (date) => ref.read(hotelBookingProvider.notifier).setDates(checkIn: date),
                    onCheckOutSelected: (date) => ref.read(hotelBookingProvider.notifier).setDates(checkOut: date),
                    dateFormat: _dateFormat,
                  ),
                  const SizedBox(height: 24),
                  _GuestSection(guests: bookingState.guests),
                  const SizedBox(height: 24),
                  _PriceBreakdown(
                    currency: widget.offer.price.currency,
                    basePrice: bookingState.basePrice,
                    taxes: bookingState.taxes,
                    total: bookingState.totalPrice,
                  ),
                  const SizedBox(height: 24),
                  _CheckoutButton(
                    enabled: bookingState.isReadyForCheckout,
                    label: 'Save & Continue (${bookingState.totalPrice.toIDR()})',
                    onTap: () => _handleCheckout(context, bookingState),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckout(
    BuildContext context,
    HotelBookingState state,
  ) async {
    final payload = state.buildPayload();
    if (payload == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapi data tamu terlebih dahulu.',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detail booking hotel tersimpan. Lanjut ke checkout!'),
      ),
    );
  }

  List<HotelGuestForm> _buildInitialGuests(HotelOffer offer) {
    final guests = offer.guests.adults + (offer.guests.children ?? 0);
    if (guests == 0) {
      return const [HotelGuestForm()];
    }
    return List.generate(guests, (_) => const HotelGuestForm());
  }
}

class _HotelSummaryCard extends StatelessWidget {
  const _HotelSummaryCard({
    required this.hotelGroup,
    required this.offer,
    required this.imageUrl,
    required this.dateFormat,
  });

  final HotelOfferGroup hotelGroup;
  final HotelOffer offer;
  final String imageUrl;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final room = offer.room;
    final checkIn = offer.checkInDate;
    final checkOut = offer.checkOutDate;
    final stayLabel = (checkIn != null && checkOut != null)
        ? '${dateFormat.format(checkIn)} → ${dateFormat.format(checkOut)}'
        : 'Flexible dates';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotelGroup.hotel.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hotelGroup.hotel.address?.lines ?? '-',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: stayLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  room?.description ?? room?.type ?? 'Room',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${offer.price.total.toIDR()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }
}

class _TripSelector extends ConsumerWidget {
  const _TripSelector({
    required this.tripsAsync,
    required this.currentTrip,
  });

  final AsyncValue<List<TripModel>> tripsAsync;
  final String? currentTrip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return tripsAsync.when(
      data: (trips) {
        if (trips.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No trips available (Optional). You can proceed without attaching a trip.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attach to Trip',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: currentTrip,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Trip',
              ),
              items: trips
                  .map(
                    (trip) => DropdownMenuItem<String>(
                      value: trip.tripId,
                      child: Text(trip.tripName),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  ref.read(hotelBookingProvider.notifier).setTrip(value),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          err.toString(),
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }
}

class _EmptyTripInfo extends StatelessWidget {
  const _EmptyTripInfo({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Belum ada trip yang tersedia. Buat trip di halaman Travel Plan.',
            ),
          ),
          TextButton(
            onPressed: onRefresh,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}

class _DateSelectionSection extends StatelessWidget {
  const _DateSelectionSection({
    required this.checkInDate,
    required this.checkOutDate,
    required this.onCheckInSelected,
    required this.onCheckOutSelected,
    required this.dateFormat,
  });

  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final void Function(DateTime?) onCheckInSelected;
  final void Function(DateTime?) onCheckOutSelected;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stay Duration',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DatePickerTile(
                label: 'Check-in',
                date: checkInDate,
                dateFormat: dateFormat,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: checkInDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    onCheckInSelected(picked);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DatePickerTile(
                label: 'Check-out',
                date: checkOutDate,
                dateFormat: dateFormat,
                onTap: () async {
                  final initialDate = checkOutDate ?? 
                      (checkInDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)));
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: initialDate,
                    firstDate: checkInDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    onCheckOutSelected(picked);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile({
    required this.label,
    required this.date,
    required this.dateFormat,
    required this.onTap,
  });

  final String label;
  final DateTime? date;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    date != null ? dateFormat.format(date!) : 'Select',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestSection extends ConsumerWidget {
  const _GuestSection({required this.guests});

  final List<HotelGuestForm> guests;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(hotelBookingProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Guest Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.person_add_alt),
              onPressed: notifier.addGuest,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (guests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Tambahkan minimal satu tamu.'),
          )
        else
          ...List.generate(
            guests.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GuestCard(
                index: index,
                guest: guests[index],
              ),
            ),
          ),
      ],
    );
  }
}

class _GuestCard extends ConsumerStatefulWidget {
  const _GuestCard({
    required this.index,
    required this.guest,
  });

  final int index;
  final HotelGuestForm guest;

  @override
  ConsumerState<_GuestCard> createState() => _GuestCardState();
}

class _GuestCardState extends ConsumerState<_GuestCard> {
  final List<String> titles = const ['MR', 'MRS', 'MS'];

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(hotelBookingProvider.notifier);
    final guest = widget.guest;

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
                'Guest ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (widget.index > 0)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => notifier.removeGuest(widget.index),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            value: guest.title,
            decoration: const InputDecoration(labelText: 'Title'),
            items: titles
                .map(
                  (title) => DropdownMenuItem(
                    value: title,
                    child: Text(title),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              notifier.updateGuest(
                widget.index,
                guest.copyWith(title: value),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: guest.firstName,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (value) => notifier.updateGuest(
                    widget.index,
                    guest.copyWith(firstName: value),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: guest.lastName,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (value) => notifier.updateGuest(
                    widget.index,
                    guest.copyWith(lastName: value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: guest.email,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            onChanged: (value) => notifier.updateGuest(
              widget.index,
              guest.copyWith(email: value),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: guest.phone,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
            onChanged: (value) => notifier.updateGuest(
              widget.index,
              guest.copyWith(phone: value),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSection extends StatelessWidget {
  const _PaymentMethodSection({
    required this.methods,
    required this.selected,
    required this.onSelected,
  });

  final List<String> methods;
  final String? selected;
  final void Function(String? method) onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: methods
              .map(
                (method) => ChoiceChip(
                  label: Text(method.toUpperCase()),
                  selected: selected == method,
                  onSelected: (_) => onSelected(method),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.currency,
    required this.basePrice,
    required this.taxes,
    required this.total,
  });

  final String currency;
  final double basePrice;
  final double taxes;
  final double total;

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
            'Price Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _PriceRow(label: 'Base price ($currency)', value: basePrice.toIDR()),
          _PriceRow(label: 'Taxes & fees', value: taxes.toIDR()),
          const Divider(height: 24),
          _PriceRow(
            label: 'Total',
            value: total.toIDR(),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
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
              fontSize: emphasize ? 18 : 14,
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
    required this.label,
    required this.onTap,
  });

  final bool enabled;
  final String label;
  final VoidCallback onTap;

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
}

