// screens/boat_owner/start_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/api_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/location_service.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/main.dart';

class StartTripScreen extends StatefulWidget {
  final int intimationId;
  final String boatName;
  final String? referenceNo;

  const StartTripScreen({
    super.key,
    required this.intimationId,
    required this.boatName,
    this.referenceNo,
  });

  @override
  State<StartTripScreen> createState() => _StartTripScreenState();
}

class _StartTripScreenState extends State<StartTripScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController remarksController = TextEditingController();

  bool isLoading = false;
  bool isPageLoading = true;
  Map<String, double>? location;

  DateTime selectedDateTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    remarksController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isPageLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Enable GPS'),
            content: const Text(
                'GPS location is required to start a trip. Please enable GPS in settings.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Open Settings')),
            ],
          ),
        );
        if (result == true) {
          await Geolocator.openLocationSettings();
          await Future.delayed(const Duration(seconds: 2));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) throw Exception('GPS location service is disabled.');
        } else {
          throw Exception('Location service is required.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Location permission is required.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permissions are permanently denied. Please enable them in app settings.');
      }

      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      if (position.latitude == 0.0 && position.longitude == 0.0) {
        throw Exception('Unable to get GPS location.');
      }

      setState(() {
        location = {
          'latitude': position.latitude,
          'longitude': position.longitude,
        };
      });

      print('📍 Current Location: Lat: ${position.latitude}, Lng: ${position.longitude}');
    } catch (e) {
      print('❌ Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => isPageLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
                primary: Color(0xFF1257C7),
                onPrimary: Colors.white,
                onSurface: Color(0xFF07347F)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                  primary: Color(0xFF1257C7),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF07347F)),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _submitStartTrip() async {
    if (location == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please wait, getting location...'),
              backgroundColor: Colors.orange),
        );
      }
      await _getCurrentLocation();
      if (location == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Unable to get location. Please try again.'),
              backgroundColor: Colors.red),
        );
        return;
      }
    }

    setState(() => isLoading = true);

    try {
      final String remarks = remarksController.text.isNotEmpty
          ? remarksController.text
          : 'Departed on schedule';
      final double latitude = location!['latitude']!;
      final double longitude = location!['longitude']!;

      final session = await _db.getUserSession();
      final userId = session?['owner_id'] ?? 0;
      if (userId == 0) {
        _showError('User not found. Please login again.');
        return;
      }

      print('📤 Start Trip Request:');
      print('  intimation_id: ${widget.intimationId}');
      print('  user_id: $userId');
      print('  latitude: $latitude');
      print('  longitude: $longitude');

      Map<String, dynamic> response;
      try {
        response = await _apiService.startVoyage(
          intimationId: widget.intimationId.toString(),
          userId: userId,
          latitude: latitude,
          longitude: longitude,
          remarks: remarks,
        );
      } catch (e) {
        response = {
          'success': true,
          'offline': true,
          'message': 'Started locally (Offline)',
          'data': {
            'reference_no':
            widget.referenceNo ?? 'VOY-${widget.intimationId}'
          }
        };
      }

      print('📥 Start Trip Response: $response');

      if (response['success'] == true) {
        final bool isOffline = response['offline'] == true;
        final responseData = response['data'] as Map<String, dynamic>?;

        // Save active voyage data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('active_voyage_id', widget.intimationId);
        await prefs.setString(
            'active_voyage_no',
            responseData?['reference_no'] ??
                widget.referenceNo ??
                '');

        // Update local database status
        await _db.updateVoyageStatus(widget.intimationId, 'active');
        if (isOffline) {
          await _db.updateVoyageSyncStatus(widget.intimationId, 0);
        }

        // Request notification permission (Android 13+)
        final notificationStatus =
        await FlutterForegroundTask.checkNotificationPermission();
        if (notificationStatus != NotificationPermission.granted) {
          await FlutterForegroundTask.requestNotificationPermission();
        }

        // Request background location permission (Android 10+)
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.always) {
          _showBackgroundLocationDialog();
        }

        // Request ignore battery optimization
        await _requestIgnoreBatteryOptimization();

        // Start foreground service with error handling
        bool foregroundStarted = false;
        try {
          final result = await FlutterForegroundTask.startService(
            notificationTitle: 'Fishing Voyage',
            notificationText: 'Tracking location...',
            notificationIcon: const NotificationIcon(
              metaDataName: 'com.example.fishing_voyage_manag_sys.ICON',
            ),
            callback: startCallback,
          );

          // flutter_foreground_task v8+ returns a ServiceRequestResult.
          foregroundStarted = result is ServiceRequestSuccess;
          print('Foreground service start result: $result');
        } catch (e) {
          print('Error starting foreground service: $e');
        }

        // Always start the fallback location service
        LocationService().startTracking(widget.intimationId, intervalSeconds: 30);

        if (mounted) {
          String snackMsg = isOffline
              ? '✅ Trip started locally! (Will sync when online)'
              : (foregroundStarted
              ? '✅ Trip started! Location tracking active.'
              : '✅ Trip started! Location tracking active (fallback mode).');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(snackMsg),
              backgroundColor: isOffline ? Colors.orange : Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response['message'] ?? 'Failed to start trip'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showBackgroundLocationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Location Access'),
        content: const Text(
          'This app collects location data to track your fishing voyage even when the app is closed or not in use. '
              'Please select "Allow all the time" in location permissions to ensure continuous tracking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestIgnoreBatteryOptimization() async {
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Start Trip'),
        backgroundColor: const Color(0xFF07347F),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(14.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: isPageLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF1257C7)),
            SizedBox(height: 16),
            Text('Getting location...',
                style:
                TextStyle(color: Color(0xFF24365B), fontSize: 14)),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: const Color(0xFF1257C7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.directions_boat_rounded,
                        color: Color(0xFF1257C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Boat',
                            style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500)),
                        Text(widget.boatName,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF07347F))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text('ID: ${widget.intimationId}',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border:
                Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📍 Location captured',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.green)),
                        Text(
                          location != null
                              ? 'Lat: ${location!['latitude']?.toStringAsFixed(6)}, Lng: ${location!['longitude']?.toStringAsFixed(6)}'
                              : 'Getting location...',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  if (location == null)
                    const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.green)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Start Date & Time',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF07347F))),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDateTime,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 18, color: Color(0xFF1257C7)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('dd MMM yyyy, HH:mm')
                            .format(selectedDateTime),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF07347F)),
                      ),
                    ),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Remarks',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF07347F))),
            const SizedBox(height: 8),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                hintText: 'Enter any remarks (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Colors.grey.shade300)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                    const BorderSide(color: Color(0xFF1257C7))),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                Border.all(color: Colors.orange.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Once started, you can track the trip and update catch details.',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitStartTrip,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1257C7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Start Trip',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}