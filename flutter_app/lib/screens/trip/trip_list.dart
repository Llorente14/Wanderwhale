import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/trip_model.dart';
import '../../providers/app_providers.dart';
import '../../widgets/common/custom_bottom_nav.dart';
import '../../widgets/trip_card.dart';
import 'create_trip.dart';
import 'trip_detail.dart';

import '../../core/navigation/app_routes.dart';

class TripList extends ConsumerStatefulWidget {
  const TripList({super.key});

  @override
  ConsumerState<TripList> createState() => _TripListState();
}

class _TripListState extends ConsumerState<TripList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = 2;
    });
  }

  void _navigateToTripDetail(Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailPage(tripId: trip.id)),
    );
  }

  void _createNewTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateTripPage()),
    ).then((_) {
      // Refresh the list when returning from create trip page
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Trips',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        // here
        actions: [
          // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          // !!! TEMPORARY LOGIN BUTTON FOR TESTING - REMOVE BEFORE PUSHING !!!
          // !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          IconButton(
            icon: const Icon(Icons.login, color: Colors.red),
            tooltip: 'Go to Login (TESTING ONLY)',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.login);
            },
          ),
        ],
        //  to here
      ),
      body: user == null
          ? const Center(child: Text("Please login to view trips"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('trips')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print("TripList Error: ${snapshot.error}");
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                print(
                  "TripList: Found ${docs.length} trips for user ${user.uid}",
                );

                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    // Ensure ID is included
                    data['id'] = doc.id;

                    // Handle potential date parsing issues if fields are missing or different types
                    // Trip.fromJson handles string parsing for dates, but Firestore returns Timestamp
                    // We need to convert Timestamps to Strings or update Trip.fromJson to handle Timestamps.
                    // Let's update the data map to convert Timestamps to ISO strings for Trip.fromJson
                    _convertTimestamps(data);

                    Trip trip;
                    try {
                      trip = Trip.fromJson(data);
                    } catch (e) {
                      print("Error parsing trip ${doc.id}: $e");
                      return const SizedBox.shrink(); // Skip invalid trips
                    }

                    return TripCard(
                      trip: trip,
                      onTap: () => _navigateToTripDetail(trip),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTrip,
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Create Trip',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const CustomBottomNav(),
    );
  }

  void _convertTimestamps(Map<String, dynamic> data) {
    final keys = [
      'startDate',
      'endDate',
      'hotelCheckIn',
      'hotelCheckOut',
      'createdAt',
      'updatedAt',
    ];
    for (final key in keys) {
      if (data[key] is Timestamp) {
        data[key] = (data[key] as Timestamp).toDate().toIso8601String();
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight_takeoff, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No trips yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first trip to get started',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewTrip,
            icon: const Icon(Icons.add),
            label: const Text(
              'Create Trip',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}
