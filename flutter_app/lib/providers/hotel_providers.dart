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
// This provider accepts optional check-in, check-out, and adults parameters
@immutable
class HotelSearchByCityParams {
  const HotelSearchByCityParams({
    required this.cityCode,
    this.checkIn,
    this.checkOut,
    this.adults,
  });

  final String cityCode;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? adults;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HotelSearchByCityParams &&
        other.cityCode == cityCode &&
        other.checkIn == checkIn &&
        other.checkOut == checkOut &&
        other.adults == adults;
  }

  @override
  int get hashCode => Object.hash(cityCode, checkIn, checkOut, adults);
}

final hotelSearchByCityProvider = FutureProvider.family<List<HotelOfferGroup>, HotelSearchByCityParams>((ref, params) async {
  final api = ref.watch(apiServiceProvider);
  
  try {
    // 1. Get hotels in city using /api/hotels/search/by-city
    // This calls GET /api/hotels/search/by-city?cityCode=XXX
    final hotels = await api.searchHotelsByCity(cityCode: params.cityCode);
    if (hotels.isEmpty) {
      print('⚠️ No hotels found in city ${params.cityCode}');
      return [];
    }
    
    print('🔍 Found ${hotels.length} hotels in city ${params.cityCode}');
    
    // Extract hotel IDs from response
    // Response structure from Amadeus: each hotel has 'hotelId' field
    final hotelIds = <String>[];
    for (final hotel in hotels) {
      if (hotel is Map<String, dynamic>) {
        // Try different possible field names
        final hotelId = hotel['hotelId'] as String? ?? 
                       hotel['id'] as String?;
        if (hotelId != null && hotelId.isNotEmpty) {
          hotelIds.add(hotelId);
        }
      }
    }
    
    if (hotelIds.isEmpty) {
      print('⚠️ No valid hotel IDs found in response');
      print('   Response sample: ${hotels.isNotEmpty ? hotels.first : "empty"}');
      return [];
    }
    
    // Limit to 20 hotels to avoid URL length issues or API limits
    final limitedIds = hotelIds.take(20).toList();
    
    print('🔍 Extracted ${limitedIds.length} hotel IDs: ${limitedIds.take(3).join(", ")}${limitedIds.length > 3 ? "..." : ""}');
    
    // 2. Determine check-in, check-out, and adults
    // Use provided values or defaults
    final checkIn = params.checkIn ?? DateTime.now().add(const Duration(days: 7));
    final checkOut = params.checkOut ?? checkIn.add(const Duration(days: 3));
    final adults = params.adults ?? 1;
    
    // Format dates as YYYY-MM-DD
    final checkInDate = checkIn.toIso8601String().split('T')[0];
    final checkOutDate = checkOut.toIso8601String().split('T')[0];
    
    print('🔍 Searching hotel offers:');
    print('   City: ${params.cityCode}');
    print('   Check-in: $checkInDate, Check-out: $checkOutDate');
    print('   Adults: $adults');
    print('   Hotel IDs: ${limitedIds.length}');
    
    // 3. Get offers using /api/hotels/offers
    // This calls GET /api/hotels/offers?hotelIds=XXX,YYY&checkInDate=...&checkOutDate=...&adults=...
    final offers = await api.getHotelOffers(
      hotelIds: limitedIds,
      checkInDate: checkInDate,
      checkOutDate: checkOutDate,
      adults: adults,
    );
    
    print('✅ Found ${offers.length} hotel offer groups with available rooms');
    return offers;
  } catch (e) {
    print('❌ Hotel search error: $e');
    print('   Stack trace: ${StackTrace.current}');
    // Return empty list instead of demo data for better error handling
    rethrow;
  }
});
