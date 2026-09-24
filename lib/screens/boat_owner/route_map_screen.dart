// lib/screens/boat_owner/route_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/offline_map_service.dart';

class RouteMapScreen extends StatefulWidget {
  final int voyageId;

  const RouteMapScreen({super.key, required this.voyageId});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  List<LatLng> routePoints = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    print('🗺️ Loading route for voyage ${widget.voyageId}');
    try {
      final locations = await _db.getLocationsForVoyage(widget.voyageId);
      setState(() {
        routePoints = locations
            .map((loc) => LatLng(loc['latitude'] as double, loc['longitude'] as double))
            .toList();
        isLoading = false;
      });

      if (routePoints.isEmpty) {
        print('⚠️ No route data found for voyage ${widget.voyageId}');
      } else {
        print('✅ Route loaded: ${routePoints.length} points');
      }
    } catch (e) {
      print('Error loading route: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travelled Route'),
        backgroundColor: const Color(0xFF07347F),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : routePoints.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 60, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No route data available for this voyage.'),
                      SizedBox(height: 8),
                      Text('Location tracking may not have been active.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: routePoints.isNotEmpty
                            ? routePoints.first
                            : const LatLng(10.5, 72.5),
                        initialZoom: 9,
                        minZoom: 3,
                        maxZoom: 18,
                      ),
                      children: [
                        // ✅ Offline-capable base map
                        OfflineMapService.buildTileLayer(),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: routePoints,
                              color: Colors.blueAccent,
                              strokeWidth: 5,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            if (routePoints.isNotEmpty)
                              Marker(
                                point: routePoints.first,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.trip_origin,
                                    color: Colors.green, size: 28),
                              ),
                            if (routePoints.length > 1)
                              Marker(
                                point: routePoints.last,
                                width: 40,
                                height: 40,
                                child: const Icon(Icons.location_on,
                                    color: Colors.red, size: 32),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.route_rounded, color: Colors.blue, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${routePoints.length} tracking points',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                setState(() => isLoading = true);
                                _loadRoute();
                              },
                              child: const Icon(Icons.refresh, color: Colors.blue, size: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}