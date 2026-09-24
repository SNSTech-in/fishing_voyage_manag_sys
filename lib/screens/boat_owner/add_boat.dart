// screens/boat_owner/boat_selection_screen.dart

import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../services/api_services/api_service.dart';

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

  static const Color primaryBlue = Color(0xFF1257C7);
  static const Color darkBlue = Color(0xFF07347F);
  static const Color lightBlue = Color(0xFFE8F3FF);

  @override
  void initState() {
    super.initState();
    _loadOwnerDetails();
    _loadBoats();
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

      if (owner != null && mounted) {
        setState(() {
          ownerName = owner['owner_name']?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading owner details: $e');
    }
  }

  // ============================================================
  // LOAD BOATS
  // ============================================================

  Future<void> _loadBoats({bool refresh = false}) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;

      if (refresh) {
        boats.clear();
      }
    });

    try {
      final response = await _apiService.getBoats(
        page: 1,
        pageSize: 100,
      );

      debugPrint('📥 Boats API Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];

        final items = data is Map
            ? data['items'] as List?
            : null;

        if (items != null && items.isNotEmpty) {
          final loadedBoats =
          List<Map<String, dynamic>>.from(items);

          final mappedBoats = loadedBoats.map((boat) {
            return {
              'id': boat['boat_id'],
              'boat_id': boat['boat_id'],
              'boat_name': boat['boat_name'] ?? 'Boat',
              'registration_number':
              boat['boat_reg_no'] ?? 'N/A',
              'length': boat['length'] ?? 'N/A',
              'engine': boat['engine'] ?? 'N/A',
              'home_port': boat['home_port'] ?? 'N/A',
              'owner_name':
              boat['owner_name'] ?? ownerName,
              'licence_id':
              boat['licence_id'] ?? 'N/A',
              'licence_type':
              boat['licence_type'] ?? 'N/A',
              'licence_issue_date':
              boat['licence_issue_date'] ?? 'N/A',
              'licence_valid_upto':
              boat['licence_valid_upto'] ?? 'N/A',
              'licence_expired':
              boat['licence_expired'] ?? false,
              'nic_verified':
              boat['nic_verified'] ?? false,
              'status':
              boat['status'] ?? 'ACTIVE',
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
          errorMessage =
              response['message'] ??
                  'Failed to load boats';
        });
      }
    } catch (e) {
      if (!mounted) return;

      debugPrint('❌ Error loading boats: $e');

      setState(() {
        isLoading = false;
        errorMessage =
        'Error loading boats: ${e.toString()}';
      });
    }
  }

  // ============================================================
  // ADD BOAT DIALOG
  // ============================================================

  Future<void> _showAddBoatDialog() async {
    final TextEditingController boatRegNoController =
    TextEditingController();

    final TextEditingController boatNameController =
    TextEditingController();

    final TextEditingController licenceIdController =
    TextEditingController();

    final TextEditingController licenceIssueDateController =
    TextEditingController();

    final TextEditingController licenceValidUptoController =
    TextEditingController();

    bool isLoadingLocal = false;

    Future<void> selectDate(
        TextEditingController controller,
        ) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2035),
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
        controller.text =
            picked.toIso8601String().split('T').first;
      }
    }

    await showDialog(
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
                      borderRadius:
                      BorderRadius.circular(10),
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
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAddBoatField(
                      label: 'Boat Registration No',
                      hint: 'e.g., IND-KA-2231',
                      controller:
                      boatRegNoController,
                      icon: Icons.assignment_rounded,
                      isRequired: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAddBoatField(
                      label: 'Boat Name',
                      hint: 'e.g., Sagar Kanya',
                      controller:
                      boatNameController,
                      icon:
                      Icons.directions_boat_rounded,
                      isRequired: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAddBoatField(
                      label: 'License ID',
                      hint: 'e.g., FL-KA-77120',
                      controller:
                      licenceIdController,
                      icon:
                      Icons.document_scanner_rounded,
                      isRequired: true,
                    ),

                    const SizedBox(height: 12),

                    _buildAddBoatField(
                      label: 'Issue Date',
                      hint: 'YYYY-MM-DD',
                      controller:
                      licenceIssueDateController,
                      icon:
                      Icons.calendar_today_rounded,
                      isRequired: true,
                      readOnly: true,
                      onTap: () => selectDate(
                        licenceIssueDateController,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildAddBoatField(
                      label: 'Valid Upto',
                      hint: 'YYYY-MM-DD',
                      controller:
                      licenceValidUptoController,
                      icon:
                      Icons.calendar_today_rounded,
                      isRequired: true,
                      readOnly: true,
                      onTap: () => selectDate(
                        licenceValidUptoController,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoadingLocal
                      ? null
                      : () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: isLoadingLocal
                      ? null
                      : () async {
                    if (boatRegNoController.text
                        .trim()
                        .isEmpty) {
                      _showError(
                        'Please enter boat registration number',
                      );
                      return;
                    }

                    if (boatNameController.text
                        .trim()
                        .isEmpty) {
                      _showError(
                        'Please enter boat name',
                      );
                      return;
                    }

                    if (licenceIdController.text
                        .trim()
                        .isEmpty) {
                      _showError(
                        'Please enter license ID',
                      );
                      return;
                    }

                    if (licenceIssueDateController
                        .text
                        .trim()
                        .isEmpty) {
                      _showError(
                        'Please select license issue date',
                      );
                      return;
                    }

                    if (licenceValidUptoController
                        .text
                        .trim()
                        .isEmpty) {
                      _showError(
                        'Please select license valid date',
                      );
                      return;
                    }

                    setStateDialog(() {
                      isLoadingLocal = true;
                    });

                    try {
                      final response =
                      await _apiService.addBoat(
                        boatRegNo:
                        boatRegNoController
                            .text
                            .trim(),
                        boatName:
                        boatNameController
                            .text
                            .trim(),
                        licenceId:
                        licenceIdController
                            .text
                            .trim(),
                        licenceIssueDate:
                        licenceIssueDateController
                            .text
                            .trim(),
                        licenceValidUpto:
                        licenceValidUptoController
                            .text
                            .trim(),
                      );

                      if (response['success'] ==
                          true) {
                        if (!mounted) return;

                        Navigator.pop(
                          dialogContext,
                        );

                        _showSuccess(
                          'Boat added successfully!',
                        );

                        await _loadBoats(
                          refresh: true,
                        );
                      } else {
                        setStateDialog(() {
                          isLoadingLocal = false;
                        });

                        _showError(
                          response['message'] ??
                              'Failed to add boat',
                        );
                      }
                    } catch (e) {
                      setStateDialog(() {
                        isLoadingLocal = false;
                      });

                      _showError(
                        'Error: ${e.toString()}',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoadingLocal
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
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

    boatRegNoController.dispose();
    boatNameController.dispose();
    licenceIdController.dispose();
    licenceIssueDateController.dispose();
    licenceValidUptoController.dispose();
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
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),

        const SizedBox(height: 5),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey.shade300,
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
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding:
                    const EdgeInsets.symmetric(
                      vertical: 10,
                    ),
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
                ),
            ],
          ),
        ),
      ],
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
      body: _buildBody(),
    );
  }

  // ============================================================
  // APP BAR
  // ONLY BACK + REFRESH + ADD BOAT
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF06358D),
      elevation: 0,
      toolbarHeight: 56,

      // BACK
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        tooltip: 'Back',
      ),

      titleSpacing: 0,

      title: const Text(
        'My Boats',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ONLY REFRESH + ADD
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

        const SizedBox(width: 4),
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

    return RefreshIndicator(
      color: primaryBlue,
      onRefresh: () => _loadBoats(
        refresh: true,
      ),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 20,
        ),
        children: [
          _buildWelcome(),

          const SizedBox(height: 8),

          _buildBoatSection(),
        ],
      ),
    );
  }

  // ============================================================
  // WELCOME
  // ============================================================

  Widget _buildWelcome() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
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

          const SizedBox(height: 3),

          const Text(
            'Manage your boats here.',
            style: TextStyle(
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
        crossAxisAlignment:
        CrossAxisAlignment.start,
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

              Text(
                '${boats.length} boat${boats.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF5F6B7A),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
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

  Widget _buildBoatCard(
      Map<String, dynamic> boat,
      int index,
      ) {
    final List<Color> boatColors = [
      const Color(0xFF1257C7),
      const Color(0xFF2DA65A),
      const Color(0xFFE68A0B),
      const Color(0xFF5B4BB7),
      const Color(0xFFD94A4A),
    ];

    final Color boatColor =
    boatColors[index % boatColors.length];

    final bool isExpired =
        boat['licence_expired'] == true;

    final bool isActive =
        boat['status']
            ?.toString()
            .toUpperCase() ==
            'ACTIVE';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xFFE7ECF4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(11),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF4FF),
                borderRadius:
                BorderRadius.all(
                  Radius.circular(10),
                ),
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
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          boat['boat_name']
                              ?.toString() ??
                              'Boat ${index + 1}',
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style:
                          const TextStyle(
                            color: darkBlue,
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),

                      if (!isActive)
                        _statusBadge(
                          'INACTIVE',
                          Colors.red,
                        ),

                      if (isExpired)
                        _statusBadge(
                          'EXPIRED',
                          Colors.orange,
                        ),
                    ],
                  ),

                  const SizedBox(height: 3),

                  Text(
                    boat['registration_number']
                        ?.toString() ??
                        'No registration',
                    style: const TextStyle(
                      color: Color(0xFF24365B),
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

                  if (boat['nic_verified'] == true)
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
                              fontWeight:
                              FontWeight.w500,
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
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _statusBadge(
      String text,
      MaterialColor color,
      ) {
    return Container(
      margin: const EdgeInsets.only(
        left: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color[100],
        borderRadius:
        BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8,
          color: color[700],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // BOAT DETAIL
  // ============================================================

  Widget _buildBoatDetail(
      IconData icon,
      String title,
      String value,
      ) {
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
                color: Color(0xFF24365B),
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
              overflow:
              TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF24365B),
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
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 16),

            Text(
              errorMessage ??
                  'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: () => _loadBoats(
                refresh: true,
              ),
              icon: const Icon(
                Icons.refresh_rounded,
              ),
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

  // ============================================================
  // EMPTY
  // ============================================================

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration:
              const BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_boat_outlined,
                size: 60,
                color: primaryBlue,
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
              'Add your first boat to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: _showAddBoatDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Add Boat',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior:
        SnackBarBehavior.floating,
        duration:
        const Duration(seconds: 2),
      ),
    );
  }
}