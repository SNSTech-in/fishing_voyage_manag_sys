import 'package:fishing_voyage_manag_sys/screen/selection_screen.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'voyage_form_screen.dart';

class OwnerDashboard extends StatefulWidget {
  final Map<String, dynamic> ownerData;

  const OwnerDashboard({super.key, required this.ownerData});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _voyages = [];
  int _totalVoyages = 0;
  int _pendingVoyages = 0;
  int _completedVoyages = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVoyages();
  }

  Future<void> _loadVoyages() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Map<String, dynamic>> voyages =
      await _databaseHelper.getVoyagesByOwnerId(widget.ownerData['id']);

      setState(() {
        _voyages = voyages;
        _totalVoyages = voyages.length;
        _pendingVoyages = voyages.where((v) => v['status'] == 'pending').length;
        _completedVoyages = voyages.where((v) => v['status'] == 'completed').length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading voyages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showProfileDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'PROFILE DETAILS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Profile Picture
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1976D2),
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Container(
                      color: Colors.blue.shade50,
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Personal Information Section
              _buildProfileSection('Personal Information', [
                _buildProfileDetailRow('Owner Name:', widget.ownerData['owner_name'] ?? 'N/A'),
                _buildProfileDetailRow('Mobile Number:', widget.ownerData['mobile_number'] ?? 'N/A'),
                _buildProfileDetailRow('Aadhar Number:', widget.ownerData['aadhar_number'] ?? 'N/A'),
              ]),

              // Boat Information Section
              _buildProfileSection('Boat Information', [
                _buildProfileDetailRow('Boat Name:', widget.ownerData['boat_name'] ?? 'N/A'),
                _buildProfileDetailRow('Registration No:', widget.ownerData['registration_number'] ?? 'N/A'),
                _buildProfileDetailRow('Home Port:', widget.ownerData['home_port'] ?? 'N/A'),
                _buildProfileDetailRow('Number of Boats:', '${widget.ownerData['number_of_boats'] ?? 1}'),
              ]),

              // Address Section
              _buildProfileSection('Address', [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Address:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.ownerData['address'] ?? 'No address provided',
                          style: const TextStyle(
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),

              // Account Details
              _buildProfileSection('Account Details', [
                _buildProfileDetailRow('Registration Date:',
                    _formatDate(widget.ownerData['registration_date'])),
              ]),

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildProfileDetailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D47A1),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        )
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDisplayDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Not set';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _viewVoyageDetails(Map<String, dynamic> voyage) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Center(
                child: Text(
                  'VOYAGE DETAILS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Voyage Number:', voyage['voyage_number'] ?? 'Not Set'),
              _buildDetailRow('Status:', _getStatusText(voyage['status'])),
              _buildDetailRow('Departure Port:', voyage['departure_port'] ?? 'Not Set'),
              _buildDetailRow('Destination Port:', voyage['destination_port'] ?? 'Not Set'),
              _buildDetailRow('Voyage Date:', voyage['voyage_date'] ?? 'Not Set'),
              _buildDetailRow('Expected Return:', voyage['expected_return_date'] ?? 'Not Set'),
              _buildDetailRow('Fresh Water:', '${voyage['fresh_water'] ?? 0} liters'),
              _buildDetailRow('Diesel:', '${voyage['diesel'] ?? 0} liters'),
              _buildDetailRow('Life Jackets:', '${voyage['life_jackets'] ?? 0}'),
              _buildDetailRow('Life Buoys:', '${voyage['life_buoys'] ?? 0}'),
              _buildDetailRow('Comm Devices:', '${voyage['communication_devices'] ?? 0}'),
              _buildDetailRow('Crew Members:', '${voyage['crew_count'] ?? 0}'),
              _buildDetailRow('License Number:', voyage['fishing_license'] ?? 'Not Set'),
              _buildDetailRow('Previous Catch Submitted:',
                  (voyage['previous_catch_submitted'] == 1) ? 'Yes' : 'No'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending Approval';
      case 'approved':
        return 'Approved';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Submitted';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0D47A1),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        )
    );
  }

  void _logout() async {
    // Show confirmation dialog
    bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirm Logout',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning,
              size: 50,
              color: Colors.orange,
            ),
            SizedBox(height: 10),
            Text(
              'Are you sure you want to logout?\n\nThis will clear all data including voyages, owner information, and ports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF1976D2),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmLogout != true) {
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Clearing data and logging out...',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );

    try {
      // Clear all data from database
      await _databaseHelper.clearAllData();
      print('All data cleared successfully');

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      // Navigate to login screen and clear all routes
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const SelectionScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      print('Error during logout: $e');
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToVoyageForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoyageFormScreen(ownerData: widget.ownerData),
      ),
    );

    if (result == true) {
      _loadVoyages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.2),
              ),
              child: const Icon(Icons.directions_boat, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.ownerData['owner_name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Voyages: $_totalVoyages',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        toolbarHeight: 60, // Reduced toolbar height
        actions: [
          // Increased tap area for app bar icons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              icon: const Icon(Icons.person_outline, size: 20, color: Colors.white),
              onPressed: _showProfileDetails,
              tooltip: 'Profile',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
              onPressed: _loadVoyages,
              tooltip: 'Refresh',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20, color: Colors.white),
              onPressed: _logout,
              tooltip: 'Logout',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
        ),
      )
          : Column(
        children: [
          // Compact User Info Card - Made entire card tappable
          GestureDetector(
            onTap: _showProfileDetails,
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1976D2).withOpacity(0.1),
                      border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.ownerData['owner_name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Boat: ${widget.ownerData['boat_name'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Info icon - kept for visual cue but entire card is tappable
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: const Color(0xFF1976D2).withOpacity(0.7),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total',
                          '$_totalVoyages',
                          Icons.directions_boat,
                          const Color(0xFF1976D2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Pending',
                          '$_pendingVoyages',
                          Icons.pending_actions,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Completed',
                          '$_completedVoyages',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // New Voyage Button - Made entire container tappable
                  GestureDetector(
                    onTap: _navigateToVoyageForm,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade100,
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue.shade50,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 24,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Voyage Intimation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Submit a new voyage intimation',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1976D2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 16, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Submit',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Voyages List Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Voyages',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          '$_totalVoyages',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Voyages List or Empty State
                  if (_voyages.isEmpty)
                    GestureDetector(
                      onTap: _navigateToVoyageForm,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_boat_outlined,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'No Voyages Yet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tap to submit your first voyage',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _voyages.length,
                      separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final voyage = _voyages[index];
                        final voyageDate = voyage['voyage_date'] ?? '';
                        final formattedDate = voyageDate.isNotEmpty
                            ? _formatDisplayDate(voyageDate)
                            : 'Not set';

                        // Wrap entire Card with GestureDetector for larger tap area
                        return GestureDetector(
                          onTap: () => _viewVoyageDetails(voyage),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            child: Card(
                              margin: EdgeInsets.zero,
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10), // Increased vertical padding
                                minVerticalPadding: 10,
                                minLeadingWidth: 36,
                                leading: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _getStatusColor(voyage['status'])
                                        .withOpacity(0.1),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward,
                                    size: 18,
                                    color: _getStatusColor(voyage['status']),
                                  ),
                                ),
                                title: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    voyage['voyage_number'] ?? 'Voyage ${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${voyage['departure_port']} → ${voyage['destination_port']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Date: $formattedDate',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(voyage['status'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _getStatusColor(voyage['status']),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    _getStatusText(voyage['status']),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: _getStatusColor(voyage['status']),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        // Optional: Add tap feedback for stats cards
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title: $value voyages'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12), // Increased padding
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color), // Slightly larger icon
            const SizedBox(height: 6), // Increased spacing
            Text(
              value,
              style: TextStyle(
                fontSize: 20, // Slightly larger text
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10, // Slightly larger
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}