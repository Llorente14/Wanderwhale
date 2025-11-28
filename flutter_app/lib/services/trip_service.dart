import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/trip_model.dart';

class TripService {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final List<Trip> _trips = [];
  
  // Get all trips
  UnmodifiableListView<Trip> get trips => UnmodifiableListView(_trips);

  // Get trip by ID
  Trip? getTripById(String id) {
    try {
      return _trips.firstWhere((trip) => trip.id == id);
    } catch (e) {
      return null;
    }
  }

  // Add a new trip
  void addTrip(Trip trip) {
    _trips.add(trip);
    _notifyListeners();
  }

  // Update an existing trip
  void updateTrip(Trip updatedTrip) {
    final index = _trips.indexWhere((trip) => trip.id == updatedTrip.id);
    if (index != -1) {
      _trips[index] = updatedTrip;
      _notifyListeners();
    }
  }

  // Delete a trip
  void deleteTrip(String id) {
    _trips.removeWhere((trip) => trip.id == id);
    _notifyListeners();
  }

  // Clear all trips
  void clearAllTrips() {
    _trips.clear();
    _notifyListeners();
  }

  // Listeners for state management
  final List<VoidCallback> _listeners = [];

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }
}

