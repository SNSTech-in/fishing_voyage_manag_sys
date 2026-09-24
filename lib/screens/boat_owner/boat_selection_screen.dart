// lib/screens/boat_owner/boat_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';
import 'package:fishing_voyage_manag_sys/screens/depart_login_selection.dart';
import 'dashboard_screen.dart';

class BoatSelectionScreen extends StatefulWidget {
  final bool isSelectionMode;

  const BoatSelectionScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<BoatSelectionScreen> createState() => _BoatSelectionScreenState();
}

class _BoatSelectionScreenState extends State<BoatSelectionScreen> {
  List<Map<String, dynamic>> boats = [];
  final Set<dynamic> selectedBoatIds = <dynamic>{};
  bool isLoading = true;
  bool isAccepting = false;
  bool isLoggingOut = false;
  bool isAddingBoat = false;
  String? ownerName;
  String? ownerMobile;
  String? ownerAddress;
  String? errorMessage;
  int currentPage = 1;
  int totalPages = 1;
  int totalBoats = 0;

  // ─── NEW UI PALETTE ───────────────────────────────────────────
  static const Color primaryBlue   = Color(0xFF0EA5E9);
  static const Color darkNavy      = Color(0xFF061E3D);
  static const Color midNavy       = Color(0xFF082952);
  static const Color deepNavy      = Color(0xFF0B3C75);
  static const Color actionNavy    = Color(0xFF062660);
  static const Color surfaceBg     = Color(0xFFF8FAFC);
  static const Color textPrimary   = Color(0xFF011C37);
  static const Color textMuted     = Color(0xFF5F6B7A);
  static const Color activeGreen   = Color(0xFF10B981);
  static const Color activeGreenBg = Color(0xFFECFDF5);

  // Kept for backwards compat with any other references
  static const Color darkBlue  = Color(0xFF061E3D);
  static const Color lightBlue = Color(0xFFE8F3FF);

  // Per-boat duotone palette
  static const List<Map<String, Color>> boatPalette = [
    {'fg': Color(0xFF0284C7), 'bg1': Color(0xFFF0F9FF), 'bg2': Color(0xFFDBEAFE), 'border': Color(0xFFBAE6FD)},
    {'fg': Color(0xFF059669), 'bg1': Color(0xFFECFDF5), 'bg2': Color(0xFFCCFBF1), 'border': Color(0xFFA7F3D0)},
    {'fg': Color(0xFFD97706), 'bg1': Color(0xFFFFFBEB), 'bg2': Color(0xFFFFEDD5), 'border': Color(0xFFFDE68A)},
    {'fg': Color(0xFF4F46E5), 'bg1': Color(0xFFEEF2FF), 'bg2': Color(0xFFF3E8FF), 'border': Color(0xFFC7D2FE)},
    {'fg': Color(0xFFDC2626), 'bg1': Color(0xFFFEF2F2), 'bg2': Color(0xFFFEE2E2), 'border': Color(0xFFFECACA)},
  ];

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
    _loadBoats();
    if (!widget.isSelectionMode) {
      _loadSelectedFromDatabase();
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  LOGIC (UNCHANGED)
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadOwnerDetails() async {
    try {
      final owner = await _db.getBoatOwner();
      if (owner != null && mounted) {
        setState(() {
          ownerName = owner['owner_name']?.toString();
          ownerMobile = owner['mobile']?.toString();
          ownerAddress = owner['address']?.toString();
        });
      }
    } catch (e) {
      print('Error loading owner details: $e');
    }
  }

  Future<void> _loadBoats({bool refresh = false}) async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
      if (refresh) {
        boats = [];
        selectedBoatIds.clear();
        currentPage = 1;
      }
    });

    try {
      final response = await _apiService.getBoats(page: currentPage, pageSize: 20);
      print('📥 Boats API Response: $response');

      if (response['success'] == true) {
        final data = response['data'];
        final items = data['items'] as List?;
        totalBoats = data['total'] ?? 0;
        totalPages = data['total_pages'] ?? 1;

        if (items != null && items.isNotEmpty) {
          final loadedBoats = List<Map<String, dynamic>>.from(items);
          final mappedBoats = loadedBoats.map((boat) {
            return {
              'id': boat['boat_id'],
              'boat_id': boat['boat_id'],
              'boat_name': boat['boat_name'] ?? 'Boat',
              'registration_number': boat['boat_reg_no'] ?? 'N/A',
              'length': boat['length'] ?? 'N/A',
              'engine': boat['engine'] ?? 'N/A',
              'home_port': boat['home_port'] ?? 'N/A',
              'owner_name': boat['owner_name'] ?? ownerName,
              'licence_id': boat['licence_id'] ?? 'N/A',
              'licence_type': boat['licence_type'] ?? 'N/A',
              'licence_issue_date': boat['licence_issue_date'] ?? 'N/A',
              'licence_valid_upto': boat['licence_valid_upto'] ?? 'N/A',
              'licence_expired': boat['licence_expired'] ?? false,
              'nic_verified': boat['nic_verified'] ?? false,
              'status': boat['status'] ?? 'ACTIVE',
              'is_selected': 0,
            };
          }).toList();

          if (!mounted) return;
          setState(() {
            if (refresh) {
              boats = mappedBoats;
            } else {
              boats = [...boats, ...mappedBoats];
            }
            if (!widget.isSelectionMode) {
              _loadSelectedFromDatabase();
            }
            isLoading = false;
          });
        } else {
          if (!mounted) return;
          setState(() {
            isLoading = false;
            errorMessage = null;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          errorMessage = response['message'] ?? 'Failed to load boats';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading boats: ${e.toString()}';
      });
    }
  }

  Future<void> _loadSelectedFromDatabase() async {
    try {
      final selectedBoats = await _db.getSelectedBoats();
      for (var boat in selectedBoats) {
        final boatId = boat['boat_id'];
        if (boatId != null) {
          selectedBoatIds.add(boatId);
        }
      }
    } catch (e) {
      print('Error loading selected from database: $e');
    }
  }

  Future<void> _showAddBoatDialog() async {
    final TextEditingController boatRegNoController = TextEditingController();
    final TextEditingController boatNameController = TextEditingController();
    final TextEditingController licenceIdController = TextEditingController();
    final TextEditingController licenceIssueDateController = TextEditingController();
    final TextEditingController licenceValidUptoController = TextEditingController();
    bool isLoadingLocal = false;

    Future<void> selectDate(TextEditingController controller) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: primaryBlue,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );
      if (picked != null) {
        controller.text = picked.toIso8601String().split('T').first;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ─── Dialog Header (new style) ───
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [darkNavy, midNavy, deepNavy],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42, height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.18)),
                            ),
                            child: const Icon(Icons.directions_boat_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Add Boat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('Register a new vessel to your fleet', style: TextStyle(fontSize: 11, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ─── Form Fields ───
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildAddBoatField(
                              label: 'Boat Registration No',
                              hint: 'e.g., IND-KA-2231',
                              controller: boatRegNoController,
                              icon: Icons.assignment_rounded,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildAddBoatField(
                              label: 'Boat Name',
                              hint: 'e.g., Sagar Kanya',
                              controller: boatNameController,
                              icon: Icons.directions_boat_rounded,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildAddBoatField(
                              label: 'License ID',
                              hint: 'e.g., FL-KA-77120',
                              controller: licenceIdController,
                              icon: Icons.document_scanner_rounded,
                              isRequired: true,
                            ),
                            const SizedBox(height: 12),
                            _buildAddBoatField(
                              label: 'Issue Date',
                              hint: 'YYYY-MM-DD',
                              controller: licenceIssueDateController,
                              icon: Icons.calendar_today_rounded,
                              isRequired: true,
                              readOnly: true,
                              onTap: () => selectDate(licenceIssueDateController),
                            ),
                            const SizedBox(height: 12),
                            _buildAddBoatField(
                              label: 'Valid Upto',
                              hint: 'YYYY-MM-DD',
                              controller: licenceValidUptoController,
                              icon: Icons.calendar_today_rounded,
                              isRequired: true,
                              readOnly: true,
                              onTap: () => selectDate(licenceValidUptoController),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ─── Action Buttons ───
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoadingLocal
                                  ? null
                                  : () async {
                                if (boatRegNoController.text.trim().isEmpty) {
                                  _showError('Please enter boat registration number');
                                  return;
                                }
                                if (boatNameController.text.trim().isEmpty) {
                                  _showError('Please enter boat name');
                                  return;
                                }
                                if (licenceIdController.text.trim().isEmpty) {
                                  _showError('Please enter license ID');
                                  return;
                                }
                                if (licenceIssueDateController.text.trim().isEmpty) {
                                  _showError('Please select license issue date');
                                  return;
                                }
                                if (licenceValidUptoController.text.trim().isEmpty) {
                                  _showError('Please select license valid date');
                                  return;
                                }

                                setStateDialog(() => isLoadingLocal = true);

                                try {
                                  final response = await _apiService.addBoat(
                                    boatRegNo: boatRegNoController.text.trim(),
                                    boatName: boatNameController.text.trim(),
                                    licenceId: licenceIdController.text.trim(),
                                    licenceIssueDate: licenceIssueDateController.text.trim(),
                                    licenceValidUpto: licenceValidUptoController.text.trim(),
                                  );

                                  if (response['success'] == true) {
                                    if (!mounted) return;
                                    Navigator.pop(dialogContext);
                                    _showSuccess('Boat added successfully!');
                                    _loadBoats(refresh: true);
                                  } else {
                                    setStateDialog(() => isLoadingLocal = false);
                                    _showError(response['message'] ?? 'Failed to add boat');
                                  }
                                } catch (e) {
                                  setStateDialog(() => isLoadingLocal = false);
                                  _showError('Error: ${e.toString()}');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoadingLocal
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Add Boat', style: TextStyle(fontWeight: FontWeight.w700)),
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
      },
    );
  }

  // ─── Add Boat Field (new styling) ───
  Widget _buildAddBoatField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: darkNavy)),
            if (isRequired) const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 13, color: textPrimary, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (readOnly)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18, color: primaryBlue),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }

  void _toggleBoatSelection(dynamic boatId) {
    if (boatId == null) return;
    setState(() {
      if (selectedBoatIds.contains(boatId)) {
        selectedBoatIds.remove(boatId);
      } else {
        selectedBoatIds.add(boatId);
      }
    });
  }

  Future<void> _logout() async {
    if (isLoggingOut) return;
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: primaryBlue),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: const Text('Are you sure you want to logout? Your voyage data will remain on this device.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
    if (shouldLogout != true) return;
    if (!mounted) return;
    setState(() => isLoggingOut = true);
    try {
      await _db.clearUserSessionOnly();
      selectedBoatIds.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DepartLoginSelection()),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoggingOut = false);
      _showError('Logout failed: $e');
    }
  }

  Future<void> _acceptSelection() async {
    if (selectedBoatIds.isEmpty) {
      _showError('Please select at least one boat');
      return;
    }
    if (isAccepting) return;
    setState(() => isAccepting = true);

    try {
      if (!widget.isSelectionMode) {
        await _db.clearSelectedBoats();
      }
      for (final boatId in selectedBoatIds) {
        if (boatId == null) continue;
        final boat = boats.firstWhere(
              (b) => b['id'] == boatId || b['boat_id'] == boatId,
          orElse: () => {},
        );
        if (boat.isNotEmpty) {
          await _db.insertBoatSelection({
            'boat_id': boatId,
            'boat_name': boat['boat_name'] ?? 'Boat',
            'registration_number': boat['registration_number'] ?? 'N/A',
          });
        }
      }
      if (!mounted) return;
      setState(() => isAccepting = false);
      _showSuccess('${selectedBoatIds.length} boat(s) selected successfully');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isAccepting = false);
      _showError('Error saving selection: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildNewHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─── NEW HEADER: Deep Ocean Gradient + Glass App Bar ───
  Widget _buildNewHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [darkNavy, midNavy, deepNavy],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50, right: -50,
            child: Container(
              width: 190, height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.20),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: Container(
              width: 170, height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFF2DD4BF).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  // Menu (opens drawer)
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () => Scaffold.of(context).openDrawer(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          widget.isSelectionMode ? 'Select Boat' : 'My Boats',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const _PulseDot(),
                      ],
                    ),
                  ),
                  // Refresh
                  GestureDetector(
                    onTap: isLoading ? null : () => _loadBoats(refresh: true),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: isLoading
                          ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Add Boat
                  GestureDetector(
                    onTap: _showAddBoatDialog,
                    child: Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF67E8F9)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, color: Color(0xFF0F172A), size: 18),
                          SizedBox(width: 4),
                          Text('Add Boat', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Drawer (light restyle, same logic) ───
  Widget _buildDrawer() {
    return Drawer(
      width: 300,
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [darkNavy, midNavy, deepNavy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58, height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ownerName ?? 'Boat Owner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  if (ownerMobile != null) ...[
                    const SizedBox(height: 3),
                    Text(ownerMobile!, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  _buildDrawerItem(
                    icon: Icons.directions_boat_rounded,
                    title: 'My Boats',
                    count: totalBoats,
                    selected: true,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    icon: Icons.add_rounded,
                    title: 'Add Boat',
                    onTap: () {
                      Navigator.pop(context);
                      _showAddBoatDialog();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile Details',
                    onTap: () {
                      Navigator.pop(context);
                      _showProfileDetails();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _buildDrawerItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? count,
    bool selected = false,
    Color color = darkNavy,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFE0F2FE) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 4,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, size: 22, color: selected ? primaryBlue : color),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? primaryBlue : color,
          ),
        ),
        trailing: count != null
            ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showProfileDetails() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE8F3FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.person_rounded, color: primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              const Text('Profile Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: darkNavy)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileDetail('Name', ownerName ?? 'Not available'),
              const Divider(height: 16),
              _buildProfileDetail('Mobile', ownerMobile ?? 'Not available'),
              const Divider(height: 16),
              _buildProfileDetail('Address', ownerAddress ?? 'Not available'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: darkNavy)),
      ],
    );
  }

  // ─── BODY (NEW UI) ───
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 16),
            Text('Loading boats...', style: TextStyle(color: textMuted, fontSize: 14)),
          ],
        ),
      );
    }
    if (errorMessage != null) return _buildError();
    if (boats.isEmpty) return _buildEmpty();

    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: () => _loadBoats(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 140),
        children: [
          _buildWelcomeHero(),
          const SizedBox(height: 14),
          _buildBoatSectionHeader(),
          const SizedBox(height: 10),
          ...boats.asMap().entries.map((entry) => _buildBoatCard(entry.value, entry.key)),
          if (currentPage < totalPages) ...[
            const SizedBox(height: 4),
            _buildLoadMoreButton(),
          ],
          const SizedBox(height: 12),
          _buildConfirmSection(),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: () {
          currentPage++;
          _loadBoats(refresh: false);
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: primaryBlue),
          foregroundColor: primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: const Text('Load More Boats', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ─── Welcome Hero Card ───
  Widget _buildWelcomeHero() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF2DD4BF), Color(0xFF2563EB)]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 30, height: 30,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF0F9FF),
                                    borderRadius: BorderRadius.circular(9),
                                    border: Border.all(color: const Color(0xFFE0F2FE)),
                                  ),
                                  child: const Icon(Icons.waving_hand_rounded, size: 17, color: Color(0xFF0284C7)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Welcome ${ownerName ?? "Boat Owner"}!',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.only(left: 38),
                              child: Text(
                                widget.isSelectionMode ? 'Select your boat to continue.' : 'Manage your boats here.',
                                style: const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: activeGreenBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: activeGreen, shape: BoxShape.circle)),
                            const SizedBox(width: 5),
                            Text('${boats.length} Loaded', style: const TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
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
    );
  }

  // ─── Boat Section Header ───
  Widget _buildBoatSectionHeader() {
    final int selectedCount = selectedBoatIds.length;
    final bool allSelected = boats.isNotEmpty && selectedCount == boats.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0B3B8C), Color(0xFF0EA5E9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [BoxShadow(color: const Color(0xFF0B3B8C).withOpacity(0.20), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.directions_boat_rounded, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Boat Details', style: TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                Text('Select vessels for clearance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (allSelected) {
                  selectedBoatIds.clear();
                } else {
                  selectedBoatIds.clear();
                  selectedBoatIds.addAll(boats.map((b) => b['id'] ?? b['boat_id']));
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                allSelected ? 'Deselect all' : 'Select all',
                style: const TextStyle(color: Color(0xFF0284C7), fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selectedCount > 0 ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selectedCount > 0 ? const Color(0xFF7DD3FC) : const Color(0xFFE2E8F0)),
            ),
            child: Text(
              '$selectedCount selected',
              style: TextStyle(
                color: selectedCount > 0 ? const Color(0xFF075985) : const Color(0xFF64748B),
                fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Boat Card (New UI) ───
  Widget _buildBoatCard(Map<String, dynamic> boat, int index) {
    final palette    = boatPalette[index % boatPalette.length];
    final Color fg   = palette['fg']!;
    final Color bg1  = palette['bg1']!;
    final Color bg2  = palette['bg2']!;
    final Color bdr  = palette['border']!;

    final dynamic boatId = boat['id'] ?? boat['boat_id'];
    final bool selected = selectedBoatIds.contains(boatId);
    final bool isExpired = boat['licence_expired'] == true;
    final bool isActive = boat['status']?.toString().toUpperCase() == 'ACTIVE';

    return GestureDetector(
      onTap: boatId == null ? null : () => _toggleBoatSelection(boatId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF0284C7) : bdr,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [bg1, bg2], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: bdr),
                ),
                child: Icon(Icons.directions_boat_rounded, size: 26, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            boat['boat_name']?.toString() ?? 'Boat ${index + 1}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                          ),
                        ),
                        if (!isActive)
                          _statusBadge('INACTIVE', const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
                        if (isExpired)
                          _statusBadge('EXPIRED', const Color(0xFFD97706), const Color(0xFFFFEDD5)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        boat['registration_number']?.toString() ?? 'N/A',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w700, fontFamily: 'monospace', letterSpacing: 0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.badge_rounded, 'License', boat['licence_id']?.toString() ?? 'N/A', isMono: true),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 5),
                        const SizedBox(width: 58, child: Text('Valid Till', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500))),
                        const Text(':', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                        const SizedBox(width: 5),
                        Text(
                          boat['licence_valid_upto']?.toString() ?? 'N/A',
                          style: const TextStyle(color: Color(0xFF334155), fontSize: 10, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 6),
                        if (isActive && !isExpired)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(color: activeGreenBg, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Active', style: TextStyle(color: Color(0xFF047857), fontSize: 8, fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildDetailRow(Icons.anchor_rounded, 'Home Port', boat['home_port']?.toString() ?? 'N/A', isItalicIfNA: true),
                    if (boat['nic_verified'] == true) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 13),
                          SizedBox(width: 4),
                          Text('NIC Verified', style: TextStyle(fontSize: 10, color: Color(0xFF047857), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF0B3B8C) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF0B3B8C) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Detail Row ───
  Widget _buildDetailRow(
      IconData icon,
      String title,
      String value, {
        bool isMono = false,
        bool isItalicIfNA = false,
      }) {
    final bool isNA = value.toUpperCase() == 'N/A';
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 5),
        SizedBox(
          width: 58,
          child: Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w500)),
        ),
        const Text(':', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isNA ? const Color(0xFF94A3B8) : const Color(0xFF334155),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              fontFamily: isMono ? 'monospace' : null,
              fontStyle: (isItalicIfNA && isNA) ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color fg, Color bg) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 8, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  // ─── Confirm Section (New UI restyle) ───
  Widget _buildConfirmSection() {
    final selectedCount = selectedBoatIds.length;
    final bool enabled = selectedCount > 0 && !isAccepting;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryBlue.withOpacity(0.12),
                    border: Border.all(color: primaryBlue, width: 2),
                  ),
                  child: const Center(
                    child: Text('i', style: TextStyle(color: primaryBlue, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Please Confirm', style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.w700)),
                      Text(
                        widget.isSelectionMode
                            ? 'Select boats above & tap Accept.'
                            : 'Select boats above & tap Update.',
                        style: const TextStyle(color: Color(0xFF075985), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: enabled ? _acceptSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                disabledBackgroundColor: const Color(0xFFB9C3D1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                shadowColor: primaryBlue.withOpacity(0.3),
              ),
              child: isAccepting
                  ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 23, height: 23,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    selectedCount > 0
                        ? (widget.isSelectionMode
                        ? 'Accept ($selectedCount selected)'
                        : 'Update ($selectedCount selected)')
                        : 'Select a boat',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ───
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadBoats(refresh: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty ───
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: const BoxDecoration(color: Color(0xFFE8F3FF), shape: BoxShape.circle),
              child: const Icon(Icons.directions_boat_outlined, size: 60, color: primaryBlue),
            ),
            const SizedBox(height: 24),
            const Text('No Boats Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: darkNavy)),
            const SizedBox(height: 8),
            Text('Get started by adding your first boat.', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 32),
            SizedBox(
              width: 200, height: 50,
              child: ElevatedButton.icon(
                onPressed: _showAddBoatDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text('Add Boat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadBoats(refresh: true),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  PULSE DOT WIDGET
// ══════════════════════════════════════════════════════════════

class _PulseDot extends StatefulWidget {
  const _PulseDot();

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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 7, height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF34D399),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}