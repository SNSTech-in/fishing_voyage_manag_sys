import 'package:flutter/material.dart';
import '../../services/api_services/officer_api_service.dart';
import '../ui/officer_dashboard_ui.dart';
import '../ui/fisheries_officer_ocean_ui.dart';

class OfficerDashboard extends StatefulWidget {
  @override
  _OfficerDashboardState createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> with WidgetsBindingObserver {
  final OfficerApiService _api = OfficerApiService();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAbsoluteData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAbsoluteData(silent: true);
    }
  }

  Future<void> _loadAbsoluteData({bool silent = false}) async {
    if (!silent) setState(() { _loading = true; _error = null; });
    try {
      final response = await _api.fetchDashboardStats();
      
      if (response['success'] == true) {
        var data = response['data'];
        var counts = data['counts'] ?? {};
        var alerts = data['alerts'] ?? {};

        if (!mounted) return;
        setState(() {
          _data = {
            'open_sos': alerts['open_sos'] ?? 0,
            'crew_not_returned': alerts['crew_not_returned'] ?? 0,
            'overdue_voyages': counts['overdue'] ?? 0,
            'citings_pending': alerts['citings_pending_review'] ?? 0,
            'licences_expiring': alerts['licences_expiring_30d'] ?? 0,
            'intimation_status': {
              'total': counts['total_intimations'] ?? 0,
              'upcoming': counts['upcoming'] ?? 0,
              'ongoing': counts['ongoing'] ?? 0,
              'overdue': counts['overdue'] ?? 0,
              'completed': counts['completed'] ?? 0,
              'cancelled': counts['cancelled'] ?? 0,
            },
            'top_ports': data['top_ports'] ?? [],
            'top_species': data['catch_summary']?['top_species'] ?? [],
          };
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() { _error = "Server Error: ${response['message']}"; _loading = false; });
      }
    } catch (e) {
      if (mounted) setState(() { _error = "Fatal Error: $e"; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FisheriesOfficerOceanRefresh(
      onRefresh: () => _loadAbsoluteData(silent: true),
      child: OfficerDashboardUI(data: _data, loading: _loading, error: _error, onRetry: _loadAbsoluteData),
    );
  }
}
