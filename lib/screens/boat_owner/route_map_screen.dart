// lib/screens/boat_owner/route_map_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/boat_owners_api_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/offline_map_service.dart';

class RouteMapScreen extends StatefulWidget {
  final int voyageId;

  const RouteMapScreen({super.key, required this.voyageId});

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  final BoatOwnwesApiService _api = BoatOwnwesApiService();

  List<LatLng> routePoints = [];
  bool isLoading = true;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  /// Route loading — three-step, server-aware:
  ///
  ///  1. Show whatever is cached locally RIGHT NOW (fast draw).
  ///  2. Ask the server for the authoritative list of pings.
  ///  3. Merge into local cache and re-render.
  ///
  /// Step 2 is what makes historical voyages show their route after
  /// uninstall + reinstall (local DB was wiped, server still has them).
  Future<void> _loadRoute() async {
    debugPrint('🗺️ Loading route for voyage ${widget.voyageId}');
    setState(() {
      isLoading = true;
      _statusMessage = null;
    });

    // ---------- 1. Local first ----------
    try {
      final local = await _db.getLocationsForVoyage(widget.voyageId);
      if (mounted && local.isNotEmpty) {
        setState(() {
          routePoints = local
              .map((loc) => LatLng(
            (loc['latitude'] as num).toDouble(),
            (loc['longitude'] as num).toDouble(),
          ))
              .toList();
          isLoading = false;
        });
        debugPrint('📍 Local points: ${routePoints.length}');
      }
    } catch (e) {
      debugPrint('⚠️ Local load failed: $e');
    }

    // ---------- 2. Server ----------
    try {
      final voyageNo = await _db.getVoyageReferenceNo(widget.voyageId);

      final res = await _api.getVoyageLocations(
        intimationId: widget.voyageId,
        voyageNo: voyageNo,
      );

      if (!mounted) return;

      if (res['success'] == true) {
        final serverPts = List<Map<String, dynamic>>.from(
          res['locations'] as List? ?? const [],
        );

        debugPrint('📡 Server points: ${serverPts.length}');

        if (serverPts.isNotEmpty) {
          // ---------- 3. Merge & redraw ----------
          await _db.mergeServerLocations(widget.voyageId, serverPts);

          final merged = await _db.getLocationsForVoyage(widget.voyageId);

          if (!mounted) return;
          setState(() {
            routePoints = merged
                .map((loc) => LatLng(
              (loc['latitude'] as num).toDouble(),
              (loc['longitude'] as num).toDouble(),
            ))
                .toList();
            isLoading = false;
            _statusMessage = null;
          });
          debugPrint('✅ Merged route: ${routePoints.length} points');
          return;
        }
      } else {
        debugPrint('⚠️ Server route fetch failed: ${res['message']}');
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (routePoints.isEmpty) {
          _statusMessage =
          'No route data available.\nThe server has no pings for this voyage yet.';
        }
      });
    } catch (e) {
      debugPrint('⚠️ Server route fetch error: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        if (routePoints.isEmpty) {
          _statusMessage = 'Could not reach the server. Showing local data only.';
        }
      });
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
          ? _emptyView()
          : _mapView(),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No route data available for this voyage.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage ??
                  'Location tracking may not have been active, or the server has no pings yet.',
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadRoute,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapView() {
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter:
            routePoints.isNotEmpty ? routePoints.first : const LatLng(10.5, 72.5),
            initialZoom: 9,
            minZoom: 3,
            maxZoom: 18,
          ),
          children: [
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
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_rounded,
                    color: Colors.blue, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${routePoints.length} tracking points',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _loadRoute,
                  child:
                  const Icon(Icons.refresh, color: Colors.blue, size: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}