// lib/screens/boat_owner/dashboard_screen.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:fishing_voyage_manag_sys/main.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/start_trip_screen.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/end_trip_screen.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/api_service.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/location_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/offline_map_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/sync_service.dart';
import 'package:fishing_voyage_manag_sys/services/background_Services/offline_queue_service.dart';
import 'boat_selection_screen.dart';
import 'voyage_intimation_screen.dart';
import 'add_crew_screen.dart';
import 'sos_screen.dart';
import 'add_catch_screen.dart';
import 'route_map_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // ─── NEW UI PALETTE ───────────────────────────────────────────
  static const Color maritime950 = Color(0xFF051329);
  static const Color maritime900 = Color(0xFF0A1D3B);
  static const Color maritime800 = Color(0xFF0F2B57);
  static const Color maritime700 = Color(0xFF153E7C);
  static const Color maritime600 = Color(0xFF1D5BD8);
  static const Color maritime500 = Color(0xFF2563EB);
  static const Color maritime400 = Color(0xFF38BDF8);
  static const Color maritime100 = Color(0xFFE0EDFF);
  static const Color maritime50  = Color(0xFFF0F6FF);
  static const Color cyberCyan   = Color(0xFF06B6D4);
  static const Color cyberEmerald = Color(0xFF10B981);
  static const Color cyberAmber  = Color(0xFFF59E0B);
  static const Color cyberCoral  = Color(0xFFF43F5E);
  static const Color surfaceBg   = Color(0xFFF8FAFC);

  List<Map<String, dynamic>> intimations = [];
  List<Map<String, dynamic>> crewMembers = [];
  Map<String, dynamic> summary = {};

  String selectedFilter = 'all';
  bool isLoading = true;
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;

  // Sync status
  int unsyncedLocations = 0;
  int? activeVoyageId;
  Timer? _syncCheckTimer;
  Timer? _syncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOffline = false;

  // Profile data
  String? ownerName;
  String? ownerMobile;
  String? ownerAddress;
  String? ownerHomePort;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadProfile();
    _startSyncStatusTimer();
    _startPeriodicSync();
    _initConnectivity();
    _checkAndSyncOnStart();
  }

  void _checkAndSyncOnStart() async {
    final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
    if (result.any((r) => r != ConnectivityResult.none)) {
      debugPrint('🌐 App started online — syncing pending');
      try {
        await SyncService().syncAll();
        await _updateSyncStatus();
      } catch (e) {
        debugPrint('⚠️ Start sync error: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncCheckTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> result) async {
        final isOffline = result.every((r) => r == ConnectivityResult.none);

        if (mounted && _isOffline != isOffline) {
          setState(() => _isOffline = isOffline);

          if (!isOffline) {
            debugPrint('🌐 Back online — triggering full sync');

            // 1. Drain the offline queue (locations + SOS + citing)
            try {
              await SyncService().syncAll();
              debugPrint('✅ [dashboard] syncAll completed');
            } catch (e) {
              debugPrint('❌ [dashboard] syncAll failed: $e');
            }

            // 2. Refresh UI
            await _loadData(refresh: true, showLoading: false);

            // 3. Update badge
            await _updateSyncStatus();

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Back Online! Syncing pending data...'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      },
    );
  }

  void _startSyncStatusTimer() {
    _syncCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateSyncStatus();
    });
    _updateSyncStatus();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final List<ConnectivityResult> result = await Connectivity().checkConnectivity();
      if (result.any((r) => r != ConnectivityResult.none)) {
        debugPrint('⏰ Periodic sync tick');
        try {
          await SyncService().syncAll();
          await _updateSyncStatus();
        } catch (e) {
          debugPrint('⚠️ Periodic sync error: $e');
        }
      }
    });
  }

  void _safeSync() async {
    try {
      await SyncService().syncAll();
      await _updateSyncStatus();
    } catch (e) {
      debugPrint('⚠️ Periodic sync error (ignored): $e');
    }
  }

  Future<void> _updateSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final voyageId = prefs.getInt('active_voyage_id');
      if (voyageId != null) {
        final count = await _db.getUnsyncedLocationCount(voyageId);
        if (mounted) {
          setState(() {
            activeVoyageId = voyageId;
            unsyncedLocations = count;
          });
        }
      } else {
        if (mounted && activeVoyageId != null) {
          setState(() {
            activeVoyageId = null;
            unsyncedLocations = 0;
          });
        }
      }
    } catch (e) {
      print('Error updating sync status: $e');
    }
  }

  Future<void> _loadProfile() async {
    try {
      final owner = await _db.getBoatOwner();
      if (owner != null && mounted) {
        setState(() {
          ownerName = owner['owner_name']?.toString();
          ownerMobile = owner['mobile']?.toString();
          ownerAddress = owner['address']?.toString();
          ownerHomePort = owner['home_port_name']?.toString();
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }

  Future<void> _loadData({bool refresh = false, bool showLoading = true}) async {
    if (!mounted) return;
    if (showLoading) setState(() => isLoading = true);
    if (refresh) {
      intimations.clear();
      currentPage = 1;
    }
    await _loadLocalVoyages();
    try {
      await _loadFromApi();
    } catch (e) {
      debugPrint('⚠️ Could not refresh from API: $e');
      if (mounted) {
        if (intimations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cached data. Please check your internet connection.'), backgroundColor: Colors.red),
          );
        } else if (refresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Refresh failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.orange),
          );
        }
      }
    } finally {
      if (mounted && showLoading) setState(() => isLoading = false);
    }

    // ⭐ CRITICAL — drain offline queue every time _loadData runs
    try {
      await SyncService().syncAll();
      await _updateSyncStatus();
    } catch (e) {
      debugPrint('⚠️ syncAll from _loadData failed: $e');
    }
  }

  Future<void> _loadFromApi() async {
    final List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
    if (connectivity.every((r) => r == ConnectivityResult.none)) {
      debugPrint('⚠️ No internet connection. Skipping API call.');
      return;
    }
    try {
      final response = await retryApiCall(
            () => _apiService.getIntimations(
          page: currentPage,
          pageSize: 20,
          onError: (msg) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
            }
          },
        ),
      );

      if (response['success'] == true) {
        final data = response['data'];
        final items = data['items'] as List?;
        if (items != null) {
          final loadedIntimations = List<Map<String, dynamic>>.from(items);
          await _db.syncVoyages(
            items: loadedIntimations,
            onError: (msg) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
              }
            },
          );
          for (final item in loadedIntimations) {
            item['id'] = item['intimation_id'];
          }
          if (mounted) {
            setState(() {
              intimations = loadedIntimations;
              totalItems = data['total'] ?? 0;
              totalPages = data['total_pages'] ?? 1;
              if (data['summary'] != null) {
                summary = Map<String, dynamic>.from(data['summary']);
              }
            });
            debugPrint('✅ Loaded ${intimations.length} voyages from API.');
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to load data');
      }
      await _loadCrew();
    } catch (e) {
      rethrow;
    }
  }

  // ─── OPTIMISTIC UI UPDATES ───
  void _addVoyageLocally(Map<String, dynamic> newVoyage) {
    setState(() {
      intimations.insert(0, newVoyage);
    });
    print('✅ Added placeholder voyage locally.');
  }

  void _updateVoyageStatusLocally(int intimationId, String newStatus) {
    setState(() {
      final index = intimations.indexWhere((v) => (v['intimation_id'] ?? v['id']) == intimationId);
      if (index != -1) {
        intimations[index]['derived_status'] = newStatus;
        if (newStatus == 'AT SEA') {
          intimations[index]['btn_status'] = 'End Trip';
        } else if (newStatus == 'COMPLETED') {
          intimations[index]['btn_status'] = null;
        }
      }
    });
    print('✅ Updated voyage $intimationId status to $newStatus locally.');
  }

  Future<void> _loadLocalVoyages() async {
    try {
      final localVoyages = await _db.getAllLocalVoyages();
      if (localVoyages.isNotEmpty && mounted) {
        setState(() {
          intimations = localVoyages.map((v) {
            return {
              'intimation_id': v['id'],
              'reference_no': v['reference_no'] ?? 'N/A',
              'boat_id': v['boat_id'],
              'boat_name': v['boat_name'] ?? 'N/A',
              'boat_reg_no': v['boat_reg_no'] ?? 'N/A',
              'voyage_start_date': v['voyage_start_date'],
              'voyage_return_date': v['voyage_return_date'],
              'derived_status': v['derived_status'] ?? 'UNKNOWN',
              'intimation_status': v['status'] ?? 'SUBMITTED',
              'trip_status': v['derived_status'] ?? 'PENDING',
              'btn_status': v['btn_status'],
              'total_crew_count': v['total_crew_count'] ?? 0,
              'crew_names': v['crew_names_json'] != null ? jsonDecode(v['crew_names_json']) : [],
              'destination_ports_text': v['destination_ports_text'] ?? 'N/A',
              'communication_devices': v['communication_devices'] ?? 0,
              'total_fish_weight_kg': v['total_fish_weight_kg'] ?? 0.0,
              'sos_count': v['sos_count'] ?? 0,
              'citing_count': v['citing_count'] ?? 0,
            };
          }).toList();
          totalItems = intimations.length;
          totalPages = 1;
        });
        print('✅ Loaded ${intimations.length} voyages from local database.');
      }
    } catch (e) {
      print('❌ Error loading local voyages: $e');
    }
  }

  Future<void> _loadCrew() async {
    try {
      final session = await _db.getUserSession();
      final token = session?['access_token'];
      if (token == null) return;
      final response = await retryApiCall(
            () => _apiService.getCrewList(page: 1, pageSize: 50),
      );
      if (response['success'] == true) {
        final items = response['data']['items'] as List?;
        if (items != null && items.isNotEmpty) {
          crewMembers = List<Map<String, dynamic>>.from(items);
          crewMembers = crewMembers.map((crew) {
            crew['id'] = crew['crew_id'];
            return crew;
          }).toList();
          print('✅ Loaded ${crewMembers.length} crew members');
        } else {
          crewMembers = [];
        }
      }
    } catch (e) {
      print('Error loading crew: $e');
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _showLocationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final voyageId = prefs.getInt('active_voyage_id');
    if (voyageId == null) {
      _showSnackBar('No active voyage', backgroundColor: Colors.orange);
      return;
    }
    final locations = await _db.getLocationsForVoyage(voyageId);
    _showSnackBar('Voyage $voyageId: ${locations.length} locations stored', backgroundColor: Colors.green);
  }

  Future<void> _forcePushMissingLocations() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('⏳ Force push started... Check logs.')),
    );

    try {
      final session = await _db.getUserSession();
      final String? token = session?['access_token'];
      if (token == null || token.isEmpty) {
        debugPrint('❌ Token not found. Please login again.');
        _showSnackBar('Session expired. Please login again.', backgroundColor: Colors.red);
        return;
      }
      final unsynced = await _db.getUnsyncedLocations();
      debugPrint('📊 Found ${unsynced.length} unsynced locations to push.');
      if (unsynced.isEmpty) {
        debugPrint('✅ No missing locations to push.');
        _showSnackBar('✅ No missing data.', backgroundColor: Colors.green);
        return;
      }
      int successCount = 0;
      int failCount = 0;
      for (var loc in unsynced) {
        final intimationId = loc['voyage_id'];
        if (intimationId == null) {
          failCount++;
          continue;
        }
        try {
          debugPrint('📤 Pushing point ID ${loc['id']} for voyage $intimationId');
          final String? voyageNo = await _db.getVoyageReferenceNo(intimationId);
          final response = await _apiService.sendPing(
            intimationId: intimationId,
            voyageNo: voyageNo,
            latitude: loc['latitude'],
            longitude: loc['longitude'],
            timestamp: loc['timestamp'],
            token: token,
          );
          if (response['success'] == true) {
            await _db.markLocationSynced(loc['id']);
            successCount++;
            debugPrint('✅ Point ${loc['id']} pushed successfully.');
          } else {
            failCount++;
            debugPrint('❌ Point ${loc['id']} failed: ${response['message']}');
          }
        } catch (e) {
          failCount++;
          debugPrint('❌ Exception for point ${loc['id']}: $e');
        }
      }
      debugPrint('🏁 Force push finished. Success: $successCount, Failed: $failCount');
      await _updateSyncStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Push done. Success: $successCount, Failed: $failCount'),
            backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Fatal error in force push: $e');
      _showSnackBar('❌ Error: $e', backgroundColor: Colors.red);
    }
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return '';
    return status.toString().trim().toUpperCase();
  }

  int get _totalVoyageCount => intimations.length;
  int get _appliedVoyageCount => intimations.where((item) => _normalizeStatus(item['derived_status']) == 'APPLIED').length;
  int get _atSeaVoyageCount => intimations.where((item) => _normalizeStatus(item['derived_status']) == 'AT SEA').length;
  int get _completedVoyageCount => intimations.where((item) => _normalizeStatus(item['derived_status']) == 'COMPLETED').length;

  List<Map<String, dynamic>> get _filteredIntimations {
    if (selectedFilter == 'all') return intimations;
    if (selectedFilter == 'applied') {
      return intimations.where((v) => _normalizeStatus(v['derived_status']) == 'APPLIED').toList();
    }
    if (selectedFilter == 'at_sea') {
      return intimations.where((v) => _normalizeStatus(v['derived_status']) == 'AT SEA').toList();
    }
    if (selectedFilter == 'completed') {
      return intimations.where((v) => _normalizeStatus(v['derived_status']) == 'COMPLETED').toList();
    }
    return intimations;
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'N/A';
    switch (_normalizeStatus(status)) {
      case 'APPLIED': return 'Applied';
      case 'AT SEA': return 'At Sea';
      case 'COMPLETED': return 'Completed';
      default: return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (_normalizeStatus(status)) {
      case 'APPLIED': return const Color(0xFFF59E0B);
      case 'AT SEA': return const Color(0xFF06B6D4);
      case 'COMPLETED': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.help;
    switch (_normalizeStatus(status)) {
      case 'APPLIED': return Icons.pending_actions;
      case 'AT SEA': return Icons.sailing;
      case 'COMPLETED': return Icons.check_circle;
      default: return Icons.help;
    }
  }

  String _getButtonText(String? btnStatus) {
    if (btnStatus == null) return 'Start Trip';
    switch (btnStatus.toLowerCase()) {
      case 'start trip': return 'Start Trip';
      case 'end trip': return 'End Trip';
      default: return btnStatus;
    }
  }

  Color _getButtonColor(String? btnStatus) {
    if (btnStatus == null) return maritime500;
    switch (btnStatus.toLowerCase()) {
      case 'start trip': return maritime500;
      case 'end trip': return const Color(0xFF10B981);
      default: return maritime500;
    }
  }

  bool _shouldShowButton(String? btnStatus) {
    if (btnStatus == null) return false;
    final status = btnStatus.toLowerCase();
    return status == 'start trip' || status == 'end trip';
  }

  // ─── NAVIGATION (UNCHANGED) ───
  void _navigateToSOS(Map<String, dynamic> intimation) async {
    final intimationId = intimation['intimation_id'] ?? intimation['id'];
    final boatName = intimation['boat_name'] ?? 'N/A';
    final boatRegNo = intimation['boat_reg_no'] ?? 'N/A';
    final referenceNo = intimation['reference_no'] ?? 'N/A';

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SOSScreen(
          intimationId: intimationId,
          boatName: boatName,
          boatRegNo: boatRegNo,
          referenceNo: referenceNo,
        ),
      ),
    );
    if (!mounted) return;
    _loadData(refresh: true, showLoading: false);
  }

  Future<void> _navigateToAddCatch(int intimationId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddCatchScreen(voyageId: intimationId)),
    );
    if (!mounted) return;
    _loadData(refresh: true, showLoading: false);
  }

  Future<void> _navigateToAddCrew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCrewScreen()),
    );
    if (!mounted) return;
    _loadData(refresh: true, showLoading: false);
  }

  Future<void> _navigateToVoyageIntimation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoyageIntimationScreen()),
    );
    if (!mounted) return;
    if (result == true) {
      final placeholder = {
        'intimation_id': DateTime.now().millisecondsSinceEpoch,
        'boat_name': 'Loading...',
        'derived_status': 'SUBMITTED',
        'reference_no': '...',
      };
      _addVoyageLocally(placeholder);
    }
    _loadData(refresh: true, showLoading: false);
  }

  void _navigateToBoatSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BoatSelectionScreen()),
    );
    if (!mounted) return;
    _loadData(refresh: true, showLoading: false);
  }

  Future<void> _handleStartTrip(int intimationId, String boatName, String? referenceNo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartTripScreen(
          intimationId: intimationId,
          boatName: boatName,
          referenceNo: referenceNo,
        ),
      ),
    );
    if (result == true && mounted) {
      _updateVoyageStatusLocally(intimationId, 'AT SEA');
      _loadData(refresh: true, showLoading: false);
    }
  }

  Future<void> _handleEndTrip(int intimationId, String boatName) async {
    final intimation = intimations.firstWhere(
          (item) => (item['intimation_id'] ?? item['id']) == intimationId,
      orElse: () => {},
    );
    final int boatId = intimation['boat_id'] ?? 0;
    if (boatId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Boat ID not found for this intimation'), backgroundColor: Colors.red),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EndTripScreen(
          intimationId: intimationId,
          boatName: boatName,
          boatId: boatId,
        ),
      ),
    );
    if (result == true && mounted) {
      _updateVoyageStatusLocally(intimationId, 'COMPLETED');
      _loadData(refresh: true, showLoading: false);
    }
  }

  void _resumeTracking() async {
    final prefs = await SharedPreferences.getInstance();
    final voyageId = prefs.getInt('active_voyage_id');
    if (voyageId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active voyage found.')));
      }
      return;
    }
    await FlutterForegroundTask.startService(
      notificationTitle: 'Fishing Voyage',
      notificationText: 'Tracking location...',
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.example.fishing_voyage_manag_sys.ICON',
      ),
      callback: startCallback,
    );
    LocationService().startTracking(voyageId, intervalSeconds: 60);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Tracking resumed')));
    }
  }

  Future<void> _downloadOfflineMap() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting map download for Lakshadweep area...')),
      );
      await OfflineMapService.downloadLakshadweepTiles(
        onProgress: (progress) {
          debugPrint('Offline map: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Map download completed!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      debugPrint('❌ Map download error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Map download failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? Your voyage data will remain on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _db.clearUserSessionOnly();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/depart_login_selection');
      }
    }
  }

  // ─── VOYAGE DETAILS DIALOG (restyled) ───
  void _showVoyageDetails(Map<String, dynamic> intimation) {
    final startDate = intimation['voyage_start_date'] != null
        ? DateTime.tryParse(intimation['voyage_start_date'].toString())
        : null;
    final returnDate = intimation['voyage_return_date'] != null
        ? DateTime.tryParse(intimation['voyage_return_date'].toString())
        : null;
    final crewNames = intimation['crew_names'] is List
        ? (intimation['crew_names'] as List).join(', ')
        : null;
    final fishWeight = (intimation['total_fish_weight_kg'] ?? 0).toString();
    final status = _getStatusLabel(intimation['derived_status']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [maritime900, maritime700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.directions_boat_rounded, color: Colors.white, size: 25),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intimation['boat_name']?.toString() ?? 'Voyage Details',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 3),
                            const Text('Voyage Information', style: TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Basic Information', Icons.info_outline_rounded),
                        const SizedBox(height: 10),
                        _buildVoyageDetailCard(children: [
                          _buildVoyageDetailRow(Icons.tag_rounded, 'Reference', intimation['reference_no']?.toString() ?? 'N/A'),
                          _buildVoyageDetailRow(Icons.directions_boat_rounded, 'Boat Name', intimation['boat_name']?.toString() ?? 'N/A'),
                          _buildVoyageDetailRow(Icons.badge_outlined, 'Registration', intimation['boat_reg_no']?.toString() ?? 'N/A'),
                          _buildVoyageDetailRow(Icons.person_outline_rounded, 'Owner', intimation['owner_name']?.toString() ?? 'N/A', isLast: true),
                        ]),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Voyage Status', Icons.flag_outlined),
                        const SizedBox(height: 10),
                        _buildVoyageDetailCard(children: [_buildVoyageStatusRow(status: status)]),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Voyage Details', Icons.map_outlined),
                        const SizedBox(height: 10),
                        _buildVoyageDetailCard(children: [
                          _buildVoyageDetailRow(Icons.location_on_outlined, 'Destinations', intimation['destination_ports_text']?.toString() ?? 'N/A'),
                          if (startDate != null)
                            _buildVoyageDetailRow(Icons.calendar_today_outlined, 'Start Date', DateFormat('dd MMM yyyy').format(startDate)),
                          if (returnDate != null)
                            _buildVoyageDetailRow(Icons.event_available_outlined, 'Return Date', DateFormat('dd MMM yyyy').format(returnDate), isLast: true),
                        ]),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Crew & Communication', Icons.groups_outlined),
                        const SizedBox(height: 10),
                        _buildVoyageDetailCard(children: [
                          _buildVoyageDetailRow(Icons.groups_outlined, 'Crew Count', intimation['total_crew_count']?.toString() ?? '0'),
                          if (crewNames != null && crewNames.isNotEmpty)
                            _buildVoyageDetailRow(Icons.people_outline_rounded, 'Crew Members', crewNames),
                          _buildVoyageDetailRow(Icons.devices_other_outlined, 'Communication Devices', intimation['communication_devices']?.toString() ?? '0', isLast: true),
                        ]),
                        const SizedBox(height: 18),
                        _buildSectionTitle('Activity Summary', Icons.analytics_outlined),
                        const SizedBox(height: 10),
                        _buildVoyageDetailCard(children: [
                          _buildVoyageDetailRow(Icons.set_meal_outlined, 'Fish Weight', '$fishWeight kg'),
                          _buildVoyageDetailRow(Icons.sos_outlined, 'SOS Count', intimation['sos_count']?.toString() ?? '0'),
                          _buildVoyageDetailRow(Icons.directions_boat_rounded, 'Citing Count', intimation['citing_count']?.toString() ?? '0'),
                          _buildVoyageDetailRow(Icons.lock_outline_rounded, 'Is Locked', intimation['is_locked'] == true ? 'Yes' : 'No', isLast: true),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RouteMapScreen(
                                    voyageId: intimation['intimation_id'] ?? intimation['id'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('View Travelled Route'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: maritime500),
                              foregroundColor: maritime500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: maritime500,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30, height: 30,
          decoration: BoxDecoration(color: maritime500.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 17, color: maritime500),
        ),
        const SizedBox(width: 9),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildVoyageDetailCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildVoyageDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: isLast
          ? null
          : const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: maritime50, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: maritime500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 5),
                Text(value, softWrap: true, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoyageStatusRow({required String status}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: maritime500.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.flag_rounded, size: 19, color: maritime500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 5),
                Text(status, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: maritime500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD (NEW UI)
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceBg,
      drawer: _buildDrawer(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildNewHeader(),
            Expanded(
              child: isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: maritime500),
                    SizedBox(height: 16),
                    Text('Loading data...', style: TextStyle(color: Color(0xFF24365B), fontSize: 14)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: () => _loadData(refresh: true),
                color: maritime500,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeBanner(),
                      const SizedBox(height: 12),
                      _buildSyncStatusCard(),
                      const SizedBox(height: 12),
                      _buildPushMissingButton(),
                      const SizedBox(height: 12),
                      _buildStatsGrid(),
                      const SizedBox(height: 12),
                      _buildVoyageIntimationButton(),
                      const SizedBox(height: 12),
                      _buildCrewCard(),
                      const SizedBox(height: 12),
                      if (_isOffline) _buildOfflineBanner(),
                      if (_isOffline) const SizedBox(height: 12),
                      _buildVoyageList(),
                      if (currentPage < totalPages) ...[
                        const SizedBox(height: 12),
                        _buildLoadMoreButton(),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── NEW HEADER ───
  Widget _buildNewHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8),
        ),
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'HQ-SYS',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: cyberCyan,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    SizedBox(width: 6),
                    _PulseDot(color: cyberEmerald),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Command Dashboard',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
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
                margin: const EdgeInsets.only(right: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: maritime50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: maritime100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_upload_rounded,
                      color: maritime600,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: const TextStyle(
                        color: maritime700,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          GestureDetector(
            onTap: () => _loadData(refresh: true),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF0F172A),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
        GestureDetector(
          onTap: _handleLogout,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2), // soft rose background
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: const Color(0xFFFECDD3)), // light pink border
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF43F5E).withOpacity(0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFE11D48), // deep rose icon
              size: 22,
            ),
          ),
        ),
        ],
      ),
    );
  }

  // ─── WELCOME BANNER ───
  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFECFEFF), Color(0xFFEFF6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5F3FC)),
        boxShadow: [
          BoxShadow(color: maritime500.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(color: cyberCyan.withOpacity(0.08), shape: BoxShape.circle),
            ),
          ),
          Row(
            children: [
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFECFEFF), Color(0xFFDBEAFE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF67E8F9)),
                  boxShadow: [BoxShadow(color: cyberCyan.withOpacity(0.20), blurRadius: 12)],
                ),
                child: const Icon(Icons.directions_boat_rounded, color: maritime600, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFCFFAFE),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF67E8F9)),
                          ),
                          child: const Text('VESSEL ID: ACTIVE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: maritime700, fontFamily: 'monospace')),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cyberEmerald.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cyberEmerald.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _PulseDot(color: cyberEmerald),
                              const SizedBox(width: 5),
                              const Text('ONLINE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF047857))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome ${ownerName ?? "Boat Owner"}!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [maritime600, cyberCyan]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: maritime500.withOpacity(0.20), blurRadius: 8)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 5, height: 5, decoration: const BoxDecoration(color: Color(0xFFA5F3FC), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            '$_totalVoyageCount voyages total',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFFA5F3FC), size: 13),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── SYNC STATUS CARD ───
  Widget _buildSyncStatusCard() {
    final bool hasPending = unsyncedLocations > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA5F3FC)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: hasPending
                  ? [const Color(0xFFFFE4E6), const Color(0xFFFFF1F2)]
                  : [const Color(0xFFD1FAE5), const Color(0xFFECFDF5)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: hasPending ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
            ),
            child: Icon(
              hasPending ? Icons.sync_problem_rounded : Icons.sync_rounded,
              color: hasPending ? cyberCoral : cyberEmerald,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hasPending ? 'Syncing Location Data...' : 'Location Data Synced',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: hasPending ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _PulseDot(color: hasPending ? cyberCoral : cyberEmerald),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hasPending ? '$unsyncedLocations locations pending sync' : 'Tracking is active and healthy',
                  style: TextStyle(
                    fontSize: 11,
                    color: hasPending ? const Color(0xFFB91C1C) : const Color(0xFF047857),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasPending ? const Color(0xFFFFE4E6) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hasPending ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 5, height: 5, decoration: BoxDecoration(color: hasPending ? cyberCoral : cyberEmerald, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(
                  hasPending ? 'PENDING' : 'LIVE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: hasPending ? const Color(0xFFB91C1C) : const Color(0xFF047857), fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── PUSH MISSING LOCATIONS BUTTON ───
  Widget _buildPushMissingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFDC2626), Color(0xFFBE123C)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: cyberCoral.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))],
        border: Border.all(color: const Color(0xFFFB7185).withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _forcePushMissingLocations,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'PUSH ALL MISSING LOCATIONS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── STATS GRID ───
  Widget _buildStatsGrid() {
    final items = [
      _StatItem('TOTAL',   _totalVoyageCount.toString(),     maritime700,               maritime800,               Colors.white,  'all'),
      _StatItem('APPLIED', _appliedVoyageCount.toString(),   Colors.white,              Colors.white,              const Color(0xFF334155), 'applied'),
      _StatItem('AT SEA',  _atSeaVoyageCount.toString(),     const Color(0xFFECFEFF),   const Color(0xFFE0F2FE),   cyberCyan,     'at_sea', dot: true),
      _StatItem('DONE',    _completedVoyageCount.toString(), Colors.white,              Colors.white,              cyberEmerald,  'completed'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.35,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final isSelected = selectedFilter == item.key;
        final isDark = item.bgStart == maritime700;

        return GestureDetector(
          onTap: () => setState(() => selectedFilter = item.key),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [item.bgStart, item.bgEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? item.fg : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Pulse dot only on AT SEA — top-right corner
                if (item.dot)
                  const Positioned(
                    top: 6,
                    right: 6,
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: _DotPulse(),
                    ),
                  ),

                // ✅ THE LAYOUT YOU WANT — vertical stack, centered
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,           // shrink to content
                    mainAxisAlignment: MainAxisAlignment.center, // vertical center
                    crossAxisAlignment: CrossAxisAlignment.center, // horizontal center
                    children: [
                      // Number
                      Text(
                        item.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark ? const Color(0xFF67E8F9) : item.fg,
                          fontFamily: 'monospace',
                          height: 1.0,                        // removes extra line spacing
                        ),
                      ),

                      // Small gap
                      const SizedBox(height: 4),

                      // Label
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? const Color(0xFFCFFAFE)
                              : item.fg.withOpacity(0.85),
                          fontFamily: 'monospace',
                          letterSpacing: 0.5,
                          height: 1.0,                        // removes extra line spacing
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── VOYAGE INTIMATION BUTTON ───
  Widget _buildVoyageIntimationButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [maritime700, maritime600, cyberCyan],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: maritime500.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _navigateToVoyageIntimation,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.20), shape: BoxShape.circle),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 15),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Voyage Intimation',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── CREW CARD ───
  Widget _buildCrewCard() {
    final int crewCount = crewMembers.length;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFECFEFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5F3FC)),
            ),
            child: const Icon(Icons.groups_rounded, color: cyberCyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Crew Members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text('$crewCount members available', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _navigateToAddCrew,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [maritime600, cyberCyan]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: maritime500.withOpacity(0.20), blurRadius: 8)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Add Crew', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── VOYAGE LIST ───
  Widget _buildVoyageList() {
    final filtered = _filteredIntimations;
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 44, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text('No voyages found', style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Tap "Voyage Intimation" to start a new trip.', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildVoyageCard(filtered[index]);
      },
    );
  }

  // ─── VOYAGE CARD ───
  Widget _buildVoyageCard(Map<String, dynamic> intimation) {
    final derivedStatus = intimation['derived_status'] ?? 'APPLIED';
    final btnStatus = intimation['btn_status'];
    final statusLabel = _getStatusLabel(derivedStatus);
    final statusColor = _getStatusColor(derivedStatus);
    final statusIcon = _getStatusIcon(derivedStatus);
    final boatName = intimation['boat_name'] ?? 'N/A';
    final boatRegNo = intimation['boat_reg_no'] ?? 'N/A';
    final intimationId = intimation['intimation_id'] ?? intimation['id'];
    final referenceNo = intimation['reference_no'] ?? 'N/A';
    final crewNames = intimation['crew_names'] ?? [];
    final destinationText = intimation['destination_ports_text'] ?? 'N/A';
    final totalCrewCount = intimation['total_crew_count'] ?? 0;
    final totalFishWeight = intimation['total_fish_weight_kg'] ?? 0.0;
    final sosCount = intimation['sos_count'] ?? 0;
    final citingCount = intimation['citing_count'] ?? 0;

    final startDate = intimation['voyage_start_date'] != null
        ? DateTime.tryParse(intimation['voyage_start_date'].toString())
        : null;
    final returnDate = intimation['voyage_return_date'] != null
        ? DateTime.tryParse(intimation['voyage_return_date'].toString())
        : null;

    final bool showMainButton = _shouldShowButton(btnStatus);
    final String mainButtonText = _getButtonText(btnStatus);
    final Color mainButtonColor = _getButtonColor(btnStatus);
    final bool isAtSea = _normalizeStatus(derivedStatus) == 'AT SEA';
    final bool isCompleted = _normalizeStatus(derivedStatus) == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAtSea ? const Color(0xFFA5F3FC) : const Color(0xFFE2E8F0),
          width: isAtSea ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAtSea ? cyberCyan.withOpacity(0.12) : Colors.black.withOpacity(0.03),
            blurRadius: isAtSea ? 16 : 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Reference
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.30)),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.5, fontFamily: 'monospace')),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(referenceNo, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w700, fontFamily: 'monospace')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Boat + SOS
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: maritime50, borderRadius: BorderRadius.circular(8), border: Border.all(color: maritime100)),
                child: const Text('🚢', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(boatName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text('Reg: $boatRegNo', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontFamily: 'monospace')),
                  ],
                ),
              ),
              if (isAtSea)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: const Row(
                    children: [
                      Text('⚠️', style: TextStyle(fontSize: 11)),
                      SizedBox(width: 4),
                      Text('SOS ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFF8FAFC), const Color(0xFFECFEFF).withOpacity(0.5)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA5F3FC).withOpacity(0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Destination
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: cyberCyan),
                    const SizedBox(width: 6),
                    const SizedBox(width: 44, child: Text('Dest', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                    Expanded(
                      child: Text(destinationText, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Dates
                if (startDate != null)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const SizedBox(width: 44, child: Text('Start', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                      Text(DateFormat('dd MMM yyyy').format(startDate), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                      if (returnDate != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd MMM yyyy').format(returnDate), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                      ],
                    ],
                  ),
                if (crewNames.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      const SizedBox(width: 44, child: Text('Crew', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600, letterSpacing: 0.5))),
                      Expanded(
                        child: Text(
                          crewNames.join(', '),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (totalCrewCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: maritime50, borderRadius: BorderRadius.circular(4), border: Border.all(color: maritime100)),
                          child: Text('$totalCrewCount', style: const TextStyle(fontSize: 10, color: maritime700, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Chips
          if (totalFishWeight > 0 || citingCount > 0 || sosCount > 0) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (totalFishWeight > 0) _buildChip(Icons.analytics_rounded, '${totalFishWeight.toStringAsFixed(1)} kg', cyberEmerald),
                if (citingCount > 0) _buildChip(Icons.flag_rounded, '$citingCount citing', cyberAmber),
                if (sosCount > 0) _buildChip(Icons.sos_rounded, '$sosCount SOS', cyberCoral),
              ],
            ),
          ],
          const SizedBox(height: 12),
          // Actions
          _buildActionButtons(intimation, mainButtonText, mainButtonColor, showMainButton),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> intimation, String mainButtonText, Color mainButtonColor, bool showMainButton) {
    final derivedStatus = intimation['derived_status'] ?? 'APPLIED';
    final intimationId = intimation['intimation_id'] ?? intimation['id'];
    final boatName = intimation['boat_name'] ?? 'N/A';
    final referenceNo = intimation['reference_no'] ?? 'N/A';
    final bool showSOS = _normalizeStatus(derivedStatus) == 'AT SEA';
    final bool isCompleted = _normalizeStatus(derivedStatus) == 'COMPLETED';

    return Column(
      children: [
        Row(
          children: [
            if (showMainButton)
              Expanded(
                child: ElevatedButton(
                  onPressed: mainButtonText == 'Start Trip'
                      ? () => _handleStartTrip(intimationId, boatName, referenceNo)
                      : () => _handleEndTrip(intimationId, boatName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainButtonColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                    elevation: 0,
                  ),
                  child: Text(
                    mainButtonText.toUpperCase(),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                  ),
                ),
              ),
            if (showMainButton) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showVoyageDetails(intimation),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF67E8F9)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 44),
                  foregroundColor: maritime700,
                ),
                child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (showSOS)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _navigateToSOS(intimation),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFB7185)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    foregroundColor: cyberCoral,
                    minimumSize: const Size(0, 44),
                    backgroundColor: const Color(0xFFFFE4E6).withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.warning_rounded, size: 16),
                  label: const Text('SOS EMERGENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
            if (isCompleted) ...[
              if (showSOS) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _navigateToAddCatch(intimationId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cyberAmber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Catch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {
          currentPage++;
          _loadData(refresh: false);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: maritime500),
          foregroundColor: maritime500,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('Load More Voyages', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Working Offline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFB91C1C))),
                SizedBox(height: 2),
                Text('Some features may be limited. Data will sync when online.', style: TextStyle(fontSize: 11, color: Color(0xFFB91C1C))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── DRAWER (restyled) ───
  Widget _buildDrawer() {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [maritime900, maritime700, maritime600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.person_rounded, color: maritime600, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName ?? 'Boat Owner',
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (ownerMobile != null)
                            Text(ownerMobile!, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withOpacity(0.2), height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ownerAddress ?? 'No address available',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (ownerHomePort != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.directions_boat_rounded, size: 14, color: Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 6),
                      Text('Home Port: $ownerHomePort', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(icon: Icons.directions_boat_rounded, title: 'My Boats', onTap: () {
                  Navigator.pop(context);
                  _navigateToBoatSelection();
                }),
                _buildDrawerItem(icon: Icons.people_rounded, title: 'Crew Members', onTap: () {
                  Navigator.pop(context);
                  _navigateToAddCrew();
                }),
                _buildDrawerItem(icon: Icons.download_for_offline_rounded, title: 'Download Offline Map', onTap: () {
                  Navigator.pop(context);
                  _downloadOfflineMap();
                }),
                if (activeVoyageId != null)
                  _buildDrawerItem(icon: Icons.play_circle_filled_rounded, title: 'Resume Tracking', color: cyberEmerald, onTap: () {
                    Navigator.pop(context);
                    _resumeTracking();
                  }),
                _buildDrawerItem(icon: Icons.bug_report_rounded, title: 'Debug: Location Stats', color: cyberAmber, onTap: () {
                  Navigator.pop(context);
                  _showLocationCount();
                }),
                const Divider(height: 1),
                _buildDrawerItem(icon: Icons.logout_rounded, title: 'Logout', color: cyberCoral, onTap: () {
                  Navigator.pop(context);
                  _handleLogout();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? maritime700, size: 22),
      title: Text(title, style: TextStyle(color: color ?? maritime700, fontWeight: FontWeight.w600, fontSize: 14)),
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ══════════════════════════════════════════════════════════════

class _StatItem {
  final String label;
  final String value;
  final Color bgStart;
  final Color bgEnd;
  final Color fg;
  final String key;
  final bool dot;
  _StatItem(this.label, this.value, this.bgStart, this.bgEnd, this.fg, this.key, {this.dot = false});
}

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({this.color = const Color(0xFF10B981)});
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        width: 7, height: 7,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class _DotPulse extends StatefulWidget {
  const _DotPulse();
  @override
  State<_DotPulse> createState() => _DotPulseState();
}

class _DotPulseState extends State<_DotPulse> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(_c),
      child: Container(
        width: 6, height: 6,
        decoration: BoxDecoration(color: const Color(0xFF06B6D4), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.6), blurRadius: 6)]),
      ),
    );
  }
}