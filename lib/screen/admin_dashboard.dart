import 'package:fishing_voyage_manag_sys/screen/selection_screen.dart';
import 'package:flutter/material.dart';
import 'add_officer_screen.dart';
import 'ports_management_screen.dart';
import '../../database/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DatabaseHelper _dbHelper;

  List<Map<String, dynamic>> _officers = [];
  List<Map<String, dynamic>> _boatOwners = [];
  List<Map<String, dynamic>> _customPorts = [];
  List<Map<String, dynamic>> _filteredOwners = [];
  bool _isLoading = true;

  // Filter variables
  String _selectedPortFilter = 'All Ports';
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  List<String> _portsList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dbHelper = DatabaseHelper();
    _loadData();
    _initializeFilters();
  }

  Future<void> _loadData() async {
    try {
      final officers = await _dbHelper.getAllOfficers();
      final boatOwners = await _dbHelper.getAllBoatOwners();
      final customPorts = await _dbHelper.getAllCustomPorts();

      setState(() {
        _officers = officers;
        _boatOwners = boatOwners;
        _customPorts = customPorts;
        _filteredOwners = _boatOwners;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadData();
    _applyFilters();
  }

  void _initializeFilters() async {
    final ports = await _dbHelper.getAllPorts();
    setState(() {
      _portsList = ['All Ports', ...ports];
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_boatOwners);

    // Apply port filter
    if (_selectedPortFilter != 'All Ports') {
      filtered = filtered.where((owner) {
        final homePort = owner['home_port']?.toString() ?? '';
        return homePort.toLowerCase() == _selectedPortFilter.toLowerCase();
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((owner) {
        final name = owner['owner_name']?.toString() ?? '';
        final mobile = owner['mobile_number']?.toString() ?? '';
        final regNumber = owner['registration_number']?.toString() ?? '';
        final aadhar = owner['aadhar_number']?.toString() ?? '';

        return name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            mobile.contains(_searchQuery) ||
            regNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            aadhar.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredOwners = filtered;
    });
  }

  Future<void> _generateOwnerReport(Map<String, dynamic> owner) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAKSHADWEEP FISHERMAN REGISTRATION REPORT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Port: ${owner['home_port'] ?? 'Not specified'}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Personal Details Section
              pw.Text(
                'Personal Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow('Owner Name:', owner['owner_name'] ?? 'Not specified'),
              _buildPdfRow('Mobile Number:', owner['mobile_number'] ?? 'Not specified'),
              _buildPdfRow('Email:', owner['official_email'] ?? owner['email'] ?? 'Not specified'),
              _buildPdfRow('Address:', owner['address'] ?? 'Not specified'),
              _buildPdfRow('Home Port:', owner['home_port'] ?? 'Not specified'),

              pw.SizedBox(height: 15),

              // Registration Details Section
              pw.Text(
                'Registration Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow('Registration Number:', owner['registration_number'] ?? 'Not specified'),
              _buildPdfRow('Aadhar Number:', owner['aadhar_number'] ?? 'Not specified'),
              _buildPdfRow('Registration Date:', owner['registration_date']?.toString().substring(0, 10) ?? 'Not specified'),
              _buildPdfRow('Number of Boats:', owner['number_of_boats']?.toString() ?? '1'),
              _buildPdfRow('Boat Name:', owner['boat_name'] ?? 'Not specified'),

              // Boats Information if available
              if (owner['boats'] != null && owner['boats'] is List)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 15),
                    pw.Text(
                      'Registered Boats',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    for (var boat in owner['boats'])
                      pw.Container(
                        margin: const pw.EdgeInsets.only(left: 20, bottom: 10),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            _buildPdfRow('• Boat Name:', boat['name'] ?? 'Not specified'),
                            _buildPdfRow('  Type:', boat['type'] ?? 'Not specified'),
                            _buildPdfRow('  Tonnage:', '${boat['tonnage']} tons'),
                          ],
                        ),
                      ),
                  ],
                ),

              // Additional Information
              pw.SizedBox(height: 15),
              pw.Text(
                'Additional Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow('Fishing Experience:', owner['fishing_experience'] ?? 'Not specified'),
              _buildPdfRow('License Type:', owner['license_type'] ?? 'Not specified'),
              _buildPdfRow('Valid Until:', owner['valid_until'] ?? 'Not specified'),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Report generated on: ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Lakshadweep Fisheries Department',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _generateBulkReport() async {
    if (_filteredOwners.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No owners to generate report for'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAKSHADWEEP FISHERMAN REGISTRATION REPORT - BULK',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Filter: ${_selectedPortFilter} | Total Owners: ${_filteredOwners.length}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Summary Statistics
              pw.Text(
                'Summary Statistics',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildPdfRow('Total Owners:', _filteredOwners.length.toString()),
              _buildPdfRow('Filter Applied:', _selectedPortFilter),
              _buildPdfRow('Search Query:', _searchQuery.isNotEmpty ? _searchQuery : 'None'),

              // Port Distribution
              pw.SizedBox(height: 15),
              pw.Text(
                'Port Distribution',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              for (var port in _getPortDistribution())
                _buildPdfRow('• $port:', _getOwnerCountByPort(port).toString()),

              pw.SizedBox(height: 15),
              pw.Text(
                'Owner List',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Owner List Table
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['No.', 'Name', 'Mobile', 'Port', 'Boats', 'Reg No.'],
                  ..._filteredOwners.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final owner = entry.value;
                    return [
                      index.toString(),
                      owner['owner_name'] ?? 'N/A',
                      owner['mobile_number'] ?? 'N/A',
                      owner['home_port'] ?? 'N/A',
                      owner['number_of_boats']?.toString() ?? '1',
                      owner['registration_number']?.substring(0, 8) ?? 'N/A',
                    ];
                  }).toList(),
                ],
                cellStyle: pw.TextStyle(fontSize: 9),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                ),
                border: pw.TableBorder.all(width: 0.5),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Report generated on: ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Lakshadweep Fisheries Department - Administrative Report',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  List<String> _getPortDistribution() {
    Set<String> ports = {};
    for (var owner in _filteredOwners) {
      final port = owner['home_port']?.toString();
      if (port != null && port.isNotEmpty) {
        ports.add(port);
      }
    }
    return ports.toList()..sort();
  }

  int _getOwnerCountByPort(String port) {
    return _filteredOwners.where((owner) => owner['home_port']?.toString() == port).length;
  }

  void _viewOwnerDetails(Map<String, dynamic> owner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(owner['owner_name'] ?? 'Unknown Owner'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Mobile:', owner['mobile_number'] ?? 'Not specified'),
              _buildDetailRow('Email:', owner['official_email'] ?? owner['email'] ?? 'Not specified'),
              _buildDetailRow('Address:', owner['address'] ?? 'Not specified'),
              _buildDetailRow('Home Port:', owner['home_port'] ?? 'Not specified'),
              _buildDetailRow('Registration No:', owner['registration_number'] ?? 'Not specified'),
              _buildDetailRow('Aadhar No:', owner['aadhar_number'] ?? 'Not specified'),
              _buildDetailRow('Boat Name:', owner['boat_name'] ?? 'Not specified'),
              _buildDetailRow('Boats Count:', owner['number_of_boats']?.toString() ?? '1'),
              _buildDetailRow('Registration Date:',
                  owner['registration_date']?.toString().substring(0, 10) ?? 'Not specified'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateOwnerReport(owner);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOwner(Map<String, dynamic> owner) async {
    String name = owner['owner_name'] ?? 'Unknown Owner';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Owner'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteBoatOwner(owner['id']);
                setState(() {
                  _boatOwners.removeWhere((o) => o['id'] == owner['id']);
                  _applyFilters();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Owner "$name" deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAndClearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout & Clear All Data'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 60,
              color: Colors.orange,
            ),
            SizedBox(height: 16),
            Text(
              'This will clear ALL data including:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• All boat owners'),
            Text('• All voyages'),
            Text('• All officers'),
            Text('• All custom ports'),
            SizedBox(height: 16),
            Text(
              'This action cannot be undone!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout & Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              const Text('Clearing all data...'),
              FutureBuilder(
                future: _clearAllDatabaseData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted) {
                        Navigator.pop(context);
                        _navigateToLogin();
                      }
                    });
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _clearAllDatabaseData() async {
    try {
      await _dbHelper.clearAllData();
      print('All database data cleared successfully');
    } catch (e) {
      print('Error clearing database: $e');
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectionScreen(),
      ),
          (route) => false,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D47A1)),
          ),
          const SizedBox(height: 20),
          Text(
            'Loading data...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficersTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Port Officers\n Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage authorized port officers',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.people,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics Card
            _buildOfficerStatistics(),

            const SizedBox(height: 20),

            // Add Officer Button
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddOfficerScreen(),
                    ),
                  );

                  if (result == true) {
                    await _refreshData();
                  }
                },
                icon: const Icon(Icons.person_add, size: 24),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    'ADD NEW OFFICER',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Officers List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Officers (${_officers.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Chip(
                  label: Text('${_officers.length}'),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: const TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Officers List
            if (_officers.isEmpty)
              _buildEmptyOfficersState()
            else
              ..._officers.map((officer) {
                return _buildOfficerCard(officer);
              }),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildPortsTab() {
    return const PortsManagementScreen();
  }

  Widget _buildOwnersTab() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.search, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _applyFilters();
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search by name, mobile, or registration number...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _applyFilters();
                            });
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedPortFilter,
                          isExpanded: true,
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down),
                          items: _portsList.map((port) {
                            return DropdownMenuItem(
                              value: port,
                              child: Text(
                                port,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPortFilter = value!;
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _generateBulkReport,
                      icon: const Icon(Icons.picture_as_pdf, size: 20),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Text(
                      '${_filteredOwners.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    Text(
                      'Filtered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_boatOwners.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      '${_countTotalBoats()}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Total Boats',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Owners List
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_filteredOwners.isEmpty)
                    _buildEmptyOwnersState()
                  else
                    ..._filteredOwners.map((owner) {
                      return _buildOwnerCard(owner);
                    }),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerStatistics() {
    int activeCount = _officers.where((officer) => officer['status'] == 'active').length;
    int adminCount = _officers.where((officer) => officer['role'] == 'admin').length;
    int portOfficerCount = _officers.where((officer) => officer['role'] == 'port_officer').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatChip(
            count: _officers.length,
            label: 'Total',
            icon: Icons.people,
            color: Colors.blue,
          ),
          _buildStatChip(
            count: activeCount,
            label: 'Active',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          _buildStatChip(
            count: adminCount,
            label: 'Admins',
            icon: Icons.admin_panel_settings,
            color: Colors.purple,
          ),
          _buildStatChip(
            count: portOfficerCount,
            label: 'Port Officers',
            icon: Icons.anchor,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required int count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  int _countTotalBoats() {
    int total = 0;
    for (var owner in _filteredOwners) {
      total += int.tryParse(owner['number_of_boats']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  Widget _buildOwnerCard(Map<String, dynamic> owner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 24,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner['owner_name'] ?? 'Unknown Owner',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      owner['mobile_number'] ?? 'No phone',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Generate PDF'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) async {
                  switch (value) {
                    case 'view':
                      _viewOwnerDetails(owner);
                      break;
                    case 'pdf':
                      await _generateOwnerReport(owner);
                      break;
                    case 'delete':
                      _deleteOwner(owner);
                      break;
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOwnerDetailRow(
                      icon: Icons.email,
                      text: owner['official_email'] ?? owner['email'] ?? 'No email',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 6),
                    _buildOwnerDetailRow(
                      icon: Icons.location_on,
                      text: owner['home_port'] ?? 'No home port',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      '${owner['number_of_boats'] ?? 1} Boat${(owner['number_of_boats'] ?? 1) > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    owner['registration_date']?.toString().substring(0, 10) ?? 'No date',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  owner['registration_number']?.toString().substring(0, 12) ?? 'No Reg',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  'Aadhar: ${owner['aadhar_number']?.toString().substring(0, 8) ?? 'N/A'}...',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOwnersState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.directions_boat_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No boat owners found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _searchQuery.isNotEmpty || _selectedPortFilter != 'All Ports'
                ? 'Try changing your search or filter criteria'
                : 'Boat owners will appear here once registered',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOfficersState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people_outline,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No officers added yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add your first port officer to start',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(Map<String, dynamic> officer) {
    String name = officer['name'] ?? officer['officer_name'] ?? 'Unknown Officer';
    String email = officer['email'] ?? officer['official_email'] ?? 'No email';
    String port = officer['assigned_port'] ?? 'No port assigned';
    String status = officer['status'] ?? 'active';
    String role = officer['role'] ?? 'port_officer';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPortColor(port).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              role == 'admin' ? Icons.admin_panel_settings : Icons.anchor,
              size: 24,
              color: _getPortColor(port),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'active'
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: status == 'active'
                              ? Colors.green.shade200
                              : Colors.red.shade200,
                        ),
                      ),
                      child: Text(
                        status == 'active' ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status == 'active' ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: role == 'admin'
                            ? Colors.purple.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: role == 'admin'
                              ? Colors.purple.shade200
                              : Colors.blue.shade200,
                        ),
                      ),
                      child: Text(
                        role == 'admin' ? 'Admin' : 'Port Officer',
                        style: TextStyle(
                          fontSize: 11,
                          color: role == 'admin' ? Colors.purple : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        port,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'view',
                child: Row(
                  children: [
                    Icon(Icons.visibility, size: 18),
                    SizedBox(width: 8),
                    Text('View Details'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _viewOfficerDetails(officer);
                  break;
                case 'edit':
                  _editOfficer(officer);
                  break;
                case 'delete':
                  _deleteOfficer(officer);
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getPortColor(String port) {
    final colors = [
      Colors.blue.shade600,
      Colors.green.shade600,
      Colors.orange.shade600,
      Colors.purple.shade600,
      Colors.red.shade600,
      Colors.teal.shade600,
    ];
    final index = port.hashCode.abs() % colors.length;
    return colors[index];
  }

  void _viewOfficerDetails(Map<String, dynamic> officer) {
    String name = officer['name'] ?? officer['officer_name'] ?? 'Unknown';
    String email = officer['email'] ?? officer['official_email'] ?? 'No email';
    String mobile = officer['mobile'] ?? officer['mobile_number'] ?? 'No mobile';
    String port = officer['assigned_port'] ?? 'No port assigned';
    String role = officer['role'] ?? 'port_officer';
    String status = officer['status'] ?? 'active';
    String address = officer['address'] ?? 'No address';
    String createdAt = officer['created_at']?.toString().substring(0, 10) ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOwnerDetailRow(
                icon: Icons.email,
                text: email,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: Icons.phone,
                text: mobile,
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: Icons.location_on,
                text: address,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: Icons.anchor,
                text: port,
                color: Colors.purple,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: role == 'admin' ? Icons.admin_panel_settings : Icons.security,
                text: role == 'admin' ? 'Administrator' : 'Port Officer',
                color: role == 'admin' ? Colors.purple : Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: Icons.calendar_today,
                text: 'Created: $createdAt',
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              _buildOwnerDetailRow(
                icon: status == 'active' ? Icons.check_circle : Icons.cancel,
                text: status == 'active' ? 'Active' : 'Inactive',
                color: status == 'active' ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _editOfficer(Map<String, dynamic> officer) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit functionality coming soon'),
      ),
    );
  }

  Future<void> _deleteOfficer(Map<String, dynamic> officer) async {
    String name = officer['name'] ?? officer['officer_name'] ?? 'Unknown Officer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Officer'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteOfficer(officer['id']);
                setState(() {
                  _officers.removeWhere((o) => o['id'] == officer['id']);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Officer "$name" deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    _logoutAndClearData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout & Clear All',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Officers'),
            Tab(text: 'Ports'),
            Tab(text: 'Owners'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOfficersTab(),
          _buildPortsTab(),
          _buildOwnersTab(),
        ],
      ),
    );
  }
}