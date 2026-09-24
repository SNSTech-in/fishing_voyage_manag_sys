// lib/screens/boat_owner/sos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'package:fishing_voyage_manag_sys/services/api_service.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/offline_queue_service.dart';
import 'package:fishing_voyage_manag_sys/services/offline_map_service.dart';
import 'package:fishing_voyage_manag_sys/services/event_location_service.dart';

class SOSScreen extends StatefulWidget {
  final int intimationId;
  final String boatName;
  final String boatRegNo;
  final String referenceNo;

  const SOSScreen({
    super.key,
    required this.intimationId,
    required this.boatName,
    required this.boatRegNo,
    required this.referenceNo,
  });

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  final MapController _mapController = MapController();

  static const LatLng _defaultLocation = LatLng(15.4909, 73.8278);

  LatLng? _mapLocation;

  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isCiting = false;

  Map<String, double>? _currentLocation;

  static const String _otherStateBoat = 'OTHER_STATE_BOAT';
  static const String _illegalActivity = 'ILLEGAL_ACTIVITY';
  static const String _defaultIllegalActivityType = 'UNKNOWN';

  String _selectedCitingType = _otherStateBoat;

  late TextEditingController _boatCountController;
  late TextEditingController _remarksController;

  // ============================================================
  // INIT / DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _boatCountController = TextEditingController(text: '1');
    _remarksController = TextEditingController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _boatCountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    if (mounted) setState(() => _isGettingLocation = true);

    try {
      final loc = await EventLocationService.acquire(
        voyageId: widget.intimationId,
        tag: 'SOS_SCREEN_INIT',
      );

      if (loc == null) {
        _setDefaultZeroLocation();
        return;
      }

      final LatLng location = LatLng(loc.lat, loc.lng);
      if (!mounted) return;

      setState(() {
        _currentLocation = {
          'latitude': loc.lat,
          'longitude': loc.lng,
        };
        _mapLocation = location;
      });

      try {
        _mapController.move(location, 13.0);
      } catch (_) {}

      debugPrint(
          '📍 Current Location (via EventLocationService): ${loc.lat}, ${loc.lng} (src=${loc.source})');
    } catch (e) {
      debugPrint('⚠️ Unable to get location in init: $e');
      _setDefaultZeroLocation();
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _setDefaultZeroLocation() {
    if (!mounted) return;
    setState(() {
      _currentLocation = {'latitude': 0.0, 'longitude': 0.0};
      _mapLocation = _defaultLocation;
    });
    debugPrint('📍 Location fallback set to: 0.0, 0.0');
  }

  Future<void> _moveToMyLocation() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
    }
    if (!mounted || _currentLocation == null) return;

    final double latitude = _currentLocation!['latitude'] ?? 0.0;
    final double longitude = _currentLocation!['longitude'] ?? 0.0;

    if (latitude == 0.0 && longitude == 0.0) return;

    final LatLng location = LatLng(latitude, longitude);
    setState(() => _mapLocation = location);

    try {
      _mapController.move(location, 15.0);
    } catch (_) {}
  }

  // ============================================================
  // SEND SOS — OFFLINE-FIRST FLOW
  // ============================================================

  Future<void> _sendSOS() async {
    if (_isLoading || _isCiting) return;

    setState(() => _isLoading = true);

    final queue = OfflineQueueService.instance;
    final online = await queue.isOnline();

    try {
      debugPrint('🚨 [SOS] Start — online=$online');

      // 1. Location
      final loc = await EventLocationService.acquire(
        voyageId: widget.intimationId,
        tag: 'SOS',
      );
      if (loc == null) {
        throw Exception(
            'Unable to acquire location for SOS. Please ensure GPS is enabled.');
      }
      debugPrint('📍 [SOS] Location: ${loc.lat}, ${loc.lng}');

      // 2. Typed values captured ONCE
      final String sosTimestamp = DateTime.now().toIso8601String();
      final String remarksText = _remarksController.text.trim();
      final String sosMessage =
      remarksText.isEmpty ? 'SOS Alert' : remarksText;

      // 3. Payload (used for both direct send and queue)
      final Map<String, dynamic> payload = {
        'intimation_id': widget.intimationId,
        'boat_reg_no': widget.boatRegNo,
        'latitude': loc.lat,
        'longitude': loc.lng,
        'location_source': loc.source,
        'sos_datetime': sosTimestamp,
        'remarks': remarksText,
        'sos_type': 'OTHER',
        'severity': 'HIGH',
      };

      // 4. Token
      final session = await _db.getUserSession();
      final token = session?['access_token']?.toString();

      // 5. OFFLINE → queue only
      if (!online) {
        debugPrint('📴 [SOS] Offline — queueing locally');
        await queue.queueSos(
          payload: payload,
          lat: loc.lat,
          lng: loc.lng,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📴 Offline — SOS saved. It will send automatically when online.'),
            backgroundColor: Color(0xFFF7B928),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // 6. ONLINE but no token → queue
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [SOS] No token — queueing anyway');
        await queue.queueSos(
          payload: payload,
          lat: loc.lat,
          lng: loc.lng,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Session expired. SOS saved locally for retry on login.'),
            backgroundColor: Color(0xFFF7B928),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // 7. ONLINE with token → direct send (awaited)
      debugPrint('📤 [SOS] Online — sending directly to backend');
      final response = await _apiService.sendSos(
        intimationId: widget.intimationId,
        latitude: loc.lat,
        longitude: loc.lng,
        timestamp: sosTimestamp,
        message: sosMessage,
        token: token,
        sosType: 'OTHER',
        locationSource: loc.source,
        severity: 'HIGH',
      );
      debugPrint('📥 [SOS] Backend response: $response');

      // 8. Backend confirmed
      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SOS sent to authorities'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // 9. Backend rejected → queue for retry
      debugPrint('⚠️ [SOS] Backend rejected → queueing for retry');
      await queue.queueSos(
        payload: payload,
        lat: loc.lat,
        lng: loc.lng,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Server unavailable: ${response['message'] ?? 'unknown'}. SOS saved for retry.'),
          backgroundColor: const Color(0xFFF7B928),
        ),
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('❌ [SOS] Error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send SOS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // CITING DIALOG
  // ============================================================

  Future<void> _showCitingDialog() async {
    if (_isCiting || _isLoading) return;

    if (_currentLocation == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting location...'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
      await _getCurrentLocation();
      if (_currentLocation == null) _setDefaultZeroLocation();
    }

    _boatCountController.text = '1';
    _remarksController.clear();

    String selectedType = _selectedCitingType;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double latitude =
                _currentLocation?['latitude'] ?? 0.0;
            final double longitude =
                _currentLocation?['longitude'] ?? 0.0;

            return Dialog(
              insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: ConstrainedBox(
                constraints:
                const BoxConstraints(maxWidth: 520, maxHeight: 650),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.directions_boat_rounded,
                              color: Color(0xFF1257C7),
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Citing of Boats',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF07347F),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Report a boat sighting',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // CITING TYPE
                      const Text(
                        'Citing Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF07347F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCitingRadio(
                        title: 'Other State Boat',
                        subtitle: 'Boat belongs to another state',
                        value: _otherStateBoat,
                        groupValue: selectedType,
                        icon: Icons.location_city_rounded,
                        iconColor: Colors.blue,
                        onChanged: (value) =>
                            setDialogState(() => selectedType = value),
                      ),
                      const SizedBox(height: 7),
                      _buildCitingRadio(
                        title: 'Illegal Activity',
                        subtitle: 'Report suspected illegal activity',
                        value: _illegalActivity,
                        groupValue: selectedType,
                        icon: Icons.warning_amber_rounded,
                        iconColor: Colors.red,
                        onChanged: (value) =>
                            setDialogState(() => selectedType = value),
                      ),

                      const SizedBox(height: 14),

                      // BOAT COUNT
                      const Text(
                        'Sighted Boat Count',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF07347F),
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _boatCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF1257C7),
                            size: 21,
                          ),
                          hintText: 'Enter number of boats',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FC),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // REMARKS
                      const Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF07347F),
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _remarksController,
                        minLines: 3,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 48),
                            child: Icon(
                              Icons.notes_rounded,
                              color: Color(0xFF1257C7),
                              size: 21,
                            ),
                          ),
                          hintText: 'Enter details about the sighting...',
                          filled: true,
                          fillColor: const Color(0xFFF7F9FC),
                          contentPadding: const EdgeInsets.all(13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                            BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // LOCATION PREVIEW
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.20)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: latitude == 0.0 && longitude == 0.0
                                  ? Colors.orange
                                  : Colors.green,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Current Location',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: latitude == 0.0 &&
                                          longitude == 0.0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${latitude.toStringAsFixed(6)}, '
                                        '${longitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: latitude == 0.0 &&
                                          longitude == 0.0
                                          ? Colors.orange
                                          : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                side: BorderSide(
                                    color: Colors.grey.shade300),
                                minimumSize: const Size(0, 46),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'No',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final String countText =
                                _boatCountController.text.trim();
                                final int? count = int.tryParse(countText);

                                if (count == null || count < 1) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter a valid boat count.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final String remarks =
                                _remarksController.text.trim();

                                final String apiCitingType =
                                selectedType == _illegalActivity
                                    ? _illegalActivity
                                    : _otherStateBoat;

                                _selectedCitingType = apiCitingType;

                                Navigator.pop(dialogContext);

                                await _sendCiting(
                                  citingType: apiCitingType,
                                  sightedBoatCount: count,
                                  remarks: remarks,
                                );
                              },
                              icon: const Icon(Icons.send_rounded, size: 12),
                              label: const Text(
                                'Submit',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1257C7),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 46),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCitingRadio({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required IconData icon,
    required Color iconColor,
    required ValueChanged<String> onChanged,
  }) {
    final bool selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFF0F6FF)
              : const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? const Color(0xFF1257C7)
                : Colors.grey.shade200,
            width: selected ? 1.3 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF07347F),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              activeColor: const Color(0xFF1257C7),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEND CITING — SAME OFFLINE-FIRST FLOW AS SOS
  // ============================================================

  Future<void> _sendCiting({
    required String citingType,
    required int sightedBoatCount,
    required String remarks,
  }) async {
    if (_isCiting || _isLoading) return;

    setState(() => _isCiting = true);

    final queue = OfflineQueueService.instance;
    final online = await queue.isOnline();

    try {
      debugPrint('🚨 [CITING] Start — online=$online');

      final loc = await EventLocationService.acquire(
        voyageId: widget.intimationId,
        tag: 'CITING',
      );
      if (loc == null) {
        throw Exception(
            'Unable to acquire location for Citing report.');
      }
      debugPrint('📍 [CITING] Location: ${loc.lat}, ${loc.lng}');

      // Typed value captured ONCE
      final String citingTimestamp = DateTime.now().toIso8601String();

      final Map<String, dynamic> payload = {
        'intimation_id': widget.intimationId,
        'latitude': loc.lat,
        'longitude': loc.lng,
        'citing_type': citingType,
        'citing_datetime': citingTimestamp,
        'sighted_boat_count': sightedBoatCount,
        'remarks': remarks,
        'illegal_activity_type': _defaultIllegalActivityType,
      };

      final session = await _db.getUserSession();
      final token = session?['access_token']?.toString();

      // OFFLINE → queue
      if (!online) {
        debugPrint('📴 [CITING] Offline — queueing locally');
        await queue.queueCiting(
          payload: payload,
          lat: loc.lat,
          lng: loc.lng,
          citingType: citingType,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '📴 Offline — Citing saved. It will sync when online.'),
            backgroundColor: Color(0xFFF7B928),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // ONLINE but no token → queue
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [CITING] No token — queueing anyway');
        await queue.queueCiting(
          payload: payload,
          lat: loc.lat,
          lng: loc.lng,
          citingType: citingType,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Session expired. Citing saved locally for retry on login.'),
            backgroundColor: Color(0xFFF7B928),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // ONLINE with token → direct send
      debugPrint('📤 [CITING] Online — sending directly to backend');
      final response = await _apiService.sendCiting(
        intimationId: widget.intimationId,
        citingReason: citingType,
        latitude: loc.lat,
        longitude: loc.lng,
        timestamp: citingTimestamp,
        token: token,
      );
      debugPrint('📥 [CITING] Backend response: $response');

      if (response['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Citing reported'),
            backgroundColor: Color(0xFF31A24C),
          ),
        );
        Navigator.pop(context, true);
        return;
      }

      // Backend rejected → queue
      debugPrint('⚠️ [CITING] Backend rejected → queueing');
      await queue.queueCiting(
        payload: payload,
        lat: loc.lat,
        lng: loc.lng,
        citingType: citingType,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '⚠️ Server unavailable: ${response['message'] ?? 'unknown'}. Citing saved for retry.'),
          backgroundColor: const Color(0xFFF7B928),
        ),
      );
      Navigator.pop(context, true);
    } catch (e, st) {
      debugPrint('❌ [CITING] Error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report citing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCiting = false);
    }
  }

  // ============================================================
  // PRETTY HELPERS
  // ============================================================

  String _prettyCitingType(String value) {
    switch (value) {
      case _otherStateBoat:
        return 'Other State Boat';
      case _illegalActivity:
        return 'Illegal Activity';
      default:
        return value;
    }
  }

  String _prettyActivityType(String value) {
    switch (value) {
      case 'FOREIGN_VESSEL':
        return 'Foreign Vessel';
      case 'BANNED_GEAR':
        return 'Banned Gear';
      case 'SMUGGLING':
        return 'Smuggling';
      case 'TRAWLING_IN_BAN':
        return 'Trawling in Ban';
      case 'UNIDENTIFIED_VESSEL':
        return 'Unidentified Vessel';
      case 'OTHER':
        return 'Unknown';
      default:
        return value;
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) {
      return DateFormat('dd MMM yyyy, HH:mm:ss').format(DateTime.now());
    }
    try {
      return DateFormat('dd MMM yyyy, HH:mm:ss')
          .format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF07347F),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP SECTION
  // ============================================================

  Widget _buildMapSection() {
    final LatLng center = _mapLocation ?? _defaultLocation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF1257C7),
                  size: 21,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Map View',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF07347F),
                      ),
                    ),
                    Text(
                      'View your current location',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _moveToMyLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.my_location_rounded, size: 16),
                label: const Text(
                  'My Location',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1257C7),
                  side: const BorderSide(color: Color(0xFF1257C7)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 255,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 12.5,
                      minZoom: 5,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      OfflineMapService.buildTileLayer(),
                      if (_mapLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _mapLocation!,
                              width: 52,
                              height: 52,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1257C7),
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.directions_boat_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      elevation: 3,
                      child: InkWell(
                        onTap: _openFullScreenMap,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(9),
                          child: Icon(
                            Icons.fullscreen_rounded,
                            color: Color(0xFF07347F),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    bottom: 9,
                    child: _buildZoomControls(_mapController),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_currentLocation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.gps_fixed_rounded,
                    size: 16,
                    color: (_currentLocation!['latitude'] == 0.0 &&
                        _currentLocation!['longitude'] == 0.0)
                        ? Colors.orange
                        : Colors.green,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${_currentLocation!['latitude']!.toStringAsFixed(6)}, '
                          '${_currentLocation!['longitude']!.toStringAsFixed(6)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: (_currentLocation!['latitude'] == 0.0 &&
                            _currentLocation!['longitude'] == 0.0)
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildZoomControls(MapController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final double zoom = controller.camera.zoom;
              controller.move(controller.camera.center, zoom + 1);
            },
            child: const SizedBox(
              width: 38,
              height: 36,
              child: Icon(Icons.add, color: Colors.black54),
            ),
          ),
          Container(width: 27, height: 1, color: Colors.grey.shade300),
          InkWell(
            onTap: () {
              final double zoom = controller.camera.zoom;
              controller.move(controller.camera.center, zoom - 1);
            },
            child: const SizedBox(
              width: 38,
              height: 36,
              child: Icon(Icons.remove, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenMapScreen(
          initialLocation: _mapLocation ?? _defaultLocation,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07347F), Color(0xFF1257C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                if (_isLoading || _isCiting) return;
                Navigator.maybePop(context);
              },
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 29),
              tooltip: 'Back',
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.directions_boat_rounded,
                color: Color(0xFF07347F),
                size: 27,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UTLCRAFT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Fisheries Department',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            FutureBuilder<int>(
              future: OfflineQueueService.instance.totalPendingCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: .5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_upload_rounded,
                          color: Colors.white, size: 10),
                      const SizedBox(width: 4),
                      Text('$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ACTION SECTION
  // ============================================================

  Widget _buildActionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              title: 'SOS',
              subtitle: 'Request immediate help',
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.red,
              backgroundColor: const Color(0xFFFFF4F4),
              onPressed: _isLoading || _isCiting ? null : _sendSOS,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildActionButton(
              title: 'Citing of Boats',
              subtitle: 'Cite nearby boats',
              icon: Icons.directions_boat_rounded,
              iconColor: const Color(0xFF1257C7),
              backgroundColor: const Color(0xFFF1F6FF),
              onPressed: _isCiting || _isLoading ? null : _showCitingDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 112 - 16,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 49,
                    height: 49,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 9.5, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VOYAGE INFORMATION
  // ============================================================

  Widget _buildVoyageInformation() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.directions_boat_rounded,
                  color: Color(0xFF1257C7),
                  size: 21,
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'Voyage Information',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF07347F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          _buildInfoRow('Boat Name', widget.boatName),
          _buildInfoRow('Registration', widget.boatRegNo),
          _buildInfoRow('Reference', widget.referenceNo),
          _buildInfoRow('Intimation ID', widget.intimationId.toString()),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF07347F),
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF07347F),
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading && !_isCiting,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8FC),
        body: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                    child: Column(
                      children: [
                        _buildActionSection(),
                        const SizedBox(height: 9),
                        _buildMapSection(),
                        const SizedBox(height: 9),
                        _buildVoyageInformation(),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.035),
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.10)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Colors.red,
                                size: 17,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'SOS sends your current GPS '
                                      'location and voyage details '
                                      'to the authorities.',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Colors.red[700],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading || _isCiting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.40),
                  child: Center(
                    child: Container(
                      margin:
                      const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              color: Color(0xFF1257C7),
                              strokeWidth: 3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _isCiting
                                ? 'Reporting Citing...'
                                : 'Sending SOS...',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF07347F),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Please wait',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// FULL SCREEN MAP
// ==================================================================

class FullScreenMapScreen extends StatefulWidget {
  final LatLng initialLocation;

  const FullScreenMapScreen({super.key, required this.initialLocation});

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen> {
  final MapController _mapController = MapController();
  late LatLng _location;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _location = widget.initialLocation;
  }

  Future<void> _getLocation() async {
    if (_isGettingLocation) return;
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Please enable GPS location.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      final LatLng newLocation =
      LatLng(position.latitude, position.longitude);

      if (!mounted) return;
      setState(() => _location = newLocation);

      try {
        _mapController.move(newLocation, 15.0);
      } catch (_) {}
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              final double zoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, zoom + 1);
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.add, size: 25),
            ),
          ),
          Container(width: 32, height: 1, color: Colors.grey.shade300),
          InkWell(
            onTap: () {
              final double zoom = _mapController.camera.zoom;
              _mapController.move(_mapController.camera.center, zoom - 1);
            },
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.remove, size: 25),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF07347F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Map View',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: _isGettingLocation ? null : _getLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.my_location_rounded, size: 17),
                label: const Text(
                  'My Location',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _location,
              initialZoom: 14,
              minZoom: 5,
              maxZoom: 19,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              OfflineMapService.buildTileLayer(),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _location,
                    width: 62,
                    height: 62,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1257C7),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_boat_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(right: 15, bottom: 25, child: _buildZoomControls()),
          Positioned(
            left: 15,
            right: 75,
            bottom: 25,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.gps_fixed_rounded,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${_location.latitude.toStringAsFixed(6)}, '
                          '${_location.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF07347F),
                      ),
                    ),
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