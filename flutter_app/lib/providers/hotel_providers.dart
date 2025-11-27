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
  return api.getHotelOffers(
    hotelIds: query.hotelIds,
    checkInDate: query.checkInDate,
    checkOutDate: query.checkOutDate,
    adults: query.adults,
  );
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

