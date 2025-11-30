import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../models/trip_model.dart';
import '../../models/simple_flight_model.dart';
import '../../services/trip_service.dart';
import '../flight/flight_list_page.dart';

import 'dart:async';
import '../../models/hotel_offer_model.dart';
import '../hotel/hotel_recommendations.dart';
import '../../utils/formatters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class CreateTripPage extends StatefulWidget {
  final Trip? existingTrip; // For editing existing trips

  const CreateTripPage({super.key, this.existingTrip});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final PageController _pageController = PageController();
  final TripService _tripService = TripService();
  
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Form fields
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _travelers = 1;
  String? _tripType;
  String? _accommodationType;
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _wantFlight = false;
  bool _wantHotel = false;
  SimpleFlightModel? _chosenFlight;
  List<String> _chosenSeats = [];
  HotelOfferGroup? _chosenHotel;
  HotelOffer? _chosenRoom;

  String? _selectedOriginIata;
  String? _selectedDestinationIata;
  String? _selectedDestinationCityName;
  
  Timer? _originDebounce;
  Completer<Iterable<Map<String, dynamic>>>? _originCompleter;
  bool _isSearchingOrigin = false;

  Timer? _destinationDebounce;
  Completer<Iterable<Map<String, dynamic>>>? _destinationCompleter;
  bool _isSearchingDestination = false;

  bool _isSaving = false;

  static const List<_FlightOption> _mockFlights = [
    _FlightOption(airline: 'AirFast', departureTime: '08:00', priceText: '\$120'),
    _FlightOption(airline: 'SkyWings', departureTime: '13:30', priceText: '\$150'),
    _FlightOption(airline: 'FlyGo', departureTime: '18:45', priceText: '\$99'),
  ];

  static const List<_HotelOption> _mockHotels = [
    _HotelOption(name: 'Sunrise Hotel', rating: 4.5, priceText: '\$60 / night'),
    _HotelOption(name: 'City Comfort Inn', rating: 4.0, priceText: '\$45 / night'),
    _HotelOption(name: 'Grand Plaza', rating: 4.8, priceText: '\$120 / night'),
  ];

  final List<String> _tripTypes = [
    'Vacation',
    'Business',
    'Adventure',
    'Romantic',
    'Family',
    'Backpacking',
  ];

  final List<String> _accommodationTypes = [
    'Hotel',
    'Apartment',
    'Airbnb',
    'Hostel',
    'Resort',
    'Camping',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingTrip != null) {
      _loadExistingTrip();
    }
  }



  void _loadExistingTrip() {
    final trip = widget.existingTrip!;
    _originController.text = trip.originCity;
    _destinationController.text =
        trip.destinationCity.isNotEmpty ? trip.destinationCity : trip.destination;
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _travelers = trip.travelers;
    _tripType = trip.tripType;
    _accommodationType = trip.accommodationType;
    _wantFlight = trip.wantFlight;
    _wantHotel = trip.wantHotel;
    if (trip.budget != null) {
      _budgetController.text = trip.budget!.toStringAsFixed(0);
    }
    if (trip.notes != null) {
      _notesController.text = trip.notes!;
    }
    // Future: load persisted chosen flight once wired to backend model
  }

  @override
  void dispose() {
    _pageController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _calculatedDuration {
    if (_startDate != null && _endDate != null) {
      final days = _endDate!.difference(_startDate!).inDays;
      return days == 0 ? 1 : days;
    }
    return 0;
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _originController.text.trim().isNotEmpty &&
            _destinationController.text.trim().isNotEmpty;
      case 1:
        return _startDate != null && _endDate != null && _calculatedDuration > 0;
      case 2:
        return _travelers > 0;
      case 3:
        return _tripType != null;
      case 4:
        return _accommodationType != null;
      case 5:
      case 6:
        return true; // Budget and notes are optional
      default:
        return false;
    }
  }

  Future<void> _saveTrip() async {
    if (!_canProceedToNextStep()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Use selected IATA codes if available, otherwise fallback to text (though text might fail if not IATA)
      // Ideally we force selection, but for robustness:
      final originCity = _selectedOriginIata ?? _originController.text.trim();
      final destinationCity = _selectedDestinationIata ?? _destinationController.text.trim();
      
      // Prepare Flight Data
      Map<String, dynamic>? flightData;
      if (_wantFlight && _chosenFlight != null) {
        flightData = {
          "airline": _chosenFlight!.airline,
          "flightNumber": _chosenFlight!.flightNumber,
          "aircraft": _chosenFlight!.aircraft,
          "origin": _chosenFlight!.origin,
          "destination": _chosenFlight!.destination,
          "departure": _chosenFlight!.departureTime.toIso8601String(),
          "arrival": _chosenFlight!.arrivalTime.toIso8601String(),
          "price": _chosenFlight!.price,
        };
      }

      // Prepare Hotel Data
      Map<String, dynamic>? hotelData;
      Map<String, dynamic>? roomData;
      if (_wantHotel && _chosenHotel != null && _chosenRoom != null) {
        hotelData = {
          "hotelName": _chosenHotel!.hotel.name,
          "hotelId": _chosenHotel!.hotel.hotelId,
          "rating": _chosenHotel!.hotel.rating,
          "address": _chosenHotel!.hotel.address?.lines,
        };
        
        roomData = {
          "roomType": _chosenRoom!.room?.type ?? 'Standard',
          "description": _chosenRoom!.room?.description,
          "pricePerNight": _chosenRoom!.price.total, // Assuming total is per night or total for stay, usually total for stay in Amadeus
          "totalPrice": _chosenRoom!.price.total,
          "checkIn": _chosenRoom!.checkInDate?.toIso8601String(),
          "checkOut": _chosenRoom!.checkOutDate?.toIso8601String(),
        };
      }

      // Determine Trip Name for Display
      String displayDestinationName;
      if (_selectedDestinationCityName != null) {
        displayDestinationName = _selectedDestinationCityName!;
      } else {
        // Try to parse "City (IATA)" from controller text
        final text = _destinationController.text.trim();
        final match = RegExp(r'^(.*?)\s*\([A-Z]{3}\)$').firstMatch(text);
        if (match != null) {
          displayDestinationName = match.group(1) ?? text;
        } else {
          displayDestinationName = text; // Fallback to whatever user typed
        }
      }

      final tripData = {
        "tripName": "Trip to $displayDestinationName",
        "origin": originCity,
        "destination": destinationCity, // This might be IATA, which is fine for 'destination'
        "destinationCity": displayDestinationName, // Save full city name for display
        "startDate": _startDate!.toIso8601String(),
        "endDate": _endDate!.toIso8601String(),
        "durationInDays": _calculatedDuration,
        "travelers": _travelers, // Fixed: changed from 'passengers' to 'travelers'
        "tripType": _tripType,
        "accommodationType": _accommodationType,
        "budget": _budgetController.text.trim().isNotEmpty
            ? double.tryParse(_budgetController.text.trim())
            : null,
        "notes": _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        
        "wantFlight": _wantFlight,
        "wantHotel": _wantHotel,
        
        // Flight
        "flight": flightData,
        "seats": _wantFlight ? _chosenSeats : null,

        // Hotel
        "hotel": hotelData,
        "room": roomData,
      };

      // 1. Send to backend
      final apiService = ApiService();
      dynamic backendResponse;
      String syncStatus = 'pending';
      String? backendTripId;

      try {
         if (widget.existingTrip != null) {
            final result = await apiService.updateTrip(widget.existingTrip!.id, tripData);
            backendResponse = result.toJson();
            backendTripId = result.tripId;
            syncStatus = 'synced';
         } else {
            final result = await apiService.createTrip(tripData);
            backendResponse = result.toJson();
            backendTripId = result.tripId;
            syncStatus = 'synced';
         }
      } catch (e) {
        print("Backend error: $e");
        backendResponse = {"error": e.toString()};
        syncStatus = 'failed';
        // We continue to save to Firebase even if backend fails
      }

      // 2. Save to Firebase
      final user = FirebaseAuth.instance.currentUser;
      final firestoreData = {
        ...tripData,
        "backend_response": backendResponse,
        "syncStatus": syncStatus,
        "userId": user?.uid,
        if (widget.existingTrip == null) "createdAt": FieldValue.serverTimestamp(),
        "updatedAt": FieldValue.serverTimestamp(),
      };

      if (widget.existingTrip != null) {
         // Edit mode: Update existing doc
         await FirebaseFirestore.instance.collection("trips").doc(widget.existingTrip!.id).set(firestoreData, SetOptions(merge: true));
      } else {
         if (backendTripId != null && backendTripId.isNotEmpty) {
           // Success: Use backend ID to prevent duplicates
           await FirebaseFirestore.instance.collection("trips").doc(backendTripId).set(firestoreData, SetOptions(merge: true));
         } else {
           // Fallback: Backend failed, generate new ID
           await FirebaseFirestore.instance.collection("trips").add(firestoreData);
         }
      }

      // 3. Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(syncStatus == 'synced' 
              ? "Trip saved and synced successfully!" 
              : "Trip saved locally (Sync failed)"),
            backgroundColor: syncStatus == 'synced' ? Colors.green : Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving trip: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 1));
          }
        } else {
          if (_startDate == null) {
            _startDate = picked.subtract(const Duration(days: 1));
          }
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingTrip != null ? 'Edit Trip' : 'Create Trip',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                _totalSteps,
                (index) => Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? const Color(0xFF2196F3)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (index < _totalSteps - 1) const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Page view for steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1Destination(),
                _buildStep2Dates(),
                _buildStep3Travelers(),
                _buildStep4TripType(),
                _buildStep5Accommodation(),
                _buildStep6Budget(),
                _buildStep7Notes(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : (_currentStep == _totalSteps - 1
                              ? _saveTrip
                              : (_canProceedToNextStep() ? _nextStep : null)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _currentStep == _totalSteps - 1
                                  ? widget.existingTrip != null
                                      ? 'Update Trip'
                                      : 'Create Trip'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: Destination
  Widget _buildStep1Destination() {
    final originFilled = _originController.text.trim().isNotEmpty;
    final destinationFilled = _destinationController.text.trim().isNotEmpty;
    final canShowResults = originFilled && destinationFilled;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan your route',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us where you are and where you want to go. We can also suggest flights and hotels.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Autocomplete<Map<String, dynamic>>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.length < 3) {
                          return const Iterable<Map<String, dynamic>>.empty();
                        }
                        
                        // Debounce Logic
                        if (_originDebounce?.isActive ?? false) _originDebounce!.cancel();
                        _originCompleter = Completer();
                        
                        setState(() => _isSearchingOrigin = true);

                        _originDebounce = Timer(const Duration(milliseconds: 1000), () async {
                          try {
                            final results = await ApiService().searchCity(textEditingValue.text);
                            if (!_originCompleter!.isCompleted) {
                              _originCompleter!.complete(results);
                            }
                          } catch (e) {
                            if (!_originCompleter!.isCompleted) {
                              _originCompleter!.complete([]);
                            }
                          } finally {
                            if (mounted) setState(() => _isSearchingOrigin = false);
                          }
                        });

                        return _originCompleter!.future;
                      },
                      displayStringForOption: (option) => '${option['cityName'] ?? option['name']} (${option['iataCode']})',
                      onSelected: (Map<String, dynamic> selection) {
                        _selectedOriginIata = selection['iataCode'];
                        // Sync our controller for validation
                        _originController.text = '${selection['cityName'] ?? selection['name']} (${selection['iataCode']})';
                        setState(() {});
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onEditingComplete: onEditingComplete,
                          onChanged: (value) {
                            _originController.text = value;
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Where are you coming from?',
                            hintText: 'e.g., Jakarta',
                            helperText: "Enter city name (min 3 chars)",
                            prefixIcon: const Icon(Icons.my_location, color: Color(0xFF2196F3)),
                            suffixIcon: _isSearchingOrigin
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: 20, 
                                      height: 20, 
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 48,
                              child: ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final option = options.elementAt(index);
                                  return ListTile(
                                    title: Text('${option['cityName'] ?? option['name']} (${option['iataCode']})'),
                                    subtitle: Text(option['name']),
                                    onTap: () => onSelected(option),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          const SizedBox(height: 16),
          Autocomplete<Map<String, dynamic>>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.length < 3) {
                return const Iterable<Map<String, dynamic>>.empty();
              }

              // Debounce Logic
              if (_destinationDebounce?.isActive ?? false) _destinationDebounce!.cancel();
              _destinationCompleter = Completer();
              
              setState(() => _isSearchingDestination = true);

              _destinationDebounce = Timer(const Duration(milliseconds: 1000), () async {
                try {
                  final results = await ApiService().searchCity(textEditingValue.text);
                  if (!_destinationCompleter!.isCompleted) {
                    _destinationCompleter!.complete(results);
                  }
                } catch (e) {
                  if (!_destinationCompleter!.isCompleted) {
                    _destinationCompleter!.complete([]);
                  }
                } finally {
                  if (mounted) setState(() => _isSearchingDestination = false);
                }
              });

              return _destinationCompleter!.future;
            },
            displayStringForOption: (option) => '${option['cityName'] ?? option['name']} (${option['iataCode']})',
            onSelected: (Map<String, dynamic> selection) {
              _selectedDestinationIata = selection['iataCode'];
              _selectedDestinationCityName = selection['cityName'] ?? selection['name'];
              _destinationController.text = '${selection['cityName'] ?? selection['name']} (${selection['iataCode']})';
              setState(() {});
            },
            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onEditingComplete: onEditingComplete,
                onChanged: (value) {
                  _destinationController.text = value;
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Where do you want to go?',
                  hintText: 'e.g., Paris',
                  helperText: "Enter city name (min 3 chars)",
                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF2196F3)),
                  suffixIcon: _isSearchingDestination
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20, 
                            height: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 48,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final option = options.elementAt(index);
                        return ListTile(
                          title: Text('${option['cityName'] ?? option['name']} (${option['iataCode']})'),
                          subtitle: Text(option['name']),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }


  Widget _buildFlightSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available flights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ..._mockFlights.map(
          (flight) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFlightCard(flight),
          ),
        ),
      ],
    );
  }

  Widget _buildHotelSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available hotels',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        ..._mockHotels.map(
          (hotel) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHotelCard(hotel),
          ),
        ),
      ],
    );
  }

  Widget _buildFlightCard(_FlightOption flight) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.flight_takeoff, color: Color(0xFF2196F3)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flight.airline,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Departure • ${flight.departureTime}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            flight.priceText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(_HotelOption hotel) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: Color(0xFFFFA000)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hotel.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Color(0xFFFFA000)),
                    const SizedBox(width: 4),
                    Text(
                      hotel.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            hotel.priceText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChosenFlightSummary() {
    final flight = _chosenFlight!;
    String fmtTime(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flight, color: Color(0xFF2196F3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${flight.origin} → ${flight.destination}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${flight.airline} • ${flight.flightNumber} • ${flight.aircraft}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seats: ${_chosenSeats.join(', ')}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${flight.price}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Color(0xFF2196F3)),
              const SizedBox(width: 6),
              Text(
                '${fmtTime(flight.departureTime)} – ${fmtTime(flight.arrivalTime)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (_chosenSeats.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: Color(0xFF2196F3)),
                const SizedBox(width: 6),
                Text(
                  'Seats: ${_chosenSeats.join(', ')}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Step 2: Travel Dates
  Widget _buildStep2Dates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'When are you traveling?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select your travel dates',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          _buildDateField(
            label: 'Start Date',
            date: _startDate,
            onTap: () => _selectDate(context, true),
          ),
          const SizedBox(height: 20),
          _buildDateField(
            label: 'End Date',
            date: _endDate,
            onTap: () => _selectDate(context, false),
          ),
          if (_calculatedDuration > 0) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF2196F3)),
                  const SizedBox(width: 12),
                  Text(
                    'Duration: $_calculatedDuration ${_calculatedDuration == 1 ? 'day' : 'days'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateField({required String label, required DateTime? date, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
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
                  Text(
                    date != null
                        ? DateFormat('MMM dd, yyyy').format(date)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // Step 3: Travelers
  Widget _buildStep3Travelers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How many travelers?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Number of people traveling',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.people,
                    size: 64,
                    color: const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _travelers > 1
                          ? () => setState(() => _travelers--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      iconSize: 40,
                      color: _travelers > 1 ? const Color(0xFF2196F3) : Colors.grey,
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$_travelers',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton(
                      onPressed: () => setState(() => _travelers++),
                      icon: const Icon(Icons.add_circle_outline),
                      iconSize: 40,
                      color: const Color(0xFF2196F3),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _travelers == 1 ? 'Traveler' : 'Travelers',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SwitchListTile.adaptive(
              value: _wantFlight,
              onChanged: (value) => setState(() {
                _wantFlight = value;
                if (!value) {
                  _chosenFlight = null;
                  _chosenSeats = [];
                }
              }),
              title: const Text(
                'Do you want to buy flight tickets?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              activeColor: const Color(0xFF2196F3),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          if (_wantFlight) ...[
            const SizedBox(height: 24),
            if (_chosenFlight == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Helper to extract IATA code
                    String getIata(String? selected, String text) {
                      if (selected != null && selected.isNotEmpty) return selected;
                      // Try to extract from "City (ABC)" format
                      final match = RegExp(r'\(([A-Z]{3})\)').firstMatch(text);
                      if (match != null) return match.group(1)!;
                      // Fallback to text if it looks like an IATA code (3 letters)
                      if (RegExp(r'^[A-Z]{3}$', caseSensitive: false).hasMatch(text.trim())) {
                        return text.trim().toUpperCase();
                      }
                      return text.trim(); // Fallback to whatever is there
                    }

                    final originCode = getIata(_selectedOriginIata, _originController.text);
                    final destinationCode = getIata(_selectedDestinationIata, _destinationController.text);

                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FlightListPage(
                          origin: originCode,
                          destination: destinationCode,
                          passengers: _travelers,
                          departureDate: _startDate,
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _chosenFlight = result['flight'] as SimpleFlightModel?;
                        _chosenSeats = result['seats'] as List<String>;
                      });
                    }
                  },
                  icon: const Icon(Icons.flight),
                  label: const Text('Choose Flight'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              _buildChosenFlightSummary(),
          ],
        ],
      ),
    );
  }

  // Step 4: Trip Type
  Widget _buildStep4TripType() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What type of trip?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the type of trip',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _tripTypes.length,
            itemBuilder: (context, index) {
              final type = _tripTypes[index];
              final isSelected = _tripType == type;
              return _buildTypeChip(
                label: type,
                isSelected: isSelected,
                onTap: () => setState(() => _tripType = type),
              );
            },
          ),
        ],
      ),
    );
  }



  // Step 5: Accommodation
  Widget _buildStep5Accommodation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Where will you stay?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book a hotel or select accommodation type',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SwitchListTile.adaptive(
              value: _wantHotel,
              onChanged: (value) => setState(() {
                _wantHotel = value;
                if (!value) {
                  _chosenHotel = null;
                  _chosenRoom = null;
                }
              }),
              title: const Text(
                'Do you want to book a hotel?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              activeColor: const Color(0xFF2196F3),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
          const SizedBox(height: 24),
          if (_wantHotel) ...[
            if (_chosenHotel == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelRecommendations(
                          destination: _destinationController.text.trim(),
                          checkIn: _startDate,
                          checkOut: _endDate,
                          guests: _travelers,
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _chosenHotel = result['hotel'] as HotelOfferGroup;
                        _chosenRoom = result['room'] as HotelOffer;
                        _accommodationType = 'Hotel'; // Auto-select Hotel
                      });
                    }
                  },
                  icon: const Icon(Icons.hotel),
                  label: const Text('Select Hotel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )
            else
              _buildChosenHotelSummary(),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.5,
              ),
              itemCount: _accommodationTypes.length,
              itemBuilder: (context, index) {
                final type = _accommodationTypes[index];
                final isSelected = _accommodationType == type;
                return _buildTypeChip(
                  label: type,
                  isSelected: isSelected,
                  onTap: () => setState(() => _accommodationType = type),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChosenHotelSummary() {
    if (_chosenHotel == null || _chosenRoom == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Hotel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Color(0xFF2196F3)),
                onPressed: () async {
                   final result = await Navigator.push<Map<String, dynamic>>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HotelRecommendations(
                          destination: _destinationController.text.trim(),
                          checkIn: _startDate,
                          checkOut: _endDate,
                          guests: _travelers,
                        ),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _chosenHotel = result['hotel'] as HotelOfferGroup;
                        _chosenRoom = result['room'] as HotelOffer;
                      });
                    }
                },
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            _chosenHotel!.hotel.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _chosenRoom!.room?.type ?? 'Room',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${_chosenRoom!.checkInDate != null ? DateFormat('MMM dd').format(_chosenRoom!.checkInDate!) : 'TBA'} - ${_chosenRoom!.checkOutDate != null ? DateFormat('MMM dd').format(_chosenRoom!.checkOutDate!) : 'TBA'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _chosenRoom!.price.total.toIDR(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  // Step 6: Budget
  Widget _buildStep6Budget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your budget?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Enter your estimated budget',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Budget',
              hintText: 'e.g., 5000',
              prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF2196F3)),
              suffixText: 'USD',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _budgetController.clear();
              });
            },
            child: const Text('Skip this step'),
          ),
        ],
      ),
    );
  }

  // Step 7: Notes
  Widget _buildStep7Notes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Any additional notes?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Optional - Add any notes or reminders',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _notesController,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'Notes',
              hintText: 'Enter any additional information...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _notesController.clear();
              });
            },
            child: const Text('Skip this step'),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlightOption {
  final String airline;
  final String departureTime;
  final String priceText;

  const _FlightOption({
    required this.airline,
    required this.departureTime,
    required this.priceText,
  });
}

class _HotelOption {
  final String name;
  final double rating;
  final String priceText;

  const _HotelOption({
    required this.name,
    required this.rating,
    required this.priceText,
  });
}

/*
TESTING INSTRUCTIONS:
1. Launch Trip Creation Page
2. App asks for location permission
3. If allowed -> field autofills with user's city
4. If denied -> manual input appears
5. Trip creation uses that origin city
*/





