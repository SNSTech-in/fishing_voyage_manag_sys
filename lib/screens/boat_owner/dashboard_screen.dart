import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'package:fishing_voyage_manag_sys/main.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/start_trip_screen.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/end_trip_screen.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/boat_owners_api_service.dart';
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
  final BoatOwnwesApiService _apiService = BoatOwnwesApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // ============================================================
  // COLORS
  // ============================================================

  static const Color primary = Color(0xFF075985);
  static const Color primaryDark = Color(0xFF0C4A6E);
  static const Color primaryLight = Color(0xFF0EA5E9);

  static const Color appBarColor = Color(0xFF07347F);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);

  static const Color background = Color(0xFFF5F8FC);
  static const Color card = Colors.white;

  static const Color textDark = Color(0xFF0F172A);
  static const Color textMedium = Color(0xFF475569);
  static const Color textLight = Color(0xFF64748B);

  static const Color border = Color(0xFFE2E8F0);

  // ============================================================
  // DATA
  // ============================================================

  List<Map<String, dynamic>> intimations = [];
  List<Map<String, dynamic>> crewMembers = [];

  Map<String, dynamic> summary = {};

  String selectedFilter = 'all';

  bool isLoading = true;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;

  int unsyncedLocations = 0;
  int? activeVoyageId;

  Timer? _syncCheckTimer;
  Timer? _syncTimer;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isOffline = false;

  // ============================================================
  // PROFILE
  // ============================================================

  String? ownerName;
  String? ownerMobile;
  String? ownerAddress;
  String? ownerHomePort;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: appBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: appBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _loadData();
    _loadProfile();

    _startSyncStatusTimer();
    _startPeriodicSync();

    _initConnectivity();
    _checkAndSyncOnStart();
  }

  // ============================================================
  // CONNECTIVITY / SYNC
  // ============================================================

  void _checkAndSyncOnStart() async {
    final result = await Connectivity().checkConnectivity();

    if (result.any((r) => r != ConnectivityResult.none)) {
      try {
        await SyncService().syncAll();
        await _updateSyncStatus();
      } catch (e) {
        debugPrint('Start sync error: $e');
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
          setState(() {
            _isOffline = isOffline;
          });

          if (!isOffline) {
            try {
              await SyncService().syncAll();

              await _loadData(
                refresh: true,
                showLoading: false,
              );

              await _updateSyncStatus();

              if (mounted) {
                _showSnackBar(
                  'Back online. Pending data is syncing.',
                  backgroundColor: green,
                );
              }
            } catch (e) {
              debugPrint('Online sync error: $e');
            }
          }
        }
      },
    );
  }

  void _startSyncStatusTimer() {
    _syncCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) {
        _updateSyncStatus();
      },
    );

    _updateSyncStatus();
  }

  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) async {
        final result = await Connectivity().checkConnectivity();

        if (result.any((r) => r != ConnectivityResult.none)) {
          try {
            await SyncService().syncAll();
            await _updateSyncStatus();
          } catch (e) {
            debugPrint('Periodic sync error: $e');
          }
        }
      },
    );
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
        if (mounted) {
          setState(() {
            activeVoyageId = null;
            unsyncedLocations = 0;
          });
        }
      }
    } catch (e) {
      debugPrint('Sync status error: $e');
    }
  }

  // ============================================================
  // PROFILE
  // ============================================================

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
      debugPrint('Profile loading error: $e');
    }
  }

  // ============================================================
  // DATA
  // ============================================================

  Future<void> _loadData({
    bool refresh = false,
    bool showLoading = true,
  }) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        isLoading = true;
      });
    }

    if (refresh) {
      intimations.clear();
      currentPage = 1;
    }

    await _loadLocalVoyages();

    try {
      await _loadFromApi();
    } catch (e) {
      debugPrint('API loading error: $e');

      if (mounted && intimations.isEmpty) {
        _showSnackBar(
          'No cached data. Please check your internet connection.',
          backgroundColor: red,
        );
      }
    } finally {
      if (mounted && showLoading) {
        setState(() {
          isLoading = false;
        });
      }
    }

    try {
      await SyncService().syncAll();
      await _updateSyncStatus();
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<void> _loadFromApi() async {
    final connectivity = await Connectivity().checkConnectivity();

    if (connectivity.every((r) => r == ConnectivityResult.none)) {
      return;
    }

    final response = await retryApiCall(
          () => _apiService.getIntimations(
        page: currentPage,
        pageSize: 20,
        onError: (msg) {
          if (mounted) {
            _showSnackBar(
              msg,
              backgroundColor: red,
            );
          }
        },
      ),
    );

    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to load data');
    }

    final data = response['data'];

    final items = data['items'] as List?;

    if (items != null) {
      final loaded = List<Map<String, dynamic>>.from(items);

      await _db.syncVoyages(
        items: loaded,
        onError: (msg) {
          if (mounted) {
            _showSnackBar(
              msg,
              backgroundColor: red,
            );
          }
        },
      );

      for (final item in loaded) {
        item['id'] = item['intimation_id'];
      }

      if (mounted) {
        setState(() {
          intimations = loaded;

          totalItems = data['total'] ?? 0;

          totalPages = data['total_pages'] ?? 1;

          if (data['summary'] != null) {
            summary = Map<String, dynamic>.from(data['summary']);
          }
        });
      }
    }

    await _loadCrew();
  }

  Future<void> _loadLocalVoyages() async {
    try {
      final localVoyages = await _db.getAllLocalVoyages();

      if (localVoyages.isEmpty || !mounted) {
        return;
      }

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
            'crew_names': v['crew_names_json'] != null
                ? jsonDecode(v['crew_names_json'])
                : [],
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
    } catch (e) {
      debugPrint('Local voyage error: $e');
    }
  }

  Future<void> _loadCrew() async {
    try {
      final session = await _db.getUserSession();

      final token = session?['access_token'];

      if (token == null) return;

      final response = await retryApiCall(
            () => _apiService.getCrewList(
          page: 1,
          pageSize: 50,
        ),
      );

      if (response['success'] == true) {
        final items = response['data']['items'] as List?;

        if (items != null) {
          crewMembers = List<Map<String, dynamic>>.from(items);

          crewMembers = crewMembers.map((crew) {
            crew['id'] = crew['crew_id'];

            return crew;
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('Crew loading error: $e');
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showSnackBar(
      String message, {
        Color? backgroundColor,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _normalizeStatus(dynamic status) {
    if (status == null) return '';

    return status.toString().trim().toUpperCase();
  }

  int get _totalVoyageCount => intimations.length;

  int get _appliedVoyageCount =>
      intimations
          .where((item) => _normalizeStatus(item['derived_status']) == 'APPLIED')
          .length;

  int get _atSeaVoyageCount =>
      intimations
          .where((item) => _normalizeStatus(item['derived_status']) == 'AT SEA')
          .length;

  int get _completedVoyageCount =>
      intimations
          .where((item) => _normalizeStatus(item['derived_status']) == 'COMPLETED')
          .length;

  List<Map<String, dynamic>> get _filteredIntimations {
    switch (selectedFilter) {
      case 'applied':
        return intimations
            .where((v) => _normalizeStatus(v['derived_status']) == 'APPLIED')
            .toList();

      case 'at_sea':
        return intimations
            .where((v) => _normalizeStatus(v['derived_status']) == 'AT SEA')
            .toList();

      case 'completed':
        return intimations
            .where((v) => _normalizeStatus(v['derived_status']) == 'COMPLETED')
            .toList();

      default:
        return intimations;
    }
  }

  String _getStatusLabel(String? status) {
    switch (_normalizeStatus(status)) {
      case 'APPLIED':
        return 'Applied';

      case 'AT SEA':
        return 'At Sea';

      case 'COMPLETED':
        return 'Completed';

      default:
        return status ?? 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (_normalizeStatus(status)) {
      case 'APPLIED':
        return amber;

      case 'AT SEA':
        return cyan;

      case 'COMPLETED':
        return green;

      default:
        return textLight;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (_normalizeStatus(status)) {
      case 'APPLIED':
        return Icons.pending_actions_rounded;

      case 'AT SEA':
        return Icons.sailing_rounded;

      case 'COMPLETED':
        return Icons.check_circle_rounded;

      default:
        return Icons.help_outline_rounded;
    }
  }

  String _getButtonText(String? status) {
    if (status == null) {
      return 'Start Trip';
    }

    switch (status.toLowerCase()) {
      case 'start trip':
        return 'Start Trip';

      case 'end trip':
        return 'End Trip';

      default:
        return status;
    }
  }

  Color _getButtonColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'end trip':
        return green;

      default:
        return primary;
    }
  }

  bool _shouldShowButton(String? status) {
    if (status == null) return false;

    final value = status.toLowerCase();

    return value == 'start trip' || value == 'end trip';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _addVoyageLocally(Map<String, dynamic> voyage) {
    setState(() {
      intimations.insert(0, voyage);
    });
  }

  void _updateVoyageStatusLocally(int id, String status) {
    setState(() {
      final index = intimations.indexWhere(
            (v) => (v['intimation_id'] ?? v['id']) == id,
      );

      if (index != -1) {
        intimations[index]['derived_status'] = status;

        if (status == 'AT SEA') {
          intimations[index]['btn_status'] = 'End Trip';
        }

        if (status == 'COMPLETED') {
          intimations[index]['btn_status'] = null;
        }
      }
    });
  }

  Future<void> _navigateToSOS(Map<String, dynamic> intimation) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SOSScreen(
          intimationId: intimation['intimation_id'] ?? intimation['id'],
          boatName: intimation['boat_name'] ?? 'N/A',
          boatRegNo: intimation['boat_reg_no'] ?? 'N/A',
          referenceNo: intimation['reference_no'] ?? 'N/A',
        ),
      ),
    );

    if (mounted) {
      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  Future<void> _navigateToAddCatch(int intimationId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCatchScreen(
          voyageId: intimationId,
        ),
      ),
    );

    if (mounted) {
      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  Future<void> _navigateToAddCrew() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCrewScreen(),
      ),
    );

    if (mounted) {
      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  Future<void> _navigateToVoyageIntimation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VoyageIntimationScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      _addVoyageLocally({
        'intimation_id': DateTime.now().millisecondsSinceEpoch,
        'boat_name': 'Loading...',
        'derived_status': 'SUBMITTED',
        'reference_no': '...',
      });
    }

    _loadData(
      refresh: true,
      showLoading: false,
    );
  }

  void _navigateToBoatSelection() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BoatSelectionScreen(),
      ),
    );

    if (mounted) {
      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  Future<void> _handleStartTrip(
      int id,
      String boatName,
      String? referenceNo,
      ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StartTripScreen(
          intimationId: id,
          boatName: boatName,
          referenceNo: referenceNo,
        ),
      ),
    );

    if (result == true && mounted) {
      _updateVoyageStatusLocally(id, 'AT SEA');

      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  Future<void> _handleEndTrip(int id, String boatName) async {
    final intimation = intimations.firstWhere(
          (item) => (item['intimation_id'] ?? item['id']) == id,
      orElse: () => {},
    );

    final int boatId = intimation['boat_id'] ?? 0;

    if (boatId == 0) {
      _showSnackBar(
        'Boat ID not found.',
        backgroundColor: red,
      );

      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EndTripScreen(
          intimationId: id,
          boatName: boatName,
          boatId: boatId,
        ),
      ),
    );

    if (result == true && mounted) {
      _updateVoyageStatusLocally(id, 'COMPLETED');

      _loadData(
        refresh: true,
        showLoading: false,
      );
    }
  }

  // ============================================================
  // LOCATION
  // ============================================================

  Future<void> _showLocationCount() async {
    final prefs = await SharedPreferences.getInstance();

    final voyageId = prefs.getInt('active_voyage_id');

    if (voyageId == null) {
      _showSnackBar(
        'No active voyage.',
        backgroundColor: amber,
      );
      return;
    }

    final locations = await _db.getLocationsForVoyage(voyageId);

    _showSnackBar(
      'Voyage $voyageId: ${locations.length} locations stored.',
      backgroundColor: green,
    );
  }

  Future<void> _resumeTracking() async {
    final prefs = await SharedPreferences.getInstance();

    final voyageId = prefs.getInt('active_voyage_id');

    if (voyageId == null) {
      _showSnackBar(
        'No active voyage found.',
        backgroundColor: amber,
      );
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

    LocationService().startTracking(
      voyageId,
      intervalSeconds: 60,
    );

    _showSnackBar(
      'Tracking resumed.',
      backgroundColor: green,
    );
  }

  // ============================================================
  // OFFLINE MAP
  // ============================================================

  Future<void> _downloadOfflineMap() async {
    _showSnackBar(
      'Starting offline map download...',
      backgroundColor: primary,
    );

    try {
      await OfflineMapService.downloadLakshadweepTiles(
        onProgress: (progress) {
          debugPrint(
            'Offline map: ${(progress * 100).toStringAsFixed(1)}%',
          );
        },
      );

      if (mounted) {
        _showSnackBar(
          'Offline map downloaded successfully.',
          backgroundColor: green,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Map download failed: $e',
          backgroundColor: red,
        );
      }
    }
  }

  // ============================================================
  // FORCE PUSH (SYNC MISSING LOCATIONS)
  // ============================================================

  Future<void> _forcePushMissingLocations() async {
    if (unsyncedLocations == 0) {
      _showSnackBar(
        'All locations are already synced.',
        backgroundColor: green,
      );
      return;
    }

    _showSnackBar(
      'Syncing $unsyncedLocations missing locations...',
      backgroundColor: primary,
    );

    try {
      final session = await _db.getUserSession();

      final token = session?['access_token'];

      if (token == null || token.isEmpty) {
        _showSnackBar(
          'Session expired. Please login again.',
          backgroundColor: red,
        );
        return;
      }

      final unsynced = await _db.getUnsyncedLocations();

      if (unsynced.isEmpty) {
        _showSnackBar(
          'No missing locations found in database.',
          backgroundColor: green,
        );
        return;
      }

      int successCount = 0;
      int failCount = 0;

      for (final loc in unsynced) {
        final voyageId = loc['voyage_id'];

        if (voyageId == null) {
          failCount++;
          continue;
        }

        try {
          final voyageNo = await _db.getVoyageReferenceNo(voyageId);

          final response = await _apiService.sendPing(
            intimationId: voyageId,
            voyageNo: voyageNo,
            latitude: loc['latitude'],
            longitude: loc['longitude'],
            timestamp: loc['timestamp'],
            token: token,
          );

          if (response['success'] == true) {
            await _db.markLocationSynced(loc['id']);
            successCount++;
          } else {
            failCount++;
          }
        } catch (_) {
          failCount++;
        }
      }

      await _updateSyncStatus();

      if (mounted) {
        _showSnackBar(
          'Sync completed. Success: $successCount, Failed: $failCount',
          backgroundColor: failCount == 0 ? green : amber,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Error: $e',
        backgroundColor: red,
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout? Your voyage data will remain on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _db.clearUserSessionOnly();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/depart_login_selection',
        );
      }
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: appBarColor,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: appBarColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: background,
        drawer: _buildDrawer(),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isLoading
                    ? _buildLoading()
                    : RefreshIndicator(
                  color: primary,
                  onRefresh: () => _loadData(refresh: true),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSyncCard(),
                        const SizedBox(height: 8),
                        _buildStats(),
                        const SizedBox(height: 8),
                        _buildVoyageButton(),
                        const SizedBox(height: 8),
                        _buildCrewCard(),
                        if (_isOffline) ...[
                          const SizedBox(height: 8),
                          _buildOfflineBanner(),
                        ],
                        const SizedBox(height: 10),
                        _buildSectionHeader(
                          'Voyages',
                          '${_filteredIntimations.length} records',
                        ),
                        // very small gap before the list starts
                        const SizedBox(height: 6),
                        _buildVoyageList(),
                        if (currentPage < totalPages) ...[
                          const SizedBox(height: 10),
                          _buildLoadMoreButton(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  Widget _buildAppBar() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(12, statusBarHeight + 4, 12, 4),
      decoration: BoxDecoration(
        color: appBarColor,
        boxShadow: [
          BoxShadow(
            color: appBarColor.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return _topButton(
                icon: Icons.menu_rounded,
                onTap: () => Scaffold.of(context).openDrawer(),
                isDark: true,
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'FISHING VOYAGE',
                      style: TextStyle(
                        color: Color(0xFF7DD3FC),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const _PulseDot(color: green),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Dashboard',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          FutureBuilder<int>(
            future: OfflineQueueService.instance.totalPendingCount(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              if (count == 0) {
                return const SizedBox();
              }

              return Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFED7AA),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_upload_rounded,
                      size: 13,
                      color: amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _topButton(
            icon: Icons.refresh_rounded,
            onTap: () => _loadData(refresh: true),
            isDark: true,
          ),
          const SizedBox(width: 6),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BUTTON
  // ============================================================

  Widget _topButton({
    required IconData icon,
    required VoidCallback onTap,
    bool danger = false,
    bool isDark = false,
  }) {
    final Color bgColor;
    final Color iconColor;
    final Color shadowColor;
    final Color highlightColor;

    if (danger) {
      bgColor = const Color(0xFFFFF1F2);
      iconColor = const Color(0xFFE11D48);
      shadowColor = const Color(0xFFE11D48).withOpacity(0.25);
      highlightColor = Colors.white.withOpacity(0.8);
    } else if (isDark) {
      bgColor = Colors.white.withOpacity(0.14);
      iconColor = Colors.white;
      shadowColor = Colors.black.withOpacity(0.3);
      highlightColor = Colors.white.withOpacity(0.25);
    } else {
      bgColor = const Color(0xFFF8FAFC);
      iconColor = textDark;
      shadowColor = Colors.black.withOpacity(0.08);
      highlightColor = Colors.white;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                Colors.white.withOpacity(0.20),
                Colors.white.withOpacity(0.08),
              ]
                  : [
                bgColor,
                bgColor.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.20)
                  : (danger
                  ? const Color(0xFFFECACA)
                  : border),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: highlightColor,
                blurRadius: 2,
                offset: const Offset(-1, -1),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 18,
            color: iconColor,
            shadows: [
              Shadow(
                color: shadowColor,
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SYNC CARD
  // ============================================================

  Widget _buildSyncCard() {
    final pending = unsyncedLocations > 0;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: pending ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  pending ? Icons.sync_problem_rounded : Icons.cloud_done_rounded,
                  color: pending ? red : green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pending
                          ? 'Location Sync Pending'
                          : 'Location Data Synced',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: pending
                            ? const Color(0xFFB91C1C)
                            : const Color(0xFF047857),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pending
                          ? '$unsyncedLocations locations waiting to sync'
                          : 'Tracking data is up to date',
                      style: const TextStyle(
                        fontSize: 10,
                        color: textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _statusPill(
                pending ? 'PENDING' : 'LIVE',
                pending ? red : green,
              ),
            ],
          ),
          if (pending) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: _forcePushMissingLocations,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 15,
                      color: Color(0xFF92400E),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Tap to sync missing locations',
                      style: TextStyle(
                        color: const Color(0xFF92400E).withOpacity(0.9),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'TOTAL',
            _totalVoyageCount,
            primary,
            Icons.directions_boat_rounded,
            'all',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statCard(
            'APPLIED',
            _appliedVoyageCount,
            amber,
            Icons.pending_actions_rounded,
            'applied',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statCard(
            'AT SEA',
            _atSeaVoyageCount,
            cyan,
            Icons.sailing_rounded,
            'at_sea',
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _statCard(
            'DONE',
            _completedVoyageCount,
            green,
            Icons.check_circle_rounded,
            'completed',
          ),
        ),
      ],
    );
  }

  Widget _statCard(
      String title,
      int value,
      Color color,
      IconData icon,
      String key,
      ) {
    final selected = selectedFilter == key;

    return _StatCardWidget(
      title: title,
      value: value,
      color: color,
      icon: icon,
      selected: selected,
      borderColor: border,
      labelColor: textLight,
      onTap: () {
        setState(() {
          selectedFilter = key;
        });
      },
    );
  }

  // ============================================================
  // VOYAGE BUTTON
  // ============================================================

  Widget _buildVoyageButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _navigateToVoyageIntimation,
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          size: 20,
        ),
        label: const Text(
          'CREATE VOYAGE INTIMATION',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: appBarColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CREW
  // ============================================================

  Widget _buildCrewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Crew Members',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${crewMembers.length} members available',
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: _navigateToAddCrew,
            icon: const Icon(
              Icons.add_rounded,
              size: 15,
            ),
            label: const Text(
              'Add Crew',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: const BorderSide(
                color: Color(0xFFBAE6FD),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(String title, String count) {
    return Row(
      children: [
        const Text(
          'Voyages',
          style: TextStyle(
            color: textDark,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2FE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: const TextStyle(
              color: primary,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        if (selectedFilter != 'all')
          GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = 'all';
              });
            },
            child: const Text(
              'Show All',
              style: TextStyle(
                color: primaryLight,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // VOYAGE LIST
  // ============================================================

  Widget _buildVoyageList() {
    final filtered = _filteredIntimations;

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 42),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sailing_rounded,
                color: Color(0xFF94A3B8),
                size: 27,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No voyages found',
              style: TextStyle(
                color: textDark,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Create a voyage intimation to start.',
              style: TextStyle(
                color: textLight,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      );
    }

    // Use a Column instead of ListView.builder to avoid any extra
    // top/bottom padding that ListView adds by default.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: filtered.map((item) => _buildVoyageCard(item)).toList(),
    );
  }

  // ============================================================
  // VOYAGE CARD
  // ============================================================

  Widget _buildVoyageCard(Map<String, dynamic> intimation) {
    final status = intimation['derived_status'] ?? 'APPLIED';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);

    final boatName = intimation['boat_name'] ?? 'N/A';
    final boatReg = intimation['boat_reg_no'] ?? 'N/A';
    final reference = intimation['reference_no'] ?? 'N/A';
    final id = intimation['intimation_id'] ?? intimation['id'];
    final destination = intimation['destination_ports_text'] ?? 'N/A';

    final crewNames = intimation['crew_names'] ?? [];
    final crewCount = intimation['total_crew_count'] ?? 0;
    final fishWeight = intimation['total_fish_weight_kg'] ?? 0.0;
    final sos = intimation['sos_count'] ?? 0;
    final citing = intimation['citing_count'] ?? 0;

    final startDate = intimation['voyage_start_date'] != null
        ? DateTime.tryParse(intimation['voyage_start_date'].toString())
        : null;
    final returnDate = intimation['voyage_return_date'] != null
        ? DateTime.tryParse(intimation['voyage_return_date'].toString())
        : null;

    final btnStatus = intimation['btn_status'];
    final showButton = _shouldShowButton(btnStatus);
    final buttonText = _getButtonText(btnStatus);
    final buttonColor = _getButtonColor(btnStatus);

    final isAtSea = _normalizeStatus(status) == 'AT SEA';
    final isCompleted = _normalizeStatus(status) == 'COMPLETED';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAtSea ? const Color(0xFF67E8F9) : border,
          width: isAtSea ? 1.3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isAtSea
                ? cyan.withOpacity(0.10)
                : Colors.black.withOpacity(0.035),
            blurRadius: isAtSea ? 15 : 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statusPill(
                statusLabel.toUpperCase(),
                statusColor,
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showVoyageDetails(intimation),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.visibility_outlined,
                        size: 14,
                        color: primary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Details',
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE0F2FE),
                      Color(0xFFECFEFF),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_boat_rounded,
                  color: primary,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boatName.toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Registration: $boatReg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAtSea) _smallAlert('SOS', red),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFEAF0F6),
              ),
            ),
            child: Column(
              children: [
                _infoRow(
                  Icons.location_on_rounded,
                  'Destination',
                  destination.toString(),
                ),
                if (startDate != null) ...[
                  const SizedBox(height: 7),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    'Start',
                    DateFormat('dd MMM yyyy').format(startDate),
                  ),
                ],
                if (returnDate != null) ...[
                  const SizedBox(height: 7),
                  _infoRow(
                    Icons.event_available_rounded,
                    'Return',
                    DateFormat('dd MMM yyyy').format(returnDate),
                  ),
                ],
                if (crewNames.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  _infoRow(
                    Icons.groups_rounded,
                    'Crew',
                    crewNames.join(', '),
                    trailing: crewCount > 0 ? '$crewCount' : null,
                  ),
                ],
              ],
            ),
          ),

          if (fishWeight > 0 || citing > 0 || sos > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (fishWeight > 0)
                  _dataChip(
                    Icons.set_meal_rounded,
                    '${double.tryParse(fishWeight.toString())?.toStringAsFixed(1) ?? fishWeight} kg',
                    green,
                  ),
                if (citing > 0)
                  _dataChip(
                    Icons.flag_rounded,
                    '$citing citing',
                    amber,
                  ),
                if (sos > 0)
                  _dataChip(
                    Icons.sos_rounded,
                    '$sos SOS',
                    red,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          _actionButtons(
            intimation,
            id,
            boatName.toString(),
            reference.toString(),
            showButton,
            buttonText,
            buttonColor,
            isAtSea,
            isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String label,
      String value, {
        String? trailing,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 14,
          color: primaryLight,
        ),
        const SizedBox(width: 7),
        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: textLight,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 7,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                color: primary,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }

  Widget _smallAlert(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION BUTTONS
  // ============================================================

  Widget _actionButtons(
      Map<String, dynamic> intimation,
      dynamic id,
      String boatName,
      String reference,
      bool showButton,
      String buttonText,
      Color buttonColor,
      bool isAtSea,
      bool isCompleted,
      ) {
    return Column(
      children: [
        if (showButton)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: buttonText == 'Start Trip'
                      ? () => _handleStartTrip(id, boatName, reference)
                      : () => _handleEndTrip(id, boatName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

        if (isAtSea || isCompleted) ...[
          if (showButton) const SizedBox(height: 8),
          Row(
            children: [
              if (isAtSea)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToSOS(intimation),
                    icon: const Icon(
                      Icons.warning_amber_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'SOS Emergency',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      backgroundColor: const Color(0xFFFFF7F8),
                      side: const BorderSide(
                        color: Color(0xFFFECACA),
                      ),
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              if (isAtSea && isCompleted) const SizedBox(width: 8),
              if (isCompleted)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _navigateToAddCatch(id),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Add Catch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amber,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  // ============================================================
  // DETAILS DIALOG
  // ============================================================

  void _showVoyageDetails(Map<String, dynamic> intimation) {
    final startDate = intimation['voyage_start_date'] != null
        ? DateTime.tryParse(intimation['voyage_start_date'].toString())
        : null;
    final returnDate = intimation['voyage_return_date'] != null
        ? DateTime.tryParse(intimation['voyage_return_date'].toString())
        : null;

    final crewNames = intimation['crew_names'] is List
        ? (intimation['crew_names'] as List).join(', ')
        : '';

    final status = _getStatusLabel(intimation['derived_status']);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 720,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 15, 10, 15),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF07347F),
                        Color(0xFF1257C7),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_boat_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              intimation['boat_name']?.toString() ?? 'Voyage Details',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Voyage Information',
                              style: TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailSection(
                          'Basic Information',
                          [
                            _detailRow(
                              Icons.tag_rounded,
                              'Reference',
                              intimation['reference_no']?.toString() ?? 'N/A',
                            ),
                            _detailRow(
                              Icons.directions_boat_rounded,
                              'Boat Name',
                              intimation['boat_name']?.toString() ?? 'N/A',
                            ),
                            _detailRow(
                              Icons.badge_outlined,
                              'Registration',
                              intimation['boat_reg_no']?.toString() ?? 'N/A',
                            ),
                            _detailRow(
                              Icons.person_outline_rounded,
                              'Owner',
                              intimation['owner_name']?.toString() ?? 'N/A',
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          'Voyage Status',
                          [
                            _detailRow(
                              Icons.flag_rounded,
                              'Status',
                              status,
                              valueColor: _getStatusColor(intimation['derived_status']),
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          'Voyage Details',
                          [
                            _detailRow(
                              Icons.location_on_outlined,
                              'Destinations',
                              intimation['destination_ports_text']?.toString() ?? 'N/A',
                            ),
                            if (startDate != null)
                              _detailRow(
                                Icons.calendar_today_outlined,
                                'Start Date',
                                DateFormat('dd MMM yyyy').format(startDate),
                              ),
                            if (returnDate != null)
                              _detailRow(
                                Icons.event_available_outlined,
                                'Return Date',
                                DateFormat('dd MMM yyyy').format(returnDate),
                                last: true,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          'Crew & Communication',
                          [
                            _detailRow(
                              Icons.groups_outlined,
                              'Crew Count',
                              intimation['total_crew_count']?.toString() ?? '0',
                            ),
                            if (crewNames.isNotEmpty)
                              _detailRow(
                                Icons.people_outline_rounded,
                                'Crew Members',
                                crewNames,
                              ),
                            _detailRow(
                              Icons.devices_other_outlined,
                              'Communication',
                              intimation['communication_devices']?.toString() ?? '0',
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _detailSection(
                          'Activity Summary',
                          [
                            _detailRow(
                              Icons.set_meal_outlined,
                              'Fish Weight',
                              '${intimation['total_fish_weight_kg'] ?? 0} kg',
                            ),
                            _detailRow(
                              Icons.sos_outlined,
                              'SOS Count',
                              intimation['sos_count']?.toString() ?? '0',
                            ),
                            _detailRow(
                              Icons.flag_outlined,
                              'Citing Count',
                              intimation['citing_count']?.toString() ?? '0',
                            ),
                            _detailRow(
                              Icons.lock_outline_rounded,
                              'Is Locked',
                              intimation['is_locked'] == true ? 'Yes' : 'No',
                              last: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(dialogContext);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RouteMapScreen(
                                    voyageId: intimation['intimation_id'] ??
                                        intimation['id'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.map_outlined,
                              size: 17,
                            ),
                            label: const Text(
                              'View Travelled Route',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primary,
                              side: const BorderSide(
                                color: Color(0xFFBAE6FD),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

  Widget _detailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: border,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
      IconData icon,
      String label,
      String value, {
        bool last = false,
        Color? valueColor,
      }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: last
          ? null
          : const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: border,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 16,
              color: primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: textLight,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  softWrap: true,
                  style: TextStyle(
                    color: valueColor ?? textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Widget _buildLoadMoreButton() {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: OutlinedButton(
        onPressed: () {
          currentPage++;

          _loadData(refresh: false);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(
            color: Color(0xFFBAE6FD),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Load More Voyages',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OFFLINE
  // ============================================================

  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFFFED7AA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: Color(0xFFC2410C),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Working Offline',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Data will automatically sync when connection is restored.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 9.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DRAWER  (fixed white strip at top of status bar)
  // ============================================================

  Widget _buildDrawer() {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // ---- Header (paints behind status bar too) ----
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              statusBarHeight + 16,
              18,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07347F),
                  Color(0xFF1257C7),
                  Color(0xFF0EA5E9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF07347F),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ownerName ?? 'Boat Owner',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (ownerMobile != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              ownerMobile!,
                              style: const TextStyle(
                                color: Color(0xFFBAE6FD),
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    children: [
                      if (ownerAddress != null)
                        _drawerProfileRow(
                          Icons.location_on_rounded,
                          ownerAddress!,
                        ),
                      if (ownerHomePort != null) ...[
                        const SizedBox(height: 7),
                        _drawerProfileRow(
                          Icons.directions_boat_rounded,
                          'Home Port: $ownerHomePort',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ---- Menu Items ----
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              children: [
                _drawerLabel('BOAT MANAGEMENT'),
                _drawerItem(
                  icon: Icons.directions_boat_rounded,
                  title: 'My Boats',
                  subtitle: 'Manage registered boats',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToBoatSelection();
                  },
                ),
                _drawerItem(
                  icon: Icons.groups_rounded,
                  title: 'Crew Members',
                  subtitle: 'Manage crew details',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToAddCrew();
                  },
                ),
                const SizedBox(height: 6),
                _drawerLabel('OFFLINE & TRACKING'),
                _drawerItem(
                  icon: Icons.download_for_offline_rounded,
                  title: 'Offline Map',
                  subtitle: 'Download map for offline use',
                  onTap: () {
                    Navigator.pop(context);
                    _downloadOfflineMap();
                  },
                ),
                if (activeVoyageId != null)
                  _drawerItem(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Resume Tracking',
                    subtitle: 'Continue location tracking',
                    iconColor: green,
                    onTap: () {
                      Navigator.pop(context);
                      _resumeTracking();
                    },
                  ),
                const SizedBox(height: 6),
                _drawerLabel('TOOLS'),
                _drawerItem(
                  icon: Icons.location_searching_rounded,
                  title: 'Location Statistics',
                  subtitle: 'View stored location points',
                  iconColor: amber,
                  onTap: () {
                    Navigator.pop(context);
                    _showLocationCount();
                  },
                ),
                const SizedBox(height: 6),
                _drawerLabel('ACCOUNT'),
                _drawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out of this account',
                  iconColor: red,
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),

          // ---- Footer ----
          Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: border,
                ),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.directions_boat_rounded,
                  size: 14,
                  color: primaryLight,
                ),
                SizedBox(width: 5),
                Text(
                  'Fishing Voyage Management',
                  style: TextStyle(
                    color: textLight,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: textLight,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _drawerProfileRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFBAE6FD),
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading dashboard...',
            style: TextStyle(
              color: textLight,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD DECORATION
  // ============================================================

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: border,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.025),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

// ================================================================
// STAT CARD WIDGET
// ================================================================

class _StatCardWidget extends StatefulWidget {
  final String title;
  final int value;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  final Color borderColor;
  final Color labelColor;

  const _StatCardWidget({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.borderColor,
    required this.labelColor,
  });

  @override
  State<_StatCardWidget> createState() => _StatCardWidgetState();
}

class _StatCardWidgetState extends State<_StatCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
    });
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _pressed = false;
    });
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    setState(() {
      _pressed = false;
    });
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final color = widget.color;

    final Color bgColor;
    if (_pressed) {
      bgColor = color.withOpacity(0.12);
    } else if (selected) {
      bgColor = color.withOpacity(0.08);
    } else {
      bgColor = Colors.white;
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnim.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 100,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected ? color : widget.borderColor,
                  width: selected ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(selected ? 0.12 : 0.03),
                    blurRadius: selected ? 12 : 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? color.withOpacity(0.18)
                          : color.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.icon,
                      color: color,
                      size: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.value}',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: widget.labelColor,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================================================================
// PULSE DOT
// ================================================================

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({
    this.color = const Color(0xFF10B981),
  });

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1200,
      ),
    )..repeat(
      reverse: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 0.35,
        end: 1,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}