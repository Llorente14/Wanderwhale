import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Service sederhana untuk mengelola izin dan pengambilan lokasi user.
class LocationService {
  double? lat;
  double? lng;

  /// Memastikan permission lokasi sudah diberikan, lalu mengembalikan posisi terkini.
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika service mati, tetap lempar error agar bisa ditangani di UI
      throw Exception('Layanan lokasi sedang nonaktif');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Izin lokasi ditolak permanen. Aktifkan lewat pengaturan perangkat.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    lat = position.latitude;
    lng = position.longitude;
    return position;
  }

  /// Mengubah posisi GPS menjadi teks yang lebih manusiawi, misalnya:
  /// "Jakarta, Indonesia" atau "Lat: -6.2, Lon: 106.8" jika geocoding gagal.
  Future<String> getReadableAddress(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        return 'Lat: ${position.latitude.toStringAsFixed(3)}, '
            'Lon: ${position.longitude.toStringAsFixed(3)}';
      }

      final place = placemarks.first;
      final city = place.locality?.isNotEmpty == true
          ? place.locality
          : (place.subAdministrativeArea?.isNotEmpty == true
              ? place.subAdministrativeArea
              : place.administrativeArea);
      final country = place.country;

      if (city != null && country != null) {
        return '$city, $country';
      }

      if (country != null) {
        return country;
      }

      return 'Lokasi tidak diketahui';
    } catch (_) {
      return 'Lokasi tidak diketahui';
    }
  }
}


