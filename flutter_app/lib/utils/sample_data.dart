import '../models/trip_model.dart';
import '../services/trip_service.dart';

/// Helper class to add sample trips for testing
class SampleData {
  static void addSampleTrips() {
    final tripService = TripService();
    
    // Only add samples if the list is empty
    if (tripService.trips.isNotEmpty) return;
    
    final now = DateTime.now();
    
    // Sample Trip 1: Vacation to Paris
    tripService.addTrip(
      Trip(
        id: 'trip_1',
        destination: 'Paris, France',
        startDate: DateTime(now.year, now.month + 1, 15),
        endDate: DateTime(now.year, now.month + 1, 22),
        durationInDays: 7,
        travelers: 2,
        tripType: 'Vacation',
        accommodationType: 'Hotel',
        budget: 3500.0,
        notes: 'Romantic getaway to the City of Light. Planning to visit the Eiffel Tower, Louvre Museum, and enjoy French cuisine.',
      ),
    );
    
    // Sample Trip 2: Business Trip
    tripService.addTrip(
      Trip(
        id: 'trip_2',
        destination: 'New York, USA',
        startDate: DateTime(now.year, now.month + 2, 5),
        endDate: DateTime(now.year, now.month + 2, 8),
        durationInDays: 3,
        travelers: 1,
        tripType: 'Business',
        accommodationType: 'Hotel',
        budget: 2000.0,
        notes: 'Client meeting and conference attendance.',
      ),
    );
    
    // Sample Trip 3: Adventure Trip
    tripService.addTrip(
      Trip(
        id: 'trip_3',
        destination: 'Bali, Indonesia',
        startDate: DateTime(now.year, now.month + 3, 1),
        endDate: DateTime(now.year, now.month + 3, 14),
        durationInDays: 13,
        travelers: 4,
        tripType: 'Adventure',
        accommodationType: 'Resort',
        budget: 4500.0,
        notes: 'Surfing, hiking, and exploring the beautiful beaches and temples of Bali.',
      ),
    );
    
    // Sample Trip 4: Family Trip
    tripService.addTrip(
      Trip(
        id: 'trip_4',
        destination: 'Tokyo, Japan',
        startDate: DateTime(now.year, now.month + 4, 10),
        endDate: DateTime(now.year, now.month + 4, 20),
        durationInDays: 10,
        travelers: 5,
        tripType: 'Family',
        accommodationType: 'Apartment',
        budget: 6000.0,
        notes: 'Family vacation with kids. Planning to visit Disneyland, temples, and experience Japanese culture.',
      ),
    );
    
    // Sample Trip 5: Backpacking Trip (no budget)
    tripService.addTrip(
      Trip(
        id: 'trip_5',
        destination: 'Thailand',
        startDate: DateTime(now.year, now.month + 5, 1),
        endDate: DateTime(now.year, now.month + 5, 21),
        durationInDays: 20,
        travelers: 2,
        tripType: 'Backpacking',
        accommodationType: 'Hostel',
        notes: 'Budget backpacking trip through Thailand. Exploring Bangkok, Chiang Mai, and the islands.',
      ),
    );
  }
}

