// lib/screens/boat_owner/boat_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:fishing_voyage_manag_sys/database/database_helper.dart';
import 'package:fishing_voyage_manag_sys/services/api_services/api_service.dart';
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

  static const Color primaryBlue = Color(0xFF1257C7);
  static const Color darkBlue = Color(0xFF07347F);
  static const Color lightBlue = Color(0xFFE8F3FF);

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
    _loadBoats();

    // If not in selection mode, load selected boats from database
    if (!widget.isSelectionMode) {
      _loadSelectedFromDatabase();
    }
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  // ============================================================
  // OWNER DETAILS
  // ============================================================

  Future<void> _loadOwnerDetails() async {
    try {
      final owner = await _db.getBoatOwner();

      if (owner != null) {
        if (!mounted) return;

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

  // ============================================================
  // LOAD BOATS
  // ============================================================

  Future<void> _loadBoats({
    bool refresh = false,
  }) async {
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
      final response = await _apiService.getBoats(
        page: currentPage,
        pageSize: 20,
      );

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

            // If not in selection mode, load selected from database
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

  // ============================================================
  // LOAD SELECTED FROM DATABASE
  // ============================================================

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

  // ============================================================
  // ADD BOAT DIALOG
  // ============================================================

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
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.directions_boat_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Boat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: darkBlue,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                constraints: const BoxConstraints(
                  maxHeight: 500,
                ),
                child: SingleChildScrollView(
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
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: lightBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: primaryBlue,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'All fields are required to add a boat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF24365B),
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
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

                    setStateDialog(() {
                      isLoadingLocal = true;
                    });

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
                        setStateDialog(() {
                          isLoadingLocal = false;
                        });
                        _showError(response['message'] ?? 'Failed to add boat');
                      }
                    } catch (e) {
                      setStateDialog(() {
                        isLoadingLocal = false;
                      });
                      _showError('Error: ${e.toString()}');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoadingLocal
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Add Boat'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // ADD BOAT FIELD
  // ============================================================

  Widget _buildAddBoatField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool isRequired = false,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 18,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  onTap: onTap,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (readOnly)
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TOGGLE BOAT
  // ============================================================

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

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    if (isLoggingOut) return;

    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: primaryBlue,
              ),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?\n\n'
                'All saved data will be removed from this device.',
          ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    if (!mounted) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
      await _db.clearAllData();

      selectedBoatIds.clear();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const DepartLoginSelection(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoggingOut = false;
      });

      _showError('Logout failed: $e');
    }
  }

  // ============================================================
  // ACCEPT SELECTION - Always navigates to Dashboard
  // ============================================================

  Future<void> _acceptSelection() async {
    if (selectedBoatIds.isEmpty) {
      _showError('Please select at least one boat');
      return;
    }

    if (isAccepting) return;

    setState(() {
      isAccepting = true;
    });

    try {
      // If not in selection mode, clear existing selections first
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

      setState(() {
        isAccepting = false;
      });

      _showSuccess('${selectedBoatIds.length} boat(s) selected successfully');

      // Always navigate to Dashboard with pushReplacement
      Future.delayed(
        const Duration(milliseconds: 500),
            () {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardScreen(),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isAccepting = false;
      });

      _showError('Error saving selection: $e');
    }
  }

  // ============================================================
  // ERROR & SUCCESS
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF06358D),
      elevation: 0,
      toolbarHeight: 56,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
            tooltip: 'Menu',
          );
        },
      ),
      titleSpacing: 0,
      title: Text(
        widget.isSelectionMode ? 'Select Boat' : 'My Boats',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          onPressed: isLoading
              ? null
              : () => _loadBoats(
            refresh: true,
          ),
          icon: isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Icon(
            Icons.refresh_rounded,
            color: Colors.white,
          ),
          tooltip: 'Refresh',
        ),
        IconButton(
          onPressed: _showAddBoatDialog,
          icon: const Icon(
            Icons.add_rounded,
            color: Colors.white,
          ),
          tooltip: 'Add Boat',
        ),
        const SizedBox(
          width: 4,
        ),
      ],
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

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
                color: Color(0xFF06358D),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ownerName ?? 'Boat Owner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (ownerMobile != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      ownerMobile!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
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
                    onTap: () {
                      Navigator.pop(context);
                    },
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
            const Divider(
              height: 1,
              thickness: 1,
            ),
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

  // ============================================================
  // DRAWER ITEM
  // ============================================================

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    int? count,
    bool selected = false,
    Color color = darkBlue,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: selected ? lightBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        minVerticalPadding: 4,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
        ),
        leading: Icon(
          icon,
          size: 22,
          color: selected ? primaryBlue : color,
        ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        )
            : null,
        onTap: onTap,
      ),
    );
  }

  // ============================================================
  // PROFILE DETAILS
  // ============================================================

  void _showProfileDetails() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Profile Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileDetail(
                'Name',
                ownerName ?? 'Not available',
              ),
              const Divider(height: 16),
              _buildProfileDetail(
                'Mobile',
                ownerMobile ?? 'Not available',
              ),
              const Divider(height: 16),
              _buildProfileDetail(
                'Address',
                ownerAddress ?? 'Not available',
              ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: darkBlue,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryBlue,
            ),
            SizedBox(height: 16),
            Text(
              'Loading boats...',
              style: TextStyle(
                color: Color(0xFF24365B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _buildError();
    }

    if (boats.isEmpty) {
      return _buildEmpty();
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                _buildWelcome(),
                const SizedBox(height: 8),
                _buildBoatSection(),
                const SizedBox(height: 10),
                // Always show confirm section
                _buildConfirmSection(),
                const SizedBox(height: 16),
                if (currentPage < totalPages) _buildLoadMoreButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LOAD MORE
  // ============================================================

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: TextButton(
        onPressed: () {
          currentPage++;
          _loadBoats(
            refresh: false,
          );
        },
        child: const Text(
          'Load More Boats',
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        10,
        16,
        6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome ${ownerName ?? "Boat Owner"}!',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkBlue,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.isSelectionMode
                ? 'Select your boat to continue.'
                : 'Manage your boats here.',
            style: const TextStyle(
              color: Color(0xFF5F6B7A),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOAT SECTION
  // ============================================================

  Widget _buildBoatSection() {
    final selectedCount = selectedBoatIds.length;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryBlue,
                ),
                child: const Icon(
                  Icons.directions_boat_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Boat Details',
                style: TextStyle(
                  color: darkBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Always show selected count
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selectedCount > 0 ? primaryBlue : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: TextStyle(
                    color: selectedCount > 0 ? Colors.white : Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...boats.asMap().entries.map(
                (entry) => _buildBoatCard(
              entry.value,
              entry.key,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOAT CARD
  // ============================================================

  Widget _buildBoatCard(Map<String, dynamic> boat, int index) {
    final dynamic boatId = boat['id'] ?? boat['boat_id'];

    final bool selected = selectedBoatIds.contains(
      boatId,
    );

    final List<Color> boatColors = [
      const Color(0xFF1257C7),
      const Color(0xFF2DA65A),
      const Color(0xFFE68A0B),
      const Color(0xFF5B4BB7),
      const Color(0xFFD94A4A),
    ];

    final Color boatColor = boatColors[
    index % boatColors.length];

    final bool isExpired = boat['licence_expired'] ?? false;

    final bool isActive = boat['status']
        ?.toString()
        .toUpperCase() ==
        'ACTIVE';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: selected
            ? const Color(
          0xFFF0F7FF,
        )
            : Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: selected
              ? primaryBlue
              : const Color(
            0xFFE7ECF4,
          ),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: boatId == null
              ? null
              : () => _toggleBoatSelection(
            boatId,
          ),
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(
                      0xFFDCEEFF,
                    )
                        : const Color(
                      0xFFEAF4FF,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.directions_boat_rounded,
                    size: 32,
                    color: boatColor,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              boat['boat_name']
                                  ?.toString() ??
                                  'Boat ${index + 1}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: darkBlue,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[
                                100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.red[
                                  700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (isExpired)
                            Container(
                              margin: const EdgeInsets.only(
                                left: 4,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[
                                100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'EXPIRED',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.orange[
                                  700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const SizedBox(width: 7),
                          // Always show selection checkbox
                          GestureDetector(
                            onTap: () =>
                                _toggleBoatSelection(
                                  boatId,
                                ),
                            child: Container(
                              width: 21,
                              height: 21,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? primaryBlue
                                      : Colors.grey[
                                  400]!,
                                  width: 2,
                                ),
                                color: selected
                                    ? primaryBlue
                                    : Colors
                                    .transparent,
                              ),
                              child: selected
                                  ? const Icon(
                                Icons.check,
                                size: 13,
                                color: Colors.white,
                              )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        boat['registration_number']
                            ?.toString() ??
                            'No registration',
                        style: const TextStyle(
                          color: Color(
                            0xFF24365B,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _buildBoatDetail(
                        Icons.document_scanner_rounded,
                        'License',
                        boat['licence_id']
                            ?.toString() ??
                            'N/A',
                      ),
                      _buildBoatDetail(
                        Icons.calendar_today_rounded,
                        'Valid Till',
                        boat['licence_valid_upto']
                            ?.toString() ??
                            'N/A',
                      ),
                      _buildBoatDetail(
                        Icons.location_on_rounded,
                        'Home Port',
                        boat['home_port']
                            ?.toString() ??
                            'N/A',
                      ),
                      if (boat['nic_verified'] ==
                          true)
                        const Padding(
                          padding: EdgeInsets.only(
                            top: 3,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                color: Colors.green,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'NIC Verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
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
          ),
        ),
      ),
    );
  }

  Widget _buildBoatDetail(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 2,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: darkBlue,
            size: 13,
          ),
          const SizedBox(width: 5),
          SizedBox(
            width: 58,
            child: Text(
              title,
              style: const TextStyle(
                color: Color(
                  0xFF24365B,
                ),
                fontSize: 11,
              ),
            ),
          ),
          const Text(
            ':',
            style: TextStyle(
              color: Color(0xFF24365B),
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(
                  0xFF24365B,
                ),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRM SECTION (Always visible)
  // ============================================================

  Widget _buildConfirmSection() {
    final selectedCount = selectedBoatIds.length;

    final bool enabled = selectedCount > 0 && !isAccepting;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: lightBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryBlue,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'i',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Please Confirm',
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        widget.isSelectionMode
                            ? 'Select boats above & click Accept.'
                            : 'Select boats above & click Update.',
                        style: const TextStyle(
                          color: Color(
                            0xFF24365B,
                          ),
                          fontSize: 11,
                        ),
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
                disabledBackgroundColor: const Color(
                  0xFFB9C3D1,
                ),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isAccepting
                  ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    selectedCount > 0
                        ? (widget.isSelectionMode
                        ? 'Accept ($selectedCount selected)'
                        : 'Update ($selectedCount selected)')
                        : 'Select a boat',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
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

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadBoats(
                refresh: true,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_boat_outlined,
                size: 60,
                color: Color(0xFF1257C7),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Boats Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started by adding your first boat.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _showAddBoatDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 24,
                ),
                label: const Text(
                  'Add Boat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _loadBoats(
                refresh: true,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PULSING DOT WIDGET
// ============================================================

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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