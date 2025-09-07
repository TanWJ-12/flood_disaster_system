import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DistanceCalculator {
  /// Returns the distance in meters between two LatLng points using the Haversine formula.
  static double calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(end.latitude - start.latitude);
    final dLng = _degreesToRadians(end.longitude - start.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
}
