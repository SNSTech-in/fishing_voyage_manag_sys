import 'package:flutter/material.dart';

import '../../../services/api_services/officer_api_service.dart';

class PortsMastersScreen extends StatefulWidget {
  const PortsMastersScreen({super.key});

  @override
  State<PortsMastersScreen> createState() => _PortsMastersScreenState();
}

class _PortsMastersScreenState extends State<PortsMastersScreen> {
  final OfficersApiService _api = OfficersApiService();
  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });

    final res = await _api.fetchPorts(search: _searchCtrl.text.trim());

    if (!mounted) return;
    if (res['success'] == true) {
      setState(() {
        _items = OfficersApiService.extractList(res);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['message']?.toString() ?? 'Failed to load ports';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Search ports...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_items.isEmpty) return const Center(child: Text('No ports found.'));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = _items[i];
          final name = p['port_name'] ?? p['name'] ?? '—';
          final state = p['state'] ?? '';
          final active = p['active'] ?? p['is_active'];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.anchor)),
            title: Text('$name'),
            subtitle: state.toString().isEmpty ? null : Text('$state'),
            trailing: active == false
                ? const Chip(label: Text('Inactive'))
                : null,
          );
        },
      ),
    );
  }
}