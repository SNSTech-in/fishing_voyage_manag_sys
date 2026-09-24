// screens/boat_owner/crew_member/add_crew_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';

class AddCrewScreen extends StatefulWidget {
  final Map<String, dynamic>? ownerData;
  final List<int>? preSelectedIds;

  const AddCrewScreen({
    super.key,
    this.ownerData,
    this.preSelectedIds,
  });

  @override
  State<AddCrewScreen> createState() => _AddCrewScreenState();
}

class _AddCrewScreenState extends State<AddCrewScreen> {
  final ApiService _apiService = ApiService();

  // ─── PALETTE ──────────────────────────────────────────────────
  static const Color brand50     = Color(0xFFF0F7FF);
  static const Color brand100    = Color(0xFFE0EFFE);
  static const Color brand200    = Color(0xFFBAE0FD);
  static const Color brand500    = Color(0xFF0284C7);
  static const Color brand600    = Color(0xFF0369A1);
  static const Color brand700    = Color(0xFF075985);
  static const Color brandGlow   = Color(0xFF38BDF8);
  static const Color slateBg     = Color(0xFFF8FAFC);
  static const Color slateBorder = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textMuted   = Color(0xFF64748B);
  static const Color emerald     = Color(0xFF10B981);
  static const Color inkNavy     = Color(0xFF06358D);

  // ─── STATE ────────────────────────────────────────────────────
  List<Map<String, dynamic>> crewMembers = [];
  List<Map<String, dynamic>> filteredCrewMembers = [];
  List<int> selectedIds = [];
  bool isLoading = false;
  bool isAdding = false;
  int currentPage = 1;
  int totalPages = 1;
  int totalCrew = 0;

  final TextEditingController searchController = TextEditingController();

  // Add Crew Dialog Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController nicRefController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController emergencyNameController = TextEditingController();
  final TextEditingController emergencyMobileController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? selectedGender;
  String? selectedRole;
  bool isCaptain = false;
  bool canLogin = true;

  final _dialogFormKey = GlobalKey<FormState>();

  final List<String> genderOptions = ['MALE', 'FEMALE', 'OTHER'];
  final List<String> roleOptions = ['CAPTAIN', 'CREW'];

  // ══════════════════════════════════════════════════════════════
  //  LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    selectedIds = List.from(widget.preSelectedIds ?? []);
    _loadCrew();
    searchController.addListener(_filterCrew);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterCrew);
    searchController.dispose();
    nameController.dispose();
    aadhaarController.dispose();
    nicRefController.dispose();
    mobileController.dispose();
    emergencyNameController.dispose();
    emergencyMobileController.dispose();
    addressController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  SEARCH FILTER
  // ══════════════════════════════════════════════════════════════

  void _filterCrew() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() => filteredCrewMembers = List.from(crewMembers));
    } else {
      setState(() {
        filteredCrewMembers = crewMembers.where((crew) {
          final name = crew['crew_name']?.toString().toLowerCase() ?? '';
          final mobile = crew['mobile_no']?.toString() ?? '';
          return name.contains(query) || mobile.contains(query);
        }).toList();
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  LOAD CREW
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadCrew({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      if (refresh) {
        crewMembers = [];
        filteredCrewMembers = [];
        currentPage = 1;
        searchController.clear();
      }
    });

    try {
      final response = await _apiService.getCrewList(page: currentPage);

      if (response['success'] == true) {
        final data = response['data'];
        final items = data['items'] as List?;
        totalCrew = data['total'] ?? 0;
        totalPages = data['total_pages'] ?? 1;

        if (items != null && items.isNotEmpty) {
          final loadedCrew = List<Map<String, dynamic>>.from(items);
          if (!mounted) return;

          setState(() {
            if (refresh) {
              crewMembers = loadedCrew;
            } else {
              crewMembers = [...crewMembers, ...loadedCrew];
            }
            filteredCrewMembers = List.from(crewMembers);
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            filteredCrewMembers = [];
          });
        }
      } else {
        if (!mounted) return;
        setState(() => isLoading = false);
        _showErrorDialog(
          response['message'] ?? 'Failed to load crew',
          response['error_code'],
          response['errors'],
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showErrorDialog('Network error: ${e.toString()}', null, null);
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  SELECTION
  // ══════════════════════════════════════════════════════════════

  void _toggleSelection(int id) {
    setState(() {
      if (selectedIds.contains(id)) {
        selectedIds.remove(id);
      } else {
        selectedIds.add(id);
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  CLEAR CONTROLLERS
  // ══════════════════════════════════════════════════════════════

  void _clearControllers() {
    nameController.clear();
    aadhaarController.clear();
    nicRefController.clear();
    mobileController.clear();
    emergencyNameController.clear();
    emergencyMobileController.clear();
    addressController.clear();
    selectedGender = null;
    selectedRole = null;
    isCaptain = false;
    canLogin = true;
    _dialogFormKey.currentState?.reset();
  }

  // ══════════════════════════════════════════════════════════════
  //  VALIDATORS — new fields included
  // ══════════════════════════════════════════════════════════════

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter crew name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  String? _validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) return 'Aadhaar is required';
    if (value.trim().length != 12) return 'Enter exactly 12 digits';
    if (!RegExp(r'^[0-9]{12}$').hasMatch(value.trim())) return 'Only numbers allowed';
    return null;
  }

  String? _validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter mobile number';
    if (value.trim().length != 10) return 'Enter valid 10-digit mobile number';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) return 'Only numbers allowed';
    return null;
  }

  /// ⭐ NEW: Emergency mobile is required now (per new UI)
  String? _validateEmergencyMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter emergency contact number';
    }
    if (value.trim().length != 10) return 'Enter valid 10-digit mobile number';
    if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) return 'Only numbers allowed';
    return null;
  }

  /// ⭐ NEW: Emergency contact name is required
  String? _validateEmergencyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter emergency contact name';
    }
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    return null;
  }

  /// ⭐ NEW: Address is required
  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter residential address';
    }
    if (value.trim().length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  // ══════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'C';
    return name.substring(0, 1).toUpperCase();
  }

  String _getGenderLabel(String? gender) {
    if (gender == null) return 'N/A';
    switch (gender) {
      case 'MALE': return 'Male';
      case 'FEMALE': return 'Female';
      case 'OTHER': return 'Other';
      default: return gender;
    }
  }

  String _getRoleLabel(String? role) {
    if (role == null) return 'N/A';
    switch (role) {
      case 'CAPTAIN': return 'Captain';
      case 'CREW': return 'Crew';
      default: return role;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'N/A';
    switch (status) {
      case 'ACTIVE': return 'Active';
      case 'INACTIVE': return 'Inactive';
      default: return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'ACTIVE': return emerald;
      case 'INACTIVE': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getDropdownLabel(String value) {
    if (value == 'MALE') return 'Male';
    if (value == 'FEMALE') return 'Female';
    if (value == 'OTHER') return 'Other';
    if (value == 'CAPTAIN') return 'Captain';
    if (value == 'CREW') return 'Crew';
    return value;
  }

  /// ⭐ NEW: When user picks a role, auto-sync the Is Captain toggle
  void _onRoleChanged(String? role, void Function(void Function()) setStateDialog) {
    setStateDialog(() {
      selectedRole = role;
      // Auto-sync is_captain with the role for the common case
      if (role == 'CAPTAIN') {
        isCaptain = true;
      } else if (role == 'CREW') {
        isCaptain = false;
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  ERROR DIALOG
  // ══════════════════════════════════════════════════════════════

  void _showErrorDialog(String? message, String? errorCode, dynamic errors) {
    if (!mounted) return;

    // Include field-level errors from backend if present
    String display = message ?? 'Something went wrong';
    if (errors is List && errors.isNotEmpty) {
      final lines = errors.map((e) {
        if (e is Map) {
          final f = e['field'] ?? '';
          final m = e['message'] ?? '';
          return f.toString().isNotEmpty ? '$f: $m' : m.toString();
        }
        return e.toString();
      }).join('\n');
      display += '\n\n$lines';
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: inkNavy)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(display, style: const TextStyle(fontSize: 14, color: Colors.black87)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  CREW DETAILS — now shows new fields
  // ══════════════════════════════════════════════════════════════

  void _showCrewDetails(Map<String, dynamic> crew) {
    final status = crew['status'] ?? 'ACTIVE';
    final role = crew['crew_role'];
    final isCapt = crew['is_captain'] == true;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0369A1), Color(0xFF0284C7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(crew['crew_name']),
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    crew['crew_name'] ?? 'Unknown',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                if (isCapt) ...[
                                  const SizedBox(width: 6),
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Crew ID: ${crew['crew_id'] ?? 'N/A'}',
                              style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      ),
                    ],
                  ),
                ),
                // Body — all fields
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDetailRow(Icons.badge_rounded, 'Role', _getRoleLabel(role)),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.phone_rounded, 'Mobile', crew['mobile_no']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.credit_card_rounded, 'Aadhaar', crew['aadhaar_no']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.description_rounded, 'NIC Ref', crew['nic_ref']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.wc_rounded, 'Gender', _getGenderLabel(crew['gender']?.toString())),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.health_and_safety_rounded, 'Emergency Name', crew['emergency_contact_name']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.emergency_rounded, 'Emergency No', crew['emergency_contact_no']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.location_on_rounded, 'Address', crew['address_line1']?.toString() ?? 'N/A'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.login_rounded, 'Can Login', crew['can_login'] == true ? 'Yes' : 'No'),
                        const SizedBox(height: 10),
                        _buildDetailRow(Icons.star_rounded, 'Is Captain', isCapt ? 'Yes' : 'No'),
                        const SizedBox(height: 14),
                        // Status pill
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getStatusColor(status).withOpacity(0.25)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: _getStatusColor(status), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${_getStatusLabel(status)}',
                                style: TextStyle(color: _getStatusColor(status), fontSize: 12.5, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brand600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2)),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: brand50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: brand200),
          ),
          child: Icon(icon, size: 17, color: brand600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13.5, color: textPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ADD CREW DIALOG
  //  ⭐ All new fields wired to payload + validation + toggles
  // ══════════════════════════════════════════════════════════════

  Future<void> _showAddCrewDialog() async {
    _clearControllers();
    isAdding = false;
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    // ─── Header ───
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF075985), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                                ),
                                child: const Row(
                                  children: [
                                    SizedBox(
                                      width: 6, height: 6,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(color: Color(0xFF38BDF8), shape: BoxShape.circle),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'MARITIME ONBOARDING',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'REG-V2',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11.5,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: isAdding ? null : () => Navigator.pop(context),
                                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add Crew Member',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Form ───
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Form(
                          key: _dialogFormKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 1. Crew Name
                              _buildFieldLabel('Crew Name', isRequired: true),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: nameController,
                                hint: 'Enter crew name',
                                icon: Icons.person_rounded,
                                validator: _validateName,
                              ),
                              const SizedBox(height: 14),

                              // 2. Mobile
                              _buildFieldLabel('Mobile Number', isRequired: true, trailing: '10 digits'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: mobileController,
                                hint: 'Enter 10-digit mobile number',
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: _validateMobile,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(height: 14),

                              // 3. Aadhaar
                              _buildFieldLabel('Aadhaar Number', isRequired: true, trailing: '12 digits'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: aadhaarController,
                                hint: 'Enter 12-digit Aadhaar number',
                                icon: Icons.badge_rounded,
                                keyboardType: TextInputType.number,
                                validator: _validateAadhaar,
                                maxLength: 12,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                isMono: true,
                              ),
                              const SizedBox(height: 6),
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_rounded, size: 12, color: brand500),
                                    SizedBox(width: 5),
                                    Text(
                                      'Encrypted & formatted as 12 numerical digits',
                                      style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 4. NIC Reference (optional)
                              _buildFieldLabel('NIC Reference', trailing: 'Optional'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: nicRefController,
                                hint: 'Enter NIC reference number',
                                icon: Icons.description_rounded,
                                isMono: true,
                              ),
                              const SizedBox(height: 14),

                              // 5 & 6. Gender + Role (Role change auto-syncs Is Captain)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Gender', isRequired: true),
                                        const SizedBox(height: 6),
                                        _buildDropdownField(
                                          value: selectedGender,
                                          options: genderOptions,
                                          hint: 'Select',
                                          onChanged: (v) => setStateDialog(() => selectedGender = v),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildFieldLabel('Role', isRequired: true),
                                        const SizedBox(height: 6),
                                        _buildDropdownField(
                                          value: selectedRole,
                                          options: roleOptions,
                                          hint: 'Select',
                                          onChanged: (v) => _onRoleChanged(v, setStateDialog),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // 7. Emergency Contact Name
                              _buildFieldLabel('Emergency Contact Name', isRequired: true),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: emergencyNameController,
                                hint: 'Enter emergency contact name',
                                icon: Icons.health_and_safety_rounded,
                                validator: _validateEmergencyName,
                              ),
                              const SizedBox(height: 14),

                              // 8. Emergency Contact No
                              _buildFieldLabel('Emergency Contact No', isRequired: true, trailing: '10 digits'),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: emergencyMobileController,
                                hint: 'Enter 10-digit emergency number',
                                icon: Icons.phone_rounded,
                                keyboardType: TextInputType.phone,
                                validator: _validateEmergencyMobile,
                                maxLength: 10,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              ),
                              const SizedBox(height: 14),

                              // 9. Address
                              _buildFieldLabel('Address', isRequired: true),
                              const SizedBox(height: 6),
                              _buildTextField(
                                controller: addressController,
                                hint: 'Enter residential address',
                                icon: Icons.location_on_rounded,
                                keyboardType: TextInputType.streetAddress,
                                validator: _validateAddress,
                                maxLines: 2,
                              ),
                              const SizedBox(height: 14),

                              // 10 & 11. Toggles
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildToggleCard(
                                      title: 'Is Captain',
                                      subtitle: 'Vessel master',
                                      value: isCaptain,
                                      onChanged: (v) => setStateDialog(() => isCaptain = v),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildToggleCard(
                                      title: 'Can Login',
                                      subtitle: 'Portal access',
                                      value: canLogin,
                                      onChanged: (v) => setStateDialog(() => canLogin = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // 12. Info pill
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: slateBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: slateBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, size: 15, color: brand600),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Credentials will be verified in real-time with the national maritime biometric registry.',
                                        style: TextStyle(fontSize: 12.5, color: textMuted, height: 1.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ─── Actions ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: isAdding ? null : () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isAdding
                                  ? null
                                  : () async {
                                // ⭐ Full validation runs across ALL fields
                                if (!_dialogFormKey.currentState!.validate()) {
                                  return;
                                }
                                if (selectedGender == null || selectedRole == null) {
                                  _showErrorDialog(
                                    'Please select Gender and Role.',
                                    null,
                                    null,
                                  );
                                  return;
                                }

                                setStateDialog(() => isAdding = true);

                                try {
                                  // ⭐ All new fields included in payload
                                  final crewData = {
                                    'crew_name': nameController.text.trim(),
                                    'mobile_no': mobileController.text.trim(),
                                    'gender': selectedGender!,
                                    'crew_role': selectedRole!,
                                    'is_captain': isCaptain,
                                    'can_login': canLogin,
                                    'nic_ref': nicRefController.text.trim(),
                                    'aadhaar_no': aadhaarController.text.trim(),
                                    'emergency_contact_name': emergencyNameController.text.trim(),
                                    'emergency_contact_no': emergencyMobileController.text.trim(),
                                    'address_line1': addressController.text.trim(),
                                  };

                                  print('📤 [addCrew] payload: $crewData');

                                  final response = await _apiService.addCrew(crewData: crewData);

                                  print('📥 [addCrew] response: $response');

                                  if (response['success'] == true) {
                                    if (!mounted) return;
                                    Navigator.pop(context);
                                    _showSuccessSnackBar('Crew member added successfully');
                                    await _loadCrew(refresh: true);
                                  } else {
                                    if (!mounted) return;
                                    _showErrorDialog(
                                      response['message'] ?? 'Failed to add crew',
                                      response['error_code'],
                                      response['errors'],
                                    );
                                  }
                                } catch (e) {
                                  print('❌ Add Crew error: $e');
                                  if (!mounted) return;
                                  _showErrorDialog('Error: $e', null, null);
                                } finally {
                                  if (mounted) {
                                    setStateDialog(() => isAdding = false);
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: brand600,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isAdding
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                                  : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Add',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      )),
                                  SizedBox(width: 6),
                                  Icon(Icons.add_rounded, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  // ─── Snackbar helper ───
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  FORM FIELD HELPERS
  // ══════════════════════════════════════════════════════════════

  Widget _buildFieldLabel(String label, {bool isRequired = false, String? trailing}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        if (isRequired)
          const Text(' *',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: brand600)),
        const Spacer(),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool isMono = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slateBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 13.5,
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontFamily: isMono ? 'monospace' : null,
        ),
        validator: validator,
        maxLength: maxLength,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 30 : 0),
            child: Icon(icon, size: 18, color: textMuted),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<String> options,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slateBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: textMuted),
        hint: Text(
          hint,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        items: options
            .map((o) => DropdownMenuItem(
          value: o,
          child: Text(
            _getDropdownLabel(o),
            style: const TextStyle(
              fontSize: 15,
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ))
            .toList(),
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: slateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slateBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: 0.1,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Colors.white,
              activeTrackColor: brand600,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFCBD5E1),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = widget.preSelectedIds != null;

    return Scaffold(
      backgroundColor: slateBg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildNewHeader(isSelectionMode),
            Expanded(child: _buildBody()),
            _buildFloatingAddBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildNewHeader(bool isSelectionMode) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: slateBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),      // ← tighter
        child: Row(
          children: [
            // Back button — smaller
            GestureDetector(
              onTap: isSelectionMode
                  ? () => Navigator.pop(context, selectedIds)
                  : () => Navigator.pop(context),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: slateBorder),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: inkNavy, size: 18),
              ),
            ),
            const SizedBox(width: 10),

            // Title block — tighter
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isSelectionMode ? 'Select Crew' : 'Crew Members',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: brand50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: brand200),
                        ),
                        child: const Text(
                          'FLEET',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: brand700,
                            fontFamily: 'monospace',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 4, height: 4,
                        decoration: const BoxDecoration(color: emerald, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$totalCrew Active Personnel',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: textMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Done chip (selection mode only) — slightly smaller
            if (isSelectionMode)
              GestureDetector(
                onTap: () => Navigator.pop(context, selectedIds),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),  // ← tighter
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF0284C7)]),
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(color: brand500.withOpacity(0.25), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Done (${selectedIds.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),

            // Refresh button — smaller
            GestureDetector(
              onTap: () => _loadCrew(refresh: true),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: slateBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: slateBorder),
                ),
                child: const Icon(Icons.refresh_rounded, color: inkNavy, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading && crewMembers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: brand600),
            SizedBox(height: 16),
            Text('Loading crew...', style: TextStyle(color: textMuted, fontSize: 13)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildMetricsBar(),
        _buildSearchBar(),
        Expanded(
          child: filteredCrewMembers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            color: brand600,
            onRefresh: () => _loadCrew(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: filteredCrewMembers.length,
              itemBuilder: (ctx, i) => _buildCrewCard(filteredCrewMembers[i], i),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsBar() {
    final int total = crewMembers.length;
    final int captains = crewMembers
        .where((c) => c['crew_role']?.toString().toUpperCase() == 'CAPTAIN')
        .length;
    final int activeCount = crewMembers
        .where((c) => c['status']?.toString().toUpperCase() == 'ACTIVE')
        .length;
    final int verified = crewMembers
        .where((c) => c['nic_verified'] == true || c['aadhaar_no'] != null)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(child: _metricTile('TOTAL', total.toString().padLeft(2, '0'), brand600)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile('CAPTAINS', captains.toString().padLeft(2, '0'), brand500)),
          const SizedBox(width: 8),
          Expanded(child: _metricTile('ACTIVE', activeCount.toString().padLeft(2, '0'), emerald)),
          const SizedBox(width: 8),
          Expanded(
            child: _metricTile(
              'VERIFIED',
              total > 0 ? '${((verified / total) * 100).round()}%' : '0%',
              textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: slateBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: valueColor,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: slateBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: TextField(
          controller: searchController,
          style: const TextStyle(fontSize: 13.5, color: textPrimary, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: 'Search by name or mobile...',
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: const Icon(Icons.search_rounded, color: textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear_rounded, size: 18, color: textMuted),
              onPressed: () => searchController.clear(),
            )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCrewCard(Map<String, dynamic> crew, int index) {
    final int id = int.tryParse(crew['crew_id']?.toString() ?? '') ?? index;
    final isSelected = selectedIds.contains(id);
    final status = crew['status'] ?? 'ACTIVE';
    final role = (crew['crew_role'] ?? '').toString().toUpperCase();
    final isCaptainRole = role == 'CAPTAIN' || crew['is_captain'] == true;
    final isActive = status.toString().toUpperCase() == 'ACTIVE';

    final List<Map<String, Color>> palette = [
      {'bg': const Color(0xFFF0F7FF), 'fg': const Color(0xFF0284C7), 'border': const Color(0xFFBAE0FD)},
      {'bg': const Color(0xFFECFDF5), 'fg': const Color(0xFF059669), 'border': const Color(0xFFA7F3D0)},
      {'bg': const Color(0xFFFEF2F2), 'fg': const Color(0xFFDC2626), 'border': const Color(0xFFFECACA)},
      {'bg': const Color(0xFFFFFBEB), 'fg': const Color(0xFFD97706), 'border': const Color(0xFFFDE68A)},
      {'bg': const Color(0xFFEEF2FF), 'fg': const Color(0xFF4F46E5), 'border': const Color(0xFFC7D2FE)},
    ];
    final p = palette[index % palette.length];

    return GestureDetector(
      onTap: widget.preSelectedIds != null
          ? () => _toggleSelection(id)
          : () => _showCrewDetails(crew),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? brand50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? brand500 : slateBorder,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: p['bg'],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p['border']!),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(crew['crew_name']),
                      style: TextStyle(color: p['fg'], fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    width: 15, height: 15,
                    decoration: BoxDecoration(
                      color: isActive ? emerald : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                if (isCaptainRole)
                  Positioned(
                    top: -4, right: -4,
                    child: Container(
                      width: 18, height: 18,
                      decoration: BoxDecoration(
                        color: brand600,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          crew['crew_name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCaptainRole ? brand50 : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isCaptainRole ? brand200 : slateBorder),
                        ),
                        child: Text(
                          _getRoleLabel(role),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: isCaptainRole ? brand700 : textMuted,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 5),
                      Text(
                        crew['mobile_no']?.toString() ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (widget.preSelectedIds != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? brand600 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? brand600 : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                    : null,
              )
            else
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: brand50,
                shape: BoxShape.circle,
                border: Border.all(color: brand200, width: 2),
              ),
              child: const Icon(Icons.groups_rounded, size: 48, color: brand500),
            ),
            const SizedBox(height: 20),
            const Text(
              'No crew found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first crew member\nto get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingAddBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [slateBg.withOpacity(0), slateBg, slateBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _showAddCrewDialog,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0284C7), Color(0xFF38BDF8), Color(0xFF0284C7)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: brand500.withOpacity(0.35), blurRadius: 14, offset: const Offset(0, 6)),
              ],
              border: Border.all(color: brandGlow.withOpacity(0.4)),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '+ Add New Crew Member',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}