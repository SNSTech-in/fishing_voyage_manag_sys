// lib/services/location_service.dart

import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../database/database_helper.dart';
import 'event_location_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  StreamSubscription<Position>? _positionStream;
  int? _currentVoyageId;
  bool _isTracking = false;

  void startTracking(int voyageId, {int intervalSeconds = 60}) {
    if (_isTracking) return;
    _currentVoyageId = voyageId;
    _isTracking = true;

    // Standardized Location Settings with Distance Filter
    final LocationSettings locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 15, // 👈 Only update if moved at least 15 meters
      intervalDuration: Duration(seconds: intervalSeconds),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Tracking voyage location in background",
        notificationTitle: "Voyage Tracking Active",
        enableWakeLock: true,
      ),
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _handleNewLocation(position);
      },
      onError: (e) {
        print('❌ Location stream error: $e');
      },
    );

    print('📍 Location stream started (min 15m / ${intervalSeconds}s) for voyage $voyageId');
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    _currentVoyageId = null;
    print('📍 Location tracking stopped');
  }

  Future<void> _handleNewLocation(Position position) async {
    if (_currentVoyageId == null) return;

    // --- ACCURACY FILTER ---
    if (position.accuracy > 50) {
      print('📍 Location ignored: Poor accuracy (${position.accuracy.toStringAsFixed(1)}m)');
      return;
    }

    try {
      // Insert into database
      await _db.insertLocation(_currentVoyageId!, position.latitude, position.longitude);

      // Cache for event fallbacks (SOS/Citing)
      await EventLocationService.cacheLastKnown(
        lat: position.latitude,
        lng: position.longitude,
        accuracy: position.accuracy,
      );

      print('📍 Location stored for voyage $_currentVoyageId: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Location storage error: $e');
    }
  }

  Future<bool> _hasLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location services disabled');
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Location permission denied');
        return false;
      }
    }
    return true;
  }

  Future<int> getUnsyncedCount() async {
    if (_currentVoyageId == null) return 0;
    final db = await _db.database;
    List<Map<String, dynamic>> result = await db.query(
      'boat_locations',
      columns: ['COUNT(*) as count'],
      where: 'voyage_id = ? AND synced = 0',
      whereArgs: [_currentVoyageId],
    );
    return result.first['count'] as int;
  }

  bool get isTracking => _isTracking;
}
