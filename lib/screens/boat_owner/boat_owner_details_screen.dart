import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_service.dart';
import 'package:fishing_voyage_manag_sys/screens/boat_owner/boat_selection_screen.dart';

class BoatOwnerDetailsScreen extends StatefulWidget {
  const BoatOwnerDetailsScreen({super.key});

  @override
  State<BoatOwnerDetailsScreen> createState() => _BoatOwnerDetailsScreenState();
}

class _BoatOwnerDetailsScreenState extends State<BoatOwnerDetailsScreen> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController aadhaarController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String? selectedHomePortId;
  String? selectedHomePortName;
  String? selectedHomePortCode;
  String? selectedHomePortDistrict;
  bool isLoading = false;
  bool isLoadingPorts = false;

  // NEW: avatar preview path (UI only — not wired to backend)
  File? _avatarFile;

  List<Map<String, dynamic>> ports = [];
  List<Map<String, dynamic>> filteredPorts = [];

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // ─── MARITIME PALETTE (matches new HTML UI) ─────────────
  static const Color ocean900 = Color(0xFF0F2757);
  static const Color ocean800 = Color(0xFF1E3A8A);
  static const Color ocean700 = Color(0xFF1E40AF);
  static const Color ocean600 = Color(0xFF1D4ED8);
  static const Color ocean500 = Color(0xFF2563EB);
  static const Color ocean300 = Color(0xFF93C5FD);
  static const Color ocean200 = Color(0xFFBFDBFE);
  static const Color ocean100 = Color(0xFFE0EFFE);
  static const Color ocean50  = Color(0xFFF0F7FF);

  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate50  = Color(0xFFF8FAFC);

  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald50  = Color(0xFFECFDF5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color cyan400    = Color(0xFF22D3EE);
  static const Color cyan300    = Color(0xFF67E8F9);

  // Legacy aliases kept for any remaining references
  static const Color primaryBlue = ocean500;
  static const Color darkBlue    = ocean900;
  static const Color lightBlue   = ocean100;
  static const Color borderColor = slate200;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    addressController.dispose();
    aadhaarController.dispose();
    mobileController.dispose();
    searchController.dispose();
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await _loadMobileNumber();
    await _loadPorts();
  }

  Future<void> _loadMobileNumber() async {
    final session = await _db.getUserSession();
    if (session != null && session['mobile_no'] != null) {
      setState(() {
        mobileController.text = session['mobile_no'];
      });
    }
  }

  Future<void> _loadPorts() async {
    setState(() => isLoadingPorts = true);
    try {
      final response = await _apiService.getPorts();
      if (response['success'] == true) {
        final items = response['data']['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() {
            ports = List<Map<String, dynamic>>.from(items);
            filteredPorts = List<Map<String, dynamic>>.from(items);
          });
          print('✅ Ports loaded: ${ports.length} ports');
        } else {
          setState(() {
            ports = [];
            filteredPorts = [];
          });
          _showError('No ports available');
        }
      } else {
        setState(() {
          ports = [];
          filteredPorts = [];
        });
        _showError(response['message'] ?? 'Failed to load ports');
      }
    } catch (e) {
      setState(() {
        ports = [];
        filteredPorts = [];
      });
      _showError('Network error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoadingPorts = false);
    }
  }

  void _filterPorts(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredPorts = List<Map<String, dynamic>>.from(ports);
      } else {
        filteredPorts = ports.where((port) {
          final portName = port['port_name']?.toLowerCase() ?? '';
          final portCode = port['port_code']?.toLowerCase() ?? '';
          final district = port['district']?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          return portName.contains(searchLower) ||
              portCode.contains(searchLower) ||
              district.contains(searchLower);
        }).toList();
      }
    });
  }

  // ══════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: slate100,
      body: Stack(
        children: [
          // Maritime mesh background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: slate50,
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.9),
                  radius: 1.6,
                  colors: [Color(0x55E0EFFE), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(),
                        const SizedBox(height: 22),
                        _buildPhotoUpload(),
                        const SizedBox(height: 24),
                        _buildFormFields(),
                        const SizedBox(height: 16),
                        if (selectedHomePortId != null)
                          _buildSelectedPortInfo(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'Department of Fisheries',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: slate400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header — Maritime dark gradient with sonar accents ───
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF020617), Color(0xFF0A192F), Color(0xFF0F2444)],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x3322D3EE), width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Sonar / bathymetric accents
          Positioned.fill(
            child: CustomPaint(painter: _SonarAccentPainter()),
          ),
          Positioned(
            top: -40,
            left: -40,
            child: Container(
              width: 128, height: 128,
              decoration: BoxDecoration(
                color: cyan400.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 26, 16, 18),
            child: Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                // Titles
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Complete Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          SizedBox(
                            width: 7, height: 7,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: cyan400,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          SizedBox(width: 7),
                          Text(
                            'FISHERIES DEPARTMENT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: cyan300,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Verification badge
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF083344).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cyan400.withOpacity(0.40)),
                    boxShadow: [
                      BoxShadow(
                        color: cyan400.withOpacity(0.25),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.verified_user_rounded,
                      color: cyan300, size: 22),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Title Section ───
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Details',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: slate900,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please provide your information to complete the registration.',
          style: TextStyle(
            fontSize: 15,
            color: slate600,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              width: 56, height: 6,
              decoration: BoxDecoration(
                color: ocean600,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 16, height: 6,
              decoration: BoxDecoration(
                color: ocean300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 8, height: 6,
              decoration: BoxDecoration(
                color: ocean200,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Photo Upload ───
  Widget _buildPhotoUpload() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickAvatar,
            child: Stack(
              children: [
                // Outer glow ring
                Container(
                  width: 128, height: 128,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ocean100.withOpacity(0.9),
                        slate100,
                      ],
                    ),
                    border: Border.all(
                        color: ocean200.withOpacity(0.6), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: ocean500.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: slate100,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _avatarFile != null
                        ? Image.file(_avatarFile!, fit: BoxFit.cover)
                        : const Icon(Icons.person_rounded,
                        size: 60, color: slate400),
                  ),
                ),
                // Camera badge
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: ocean600,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: ocean600.withOpacity(0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload Official Photo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: slate700,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form Fields ───
  Widget _buildFormFields() {
    return Column(
      children: [
        _buildTextField(
          controller: ownerNameController,
          label: 'Owner Name',
          hint: 'Enter your full name',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: aadhaarController,
          label: 'Aadhaar Number',
          hint: '12-digit Aadhaar number',
          icon: Icons.assignment_ind_outlined,
          keyboardType: TextInputType.number,
          maxLength: 12,
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: mobileController,
          label: 'Mobile Number',
          hint: '10-digit number',
          icon: Icons.phone_android_outlined,
          enabled: false,
          trailing: _pill(
            label: 'Verified',
            fg: emerald600,
            bg: emerald50,
            border: emerald200,
          ),
        ),
        const SizedBox(height: 18),
        _buildTextField(
          controller: addressController,
          label: 'Address',
          hint: 'Enter your permanent address',
          icon: Icons.location_on_outlined,
          maxLines: 3,
        ),
        const SizedBox(height: 18),
        _buildPortSelector(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    int maxLines = 1,
    bool enabled = true,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: slate800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : slate100,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: slate200, width: 1),
            boxShadow: [
              BoxShadow(
                color: slate900.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(icon, size: 22, color: enabled ? ocean600 : slate400),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLength: maxLength,
                  maxLines: maxLines,
                  enabled: enabled,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: slate900,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        fontSize: 14.5, color: slate400),
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing,
                const SizedBox(width: 14),
              ] else
                const SizedBox(width: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPortSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Home Port',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: slate800,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showPortSelectionDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: slate200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: slate900.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.anchor_rounded,
                    size: 22, color: ocean600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedHomePortName ?? 'Select your home port',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w500,
                      color: selectedHomePortName != null
                          ? slate900
                          : slate400,
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: slate400, size: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Selected Port Info banner ───
  Widget _buildSelectedPortInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ocean50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ocean200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: ocean600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Selected Port: $selectedHomePortName ($selectedHomePortCode) - $selectedHomePortDistrict',
              style: const TextStyle(
                fontSize: 13.5,
                color: ocean900,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Save Button (sticky-looking, full width) ───
  Widget _buildSaveButton() {
    final bool submitted = !isLoading && false; // kept for future state
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        child: isLoading
            ? const SizedBox(
          width: 26, height: 26,
          child: CircularProgressIndicator(
              color: Colors.white, strokeWidth: 2.4),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_rounded,
                color: Color(0xFF6EE7B7), size: 22),
            SizedBox(width: 10),
            Text(
              'Complete Registration',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Port Selection Modal ───
  void _showPortSelectionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 44, height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: slate300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: ocean50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: ocean100),
                      ),
                      child: const Icon(Icons.anchor_rounded,
                          color: ocean600, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Select Home Port',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                      ),
                    ),
                    const Spacer(),
                    if (isLoadingPorts)
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: ocean600),
                      ),
                  ],
                ),
              ),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: slate100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: slate200),
                  ),
                  child: TextField(
                    onChanged: (val) {
                      _filterPorts(val);
                      setModalState(() {});
                    },
                    style: const TextStyle(fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Search by port name or code...',
                      hintStyle:
                      TextStyle(color: slate400, fontSize: 14.5),
                      prefixIcon:
                      Icon(Icons.search_rounded, color: slate500),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // List
              Expanded(
                child: filteredPorts.isEmpty
                    ? const Center(
                    child: Text('No ports found',
                        style: TextStyle(
                            fontSize: 15, color: slate500)))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 4),
                  itemCount: filteredPorts.length,
                  itemBuilder: (context, index) {
                    final port = filteredPorts[index];
                    final isSelected =
                        selectedHomePortId ==
                            port['port_id']?.toString();
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedHomePortId =
                              port['port_id']?.toString();
                          selectedHomePortName = port['port_name'];
                          selectedHomePortCode = port['port_code'];
                          selectedHomePortDistrict = port['district'];
                        });
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin:
                        const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ocean50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? ocean500
                                : slate200,
                            width: isSelected ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ocean600
                                    : slate100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.anchor_rounded,
                                size: 20,
                                color: isSelected
                                    ? Colors.white
                                    : slate500,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    port['port_name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? ocean700
                                          : slate900,
                                    ),
                                  ),
                                  if ((port['port_code'] ?? '')
                                      .toString()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      port['port_code'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: slate500,
                                        fontWeight:
                                        FontWeight.w500,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                  Icons.check_circle_rounded,
                                  color: ocean600, size: 24),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Avatar Picker (UI-only helper) ───
  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked =
      await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (_) {
      // Silently ignore — UI-only
    }
  }

  // ─── Small pill helper ───
  Widget _pill({
    required String label,
    required Color fg,
    required Color bg,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  SAVE LOGIC (UNCHANGED)
  // ══════════════════════════════════════════════════════════════

  Future<void> _saveProfile() async {
    final name = ownerNameController.text.trim();
    final aadhaar = aadhaarController.text.trim();
    final address = addressController.text.trim();
    final mobile = mobileController.text.trim();

    if (name.isEmpty ||
        aadhaar.isEmpty ||
        address.isEmpty ||
        selectedHomePortId == null) {
      _showError('Please fill all required fields');
      return;
    }

    if (aadhaar.length != 12) {
      _showError('Aadhaar number must be 12 digits');
      return;
    }

    setState(() => isLoading = true);
    try {
      final session = await _db.getUserSession();
      final setupToken = session?['setup_token'] ?? '';

      final response = await _apiService.createProfile(
        ownerName: name,
        aadhaarNo: aadhaar,
        primaryPortId: int.parse(selectedHomePortId!),
        mobileNo: mobile,
        address: address,
        setupToken: setupToken,
      );

      if (response['success'] == true) {
        // Update local boat owner info
        await _db.insertBoatOwner({
          'owner_name': name,
          'address': address,
          'aadhaar': aadhaar,
          'mobile': mobile,
          'home_port_id': selectedHomePortId,
          'home_port_name': selectedHomePortName,
          'photo_path': _avatarFile?.path,
        });

        _showSuccess('Profile completed successfully');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => const BoatSelectionScreen()),
          );
        }
      } else {
        _showError(response['message'] ?? 'Profile creation failed');
      }
    } catch (e) {
      _showError('An error occurred: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: emerald600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  Sonar accent painter (header decoration)
// ══════════════════════════════════════════════════════════════
class _SonarAccentPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF22D3EE).withOpacity(0.20);

    // Radar rings on the top-right
    final center = Offset(size.width - 30, 20);
    canvas.drawCircle(center, 40, paint);
    canvas.drawCircle(
      center,
      80,
      paint..color = const Color(0xFF22D3EE).withOpacity(0.12),
    );

    // Wave path (bottom)
    final wave = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.55,
          size.width * 0.5, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.85,
          size.width, size.height * 0.7);
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF38BDF8).withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}