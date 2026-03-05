import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/safety_zone.dart';

/// Provides location authorization, one-shot position lookups, and continuous
/// safety-zone monitoring.
///
/// Ported from the Swift `LocationService`.  Uses the `geolocator` package.
class LocationService extends ChangeNotifier {
  StreamSubscription<Position>? _positionSub;

  /// Callback invoked whenever the user moves outside a monitored zone.
  void Function(SafetyZoneRow zone)? onZoneViolation;

  // ---------------------------------------------------------------------------
  // Authorization
  // ---------------------------------------------------------------------------

  /// Requests location permissions from the OS, upgrading to "always" if
  /// possible (required for background zone monitoring on iOS).
  ///
  /// Returns `true` if at least [LocationPermission.whileInUse] was granted.
  Future<bool> requestAuthorization() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('[LocationService] Location services are disabled.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('[LocationService] Permission denied.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('[LocationService] Permission permanently denied.');
      return false;
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // One-shot position
  // ---------------------------------------------------------------------------

  /// Returns the device's current position.
  ///
  /// Throws if permissions have not been granted or services are disabled.
  Future<Position> getCurrentPosition() async {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Continuous zone monitoring
  // ---------------------------------------------------------------------------

  /// Begins listening for position updates and checks each new position
  /// against the provided [zones].
  ///
  /// When the user exits a zone that has [SafetyZoneRow.alertOnExit] set,
  /// [onZoneViolation] is invoked with that zone.
  void startMonitoringZones(List<SafetyZoneRow> zones) {
    _positionSub?.cancel();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20, // meters
      ),
    ).listen((position) {
      for (final zone in zones) {
        if (!zone.isActive) continue;
        _checkZoneViolation(position, zone);
      }
    });
  }

  /// Stops listening for position updates.
  void stopMonitoring() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  // ---------------------------------------------------------------------------
  // Zone check
  // ---------------------------------------------------------------------------

  /// Computes the Haversine distance between the current [position] and the
  /// [zone] centre.  If the user is outside the zone radius and the zone has
  /// `alertOnExit`, the violation callback fires.
  void _checkZoneViolation(Position position, SafetyZoneRow zone) {
    final distance = _haversineDistance(
      position.latitude,
      position.longitude,
      zone.latitude,
      zone.longitude,
    );

    final isOutside = distance > zone.radiusMeters;

    if (isOutside && zone.alertOnExit) {
      debugPrint(
        '[LocationService] Zone violation: ${zone.name} '
        '(distance=${distance.toStringAsFixed(1)} m, '
        'radius=${zone.radiusMeters} m)',
      );
      onZoneViolation?.call(zone);
    }
  }

  /// Haversine formula -- returns the distance in **meters** between two
  /// lat/lng pairs.
  static double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusM = 6371000.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusM * c;
  }

  static double _degToRad(double deg) => deg * (pi / 180.0);

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
