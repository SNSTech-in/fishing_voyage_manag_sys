// screens/boat_owner/end_trip_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/api_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/location_service.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';

class EndTripScreen extends StatefulWidget {
  final int intimationId;
  final String boatName;
  final int boatId;

  const EndTripScreen({
    super.key,
    required this.intimationId,
    required this.boatName,
    required this.boatId,
  });

  @override
  State<EndTripScreen> createState() => _EndTripScreenState();
}

class _EndTripScreenState extends State<EndTripScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();
  final TextEditingController tripEndRemarksController = TextEditingController();
  String? selectedOfficerId;
  String? selectedOfficerName;
  bool allCrewReturned = true;

  DateTime selectedDateTime = DateTime.now();

  List<Map<String, dynamic>> officers = [];
  List<Map<String, dynamic>> intimationCrew = [];

  Map<String, Map<String, dynamic>> crewSelection = {};

  bool isLoading = false;
  bool isPageLoading = true;
  Map<String, double>? location;

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    tripEndRemarksController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isPageLoading = true);
    try {
      await Future.wait([
        _loadOfficers(),
        _loadIntimationCrew(),
      ]);
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isPageLoading = false);
    }
  }

  Future<void> _loadOfficers() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Working Offline. Notified officer list needs internet.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final response = await _apiService.getOfficers();
      if (response['success'] == true) {
        final items = response['data']['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() => officers = List<Map<String, dynamic>>.from(items));
          print('✅ Loaded ${officers.length} officers');
        }
      }
    } catch (e) {
      print('❌ Error loading officers: $e');
    }
  }

  Future<void> _loadIntimationCrew() async {
    try {
      final response = await _apiService.getIntimationCrew(
        intimationId: widget.intimationId,
        boatId: widget.boatId,
      );
      if (response['success'] == true) {
        final items = response['data']['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() {
            intimationCrew = List<Map<String, dynamic>>.from(items);
            _initializeCrewSelection();
          });
          print('✅ Loaded ${intimationCrew.length} crew members');
        }
      }
    } catch (e) {
      print('❌ Error loading intimation crew: $e');
    }
  }

  void _initializeCrewSelection() {
    crewSelection = {};
    for (var crew in intimationCrew) {
      final crewId = crew['crew_id']?.toString();
      if (crewId != null) {
        crewSelection[crewId] = {
          'selected': false,
          'returnStatus': 'MISSING',
          'remarks': '',
          'crew_name': crew['crew_name']?.toString() ?? 'Unknown',
        };
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Enable GPS'),
            content: const Text('GPS location is required to end a trip. Please enable GPS in settings.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Open Settings')),
            ],
          ),
        );
        if (result == true) {
          await Geolocator.openLocationSettings();
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) throw Exception('GPS location service is disabled.');
        } else {
          throw Exception('Location service is required.');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
          throw Exception('Location permission is required.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable them in app settings.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, duration: const Duration(seconds: 5)),
      );
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
            colorScheme: const ColorScheme.light(primary: Color(0xFF1257C7), onPrimary: Colors.white, onSurface: Color(0xFF07347F)),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFF1257C7), onPrimary: Colors.white, onSurface: Color(0xFF07347F)),
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

  String _getFormattedDateTime(DateTime dateTime) {
    // Format: YYYY-MM-DDTHH:MM:SS+05:30
    final String iso = dateTime.toIso8601String().split('.').first;
    return '$iso+05:30';
  }

  Future<bool> _isConnected() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void _toggleCrewSelection(String crewId) {
    setState(() {
      final currentSelected = crewSelection[crewId]?['selected'] ?? false;
      crewSelection[crewId]?['selected'] = !currentSelected;
      if (!currentSelected) {
        crewSelection[crewId]?['returnStatus'] = 'MISSING';
      }
    });
  }

  Future<void> _showOfficerSelectionDialog() async {
    String searchQuery = '';
    List<Map<String, dynamic>> filteredOfficers = List.from(officers);

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFF1257C7), size: 24),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Select Officer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF07347F))),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 22),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        autofocus: true,
                        keyboardType: TextInputType.text,
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value.toLowerCase();
                            filteredOfficers = officers.where((officer) {
                              final name = officer['officer_name']?.toString().toLowerCase() ?? '';
                              final designation = officer['designation']?.toString().toLowerCase() ?? '';
                              final department = officer['department']?.toString().toLowerCase() ?? '';
                              return name.contains(searchQuery) || designation.contains(searchQuery) || department.contains(searchQuery);
                            }).toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name, designation or department',
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Color(0xFF1257C7))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    filteredOfficers.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 30),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No officers found', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: filteredOfficers.length,
                              itemBuilder: (context, index) {
                                final officer = filteredOfficers[index];
                                final officerId = officer['officer_id']?.toString() ?? '';
                                final officerName = officer['officer_name']?.toString() ?? '';
                                final designation = officer['designation']?.toString() ?? '';
                                final department = officer['department']?.toString() ?? '';
                                final isSelected = selectedOfficerId == officerId;

                                return ListTile(
                                  leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF1257C7) : const Color(0xFFF4F8FF),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.person_rounded, color: isSelected ? Colors.white : const Color(0xFF1257C7), size: 22),
                                  ),
                                  title: Text(
                                    officerName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? const Color(0xFF1257C7) : const Color(0xFF07347F),
                                    ),
                                  ),
                                  subtitle: Text('$designation • $department', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                  trailing: isSelected
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(color: const Color(0xFF1257C7), borderRadius: BorderRadius.circular(12)),
                                          child: const Text('Selected', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                                        )
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      selectedOfficerId = officerId;
                                      selectedOfficerName = officerName;
                                    });
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                if (selectedOfficerId != null)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1257C7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('OK'),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitEndTrip() async {
    if (selectedOfficerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a notified officer.'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait, getting location...'), backgroundColor: Colors.orange),
      );
      await _getCurrentLocation();
      if (location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to get location. Please try again.'), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (!await _isConnected()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Please try again later.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      List<Map<String, dynamic>> crewReturns = [];

      if (!allCrewReturned) {
        for (var crew in intimationCrew) {
          final crewId = crew['crew_id']?.toString() ?? '';
          final selection = crewSelection[crewId] ?? {};
          final isSelected = selection['selected'] ?? false;

          if (isSelected) {
            crewReturns.add({
              'crew_id': crewId,
              'has_returned': false,
              'return_status': selection['returnStatus']?.toString() ?? 'MISSING',
              'remarks': selection['remarks']?.toString() ?? '',
            });
          }
        }
      }

      final tripEndDatetime = _getFormattedDateTime(selectedDateTime);
      final endTripSubmitTime = _getFormattedDateTime(DateTime.now());

      final int intimationId = widget.intimationId;
      final double latitude = location!['latitude']!;
      final double longitude = location!['longitude']!;
      final String allCrewReturnedValue = allCrewReturned ? 'YES' : 'NO';
      final int notifiedOfficerId = int.parse(selectedOfficerId!);
      final String tripEndRemarks = tripEndRemarksController.text.isNotEmpty ? tripEndRemarksController.text : 'Trip ended';

      print('📤 End Trip Request:');
      print('  intimation_id: $intimationId');
      print('  trip_end_datetime: $tripEndDatetime');
      print('  end_trip_submit_time: $endTripSubmitTime');
      print('  latitude: $latitude');
      print('  longitude: $longitude');
      print('  all_crew_returned: $allCrewReturnedValue');
      print('  crew_returns: $crewReturns');
      print('  notified_officer_id: $notifiedOfficerId');
      print('  trip_end_remarks: $tripEndRemarks');

      Map<String, dynamic> response;
      try {
        response = await _apiService.endTrip(
          intimationId: intimationId,
          tripEndDatetime: tripEndDatetime,
          endTripSubmitTime: endTripSubmitTime,
          latitude: latitude,
          longitude: longitude,
          all_crew_returned: allCrewReturnedValue,
          crew_returns: crewReturns,
          notifiedOfficerId: notifiedOfficerId,
          tripEndRemarks: tripEndRemarks,
          token: (await _db.getUserSession())?['access_token'] ?? '',
        );
      } catch (e) {
        // Network error fallback
        response = {
          'success': true,
          'offline': true,
          'message': 'Ended locally (Offline)'
        };
      }

      print('📥 End Trip Response: $response');

      if (response['success'] == true) {
        final bool isOffline = response['offline'] == true;
        print('✅ Trip ended successfully ${isOffline ? '(locally)' : ''}');

        if (isOffline) {
          await _db.updateVoyageSyncStatus(widget.intimationId, 0);
        }

        await _db.updateVoyageStatus(widget.intimationId, 'completed');

        // Stop tracking
        LocationService().stopTracking();
        await FlutterForegroundTask.stopService();

        // Clear active voyage from SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('active_voyage_id');
        await prefs.remove('active_voyage_no');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isOffline ? '✅ Trip ended locally! (Will sync when online)' : '✅ Trip ended successfully!'),
              backgroundColor: isOffline ? Colors.orange : Colors.green
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        print('❌ End Trip failed: ${response['message']}');
        print('❌ Errors: ${response['errors']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message']?.toString() ?? 'Failed to end trip'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('❌ End Trip exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('End Trip'),
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
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
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
                  Text('Loading...', style: TextStyle(color: Color(0xFF24365B), fontSize: 14)),
                ],
              ),
            )
          : Stack(
              children: [
                SingleChildScrollView(
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: const Color(0xFF1257C7).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.directions_boat_rounded, color: Color(0xFF1257C7), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Boat', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                  Text(widget.boatName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF07347F))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('ID: ${widget.intimationId}', style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.w600)),
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
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('📍 Location captured', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green)),
                                  Text(
                                    location != null
                                        ? 'Lat: ${location!['latitude']?.toStringAsFixed(6)}, Lng: ${location!['longitude']?.toStringAsFixed(6)}'
                                        : 'Getting location...',
                                    style: const TextStyle(fontSize: 11, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                            if (location == null)
                              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Date of Return & Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF07347F))),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectDateTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF1257C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(selectedDateTime),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF07347F)),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Format: ${_getFormattedDateTime(selectedDateTime)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('All crew returned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF07347F))),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            _buildRadioOption(
                              label: 'Yes',
                              isSelected: allCrewReturned,
                              onTap: () => setState(() => allCrewReturned = true),
                            ),
                            Container(height: 1, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 14)),
                            _buildRadioOption(
                              label: 'No',
                              isSelected: !allCrewReturned,
                              onTap: () => setState(() => allCrewReturned = false),
                            ),
                          ],
                        ),
                      ),
                      if (!allCrewReturned && intimationCrew.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Select Crew with Return Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF07347F))),
                        const SizedBox(height: 8),
                        ...intimationCrew.map((crew) {
                          final crewId = crew['crew_id']?.toString() ?? '';
                          final crewName = crew['crew_name']?.toString() ?? 'Unknown';
                          final selection = crewSelection[crewId] ?? {};
                          final isSelected = selection['selected'] ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.red.withOpacity(0.05) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? Colors.red.withOpacity(0.3) : Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                InkWell(
                                  onTap: () => _toggleCrewSelection(crewId),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: isSelected ? Colors.red : Colors.grey.shade400, width: 2),
                                            color: isSelected ? Colors.red : Colors.transparent,
                                          ),
                                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            crewName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: isSelected ? Colors.red[700] : const Color(0xFF07347F),
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                            child: Text(
                                              selection['returnStatus'] ?? 'MISSING',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.red),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: selection['returnStatus'] ?? 'MISSING',
                                    decoration: InputDecoration(
                                      labelText: 'Return Status',
                                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Color(0xFF1257C7))),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'MISSING', child: Text('Missing')),
                                      DropdownMenuItem(value: 'HOSPITALISED', child: Text('Hospitalised')),
                                      DropdownMenuItem(value: 'TRANSFERRED', child: Text('Transferred')),
                                      DropdownMenuItem(value: 'DECEASED', child: Text('Deceased')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          crewSelection[crewId]?['returnStatus'] = value;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    onChanged: (value) {
                                      crewSelection[crewId]?['remarks'] = value;
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Remarks',
                                      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      hintText: 'Enter remarks (optional)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Colors.grey.shade300)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: Color(0xFF1257C7))),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    maxLines: 2,
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],
                      const Text('Notified Officer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF07347F))),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _showOfficerSelectionDialog,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 18, color: Color(0xFF1257C7)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedOfficerName ?? 'Select officer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: selectedOfficerName != null ? const Color(0xFF07347F) : Colors.grey,
                                    fontWeight: selectedOfficerName != null ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Trip End Remarks', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF07347F))),
                      const SizedBox(height: 8),
                      TextField(
                        controller: tripEndRemarksController,
                        decoration: InputDecoration(
                          hintText: 'Enter trip end remarks (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF1257C7))),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submitEndTrip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1257C7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF1257C7) : Colors.grey.shade400, width: 2),
                color: isSelected ? const Color(0xFF1257C7) : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF07347F))),
          ],
        ),
      ),
    );
  }
}
