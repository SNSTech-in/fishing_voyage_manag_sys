import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';

import '../services/officer_api_service.dart';
import '../ui/fisheries_officer_ocean_ui.dart';
import '../../services/offline_map_service.dart';

class VoyageRouteMap extends StatefulWidget {
  final int intimationId;
  const VoyageRouteMap({super.key, required this.intimationId});

  @override
  State<VoyageRouteMap> createState() => _VoyageRouteMapState();
}

class _VoyageRouteMapState extends State<VoyageRouteMap> {
  final _api = OfficerApiService();
  List<LatLng> _points = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pts = await _api.fetchVoyageRoute(widget.intimationId);
    if (mounted) setState(() {
      _points = pts;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 200,
        child: Center(child: FisheriesOfficerOceanLoading()),
      );
    }
    if (_points.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: FisheriesOfficerOcean.cardSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FisheriesOfficerOcean.border),
        ),
        child: const Center(
          child: Text('No route data available',
              style: TextStyle(
                color: FisheriesOfficerOcean.muted, fontSize: 12)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _points.first,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                OfflineMapService.buildTileLayer(),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _points,
                      strokeWidth: 4,
                      color: FisheriesOfficerOcean.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _points.first,
                      width: 28, height: 28,
                      child: _marker(FisheriesOfficerOcean.green,
                          Icons.play_arrow_rounded),
                    ),
                    Marker(
                      point: _points.last,
                      width: 28, height: 28,
                      child: _marker(FisheriesOfficerOcean.red,
                          Icons.flag_rounded),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FisheriesOfficerOcean.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.10),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route_rounded,
                        size: 12,
                        color: FisheriesOfficerOcean.primary),
                    const SizedBox(width: 4),
                    Text('${_points.length} points',
                        style: const TextStyle(
                          color: FisheriesOfficerOcean.text,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _marker(Color color, IconData icon) => Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(.30), blurRadius: 4),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: 14),
  );
}
