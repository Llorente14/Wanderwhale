// lib/providers/trip_providers.dart

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/trip_destination_model.dart';
import '../models/trip_hotel_model.dart';
import '../models/trip_model.dart';
import '../services/api_service.dart';
import 'app_providers.dart';

final tripDetailProvider =
    FutureProvider.family<TripModel, String>((ref, tripId) async {
  final api = ref.watch(apiServiceProvider);
  return api.getTripDetail(tripId);
});

final tripCommandProvider = Provider<TripCommand>((ref) {
  final api = ref.watch(apiServiceProvider);
  return TripCommand(api);
});

class TripCommand {
  TripCommand(this._api);

  final ApiService _api;

  Future<TripModel> createTrip(Map<String, dynamic> payload) {
    return _api.createTrip(payload);
  }

  Future<TripModel> updateTrip(String tripId, Map<String, dynamic> payload) {
    return _api.updateTrip(tripId, payload);
  }

  Future<void> deleteTrip(String tripId) {
    return _api.deleteTrip(tripId);
  }

  Future<TripModel> updateTripStatus(String tripId, String status) {
    return _api.updateTripStatus(tripId, status);
  }
}

class TripDestinationsNotifier
    extends StateNotifier<AsyncValue<List<TripDestinationModel>>> {
  TripDestinationsNotifier({
    required this.api,
    required this.tripId,
  }) : super(const AsyncValue.loading());

  final ApiService api;
  final String tripId;

  Future<void> fetch({String? sortBy}) async {
    state = const AsyncValue.loading();
    try {
      print('🔍 TripDestinationsNotifier: Fetching destinations for tripId: $tripId');
      final destinations =
          await api.getTripDestinations(tripId, sortBy: sortBy);
      print('✅ TripDestinationsNotifier: Got ${destinations.length} destinations');
      state = AsyncValue.data(destinations);
    } catch (err, stack) {
      print('❌ TripDestinationsNotifier: Error - $err');
      print('❌ Stack trace: $stack');
      // Jika error 404, return empty list (trip belum punya destinations)
      if (err is DioException && err.response?.statusCode == 404) {
        print('⚠️ TripDestinationsNotifier: 404 - Setting empty list');
        state = const AsyncValue.data([]);
        return;
      }
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> add(Map<String, dynamic> payload) async {
    final current = state.value ?? const <TripDestinationModel>[];
    state = const AsyncValue.loading();
    try {
      final created = await api.createTripDestination(tripId, payload);
      state = AsyncValue.data([...current, created]);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> update(String destinationId, Map<String, dynamic> payload) async {
    final current = state.value ?? const <TripDestinationModel>[];
    state = const AsyncValue.loading();
    try {
      final updated =
          await api.updateTripDestination(tripId, destinationId, payload);
      final next = current
          .map((item) => item.destinationId == updated.destinationId
              ? updated
              : item)
          .toList();
      state = AsyncValue.data(next);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> remove(String destinationId) async {
    final current = state.value ?? const <TripDestinationModel>[];
    state = const AsyncValue.loading();
    try {
      await api.deleteTripDestination(tripId, destinationId);
      state = AsyncValue.data(
        current.where((item) => item.destinationId != destinationId).toList(),
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final tripDestinationsProvider = StateNotifierProvider.family<
    TripDestinationsNotifier,
    AsyncValue<List<TripDestinationModel>>,
    String>((ref, tripId) {
  final notifier = TripDestinationsNotifier(
    api: ref.watch(apiServiceProvider),
    tripId: tripId,
  );
  notifier.fetch();
  return notifier;
});

class TripHotelsNotifier
    extends StateNotifier<AsyncValue<List<TripHotelModel>>> {
  TripHotelsNotifier({
    required this.api,
    required this.tripId,
  }) : super(const AsyncValue.loading());

  final ApiService api;
  final String tripId;

  Future<void> fetch({String? sortBy}) async {
    state = const AsyncValue.loading();
    try {
      final hotels = await api.getTripHotels(tripId, sortBy: sortBy);
      state = AsyncValue.data(hotels);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> add(Map<String, dynamic> payload) async {
    final current = state.value ?? const <TripHotelModel>[];
    state = const AsyncValue.loading();
    try {
      final created = await api.createTripHotel(tripId, payload);
      state = AsyncValue.data([...current, created]);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> update(String hotelId, Map<String, dynamic> payload) async {
    final current = state.value ?? const <TripHotelModel>[];
    state = const AsyncValue.loading();
    try {
      final updated = await api.updateTripHotel(tripId, hotelId, payload);
      final next = current
          .map((item) => item.hotelId == updated.hotelId ? updated : item)
          .toList();
      state = AsyncValue.data(next);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> remove(String hotelId) async {
    final current = state.value ?? const <TripHotelModel>[];
    state = const AsyncValue.loading();
    try {
      await api.deleteTripHotel(tripId, hotelId);
      state = AsyncValue.data(
        current.where((item) => item.hotelId != hotelId).toList(),
      );
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

final tripHotelsProvider = StateNotifierProvider.family<TripHotelsNotifier,
    AsyncValue<List<TripHotelModel>>, String>((ref, tripId) {
  final notifier = TripHotelsNotifier(
    api: ref.watch(apiServiceProvider),
    tripId: tripId,
  );
  notifier.fetch();
  return notifier;
});

