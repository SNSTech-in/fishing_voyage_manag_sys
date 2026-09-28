import 'package:flutter/material.dart';

import '../../../../services/api_services/officer_api_service.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final OfficersApiService _api = OfficersApiService();

  static const Color _primary = Color(0xFF1257C7);
  static const Color _primaryDark = Color(0xFF07347F);
  static const Color _bg = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textLight = Color(0xFF94A3B8);
  static const Color _divider = Color(0xFFE2E8F0);

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  int _page = 1;
  final int _limit = 20;
  int _total = 0;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) _page = 1;
    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await _api.fetchAuditLog(page: _page, limit: _limit);

    if (!mounted) return;

    if (res['success'] == true) {
      final list = OfficersApiService.extractList(res);
      final data = res['data'];
      int total = 0;
      int totalPages = 1;
      if (data is Map) {
        total = (data['total'] as num?)?.toInt() ?? list.length;
        totalPages = (data['total_pages'] as num?)?.toInt() ?? 1;
      }
      setState(() {
        _items = list;
        _total = total;
        _totalPages = totalPages;
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load audit log';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Audit Log',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _load(reset: true),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _load(reset: true),
              color: _primary,
              child: _body(),
            ),
          ),
          if (_total > 0) _pager(),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Center(child: Text(_error!, textAlign: TextAlign.center)),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: () => _load(reset: true),
              child: const Text('Retry'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return const Center(
        child: Text('No audit records found.',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _auditTile(_items[i]),
    );
  }

  Color _actionColor(String action) {
    switch (action.toUpperCase()) {
      case 'INSERT':
      case 'CREATE':
        return const Color(0xFF059669);
      case 'UPDATE':
        return const Color(0xFF0891B2);
      case 'DELETE':
        return const Color(0xFFDC2626);
      case 'LOGIN':
        return const Color(0xFF7C3AED);
      case 'LOGOUT':
        return const Color(0xFF64748B);
      case 'STATUS_CHANGE':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  IconData _actionIcon(String action) {
    switch (action.toUpperCase()) {
      case 'INSERT':
      case 'CREATE':
        return Icons.add_circle_rounded;
      case 'UPDATE':
        return Icons.edit_rounded;
      case 'DELETE':
        return Icons.delete_rounded;
      case 'LOGIN':
        return Icons.login_rounded;
      case 'LOGOUT':
        return Icons.logout_rounded;
      case 'STATUS_CHANGE':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.history_rounded;
    }
  }

  Widget _auditTile(Map<String, dynamic> a) {
    final action = a['action_type']?.toString() ?? 'UNKNOWN';
    final table = a['table_name']?.toString() ?? '';
    final ref = a['reference_no']?.toString();
    final byName = a['performed_by_name']?.toString() ?? '—';
    final byType = a['performed_by_type']?.toString() ?? '';
    final date = a['created_date']?.toString() ?? '';
    final changed = a['changed_columns']?.toString() ?? '';

    final color = _actionColor(action);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_actionIcon(action), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            action,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            table,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (ref != null && ref.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        ref,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _primaryDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: _divider),
          const SizedBox(height: 8),
          _rowInfo(
            Icons.person_outline_rounded,
            'By',
            byType.isEmpty ? byName : '$byName ($byType)',
          ),
          if (changed.isNotEmpty)
            _rowInfo(Icons.tune_rounded, 'Changed', changed),
          _rowInfo(Icons.schedule_rounded, 'When', date),
        ],
      ),
    );
  }

  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: _textLight),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _textLight,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pager() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Page $_page / $_totalPages  •  Total $_total',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _page > 1
                    ? () {
                  _page--;
                  _load();
                }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                onPressed: _page < _totalPages
                    ? () {
                  _page++;
                  _load();
                }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}