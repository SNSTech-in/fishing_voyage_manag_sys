import 'package:flutter/material.dart';

class OfficersRegistrationScreen extends StatefulWidget {
  const OfficersRegistrationScreen({super.key});

  @override
  State<OfficersRegistrationScreen> createState() => _OfficersRegistrationScreenState();
}

class _OfficersRegistrationScreenState extends State<OfficersRegistrationScreen> {
  List<Map<String, dynamic>> _pendingRegistrations = [];
  List<Map<String, dynamic>> _verifiedRegistrations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHardcodedData();
  }

  void _loadHardcodedData() {
    // Hardcoded registration data
    final hardcodedData = [
      {
        'id': 1,
        'owner_name': 'Rajesh Kumar',
        'email': 'rajesh.kumar@email.com',
        'mobile_number': '+91 9876543210',
        'address': 'Boat House, Agatti Island, Lakshadweep',
        'home_port': 'Agatti Port',
        'number_of_boats': '2',
        'submission_date': DateTime(2024, 1, 15),
        'status': 'pending',
      },
      {
        'id': 2,
        'owner_name': 'Meera Nair',
        'email': 'meera.nair@email.com',
        'mobile_number': '+91 8765432109',
        'address': 'Fisherman Colony, Kavaratti',
        'home_port': 'Kavaratti Port',
        'number_of_boats': '3',
        'submission_date': DateTime(2024, 1, 20),
        'status': 'verified',
      },
      {
        'id': 3,
        'owner_name': 'Abdul Rahman',
        'email': 'abdul.rahman@email.com',
        'mobile_number': '+91 7654321098',
        'address': 'Minicoy Island',
        'home_port': 'Minicoy Fishing Harbor',
        'number_of_boats': '1',
        'submission_date': DateTime(2024, 1, 25),
        'status': 'pending',
      },
      {
        'id': 4,
        'owner_name': 'Sunita Pillai',
        'email': 'sunita.pillai@email.com',
        'mobile_number': '+91 6543210987',
        'address': 'Bangaram Island',
        'home_port': 'Bangaram Jetty',
        'number_of_boats': '4',
        'submission_date': DateTime(2024, 1, 28),
        'status': 'verified',
      },
      {
        'id': 5,
        'owner_name': 'Vikram Singh',
        'email': 'vikram.singh@email.com',
        'mobile_number': '+91 5432109876',
        'address': 'Kadmat Island',
        'home_port': 'Kadmat Fishing Point',
        'number_of_boats': '2',
        'submission_date': DateTime(2024, 2, 1),
        'status': 'pending',
      },
      {
        'id': 6,
        'owner_name': 'Anjali Menon',
        'email': 'anjali.menon@email.com',
        'mobile_number': '+91 4321098765',
        'address': 'Agatti Island',
        'home_port': 'Agatti Port',
        'number_of_boats': '3',
        'submission_date': DateTime(2024, 2, 3),
        'status': 'verified',
      },
      {
        'id': 7,
        'owner_name': 'Faizal Koya',
        'email': 'faizal.koya@email.com',
        'mobile_number': '+91 3210987654',
        'address': 'Kavaratti Island',
        'home_port': 'Kavaratti Port',
        'number_of_boats': '1',
        'submission_date': DateTime(2024, 2, 5),
        'status': 'pending',
      },
      {
        'id': 8,
        'owner_name': 'Preetha Iyer',
        'email': 'preetha.iyer@email.com',
        'mobile_number': '+91 2109876543',
        'address': 'Minicoy Island',
        'home_port': 'Minicoy Fishing Harbor',
        'number_of_boats': '2',
        'submission_date': DateTime(2024, 2, 7),
        'status': 'verified',
      },
    ];

    setState(() {
      _pendingRegistrations = hardcodedData.where((reg) => reg['status'] == 'pending').toList();
      _verifiedRegistrations = hardcodedData.where((reg) => reg['status'] == 'verified').toList();
      _isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate loading delay
    await Future.delayed(const Duration(seconds: 1));

    // Reload the hardcoded data
    _loadHardcodedData();
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
            'Loading registrations...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyRegistration(Map<String, dynamic> registration) async {
    // Update the status locally
    setState(() {
      registration['status'] = 'verified';
      _pendingRegistrations.remove(registration);
      _verifiedRegistrations.add(registration);
    });

    // Sort verified registrations by date
    _verifiedRegistrations.sort((a, b) {
      final dateA = a['submission_date'] as DateTime;
      final dateB = b['submission_date'] as DateTime;
      return dateB.compareTo(dateA);
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registration verified successfully'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewRegistrationDetails(Map<String, dynamic> registration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registration Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(
                icon: Icons.person,
                text: 'Name: ${registration['owner_name'] ?? 'Unknown'}',
                color: Colors.blue,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.email,
                text: 'Email: ${registration['email'] ?? 'No email'}',
                color: Colors.green,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.phone,
                text: 'Phone: ${registration['mobile_number'] ?? 'No phone'}',
                color: Colors.purple,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.location_on,
                text: 'Address: ${registration['address'] ?? 'No address'}',
                color: Colors.orange,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.home,
                text: 'Home Port: ${registration['home_port'] ?? 'No port'}',
                color: Colors.teal,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.directions_boat,
                text: 'Boats: ${registration['number_of_boats'] ?? '0'}',
                color: Colors.indigo,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.date_range,
                text: 'Submitted: ${(registration['submission_date'] as DateTime).toString().substring(0, 10)}',
                color: Colors.brown,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: registration['status'] == 'verified' ? Icons.verified : Icons.pending,
                text: 'Status: ${(registration['status'] as String).toUpperCase()}',
                color: registration['status'] == 'verified' ? Colors.green : Colors.orange,
              ),

              // Additional hardcoded details
              const SizedBox(height: 15),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Boat Details:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 8),
              ..._getBoatDetails(registration['id'] as int).map((boatDetail) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            boatDetail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
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
        ],
      ),
    );
  }

  List<String> _getBoatDetails(int registrationId) {
    // Hardcoded boat details based on registration ID
    switch (registrationId) {
      case 1:
        return [
          'Boat 1: Speed Boat - Registration: LDW-AB123',
          'Boat 2: Fishing Trawler - Registration: LDW-CD456'
        ];
      case 2:
        return [
          'Boat 1: Fishing Vessel - Registration: LDW-EF789',
          'Boat 2: Speed Boat - Registration: LDW-GH012',
          'Boat 3: Small Fisher - Registration: LDW-IJ345'
        ];
      case 3:
        return ['Boat 1: Traditional Dhow - Registration: LDW-KL678'];
      case 4:
        return [
          'Boat 1: Fishing Trawler - Registration: LDW-MN901',
          'Boat 2: Speed Boat - Registration: LDW-OP234',
          'Boat 3: Cargo Boat - Registration: LDW-QR567',
          'Boat 4: Passenger Ferry - Registration: LDW-ST890'
        ];
      case 5:
        return [
          'Boat 1: Fishing Vessel - Registration: LDW-UV123',
          'Boat 2: Speed Boat - Registration: LDW-WX456'
        ];
      case 6:
        return [
          'Boat 1: Fishing Trawler - Registration: LDW-YZ789',
          'Boat 2: Cargo Boat - Registration: LDW-AB012',
          'Boat 3: Speed Boat - Registration: LDW-CD345'
        ];
      case 7:
        return ['Boat 1: Traditional Dhow - Registration: LDW-EF678'];
      case 8:
        return [
          'Boat 1: Fishing Vessel - Registration: LDW-GH901',
          'Boat 2: Speed Boat - Registration: LDW-IJ234'
        ];
      default:
        return ['No boat details available'];
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard(Map<String, dynamic> registration, bool isPending) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isPending ? Colors.orange.shade200 : Colors.green.shade200,
          width: 1.5,
        ),
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
                    Text(
                      registration['owner_name'] ?? 'Unknown Owner',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      registration['email'] ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isPending ? Colors.orange.shade200 : Colors.green.shade200,
                  ),
                ),
                child: Text(
                  isPending ? 'PENDING' : 'VERIFIED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPending ? Colors.orange : Colors.green,
                  ),
                ),
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
                    _buildDetailRow(
                      icon: Icons.phone,
                      text: registration['mobile_number'] ?? 'No phone',
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      icon: Icons.home,
                      text: registration['home_port'] ?? 'No home port',
                      color: Colors.teal,
                    ),
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      icon: Icons.directions_boat,
                      text: '${registration['number_of_boats'] ?? '0'} boat(s)',
                      color: Colors.indigo,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  if (isPending)
                    ElevatedButton.icon(
                      onPressed: () => _verifyRegistration(registration),
                      icon: const Icon(Icons.verified, size: 18),
                      label: const Text('Verify'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    (registration['submission_date'] as DateTime).toString().substring(0, 10),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _viewRegistrationDetails(registration),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 15),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required IconData icon,
    required Color color,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              'Registration Management',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Manage boat owner registrations',
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
                          Icons.app_registration,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.white, size: 18),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    count: _pendingRegistrations.length,
                    label: 'Pending',
                    icon: Icons.pending_actions,
                    color: Colors.orange,
                    borderColor: Colors.orange.shade200,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    count: _verifiedRegistrations.length,
                    label: 'Verified',
                    icon: Icons.verified,
                    color: Colors.green,
                    borderColor: Colors.green.shade200,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    count: _pendingRegistrations.length + _verifiedRegistrations.length,
                    label: 'Total',
                    icon: Icons.list_alt,
                    color: Colors.blue,
                    borderColor: Colors.blue.shade200,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Pending Registrations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Verifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Chip(
                  label: Text('${_pendingRegistrations.length}'),
                  backgroundColor: Colors.orange.shade50,
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_pendingRegistrations.isEmpty)
              _buildEmptyState(
                icon: Icons.check_circle,
                message: 'No pending registrations',
                subMessage: 'All registrations are verified',
              )
            else
              ..._pendingRegistrations.map((registration) {
                return _buildRegistrationCard(registration, true);
              }),

            const SizedBox(height: 20),

            // Verified Registrations
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Verified Registrations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                Chip(
                  label: Text('${_verifiedRegistrations.length}'),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_verifiedRegistrations.isEmpty)
              _buildEmptyState(
                icon: Icons.person_add_disabled,
                message: 'No verified registrations',
                subMessage: 'No registrations have been verified yet',
              )
            else
              ..._verifiedRegistrations.map((registration) {
                return _buildRegistrationCard(registration, false);
              }),

            const SizedBox(height: 30),

            // Footer note
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.developer_mode, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo Mode: All data is hardcoded for demonstration purposes.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
