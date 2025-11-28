import 'package:flutter/material.dart';
import '../../models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../widgets/section_title.dart';
import 'create_trip.dart';

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
  final TripService _tripService = TripService();
  Trip? _trip;

  @override
  void initState() {
    super.initState();
    _loadTrip();
    _tripService.addListener(_onTripsChanged);
  }

  @override
  void dispose() {
    _tripService.removeListener(_onTripsChanged);
    super.dispose();
  }

  void _loadTrip() {
    setState(() {
      _trip = _tripService.getTripById(widget.tripId);
    });
  }

  void _onTripsChanged() {
    _loadTrip();
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
          'Are you sure you want to delete your trip to ${_trip!.destination}?',
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
            onPressed: () {
              _tripService.deleteTrip(widget.tripId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to trip list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip deleted successfully')),
              );
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
                    _trip!.destination,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
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
}

