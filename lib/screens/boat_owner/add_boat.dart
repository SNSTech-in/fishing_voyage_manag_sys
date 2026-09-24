// lib/screens/boat_owner/add_boat.dart

import 'package:flutter/material.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';

class AddBoat extends StatefulWidget {
  const AddBoat({super.key});

  @override
  State<AddBoat> createState() => _AddBoatState();
}

class _AddBoatState extends State<AddBoat> {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  List<Map<String, dynamic>> boats = [];

  bool isLoading = true;
  String? errorMessage;

  String? ownerName;

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

  // Per-boat duotone palette (sky, emerald, amber, indigo, red)
  static const List<Map<String, Color>> boatPalette = [
    {'fg': Color(0xFF0284C7), 'bg1': Color(0xFFF0F9FF), 'bg2': Color(0xFFDBEAFE), 'border': Color(0xFFBAE6FD)},
    {'fg': Color(0xFF059669), 'bg1': Color(0xFFECFDF5), 'bg2': Color(0xFFCCFBF1), 'border': Color(0xFFA7F3D0)},
    {'fg': Color(0xFFD97706), 'bg1': Color(0xFFFFFBEB), 'bg2': Color(0xFFFFEDD5), 'border': Color(0xFFFDE68A)},
    {'fg': Color(0xFF4F46E5), 'bg1': Color(0xFFEEF2FF), 'bg2': Color(0xFFF3E8FF), 'border': Color(0xFFC7D2FE)},
    {'fg': Color(0xFFDC2626), 'bg1': Color(0xFFFEF2F2), 'bg2': Color(0xFFFEE2E2), 'border': Color(0xFFFECACA)},
  ];

  // Selection state
  final Set<dynamic> _selectedBoatIds = {};

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
    _loadBoats();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  //  OWNER DETAILS
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadOwnerDetails() async {
    try {
      final owner = await _db.getBoatOwner();
      if (owner != null && mounted) {
        setState(() => ownerName = owner['owner_name']?.toString());
      }
    } catch (e) {
      debugPrint('Error loading owner details: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  LOAD BOATS
  // ══════════════════════════════════════════════════════════════

  Future<void> _loadBoats({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      if (refresh) boats.clear();
    });

    try {
      final response = await _apiService.getBoats(page: 1, pageSize: 100);
      debugPrint('📥 Boats API Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];
        final items = data is Map ? data['items'] as List? : null;

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
            };
          }).toList();

          setState(() {
            boats = mappedBoats;
            isLoading = false;
          });
        } else {
          setState(() {
            boats = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = response['message'] ?? 'Failed to load boats';
        });
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error loading boats: $e');
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading boats: ${e.toString()}';
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  ADD BOAT DIALOG
  // ══════════════════════════════════════════════════════════════

  Future<void> _showAddBoatDialog() async {
    final boatRegNoController        = TextEditingController();
    final boatNameController         = TextEditingController();
    final licenceIdController        = TextEditingController();
    final licenceIssueDateController = TextEditingController();
    final licenceValidUptoController = TextEditingController();

    bool isLoadingLocal = false;

    Future<void> selectDate(TextEditingController controller) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2035),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        controller.text = picked.toIso8601String().split('T').first;
      }
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
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
                // ─── Dialog Header ───
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildAddBoatField(label: 'Boat Registration No', hint: 'e.g., IND-KA-2231', controller: boatRegNoController, icon: Icons.assignment_rounded, isRequired: true),
                        const SizedBox(height: 12),
                        _buildAddBoatField(label: 'Boat Name', hint: 'e.g., Sagar Kanya', controller: boatNameController, icon: Icons.directions_boat_rounded, isRequired: true),
                        const SizedBox(height: 12),
                        _buildAddBoatField(label: 'License ID', hint: 'e.g., FL-KA-77120', controller: licenceIdController, icon: Icons.document_scanner_rounded, isRequired: true),
                        const SizedBox(height: 12),
                        _buildAddBoatField(label: 'Issue Date', hint: 'YYYY-MM-DD', controller: licenceIssueDateController, icon: Icons.calendar_today_rounded, isRequired: true, readOnly: true, onTap: () => selectDate(licenceIssueDateController)),
                        const SizedBox(height: 12),
                        _buildAddBoatField(label: 'Valid Upto', hint: 'YYYY-MM-DD', controller: licenceValidUptoController, icon: Icons.calendar_today_rounded, isRequired: true, readOnly: true, onTap: () => selectDate(licenceValidUptoController)),
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
                          onPressed: isLoadingLocal ? null : () => Navigator.pop(dialogContext),
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
                          onPressed: isLoadingLocal ? null : () async {
                            if (boatRegNoController.text.trim().isEmpty) { _showError('Please enter boat registration number'); return; }
                            if (boatNameController.text.trim().isEmpty) { _showError('Please enter boat name'); return; }
                            if (licenceIdController.text.trim().isEmpty) { _showError('Please enter license ID'); return; }
                            if (licenceIssueDateController.text.trim().isEmpty) { _showError('Please select license issue date'); return; }
                            if (licenceValidUptoController.text.trim().isEmpty) { _showError('Please select license valid date'); return; }

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
                                await _loadBoats(refresh: true);
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
        ),
      ),
    );

    boatRegNoController.dispose();
    boatNameController.dispose();
    licenceIdController.dispose();
    licenceIssueDateController.dispose();
    licenceValidUptoController.dispose();
  }

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
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
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
            if (boats.isNotEmpty) _buildFloatingActionBar(),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  NEW HEADER — Deep Ocean Gradient
  // ══════════════════════════════════════════════════════════════

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
            child: Container(width: 190, height: 190, decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withOpacity(0.20), shape: BoxShape.circle)),
          ),
          Positioned(
            bottom: -40, left: -40,
            child: Container(width: 170, height: 170, decoration: BoxDecoration(color: const Color(0xFF2DD4BF).withOpacity(0.15), shape: BoxShape.circle)),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('16:50', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          Icon(Icons.signal_cellular_alt_rounded, color: Colors.white70, size: 15),
                          SizedBox(width: 4),
                          Icon(Icons.wifi_rounded, color: Colors.white70, size: 15),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full_rounded, color: Colors.white70, size: 15),
                          SizedBox(width: 2),
                          Text('99%', style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Row(
                          children: [
                            Text('My Boats', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            SizedBox(width: 6),
                            _PulseDot(),
                          ],
                        ),
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  BODY
  // ══════════════════════════════════════════════════════════════

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
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  WELCOME HERO
  // ══════════════════════════════════════════════════════════════

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
                                    'Welcome ${ownerName ?? "Ram"}!',
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Padding(
                              padding: EdgeInsets.only(left: 38),
                              child: Text('Manage your boats here.', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
                            Text('${boats.length} Registered', style: const TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const TextField(
                      style: TextStyle(fontSize: 12, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search boat by name or license...',
                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        prefixIcon: Icon(Icons.search_rounded, size: 17, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
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

  // ══════════════════════════════════════════════════════════════
  //  BOAT SECTION HEADER
  // ══════════════════════════════════════════════════════════════

  Widget _buildBoatSectionHeader() {
    final int selectedCount = _selectedBoatIds.length;
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
                  _selectedBoatIds.clear();
                } else {
                  _selectedBoatIds..clear()..addAll(boats.map((b) => b['id']));
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

  // ══════════════════════════════════════════════════════════════
  //  BOAT CARD
  // ══════════════════════════════════════════════════════════════

  Widget _buildBoatCard(Map<String, dynamic> boat, int index) {
    final palette    = boatPalette[index % boatPalette.length];
    final Color fg   = palette['fg']!;
    final Color bg1  = palette['bg1']!;
    final Color bg2  = palette['bg2']!;
    final Color bdr  = palette['border']!;

    final bool isExpired = boat['licence_expired'] == true;
    final bool isActive  = boat['status']?.toString().toUpperCase() == 'ACTIVE';
    final bool isSelected = _selectedBoatIds.contains(boat['id']);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedBoatIds.remove(boat['id']);
          } else {
            _selectedBoatIds.add(boat['id']);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F9FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF0284C7) : bdr,
            width: isSelected ? 1.6 : 1,
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
                    color: isSelected ? const Color(0xFF0B3B8C) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B3B8C) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isSelected
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

  // ══════════════════════════════════════════════════════════════
  //  BOAT DETAIL ROW
  // ══════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════
  //  STATUS BADGE
  // ══════════════════════════════════════════════════════════════

  Widget _statusBadge(String text, Color fg, Color bg) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 8, color: fg, fontWeight: FontWeight.w700)),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  FLOATING ACTION BAR
  // ══════════════════════════════════════════════════════════════

  Widget _buildFloatingActionBar() {
    final int selectedCount = _selectedBoatIds.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: actionNavy.withOpacity(0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
          boxShadow: [BoxShadow(color: const Color(0xFF0B1F3A).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.20),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.sailing_rounded, color: Color(0xFF38BDF8), size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCount > 0
                        ? '$selectedCount Boat${selectedCount > 1 ? 's' : ''} Ready'
                        : 'Select boat for voyage',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 1),
                  const Text('Ready for port clearance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (selectedCount == 0) {
                  _showError('Please select at least one boat');
                  return;
                }
                _showSuccess('$selectedCount boat(s) ready to proceed');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF67E8F9)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: const Row(
                  children: [
                    Text('Proceed', style: TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w800)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_rounded, color: Color(0xFF0F172A), size: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  ERROR
  // ══════════════════════════════════════════════════════════════

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadBoats(refresh: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  EMPTY
  // ══════════════════════════════════════════════════════════════

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
            Text('Add your first boat to get started.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _showAddBoatDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Boat', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SNACKBARS
  // ══════════════════════════════════════════════════════════════

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
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
        width: 7,
        height: 7,
        decoration: const BoxDecoration(
          color: Color(0xFF34D399),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}