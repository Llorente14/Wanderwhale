// lib/providers/hotel_providers.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hotel_booking_model.dart';
import '../models/hotel_offer_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

final hotelOffersProvider = FutureProvider.family
    .autoDispose<List<HotelOfferGroup>, HotelOfferQuery>((ref, query) async {
  final api = ref.watch(apiServiceProvider);
  
  try {
    // Try API first
    final offers = await api.getHotelOffers(
      hotelIds: query.hotelIds,
      checkInDate: query.checkInDate,
      checkOutDate: query.checkOutDate,
      adults: query.adults,
    );
    
    // If API returns empty, fallback to demo data
    if (offers.isEmpty) {
      print('⚠️ API returned empty results, using demo hotel data');
      return _getDemoHotelOffers();
    }
    
    print('✅ Loaded ${offers.length} hotel offers from API');
    return offers;
  } catch (e) {
    // If API fails, fallback to demo data
    print('⚠️ API error: $e, using demo hotel data');
    return _getDemoHotelOffers();
  }
});

final hotelBookingControllerProvider =
    Provider<HotelBookingController>((ref) {
  final api = ref.watch(apiServiceProvider);
  return HotelBookingController(api);
});

final hotelBookingsProvider = FutureProvider.family
    .autoDispose<List<HotelBookingModel>, HotelBookingFilter>((ref, filter) {
  final api = ref.watch(apiServiceProvider);
  return api.getHotelBookings(
    tripId: filter.tripId,
    status: filter.status,
    page: filter.page,
    limit: filter.limit,
  );
});

class HotelBookingController {
  HotelBookingController(this._api);

  final ApiService _api;

  Future<HotelBookingModel> bookHotel(Map<String, dynamic> payload) {
    return _api.storeHotelBooking(payload);
  }
}

@immutable
class HotelOfferQuery {
  const HotelOfferQuery({
    required this.hotelIds,
    required this.checkInDate,
    required this.checkOutDate,
    required this.adults,
  });

  final List<String> hotelIds;
  final String checkInDate;
  final String checkOutDate;
  final int adults;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotelOfferQuery &&
        listEquals(other.hotelIds, hotelIds) &&
        other.checkInDate == checkInDate &&
        other.checkOutDate == checkOutDate &&
        other.adults == adults;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(hotelIds),
        checkInDate,
        checkOutDate,
        adults,
      );
}

@immutable
class HotelBookingFilter {
  const HotelBookingFilter({
    this.tripId,
    this.status,
    this.page,
    this.limit,
  });

  final String? tripId;
  final String? status;
  final int? page;
  final int? limit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotelBookingFilter &&
        other.tripId == tripId &&
        other.status == status &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(tripId, status, page, limit);
}

// Helper function to get demo hotel offers
List<HotelOfferGroup> _getDemoHotelOffers() {
  // Return a simple demo hotel offer
  return [
    HotelOfferGroup(
      hotel: HotelSummary(
        hotelId: 'DEMO001',
        name: 'Grand Indonesia Hotel',
        cityCode: 'JKT',
        rating: 4.5,
      ),
      available: true,
      offers: [
        HotelOffer(
          id: 'DEMO_OFFER_1',
          checkInDate: DateTime.now().add(const Duration(days: 7)),
          checkOutDate: DateTime.now().add(const Duration(days: 9)),
           guests: HotelGuests(adults: 2),
          price: HotelPrice(
            currency: 'IDR',
            base: 1500000,
            total: 1750000,
            taxes: [],
          ),
        ),
      ],
    ),
  ];
}

// Provider to search hotels by city code (Chained: City -> Hotel IDs -> Offers)
final hotelSearchByCityProvider = FutureProvider.family<List<HotelOfferGroup>, String>((ref, cityCode) async {
  final api = ref.watch(apiServiceProvider);
  
  try {
    // 1. Get hotels in city
    final hotels = await api.searchHotelsByCity(cityCode: cityCode);
    if (hotels.isEmpty) return [];
    
    final hotelIds = hotels.map((h) => h['hotelId'] as String).toList();
    
    // 2. Get offers for these hotels
    // Limit to 20 hotels to avoid URL length issues or API limits
    final limitedIds = hotelIds.take(20).toList();
    
    if (limitedIds.isEmpty) return [];

    // Default dates: +7 days from now, 3 nights stay
    final checkIn = DateTime.now().add(const Duration(days: 7));
    final checkOut = checkIn.add(const Duration(days: 3));
    
    return api.getHotelOffers(
      hotelIds: limitedIds,
      checkInDate: checkIn.toIso8601String().split('T')[0],
      checkOutDate: checkOut.toIso8601String().split('T')[0],
      adults: 1, // Default 1 adult
    );
  } catch (e) {
    print('Hotel search error: $e');
    // Fallback to demo data if API fails or returns nothing useful
    return _getDemoHotelOffers();
  }
});
