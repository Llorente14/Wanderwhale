import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../widgets/section_title.dart';
import 'create_trip.dart';
import 'package:intl/intl.dart';
import '../../utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/api_service.dart';

class TripDetailPage extends StatefulWidget {
  final String tripId;

  const TripDetailPage({
    super.key,
    required this.tripId,
  });

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}


class _TripDetailPageState extends State<TripDetailPage> {
  Trip? _trip;
  bool _isLoading = true;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _syncFromBackend();
  }

  Future<void> _loadTrip() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('trips')
          .doc(widget.tripId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        _convertTimestamps(data);
        if (mounted) {
          setState(() {
            _trip = Trip.fromJson(data);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading trip: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _convertTimestamps(Map<String, dynamic> data) {
    final keys = ['startDate', 'endDate', 'hotelCheckIn', 'hotelCheckOut', 'createdAt', 'updatedAt'];
    for (final key in keys) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
  }

  Future<void> _syncFromBackend() async {
    try {
      // Fetch updated details from backend
      // Note: getTripDetail might return TripModel or Map depending on implementation. 
      // Assuming it returns TripModel based on previous context.
      // If getTripDetail is not implemented in ApiService yet, we might skip this or implement it.
      // Checking ApiService... it has getTripDetail(String tripId).
      
      // However, ApiService.getTripDetail returns Future<TripModel>.
      // We need to convert it to JSON to store in Firestore.
      
      // Also, we might want to update the local _trip object with backend data if it's newer?
      // For now, following instructions: "Update Firestore with the latest backend data"
      
      // We only sync if we have a valid tripId that exists in backend. 
      // Since we are using Firestore ID as tripId, we assume it matches or we stored backend ID.
      // Wait, Firestore ID is auto-generated. Backend ID might be different if we didn't send Firestore ID to backend.
      // In CreateTripPage, we sent tripData to backend. Backend likely assigned its own ID?
      // Or did we send an ID?
      // In CreateTripPage: `final result = await apiService.createTrip(tripData);`
      // The result has `tripId`. We stored `backend_response` in Firestore.
      // So we should probably use the ID from `backend_response` to fetch from backend?
      // Or did we use Firestore ID as backend ID?
      // The user instruction says: `final response = await TripController().getTripDetail(tripId);`
      // This implies `tripId` is the identifier.
      // If `tripId` passed to this page is Firestore ID, we should check if it works with backend.
      // If not, we might need to look up backend ID from Firestore doc.
      
      // Let's assume for now tripId works or we just try to sync.
      // Actually, looking at `_saveTrip`, we didn't pass an ID to `createTrip`.
      // So backend generated one.
      // We stored `backend_response` which contains `tripId`.
      // We should probably use THAT id.
      
      // But first we need to load the trip from Firestore to get the backend ID.
      // _loadTrip does that.
      
      // Let's refine _syncFromBackend to wait for _loadTrip or fetch doc again.
      
      final doc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
      if (!doc.exists) return;
      
      final data = doc.data()!;
      final backendResponse = data['backend_response'];
      String? backendId;
      
      if (backendResponse is Map && backendResponse.containsKey('tripId')) {
        backendId = backendResponse['tripId'];
      } else if (backendResponse is Map && backendResponse.containsKey('id')) {
        backendId = backendResponse['id'];
      }
      
      // If we don't have a backend ID, maybe we use the Firestore ID?
      // Or maybe we can't sync.
      final idToUse = backendId ?? widget.tripId;

      try {
        final response = await _apiService.getTripDetail(idToUse);
        
        await FirebaseFirestore.instance
            .collection("trips")
            .doc(widget.tripId)
            .update({
              "backend_response": response.toJson(),
              "syncStatus": "synced",
              "updatedAt": FieldValue.serverTimestamp(),
            });
            
        // Reload local trip to reflect changes
        _loadTrip();
      } catch (e) {
        print("Backend sync error: $e");
        await FirebaseFirestore.instance
            .collection("trips")
            .doc(widget.tripId)
            .update({"syncStatus": "failed"});
      }
    } catch (e) {
      print("Sync error: $e");
    }
  }

  void _editTrip() {
    if (_trip == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTripPage(existingTrip: _trip),
      ),
    ).then((_) {
      // Reload trip data when returning from edit page
      _loadTrip();
      _syncFromBackend();
    });
  }

  void _deleteTrip() {
    if (_trip == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Trip',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: Text(
          'Are you sure you want to delete your trip to ${_trip!.destinationCity.isNotEmpty ? _trip!.destinationCity : _trip!.destination}?',
          style: TextStyle(color: Colors.grey[700]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Delete logic
              Navigator.pop(context); // Close dialog
              
              try {
                // 1. Delete from Backend
                // We need backend ID again
                 final doc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
                 final backendResponse = doc.data()?['backend_response'];
                 String? backendId;
                 if (backendResponse is Map) {
                   backendId = backendResponse['tripId'] ?? backendResponse['id'];
                 }
                 final idToUse = backendId ?? widget.tripId;

                try {
                  await _apiService.deleteTrip(idToUse);
                } catch (e) {
                  print("Backend delete error: $e");
                  // Continue to delete from Firestore? Yes, usually.
                }

                // 2. Delete from Firestore
                await FirebaseFirestore.instance
                    .collection("trips")
                    .doc(widget.tripId)
                    .delete();

                if (mounted) {
                  Navigator.pop(context); // Return to trip list
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trip deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting trip: $e')),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Trip Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        body: const Center(
          child: Text('Trip not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination
                  Text(
                    _trip!.destinationCity.isNotEmpty
                        ? _trip!.destinationCity
                        : _trip!.destination,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
              if (_trip!.originCity.isNotEmpty ||
                  _trip!.destinationCity.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.swap_horiz, color: Color(0xFF2196F3)),
                    const SizedBox(width: 8),
                    Text(
                      '${_trip!.originCity.isNotEmpty ? _trip!.originCity : 'Origin'} → ${_trip!.destinationCity.isNotEmpty ? _trip!.destinationCity : _trip!.destination}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ],
                  const SizedBox(height: 12),
                  
                  // Trip Type and Accommodation
                  Row(
                    children: [
                      _buildTripTypeTag(_trip!.tripType),
                      const SizedBox(width: 8),
                      _buildAccommodationTag(_trip!.accommodationType),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Travel Dates Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: 'Travel Dates',
                    icon: Icons.calendar_today,
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildDateRow('Start Date', _trip!.formattedStartDate),
                  const SizedBox(height: 12),
                  _buildDateRow('End Date', _trip!.formattedEndDate),
                  const SizedBox(height: 12),
                  _buildDateRow('Duration', _trip!.durationString),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Travelers Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: 'Travelers',
                    icon: Icons.people,
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        '${_trip!.travelers} ${_trip!.travelers == 1 ? 'traveler' : 'travelers'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Flight Details Section
            if (_trip!.wantFlight) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Flight Details',
                      icon: Icons.flight_takeoff,
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (_trip!.flight != null) ...[
                      _buildFlightDetailsCard(_trip!.flight!),
                    ] else ...[
                      const Text(
                        'Flight assistance enabled, but no flight selected yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Hotel Details Section
            if (_trip!.wantHotel) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Hotel Details',
                      icon: Icons.hotel,
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    if (_trip!.hotel != null) ...[
                      _buildHotelDetailsCard(_trip!.hotel!, _trip!.room),
                    ] else ...[
                      const Text(
                        'Hotel booking enabled, but no hotel selected yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            
            
            const SizedBox(height: 16),
            
            // Budget Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: 'Budget',
                    icon: Icons.attach_money,
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Text(
                        _trip!.budget != null
                            ? _trip!.formattedBudget!
                            : 'No budget provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: _trip!.budget != null
                              ? Colors.grey[800]
                              : Colors.grey[500],
                          fontWeight: _trip!.budget != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Notes Section (only if notes exist)
            if (_trip!.notes != null && _trip!.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Notes',
                      icon: Icons.note,
                    ),
                    const Divider(),
                    const SizedBox(height: 12),
                    Text(
                      _trip!.notes!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _editTrip,
                      icon: const Icon(Icons.edit),
                      label: const Text(
                        'Edit Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _deleteTrip,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text(
                        'Delete Trip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTripTypeTag(String tripType) {
    Color backgroundColor;
    Color textColor;
    
    switch (tripType.toLowerCase()) {
      case 'vacation':
        backgroundColor = Colors.blue[100]!;
        textColor = Colors.blue[800]!;
        break;
      case 'business':
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        break;
      case 'adventure':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'romantic':
        backgroundColor = Colors.pink[100]!;
        textColor = Colors.pink[800]!;
        break;
      case 'family':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
      case 'backpacking':
        backgroundColor = Colors.brown[100]!;
        textColor = Colors.brown[800]!;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tripType,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildAccommodationTag(String accommodationType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAccommodationIcon(accommodationType),
            size: 16,
            color: Colors.grey[700],
          ),
          const SizedBox(width: 6),
          Text(
            accommodationType,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAccommodationIcon(String accommodationType) {
    final type = accommodationType.toLowerCase();
    if (type.contains('hotel')) {
      return Icons.hotel;
    } else if (type.contains('airbnb') || type.contains('apartment')) {
      return Icons.apartment;
    } else if (type.contains('hostel')) {
      return Icons.bed;
    } else if (type.contains('resort')) {
      return Icons.beach_access;
    } else if (type.contains('camping') || type.contains('tent')) {
      return Icons.cabin;
    } else {
      return Icons.home;
    }
  }

  Widget _buildPreferenceRow({
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: isEnabled ? const Color(0xFF2196F3) : Colors.grey[400],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (isEnabled
                    ? const Color(0xFF2196F3)
                    : Colors.grey[400])
                ?.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            isEnabled ? 'Enabled' : 'Disabled',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isEnabled ? const Color(0xFF2196F3) : Colors.grey[500],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightDetailsCard(Map<String, dynamic> flight) {
    final airline = flight['airline'] ?? 'Unknown Airline';
    final flightNumber = flight['flightNumber'] ?? '';
    final origin = flight['origin'] ?? 'Origin';
    final destination = flight['destination'] ?? 'Dest';
    final price = flight['price'] as num?;
    final currency = flight['currency'] ?? 'IDR';
    
    DateTime? depTime;
    DateTime? arrTime;
    try {
      if (flight['departureTime'] != null) depTime = DateTime.parse(flight['departureTime']);
      if (flight['arrivalTime'] != null) arrTime = DateTime.parse(flight['arrivalTime']);
    } catch (e) {
      print("Error parsing flight times: $e");
    }

    return Card(
      elevation: 0,
      color: Colors.blue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      airline,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      flightNumber,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                if (price != null)
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: currency, decimalDigits: 0).format(price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2196F3)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(origin, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (depTime != null)
                      Text(DateFormat('HH:mm').format(depTime), style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const Icon(Icons.flight_takeoff, color: Colors.grey),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(destination, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (arrTime != null)
                      Text(DateFormat('HH:mm').format(arrTime), style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelDetailsCard(Map<String, dynamic> hotel, Map<String, dynamic>? room) {
    final hotelName = hotel['hotelName'] ?? 'Unknown Hotel';
    final rating = hotel['rating']?.toString();
    final rawAddress = hotel['address'];
    final address = rawAddress is List 
        ? rawAddress.join(', ') 
        : rawAddress?.toString() ?? 'No address';
    
    final roomType = room?['roomType'] ?? 'Standard';
    final price = room?['totalPrice'] as num?;
    
    DateTime? checkIn;
    DateTime? checkOut;
    try {
      if (room?['checkIn'] != null) checkIn = DateTime.parse(room!['checkIn']);
      if (room?['checkOut'] != null) checkOut = DateTime.parse(room!['checkOut']);
    } catch (e) {
      print("Error parsing hotel dates: $e");
    }

    return Card(
      elevation: 0,
      color: Colors.orange[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hotelName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const SizedBox(width: 4),
                      Text(rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Room: $roomType', style: const TextStyle(fontWeight: FontWeight.w500)),
                    if (checkIn != null && checkOut != null)
                      Text(
                        '${DateFormat('dd MMM').format(checkIn)} - ${DateFormat('dd MMM').format(checkOut)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
                if (price != null)
                  Text(
                    NumberFormat.currency(locale: 'id_ID', symbol: 'IDR', decimalDigits: 0).format(price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

