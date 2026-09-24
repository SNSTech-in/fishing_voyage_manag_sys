// lib/screens/boat_owner/voyage_intimation_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'crew_member/add_crew_screen.dart';

class VoyageIntimationScreen extends StatefulWidget {
  const VoyageIntimationScreen({super.key});

  @override
  State<VoyageIntimationScreen> createState() => _VoyageIntimationScreenState();
}

class _VoyageIntimationScreenState extends State<VoyageIntimationScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

  // ─── MARITIME PALETTE ─────────────
  static const Color maritime900 = Color(0xFF0F2744);
  static const Color maritime800 = Color(0xFF0C4A6E);
  static const Color maritime700 = Color(0xFF075985);
  static const Color maritime600 = Color(0xFF0369A1);
  static const Color maritime500 = Color(0xFF0284C7);
  static const Color maritime100 = Color(0xFFE0EFFE);
  static const Color maritime50  = Color(0xFFF0F7FF);

  static const Color darkNavy    = Color(0xFF081729);
  static const Color midNavy     = Color(0xFF0F2744);
  static const Color deepNavy    = Color(0xFF0F2744);
  static const Color surfaceBg   = Color(0xFFF1F5F9);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color emerald     = Color(0xFF10B981);
  static const Color inkNavy     = Color(0xFF06358D);

  // Controllers
  final TextEditingController _voyageNumberController = TextEditingController();
  final TextEditingController _fishingLicenseController = TextEditingController();
  final TextEditingController freshWaterController = TextEditingController();
  final TextEditingController dieselController = TextEditingController();
  final TextEditingController lifeJacketController = TextEditingController();
  final TextEditingController lifeBuoysController = TextEditingController();
  final TextEditingController communicationController = TextEditingController();
  final TextEditingController _emergencyNameController = TextEditingController();
  final TextEditingController _emergencyMobileController = TextEditingController();
  final TextEditingController _captainNameController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController returnTimeController = TextEditingController();

  // Data
  List<Map<String, dynamic>> _boats = [];
  int? _selectedBoatId;
  bool _loadingBoats = false;

  List<Map<String, dynamic>> _portList = [];
  int? _primaryPortId;
  List<int> _selectedDestinationPortIds = [];
  bool _loadingPorts = false;

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  List<int> _selectedCrewIds = [];
  bool _previousCatchSubmitted = false;
  bool _isSubmitting = false;

  Map<String, dynamic>? ownerData;

  // ══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _returnDate = DateTime.now().add(const Duration(days: 7));
    _returnTime = const TimeOfDay(hour: 18, minute: 0);

    final now = DateTime.now();
    final startDateTime = now.add(const Duration(hours: 1));
    startTimeController.text = DateFormat('HH:mm').format(startDateTime);
    final returnDateTime = startDateTime.add(const Duration(hours: 2));
    returnTimeController.text = DateFormat('HH:mm').format(returnDateTime);

    _loadInitialData();
    _loadLastVoyageData();
  }

  @override
  void dispose() {
    _voyageNumberController.dispose();
    _fishingLicenseController.dispose();
    freshWaterController.dispose();
    dieselController.dispose();
    lifeJacketController.dispose();
    lifeBuoysController.dispose();
    communicationController.dispose();
    _emergencyNameController.dispose();
    _emergencyMobileController.dispose();
    _captainNameController.dispose();
    startTimeController.dispose();
    returnTimeController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  LOGIC (UNCHANGED)
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadInitialData() async {
    final owner = await _databaseHelper.getBoatOwner();
    setState(() {
      ownerData = owner;
      if (ownerData != null) {
        _primaryPortId = int.tryParse(ownerData!['home_port_id']?.toString() ?? '');
      }
    });
    await _fetchBoats();
    await _fetchPorts();
  }

  Future<void> _loadLastVoyageData() async {
    try {
      final response = await _apiService.getIntimations(page: 1, pageSize: 10);
      if (response['success'] == true) {
        final data = response['data'];
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final completed = items.where((v) => v['derived_status'] == 'COMPLETED').toList();
          if (completed.isNotEmpty) {
            final last = completed.first;
            final boatId = last['boat_id'];
            if (boatId != null) {
              setState(() {
                _selectedBoatId = int.tryParse(boatId.toString());
              });
            }
            final crewIds = last['crew_ids'];
            if (crewIds != null && crewIds is List) {
              setState(() {
                _selectedCrewIds = crewIds.map((e) => int.parse(e.toString())).toList();
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error loading last voyage data: $e');
    }
  }

  Future<void> _fetchBoats() async {
    setState(() => _loadingBoats = true);
    try {
      final session = await _databaseHelper.getUserSession();
      final token = session?['access_token'];
      if (token == null) return;

      final response = await _apiService.getBoats(page: 1, pageSize: 20);
      if (response['success'] == true) {
        setState(() {
          _boats = List<Map<String, dynamic>>.from(response['data']['items']);
          if (_boats.isNotEmpty) _selectedBoatId = _boats.first['boat_id'];
        });
      }
    } catch (e) {
      print('Error fetching boats: $e');
    } finally {
      setState(() => _loadingBoats = false);
    }
  }

  Future<void> _fetchPorts() async {
    setState(() => _loadingPorts = true);
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        final localPorts = await _databaseHelper.getAllCustomPorts();
        if (localPorts.isNotEmpty) {
          setState(() {
            _portList = localPorts.map((p) => {
              'port_id': p['id'],
              'port_name': p['port_name'],
            }).toList();
          });
        }
        return;
      }

      final session = await _databaseHelper.getUserSession();
      final token = session?['access_token'];
      if (token == null) return;

      final response = await _apiService.getPorts();
      if (response['success'] == true) {
        final items = response['data']['items'] as List? ?? [];
        setState(() {
          _portList = items.map((item) {
            return {
              'port_id': int.tryParse(item['port_id']?.toString() ?? '0') ?? 0,
              'port_name': item['port_name']?.toString() ?? 'Unknown',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching ports: $e');
    } finally {
      setState(() => _loadingPorts = false);
    }
  }

  Future<void> _selectCrewMembers() async {
    if (ownerData == null) return;
    final result = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => AddCrewScreen(
          ownerData: ownerData!,
          preSelectedIds: _selectedCrewIds,
        ),
      ),
    );
    if (result != null) setState(() => _selectedCrewIds = result);
  }

  // ─── Boat Selection Modal ───
  void _showBoatSelectionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44, height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: maritime50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: maritime100),
                          ),
                          child: const Icon(Icons.directions_boat_rounded,
                              color: maritime600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text('Select Boat',
                            style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: textPrimary)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingBoats
                        ? const Center(
                        child: CircularProgressIndicator(color: maritime600))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _boats.length,
                      itemBuilder: (ctx, index) {
                        final boat = _boats[index];
                        final isSelected =
                            _selectedBoatId == boat['boat_id'];
                        return InkWell(
                          onTap: () {
                            setState(() =>
                            _selectedBoatId = boat['boat_id']);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? maritime50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? maritime500
                                    : slateBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50, height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isSelected
                                          ? [maritime500, maritime700]
                                          : [maritime50, maritime100],
                                    ),
                                    borderRadius:
                                    BorderRadius.circular(13),
                                  ),
                                  child: Icon(
                                    Icons.directions_boat_rounded,
                                    color: isSelected
                                        ? Colors.white
                                        : maritime600,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        boat['boat_name'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: textPrimary),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        boat['boat_reg_no'] ?? '',
                                        style: const TextStyle(
                                            fontSize: 12.5,
                                            color: textMuted,
                                            fontFamily: 'monospace'),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded,
                                      color: emerald, size: 26),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Primary Port Selection Modal ───
  void _showPrimaryPortModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44, height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: maritime50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: maritime100),
                          ),
                          child: const Icon(Icons.explore_rounded,
                              color: maritime600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Primary Port',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: maritime50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: maritime100),
                          ),
                          child: const Text(
                            'DEPARTURE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: maritime700,
                              fontFamily: 'monospace',
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingPorts
                        ? const Center(
                        child:
                        CircularProgressIndicator(color: maritime600))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _portList.length,
                      itemBuilder: (ctx, index) {
                        final port = _portList[index];
                        final isSelected =
                            _primaryPortId == port['port_id'];
                        return InkWell(
                          onTap: () {
                            setState(() =>
                            _primaryPortId = port['port_id']);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? maritime50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? maritime500
                                    : slateBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 160),
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? maritime600
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? maritime600
                                          : const Color(0xFFCBD5E1),
                                      width: 2.2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    port['port_name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maritime600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Done',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── Destination Ports Modal ───
  void _showDestinationPortsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44, height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(
                            color: maritime50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: maritime100),
                          ),
                          child: const Icon(Icons.anchor_rounded,
                              color: maritime600, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Destination Ports',
                              style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: maritime50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: maritime100),
                          ),
                          child: Text(
                            '${_selectedDestinationPortIds.length} selected',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: maritime700,
                                fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _loadingPorts
                        ? const Center(
                        child:
                        CircularProgressIndicator(color: maritime600))
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _portList.length,
                      itemBuilder: (ctx, index) {
                        final port = _portList[index];
                        final isSelected =
                        _selectedDestinationPortIds
                            .contains(port['port_id']);
                        return InkWell(
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedDestinationPortIds
                                    .remove(port['port_id']);
                              } else {
                                _selectedDestinationPortIds
                                    .add(port['port_id']);
                              }
                            });
                            setState(() {});
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? maritime50
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? maritime500
                                    : slateBorder,
                                width: isSelected ? 1.6 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 160),
                                  width: 26, height: 26,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? maritime600
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? maritime600
                                          : const Color(0xFFCBD5E1),
                                      width: 2.2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded,
                                      size: 16, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    port['port_name'] ?? '',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: maritime600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Done',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SUBMIT (UNCHANGED)
  // ══════════════════════════════════════════════════════════════

  Future<void> _submitIntimation() async {
    if (!_formKey.currentState!.validate() ||
        _selectedBoatId == null ||
        _selectedDestinationPortIds.isEmpty ||
        _selectedCrewIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please complete the form'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final session = await _databaseHelper.getUserSession();
      final token = session?['access_token'];
      if (token == null) throw Exception('Not authenticated');

      final startParts = startTimeController.text.split(':');
      final returnParts = returnTimeController.text.split(':');

      if (startParts.length != 2 || returnParts.length != 2) {
        throw Exception('Invalid time format. Please use HH:mm');
      }

      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        int.parse(startParts[0]),
        int.parse(startParts[1]),
      );

      final returnDateTime = DateTime(
        _returnDate!.year,
        _returnDate!.month,
        _returnDate!.day,
        int.parse(returnParts[0]),
        int.parse(returnParts[1]),
      );

      if (startDateTime.isBefore(DateTime.now())) {
        throw Exception('Departure time cannot be in the past');
      }
      if (returnDateTime.isBefore(startDateTime)) {
        throw Exception(
            'Expected return time must be after the departure time');
      }

      final voyageData = {
        'boat_id': _selectedBoatId,
        'voyage_start_date': _formatApiDateTime(startDateTime),
        'voyage_return_date': _formatApiDateTime(returnDateTime),
        'fresh_water_ltr': double.tryParse(freshWaterController.text) ?? 0.0,
        'diesel_ltr': double.tryParse(dieselController.text) ?? 0.0,
        'life_jackets': int.tryParse(lifeJacketController.text) ?? 0,
        'life_buoys': int.tryParse(lifeBuoysController.text) ?? 0,
        'communication_devices': int.tryParse(communicationController.text) ?? 0,
        'emergency_name': _emergencyNameController.text.trim(),
        'emergency_contact': _emergencyMobileController.text.trim(),
        'primary_port_id': _primaryPortId,
        'destination_port_ids': _selectedDestinationPortIds,
        'crew_ids': _selectedCrewIds,
        'status': 'SUBMITTED',
      };

      print('📤 createIntimation request: ${jsonEncode(voyageData)}');

      final response = await _apiService.createIntimation(voyageData);
      print('📥 createIntimation response: $response');

      if (response['success'] == true) {
        final respData = response['data'] ?? {};
        final int intimationId = respData['intimation_id'] ?? 0;

        await _databaseHelper.insertVoyage({
          'id': intimationId,
          'reference_no': respData['reference_no'] ?? 'N/A',
          'boat_id': _selectedBoatId,
          'boat_name': _boats
              .firstWhereOrNull((b) => b['boat_id'] == _selectedBoatId)?[
          'boat_name'] ??
              'N/A',
          'boat_reg_no': _boats
              .firstWhereOrNull((b) => b['boat_id'] == _selectedBoatId)?[
          'boat_reg_no'] ??
              'N/A',
          'derived_status': 'APPLIED',
          'status': 'applied',
          'destination_ports_text': _selectedDestinationPortIds
              .map((id) =>
          _portList
              .firstWhereOrNull((p) => p['port_id'] == id)?[
          'port_name'] ??
              id.toString())
              .join(', '),
          'destination_port': _selectedDestinationPortIds.join(','),
          'start_date': startDateTime.toIso8601String(),
          'return_date': returnDateTime.toIso8601String(),
          'voyage_start_date': _formatApiDateTime(startDateTime),
          'voyage_return_date': _formatApiDateTime(returnDateTime),
          'fresh_water': freshWaterController.text,
          'diesel': dieselController.text,
          'life_jackets': int.tryParse(lifeJacketController.text) ?? 0,
          'life_boys': int.tryParse(lifeBuoysController.text) ?? 0,
          'communication_devices': int.tryParse(communicationController.text) ?? 0,
          'emergency_name': _emergencyNameController.text,
          'emergency_mobile': _emergencyMobileController.text,
          'total_crew_count': _selectedCrewIds.length,
          'crew_names_json': jsonEncode([]),
          'boat_number': _boats
              .firstWhereOrNull((b) => b['boat_id'] == _selectedBoatId)?[
          'boat_reg_no'] ??
              'N/A',
          'fishing_license_no': _fishingLicenseController.text,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Voyage Intimation Submitted!'),
              backgroundColor: Colors.green));
          Navigator.pop(context, true);
        }
      } else {
        print('❌ Voyage submission failed: ${response['message']}');
        print('❌ Errors: ${response['errors']}');
        print('❌ Full response: $response');
        _showErrorDialog(
            response['message'], response['error_code'], response['errors']);
      }
    } catch (e) {
      if (mounted) _showErrorDialog(e.toString(), null, null);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorDialog(String? message, String? errorCode, dynamic errors) {
    print('❌ ERROR DIALOG: message=$message, errorCode=$errorCode, errors=$errors');
    if (!mounted) return;

    String errorText = message ?? 'Something went wrong.';
    if (errors != null && errors is List && errors.isNotEmpty) {
      final details = errors.map((e) {
        final field = e['field'] ?? '';
        final msg = e['message'] ?? '';
        return field.isNotEmpty ? '$field: $msg' : msg;
      }).join('\n');
      errorText += '\n\nDetails:\n$details';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.error_outline_rounded,
                    color: Colors.red),
              ),
              const SizedBox(width: 10),
              const Text('Error',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkNavy)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(errorText, style: const TextStyle(fontSize: 14)),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD — EDGE-TO-EDGE + BIGGER
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildNewHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 10, bottom: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBoatSelectionSection(),
                    const SizedBox(height: 10),
                    _buildPortDetailsSection(),
                    const SizedBox(height: 10),
                    _buildDatesAndTimesSection(),
                    const SizedBox(height: 10),
                    _buildResourcesSection(),
                    const SizedBox(height: 10),
                    _buildEmergencyContactSection(),
                    const SizedBox(height: 10),
                    _buildCrewSection(),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: _buildSubmitSection(),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header (bigger) ───
  Widget _buildNewHeader() {
    return Container(
      color: maritime900,
      child: Stack(
        children: [
          Positioned(
            top: -60, right: -50,
            child: Container(
              width: 210, height: 210,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50, left: -40,
            child: Container(
              width: 190, height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New Voyage Intimation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            SizedBox(
                              width: 9, height: 9,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 7),
                            Flexible(
                              child: Text(
                                'Coastal Security & Port Clearance',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  // ─── Section Card (edge-to-edge + bigger) ───
  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
    Color iconColor = maritime600,
    Color iconBgStart = maritime50,
    Color iconBgEnd = maritime100,
    Color iconBorder = maritime100,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: slateBorder, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconBgStart, iconBgEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: iconBorder),
                ),
                child: Icon(icon, size: 22, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  // ─── Boat Selection ───
  Widget _buildBoatSelectionSection() {
    final boat = _boats
        .firstWhereOrNull((b) => b['boat_id'] == _selectedBoatId);
    final boatName = boat?['boat_name'] ?? 'Select a boat';
    final boatReg = boat?['boat_reg_no'] ?? '';

    return _sectionCard(
      icon: Icons.directions_boat_rounded,
      title: 'Boat Selection',
      subtitle: 'Active Registered Vessel',
      trailing: _pill(
        label: 'Registered',
        fg: const Color(0xFF047857),
        bg: const Color(0xFFECFDF5),
        border: const Color(0xFFA7F3D0),
        dot: emerald,
      ),
      child: InkWell(
        onTap: _showBoatSelectionModal,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFEFF6FF), Color(0xFFF0F9FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [maritime600, Color(0xFF4F46E5)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: maritime600.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        boatName.isNotEmpty
                            ? boatName.substring(0, 1).toUpperCase()
                            : 'B',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -3, right: -3,
                    child: Container(
                      width: 17, height: 17,
                      decoration: BoxDecoration(
                        color: emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boatName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reg: ${boatReg.isNotEmpty ? boatReg : 'N/A'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text('Change',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: maritime700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Port Details ───
  Widget _buildPortDetailsSection() {
    final primaryName = _portList
        .firstWhereOrNull((p) => p['port_id'] == _primaryPortId)?[
    'port_name'] ??
        'Select Primary Port';
    final destCount = _selectedDestinationPortIds.length;

    return _sectionCard(
      icon: Icons.explore_rounded,
      title: 'Port Details',
      subtitle: 'Navigation Passage & Waypoints',
      iconColor: const Color(0xFF4F46E5),
      iconBgStart: const Color(0xFFEEF2FF),
      iconBgEnd: const Color(0xFFE0E7FF),
      iconBorder: const Color(0xFFC7D2FE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary Port (Departure)',
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: textMuted)),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showPrimaryPortModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: slateBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: const BoxDecoration(
                        color: maritime600, shape: BoxShape.circle),
                    child: const Center(
                      child: Text('A',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      primaryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textPrimary),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: textMuted, size: 24),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Select Destination Ports',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textMuted)),
              const Spacer(),
              const Text('WAYPOINTS',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: textMuted,
                      letterSpacing: 0.6)),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _showDestinationPortsModal,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFBFDBFE),
                    style: BorderStyle.solid),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: const Center(
                      child: Text('B',
                          style: TextStyle(
                              color: textMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      destCount == 0
                          ? 'Select Destination Ports'
                          : '$destCount Port${destCount > 1 ? 's' : ''} Selected',
                      style: TextStyle(
                        fontSize: 15,
                        color: destCount == 0 ? textMuted : textPrimary,
                        fontWeight: destCount == 0
                            ? FontWeight.w500
                            : FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded,
                            size: 16, color: maritime600),
                        SizedBox(width: 4),
                        Text('Add Port',
                            style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: maritime600)),
                      ],
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

  // ─── Dates & Times ───
  Widget _buildDatesAndTimesSection() {
    return _sectionCard(
      icon: Icons.calendar_month_rounded,
      title: 'Dates & Times',
      subtitle: 'Voyage Schedule Window',
      iconColor: const Color(0xFF4F46E5),
      iconBgStart: const Color(0xFFEEF2FF),
      iconBgEnd: const Color(0xFFE0E7FF),
      iconBorder: const Color(0xFFC7D2FE),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: slateBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                        width: 9, height: 9,
                        decoration: const BoxDecoration(
                            color: maritime600, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    const Text('DEPARTURE PHASE',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: maritime50,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: maritime100)),
                      child: const Text('GMT +05:30',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: maritime700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildDateField(
                            'Start Date',
                            _startDate,
                                () => _selectDate(context, true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTimeField(
                            'Start Time', startTimeController)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: slateBorder),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                        width: 9, height: 9,
                        decoration: const BoxDecoration(
                            color: Color(0xFF4F46E5),
                            shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    const Text('RETURN PHASE',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: 0.5)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                              color: const Color(0xFFE0E7FF))),
                      child: const Text('EXPECTED PORT ENTRY',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4338CA))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildDateField(
                            'Return Date',
                            _returnDate,
                                () => _selectDate(context, false))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildTimeField(
                            'Return Time', returnTimeController)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: slateBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    date != null
                        ? DateFormat('dd MMM yyyy').format(date)
                        : 'Select',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textPrimary),
                  ),
                ),
                const Icon(Icons.calendar_today_rounded,
                    size: 17, color: maritime600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textMuted)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _pickTime(controller),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: slateBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 18, color: maritime600),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? 'Select time'
                        : controller.text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Resources ───
  Widget _buildResourcesSection() {
    return _sectionCard(
      icon: Icons.shield_rounded,
      title: 'Resources',
      subtitle: 'Safety & Provisions Audit',
      iconColor: const Color(0xFF059669),
      iconBgStart: const Color(0xFFECFDF5),
      iconBgEnd: const Color(0xFFD1FAE5),
      iconBorder: const Color(0xFFA7F3D0),
      trailing: _pill(
        label: 'Mandatory',
        fg: const Color(0xFFE11D48),
        bg: const Color(0xFFFFE4E6),
        border: const Color(0xFFFECDD3),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Fresh Water',
                  freshWaterController,
                  Icons.water_drop_rounded,
                  const Color(0xFF06B6D4),
                  unit: 'L',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  'Diesel',
                  dieselController,
                  Icons.local_gas_station_rounded,
                  const Color(0xFFF59E0B),
                  unit: 'L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Life Jackets',
                  lifeJacketController,
                  Icons.health_and_safety_rounded,
                  const Color(0xFF059669),
                  unit: 'Qty',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  'Life Buoys',
                  lifeBuoysController,
                  Icons.radio_button_unchecked_rounded,
                  const Color(0xFFF97316),
                  unit: 'Qty',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithSuffix(
            label: 'Communication Devices',
            controller: communicationController,
            icon: Icons.radio_rounded,
            iconColor: const Color(0xFF4F46E5),
            hint: 'e.g., 2 VHF, 1 Sat Phone',
            suffix: 'VHF / Satellite',
            suffixFg: maritime700,
            suffixBg: maritime50,
            keyboardType: TextInputType.text,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
      String label,
      TextEditingController ctrl,
      IconData icon,
      Color iconColor, {
        String? unit,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: slateBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                    EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (unit != null)
                Text(unit,
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldWithSuffix({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color iconColor,
    required String hint,
    required String suffix,
    required Color suffixFg,
    required Color suffixBg,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: textMuted)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: slateBorder),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: iconColor),
              const SizedBox(width: 9),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  validator: validator,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: textPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 11),
                    counterText: '',
                  ),
                ),
              ),
              if (suffix.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: suffixBg,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                        color: maritime100.withOpacity(0.8)),
                  ),
                  child: Text(suffix,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: suffixFg)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Emergency Contact ───
  Widget _buildEmergencyContactSection() {
    return _sectionCard(
      icon: Icons.phone_rounded,
      title: 'Emergency Contact',
      subtitle: 'Primary Shore Representative',
      iconColor: const Color(0xFF0284C7),
      iconBgStart: const Color(0xFFF0F9FF),
      iconBgEnd: const Color(0xFFE0F2FE),
      iconBorder: const Color(0xFFBAE6FD),
      trailing: _pill(
        label: '24/7 Reachable',
        fg: maritime700,
        bg: maritime50,
        border: maritime100,
      ),
      child: Column(
        children: [
          _buildTextFieldWithSuffix(
            label: 'Emergency Contact Name',
            controller: _emergencyNameController,
            icon: Icons.person_outline_rounded,
            iconColor: textMuted,
            hint: 'Emergency Contact Name',
            suffix: '',
            suffixFg: textMuted,
            suffixBg: Colors.transparent,
            keyboardType: TextInputType.text,
            validator: (value) =>
            value == null || value.trim().isEmpty
                ? 'Enter emergency contact name'
                : null,
          ),
          const SizedBox(height: 12),
          _buildTextFieldWithSuffix(
            label: 'Emergency Contact No.',
            controller: _emergencyMobileController,
            icon: Icons.phone_outlined,
            iconColor: textMuted,
            hint: '10-digit mobile',
            suffix: '',
            suffixFg: textMuted,
            suffixBg: Colors.transparent,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter emergency mobile number';
              }
              final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (clean.length != 10) {
                return 'Enter valid 10-digit mobile number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Crew Section ───
  Widget _buildCrewSection() {
    return _sectionCard(
      icon: Icons.groups_rounded,
      title: 'Crew',
      subtitle: 'Onboard Fishermen & Seamen',
      trailing: _pill(
        label: 'Manifest',
        fg: maritime700,
        bg: maritime50,
        border: maritime100,
      ),
      child: Column(
        children: [
          _buildTextFieldWithSuffix(
            label: 'Captain Name',
            controller: _captainNameController,
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF64748B),
            hint: 'Captain Name',
            suffix: 'Master / Skipper',
            suffixFg: maritime700,
            suffixBg: maritime50,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: _selectCrewMembers,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFF0F7FF), Color(0xFFE0EFFE)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: maritime100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: maritime100),
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded,
                        size: 19, color: maritime600),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Select Crew Members',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: maritime800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: maritime100),
                    ),
                    child: Text(
                      '${_selectedCrewIds.length} Selected',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: maritime700),
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

  // ─── Submit Section ───
  Widget _buildSubmitSection() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 58,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitIntimation,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [maritime600, maritime500, Color(0xFF38BDF8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: maritime600.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 7)),
                ],
                border: Border.all(
                    color: maritime100.withOpacity(0.6)),
              ),
              child: Center(
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.6),
                )
                    : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Submit Intimation',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4)),
                    SizedBox(width: 10),
                    Icon(Icons.send_rounded,
                        color: Colors.white, size: 19),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: maritime50.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: maritime100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                    color: maritime600, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    size: 12, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Data will be officially intimated to Coastal Security & Marine Fisheries Department.',
                  style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Pill widget ───
  Widget _pill({
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
    Color? dot,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
                width: 6, height: 6,
                decoration: BoxDecoration(
                    color: dot, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: fg)),
        ],
      ),
    );
  }

  // ─── Date & Time pickers (UNCHANGED) ───
  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _returnDate = picked;
      });
    }
  }

  Future<void> _pickTime(TextEditingController controller) async {
    int hour = 0;
    int minute = 0;
    final text = controller.text.trim();
    if (text.contains(':')) {
      final parts = text.split(':');
      hour = int.tryParse(parts[0]) ?? 0;
      minute = int.tryParse(parts[1]) ?? 0;
    } else {
      final now = TimeOfDay.now();
      hour = now.hour;
      minute = now.minute;
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      initialEntryMode: TimePickerEntryMode.dialOnly,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hh = picked.hour.toString().padLeft(2, '0');
      final mm = picked.minute.toString().padLeft(2, '0');
      controller.text = '$hh:$mm';
      setState(() {});
    }
  }

  String _formatApiDateTime(DateTime dt) {
    final String iso = dt.toIso8601String().split('.').first;
    return '$iso+05:30';
  }
}