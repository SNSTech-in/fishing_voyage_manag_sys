import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Hardcoded Lakshadweep islands
  final List<String> _homePorts = [
    'Agati',
    'Kavarati',
    'Androdh',
    'Kalpeni',
    'Kadmat',
    'Amini',
    'Chetlat',
    'Bitra'
  ];

  // Hardcoded reports data for Lakshadweep fishing management
  final List<Map<String, dynamic>> _reports = [
    {
      'id': '1',
      'type': 'fishing_voyage',
      'title': 'Fishing Voyage Report - Agati Island',
      'description': 'Traditional fishing expedition - Tuna catch',
      'date': '2024-01-15',
      'status': 'completed',
      'vesselName': 'MF Agati-101',
      'voyageNumber': 'FV2024-AG001',
      'captainName': 'Captain Ahmed Ali',
      'departurePort': 'Agati',
      'arrivalPort': 'Agati',
      'departureDate': '2024-01-14',
      'estimatedArrival': '2024-01-15',
      'actualArrival': '2024-01-15',
      'catchType': 'Tuna',
      'catchWeight': '850',
      'fuelConsumed': '120',
      'distance': '25',
      'duration': '1 day',
      'crewCount': '8',
      'fishingMethod': 'Traditional Line Fishing',
      'weatherConditions': 'Clear, Sea: Calm',
      'fishingZone': 'Zone A - Coastal Waters',
      'fishermenCount': '5',
      'gearUsed': 'Hand Lines',
      'licenseNumber': 'LAK-FH-2024-AG101',
      'island': 'Agati',
    },
    {
      'id': '2',
      'type': 'registration',
      'title': 'Fisherman Registration - Kavarati Island',
      'description': 'New fisherman registration with 2 boats',
      'date': '2024-01-14',
      'status': 'verified',
      'ownerName': 'Ismail Koya',
      'email': 'ismail.koya@example.com',
      'mobileNumber': '+91 9447123456',
      'address': 'Kavarati Island, Lakshadweep',
      'homePort': 'Kavarati',
      'numberOfBoats': '2',
      'registrationDate': '2024-01-10',
      'validUntil': '2025-01-09',
      'licenseType': 'Traditional Fisherman',
      'fishingExperience': '15 years',
      'boats': [
        {'name': 'MF Kavarati-205', 'type': 'Traditional', 'tonnage': '3'},
        {'name': 'MF Kavarati-206', 'type': 'Motorized', 'tonnage': '5'},
      ],
      'familyMembers': '4',
      'incomeSource': 'Fishing',
      'island': 'Kavarati',
    },
    {
      'id': '3',
      'type': 'catch_report',
      'title': 'Daily Catch Report - Androdh Island',
      'description': 'Mixed fish catch including Mackerel and Sardines',
      'date': '2024-01-13',
      'status': 'submitted',
      'vesselName': 'MF Androdh-305',
      'captainName': 'Captain Rahim Basha',
      'port': 'Androdh',
      'reportDate': '2024-01-13',
      'totalCatch': '650',
      'catchBreakdown': {
        'Mackerel': '300',
        'Sardines': '200',
        'Prawns': '100',
        'Other': '50'
      },
      'fishingHours': '8',
      'marketValue': '₹32,500',
      'fishermenCount': '6',
      'weather': 'Partly Cloudy',
      'seaConditions': 'Moderate',
      'island': 'Androdh',
    },
    {
      'id': '4',
      'type': 'equipment',
      'title': 'Fishing Gear Distribution - Kalpeni Island',
      'description': 'Distribution of new fishing nets and equipment',
      'date': '2024-01-12',
      'status': 'completed',
      'island': 'Kalpeni',
      'distributionDate': '2024-01-10',
      'itemsDistributed': [
        {'item': 'Fishing Nets', 'quantity': '50', 'recipients': '25 fishermen'},
        {'item': 'Life Jackets', 'quantity': '100', 'recipients': '50 fishermen'},
        {'item': 'GPS Devices', 'quantity': '10', 'recipients': '10 boat owners'},
      ],
      'totalValue': '₹1,50,000',
      'fundingSource': 'Government Scheme',
      'coordinator': 'Fisheries Department Officer',
    },
    {
      'id': '5',
      'type': 'training',
      'title': 'Sustainable Fishing Training - Kadmat Island',
      'description': 'Training program on sustainable fishing practices',
      'date': '2024-01-11',
      'status': 'completed',
      'island': 'Kadmat',
      'trainingDate': '2024-01-08',
      'trainer': 'Marine Biologist - Dr. Sarah Khan',
      'participantsCount': '35',
      'topics': [
        'Sustainable Fishing Methods',
        'Marine Conservation',
        'First Aid at Sea',
        'Weather Monitoring'
      ],
      'duration': '2 days',
      'venue': 'Kadmat Community Hall',
      'sponsor': 'Ministry of Fisheries',
    },
    {
      'id': '6',
      'type': 'inspection',
      'title': 'Boat Safety Inspection - Amini Island',
      'description': 'Quarterly safety inspection of fishing vessels',
      'date': '2024-01-10',
      'status': 'completed',
      'island': 'Amini',
      'inspectionDate': '2024-01-08',
      'inspector': 'Port Officer - Mr. Rajesh Kumar',
      'boatsInspected': '28',
      'boatsPassed': '25',
      'boatsFailed': '3',
      'commonIssues': [
        'Fire extinguishers expired',
        'Life jackets missing',
        'Navigation lights faulty'
      ],
      'actionTaken': 'Repair notices issued',
      'nextInspection': '2024-04-08',
    },
    {
      'id': '7',
      'type': 'weather_alert',
      'title': 'Weather Warning Report - Chetlat Island',
      'description': 'Cyclone alert and fishing restrictions',
      'date': '2024-01-09',
      'status': 'active',
      'island': 'Chetlat',
      'alertDate': '2024-01-08',
      'alertType': 'Cyclone Warning',
      'severity': 'High',
      'affectedZones': ['Zone B', 'Zone C', 'Zone D'],
      'restrictions': 'No fishing operations for 48 hours',
      'issuedBy': 'Indian Meteorological Department',
      'validUntil': '2024-01-10',
      'advice': 'All vessels to return to port immediately',
    },
    {
      'id': '8',
      'type': 'market',
      'title': 'Fish Market Daily Report - Bitra Island',
      'description': 'Daily fish auction and market prices',
      'date': '2024-01-08',
      'status': 'completed',
      'island': 'Bitra',
      'marketDate': '2024-01-08',
      'totalArrivals': '1,200 kg',
      'totalValue': '₹60,000',
      'priceTrend': 'Stable',
      'topSpecies': [
        {'name': 'Tuna', 'price': '₹80/kg'},
        {'name': 'Mackerel', 'price': '₹60/kg'},
        {'name': 'Sardines', 'price': '₹40/kg'},
        {'name': 'Prawns', 'price': '₹200/kg'},
      ],
      'buyersCount': '15',
      'exportQuantity': '300 kg',
      'localConsumption': '900 kg',
    },
    {
      'id': '9',
      'type': 'fishing_voyage',
      'title': 'Night Fishing Voyage - Kavarati Island',
      'description': 'Squid fishing expedition',
      'date': '2024-01-07',
      'status': 'completed',
      'vesselName': 'MF Kavarati-108',
      'voyageNumber': 'FV2024-KV002',
      'captainName': 'Captain Salim Mohammed',
      'departurePort': 'Kavarati',
      'arrivalPort': 'Kavarati',
      'departureDate': '2024-01-06',
      'estimatedArrival': '2024-01-07',
      'actualArrival': '2024-01-07',
      'catchType': 'Squid',
      'catchWeight': '450',
      'fuelConsumed': '90',
      'distance': '18',
      'duration': '1 night',
      'crewCount': '7',
      'fishingMethod': 'Jigging',
      'weatherConditions': 'Clear, Moonlit Night',
      'fishingZone': 'Zone C - Near Reef',
      'island': 'Kavarati',
    },
    {
      'id': '10',
      'type': 'conservation',
      'title': 'Coral Reef Protection - Agati Island',
      'description': 'Monthly coral reef monitoring report',
      'date': '2024-01-06',
      'status': 'submitted',
      'island': 'Agati',
      'monitoringDate': '2024-01-05',
      'monitoredBy': 'Marine Conservation Team',
      'reefHealth': 'Good',
      'coralCover': '65%',
      'fishDiversity': 'High',
      'threatsObserved': 'None',
      'recommendations': 'Continue current conservation measures',
      'nextMonitoring': '2024-02-05',
    },
  ];

  List<Map<String, dynamic>> _filteredReports = [];
  String _selectedIsland = 'All Islands';
  String _selectedReportType = 'All Types';

  @override
  void initState() {
    super.initState();
    _filteredReports = _reports;
  }

  void _filterReports() {
    setState(() {
      _filteredReports = _reports.where((report) {
        bool islandMatch = _selectedIsland == 'All Islands' ||
            (report['island'] != null && report['island'] == _selectedIsland);
        bool typeMatch = _selectedReportType == 'All Types' ||
            (report['type'] != null && report['type'] == _selectedReportType);
        return islandMatch && typeMatch;
      }).toList();
    });
  }

  Future<void> _generateFishingVoyageReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAKSHADWEEP FISHING VOYAGE REPORT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Island: ${report['island']}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Voyage Details
              pw.Text(
                'Voyage Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Vessel Name:', report['vesselName'] ?? 'N/A'),
              _buildReportRow('Voyage Number:', report['voyageNumber'] ?? 'N/A'),
              _buildReportRow('Captain:', report['captainName'] ?? 'N/A'),
              _buildReportRow('Departure Port:', report['departurePort'] ?? 'N/A'),
              _buildReportRow('Arrival Port:', report['arrivalPort'] ?? 'N/A'),
              _buildReportRow('Departure Date:', report['departureDate'] ?? 'N/A'),
              _buildReportRow('Arrival Date:', report['actualArrival'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Catch Information
              pw.Text(
                'Catch Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Catch Type:', report['catchType'] ?? 'N/A'),
              _buildReportRow('Catch Weight:', '${report['catchWeight']} kg'),
              _buildReportRow('Fishing Method:', report['fishingMethod'] ?? 'N/A'),
              _buildReportRow('Fishing Zone:', report['fishingZone'] ?? 'N/A'),
              _buildReportRow('Crew Count:', report['crewCount'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Logistics
              pw.Text(
                'Logistics',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Fuel Consumed:', '${report['fuelConsumed']} liters'),
              _buildReportRow('Distance Covered:', '${report['distance']} km'),
              _buildReportRow('Duration:', report['duration'] ?? 'N/A'),
              _buildReportRow('Weather:', report['weatherConditions'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Status
              pw.Text(
                'Status: ${report['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: report['status'] == 'completed' ? PdfColors.green : PdfColors.orange,
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
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

  Future<void> _generateRegistrationReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
                'Island: ${report['island']}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Personal Details
              pw.Text(
                'Personal Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Fisherman Name:', report['ownerName'] ?? 'N/A'),
              _buildReportRow('Contact Number:', report['mobileNumber'] ?? 'N/A'),
              _buildReportRow('Email:', report['email'] ?? 'N/A'),
              _buildReportRow('Address:', report['address'] ?? 'N/A'),
              _buildReportRow('Home Port:', report['homePort'] ?? 'N/A'),
              _buildReportRow('Fishing Experience:', report['fishingExperience'] ?? 'N/A'),
              _buildReportRow('License Type:', report['licenseType'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Boat Details
              pw.Text(
                'Boat Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Number of Boats:', report['numberOfBoats'] ?? '0'),

              if (report['boats'] != null && report['boats'] is List)
                for (var boat in report['boats'])
                  pw.Container(
                    margin: const pw.EdgeInsets.only(left: 20),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildReportRow('  - Boat Name:', boat['name'] ?? 'N/A'),
                        _buildReportRow('  - Type:', boat['type'] ?? 'N/A'),
                        _buildReportRow('  - Tonnage:', '${boat['tonnage']} tons'),
                        pw.SizedBox(height: 5),
                      ],
                    ),
                  ),

              pw.SizedBox(height: 15),

              // Registration Details
              pw.Text(
                'Registration Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Registration Date:', report['registrationDate'] ?? 'N/A'),
              _buildReportRow('Valid Until:', report['validUntil'] ?? 'N/A'),
              _buildReportRow('Family Members:', report['familyMembers'] ?? 'N/A'),
              _buildReportRow('Income Source:', report['incomeSource'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Status
              pw.Text(
                'Status: ${report['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: report['status'] == 'verified' ? PdfColors.green : PdfColors.orange,
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
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

  Future<void> _generateCatchReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'DAILY CATCH REPORT - LAKSHADWEEP',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Island: ${report['island']} | Date: ${report['reportDate']}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Vessel Details
              pw.Text(
                'Vessel Information',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Vessel Name:', report['vesselName'] ?? 'N/A'),
              _buildReportRow('Captain:', report['captainName'] ?? 'N/A'),
              _buildReportRow('Port:', report['port'] ?? 'N/A'),
              _buildReportRow('Fishermen Count:', report['fishermenCount'] ?? 'N/A'),

              pw.SizedBox(height: 15),

              // Catch Summary
              pw.Text(
                'Catch Summary',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Total Catch:', '${report['totalCatch']} kg'),
              _buildReportRow('Fishing Hours:', '${report['fishingHours']} hours'),
              _buildReportRow('Market Value:', report['marketValue'] ?? 'N/A'),

              // Catch Breakdown
              if (report['catchBreakdown'] != null && report['catchBreakdown'] is Map<String, dynamic>)
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(height: 10),
                    pw.Text('Catch Breakdown:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    for (var entry in (report['catchBreakdown'] as Map<String, dynamic>).entries)
                      _buildReportRow('  • ${entry.key}:', '${entry.value} kg'),
                  ],
                ),

              pw.SizedBox(height: 15),

              // Conditions
              pw.Text(
                'Fishing Conditions',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),
              _buildReportRow('Weather:', report['weather'] ?? 'N/A'),
              _buildReportRow('Sea Conditions:', report['seaConditions'] ?? 'N/A'),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Report generated on: ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Lakshadweep Fisheries Management System',
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

  Future<void> _generateGeneralReport(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'LAKSHADWEEP FISHERIES REPORT',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                report['title'],
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Island: ${report['island']}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.Divider(),
              pw.SizedBox(height: 15),

              // Report Details
              pw.Text(
                'Report Details',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 10),

              // Add all report fields dynamically
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  for (var entry in report.entries)
                    if (!['id', 'type', 'title', 'description', 'date', 'status', 'island'].contains(entry.key))
                      _buildReportRow(
                        '${_formatKey(entry.key)}:',
                        '${entry.value}',
                      ),
                ],
              ),

              pw.SizedBox(height: 15),

              // Status
              pw.Text(
                'Status: ${report['status']?.toString().toUpperCase() ?? 'UNKNOWN'}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _getStatusColor(report['status']),
                ),
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(
                  'Report generated on: ${DateTime.now().toString().substring(0, 10)}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Lakshadweep Fisheries Management System',
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

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isNotEmpty) {
        return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
      }
      return '';
    }).join(' ');
  }

  PdfColor _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return PdfColors.green;
      case 'active':
        return PdfColors.blue;
      case 'pending':
      case 'submitted':
        return PdfColors.orange;
      case 'cancelled':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }

  pw.Widget _buildReportRow(String label, String value) {
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

  void _viewReportDetails(Map<String, dynamic> report) {
    String reportType = report['type'];
    String typeDisplay = _getReportTypeDisplay(reportType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report['title']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                report['description'],
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              const SizedBox(height: 15),
              _buildDetailRow('Report Type:', typeDisplay),
              _buildDetailRow('Island:', report['island'] ?? 'N/A'),
              _buildDetailRow('Date:', report['date'] ?? 'N/A'),
              _buildDetailRow('Status:', report['status']?.toString().toUpperCase() ?? 'UNKNOWN'),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Report Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    ...report.entries
                        .where((entry) => !['id', 'type', 'title', 'description', 'date', 'status', 'island'].contains(entry.key))
                        .map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${_formatKey(entry.key)}: ${entry.value}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ))
                        .toList(),
                  ],
                ),
              ),
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
              switch (report['type']) {
                case 'fishing_voyage':
                  await _generateFishingVoyageReport(report);
                  break;
                case 'registration':
                  await _generateRegistrationReport(report);
                  break;
                case 'catch_report':
                  await _generateCatchReport(report);
                  break;
                default:
                  await _generateGeneralReport(report);
              }
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

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isVoyage = report['type'] == 'fishing_voyage';
    final isRegistration = report['type'] == 'registration';
    final isCatch = report['type'] == 'catch_report';

    Color cardColor;
    IconData icon;

    if (isVoyage) {
      cardColor = Colors.blue;
      icon = Icons.directions_boat;
    } else if (isRegistration) {
      cardColor = Colors.green;
      icon = Icons.person_add;
    } else if (isCatch) {
      cardColor = Colors.orange;
      icon = Icons.inventory;
    } else if (report['type'] == 'weather_alert') {
      cardColor = Colors.red;
      icon = Icons.warning;
    } else if (report['type'] == 'market') {
      cardColor = Colors.purple;
      icon = Icons.shopping_cart;
    } else if (report['type'] == 'conservation') {
      cardColor = Colors.teal;
      icon = Icons.eco;
    } else {
      cardColor = Colors.indigo;
      icon = Icons.description;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardColor.withOpacity(0.3), width: 1.5),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: cardColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            report['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      report['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cardColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      report['island'] ?? 'Lakshadweep',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusBgColor(report['status']),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusBorderColor(report['status'])),
                    ),
                    child: Text(
                      report['status']?.toString().toUpperCase() ?? 'UNKNOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getStatusTextColor(report['status']),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.date_range, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          report['date'] ?? 'Unknown date',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(report['status']),
                          size: 16,
                          color: _getStatusIconColor(report['status']),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Report Type: ${_getReportTypeDisplay(report['type'])}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  switch (report['type']) {
                    case 'fishing_voyage':
                      await _generateFishingVoyageReport(report);
                      break;
                    case 'registration':
                      await _generateRegistrationReport(report);
                      break;
                    case 'catch_report':
                      await _generateCatchReport(report);
                      break;
                    default:
                      await _generateGeneralReport(report);
                  }
                },
                icon: const Icon(Icons.download, size: 18),
                label: const Text('PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _viewReportDetails(report),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('View Details'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0D47A1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBgColor(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return Colors.green.shade50;
      case 'active':
        return Colors.blue.shade50;
      case 'submitted':
      case 'pending':
        return Colors.orange.shade50;
      case 'cancelled':
        return Colors.red.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusBorderColor(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return Colors.green.shade200;
      case 'active':
        return Colors.blue.shade200;
      case 'submitted':
      case 'pending':
        return Colors.orange.shade200;
      case 'cancelled':
        return Colors.red.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return Colors.green.shade800;
      case 'active':
        return Colors.blue.shade800;
      case 'submitted':
      case 'pending':
        return Colors.orange.shade800;
      case 'cancelled':
        return Colors.red.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return Icons.check_circle;
      case 'active':
        return Icons.play_circle;
      case 'submitted':
      case 'pending':
        return Icons.pending;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Color _getStatusIconColor(String? status) {
    switch (status) {
      case 'completed':
      case 'verified':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'submitted':
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getReportTypeDisplay(String type) {
    switch (type) {
      case 'fishing_voyage':
        return 'Fishing Voyage';
      case 'registration':
        return 'Registration';
      case 'catch_report':
        return 'Catch Report';
      case 'equipment':
        return 'Equipment';
      case 'training':
        return 'Training';
      case 'inspection':
        return 'Inspection';
      case 'weather_alert':
        return 'Weather Alert';
      case 'market':
        return 'Market';
      case 'conservation':
        return 'Conservation';
      default:
        return 'Report';
    }
  }

  Widget _buildEmptyState() {
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
            Icons.description_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 20),
          const Text(
            'No reports found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Try changing your filter criteria',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate statistics
    int voyageCount = _reports.where((r) => r['type'] == 'fishing_voyage').length;
    int registrationCount = _reports.where((r) => r['type'] == 'registration').length;
    int catchCount = _reports.where((r) => r['type'] == 'catch_report').length;
    int otherCount = _reports.length - voyageCount - registrationCount - catchCount;

    return Column(
      children: [
        // Header - Reduced padding and spacing
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(15),
              bottomRight: Radius.circular(15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compact title section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Voyage Reports',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Generate and download details\n voyage reports',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.assignment,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter Section - More compact
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        const Text(
                          'Filters',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedIsland,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              items: ['All Islands', ..._homePorts]
                                  .map((island) => DropdownMenuItem(
                                value: island,
                                child: Text(island, style: const TextStyle(fontSize: 13)),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedIsland = value!;
                                  _filterReports();
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedReportType,
                              isExpanded: true,
                              underline: const SizedBox(),
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              items: [
                                'All Types',
                                'fishing_voyage',
                                'registration',
                                'catch_report',
                                'equipment',
                                'training',
                                'inspection',
                                'weather_alert',
                                'market',
                                'conservation'
                              ].map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getReportTypeDisplay(type), style: const TextStyle(fontSize: 13)),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedReportType = value!;
                                  _filterReports();
                                });
                              },
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

        // Statistics Cards - More compact
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  count: voyageCount.toString(),
                  label: 'Fishing Voyages',
                  icon: Icons.directions_boat,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  count: registrationCount.toString(),
                  label: 'Registrations',
                  icon: Icons.person_add,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  count: catchCount.toString(),
                  label: 'Catch Reports',
                  icon: Icons.inventory,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  count: _reports.length.toString(),
                  label: 'Total',
                  icon: Icons.description,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ),

        // Report List
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reports (${_filteredReports.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      Chip(
                        label: Text('${_filteredReports.length}'),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_filteredReports.isEmpty)
                    _buildEmptyState()
                  else
                    ..._filteredReports.map((report) {
                      return _buildReportCard(report);
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    // Since data is hardcoded, just simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }
}