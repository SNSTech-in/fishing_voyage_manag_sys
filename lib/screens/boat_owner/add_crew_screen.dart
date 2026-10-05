// screens/boat_owner/add_crew_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_services/boat_owners_api_service.dart';

class AddCrewScreen extends StatefulWidget {
  const AddCrewScreen({super.key});

  @override
  State<AddCrewScreen> createState() => _AddCrewScreenState();
}

class _AddCrewScreenState extends State<AddCrewScreen> {
  final BoatOwnwesApiService _apiService = BoatOwnwesApiService();

  // Crew list from API
  List<Map<String, dynamic>> crewMembers = [];
  List<Map<String, dynamic>> filteredCrewMembers = [];
  bool isLoading = false;
  bool isAdding = false;
  int currentPage = 1;
  int totalPages = 1;
  int totalCrew = 0;

  // Search controller
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

  // ── Live validation state (per field) ──
  bool nameTouched = false;
  bool aadhaarTouched = false;
  bool nicTouched = false;
  bool mobileTouched = false;
  bool emergencyNameTouched = false;
  bool emergencyMobileTouched = false;
  bool addressTouched = false;

  final _dialogFormKey = GlobalKey<FormState>();

  StateSetter? _dialogSetState;

  final List<String> genderOptions = ['MALE', 'FEMALE', 'OTHER'];
  // Updated: Only Captain and Crew options
  final List<String> roleOptions = ['CAPTAIN', 'CREW'];

  @override
  void initState() {
    super.initState();
    _loadCrew();
    searchController.addListener(_filterCrew);
  }

  @override
  void dispose() {
    _apiService.dispose();
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

  void _filterCrew() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        filteredCrewMembers = List.from(crewMembers);
      });
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

      print('📥 Crew API Response: $response');

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
        setState(() {
          isLoading = false;
        });
        _showErrorDialog(
          response['message'] ?? 'Failed to load crew',
          response['error_code'],
          response['errors'],
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Network error: ${e.toString()}', null, null);
    }
  }

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
    // Reset form state
    _dialogFormKey.currentState?.reset();
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter crew name';
    if (v.length < 2) return 'Minimum 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
      return 'Only letters and spaces';
    }
    return null;
  }

  String? _validateNicRef(String? value) {
    final v = value?.trim() ?? '';
    // Optional field — but if provided, validate
    if (v.isEmpty) return null;
    if (v.length < 3) return 'Minimum 3 characters';
    if (!RegExp(r'^[a-zA-Z0-9\-/]+$').hasMatch(v)) {
      return 'Letters, digits, - and / only';
    }
    return null;
  }

  String? _validateAadhaar(String? value) {
    final v = value?.trim() ?? '';
    // Optional field
    if (v.isEmpty) return null;
    if (v.length != 12) return 'Enter valid 12-digit Aadhaar';
    if (!RegExp(r'^[0-9]{12}$').hasMatch(v)) return 'Only digits allowed';
    return null;
  }

  String? _validateMobile(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter mobile number';
    if (v.length != 10) return 'Enter 10-digit mobile number';
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(v)) {
      return 'Must start with 6-9';
    }
    return null;
  }

  String? _validateEmergencyMobile(String? value) {
    final v = value?.trim() ?? '';
    // Optional field
    if (v.isEmpty) return null;
    if (v.length != 10) return 'Enter 10-digit mobile number';
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(v)) {
      return 'Must start with 6-9';
    }
    return null;
  }

  String? _validateEmergencyName(String? value) {
    final v = value?.trim() ?? '';
    // Optional field — only validate if a value is provided
    if (v.isEmpty) return null;
    if (v.length < 2) return 'Minimum 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
      return 'Only letters and spaces';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final v = value?.trim() ?? '';
    // Optional field — only validate if a value is provided
    if (v.isEmpty) return null;
    if (v.length < 5) return 'Minimum 5 characters';
    // Letters, digits, spaces, and safe punctuation
    if (!RegExp(r'^[a-zA-Z0-9\s,.\-/#()&]+$').hasMatch(v)) {
      return 'Contains invalid characters';
    }
    return null;
  }

  bool get _isFormComplete {
    return nameController.text.trim().isNotEmpty &&
        aadhaarController.text.trim().isNotEmpty &&
        nicRefController.text.trim().isNotEmpty &&
        mobileController.text.trim().isNotEmpty &&
        emergencyNameController.text.trim().isNotEmpty &&
        emergencyMobileController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty &&
        selectedGender != null &&
        selectedRole != null;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return 'C';
    }
    return name.substring(0, 1).toUpperCase();
  }

  String _getGenderLabel(String? gender) {
    if (gender == null) return 'N/A';
    switch (gender) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
        return 'Other';
      default:
        return gender;
    }
  }

  String _getRoleLabel(String? role) {
    if (role == null) return 'N/A';
    switch (role) {
      case 'CAPTAIN':
        return 'Captain';
      case 'CREW':
        return 'Crew';
      default:
        return role;
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null) return 'N/A';
    switch (status) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      default:
        return status;
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ============================================================
  // ERROR DIALOG
  // ============================================================

  void _showErrorDialog(String? message, String? errorCode, dynamic errors) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Error',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF07347F),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message ?? 'Something went wrong',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              if (errorCode != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Error Code: $errorCode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              if (errors != null && errors is List && errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Details:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF07347F),
                  ),
                ),
                const SizedBox(height: 6),
                ...errors.map((error) {
                  final field = error['field'] ?? '';
                  final errorMsg = error['message'] ?? '';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (field.isNotEmpty)
                                Text(
                                  field,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              Text(
                                errorMsg,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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

  // ============================================================
  // VIEW CREW DETAILS
  // ============================================================

  void _showCrewDetails(Map<String, dynamic> crew) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1257C7).withOpacity(0.1),
                child: Text(
                  _getInitials(crew['crew_name']),
                  style: const TextStyle(
                    color: Color(0xFF1257C7),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  crew['crew_name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF07347F),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Crew ID', crew['crew_id']?.toString() ?? 'N/A'),
                const Divider(height: 12),
                _buildDetailRow('Name', crew['crew_name'] ?? 'N/A'),
                const Divider(height: 12),
                _buildDetailRow('Gender', _getGenderLabel(crew['gender'])),
                const Divider(height: 12),
                _buildDetailRow('Role', _getRoleLabel(crew['crew_role'])),
                const Divider(height: 12),
                _buildDetailRow('Mobile', crew['mobile_no'] ?? 'N/A'),
                const Divider(height: 12),
                _buildDetailRow('Aadhaar (Last 4)', crew['aadhaar_last4'] ?? 'N/A'),
                const Divider(height: 12),
                _buildDetailRow('Is Captain', crew['is_captain'] == true ? 'Yes' : 'No'),
                const Divider(height: 12),
                _buildDetailRow('Can Login', crew['can_login'] == true ? 'Yes' : 'No'),
                const Divider(height: 12),
                _buildDetailRow('Status', _getStatusLabel(crew['status'])),
                const Divider(height: 12),
                if (crew['emergency_contact_name'] != null) ...[
                  _buildDetailRow('Emergency Contact', crew['emergency_contact_name']),
                  const Divider(height: 12),
                ],
                if (crew['emergency_contact_no'] != null) ...[
                  _buildDetailRow('Emergency Mobile', crew['emergency_contact_no']),
                  const Divider(height: 12),
                ],
                if (crew['address_line1'] != null) ...[
                  _buildDetailRow('Address', crew['address_line1']),
                  const Divider(height: 12),
                ],
                if (crew['nic_verification_status'] != null) ...[
                  _buildDetailRow('NIC Status', crew['nic_verification_status']),
                  const Divider(height: 12),
                ],
                if (crew['created_date'] != null) ...[
                  _buildDetailRow('Created Date', _formatDate(crew['created_date'])),
                  const Divider(height: 12),
                ],
              ],
            ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF07347F),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  // ============================================================
  // ADD CREW DIALOG
  // ============================================================

  Future<void> _showAddCrewDialog() async {
    _clearControllers();

    // Show the validation indicator immediately when the dialog opens.
    nameTouched = true;
    aadhaarTouched = true;
    nicTouched = true;
    mobileTouched = true;
    emergencyMobileTouched = true;
    emergencyNameTouched = true;
    addressTouched = true;

    // Attach listeners so ticks appear after the user starts typing
    void attachTouched(TextEditingController c, void Function() mark) {
      c.addListener(() {
        if (!mounted) return;
        final s = c.text.trim();
        if (s.isNotEmpty) mark();
      });
    }

    attachTouched(nameController, () {
      if (!nameTouched) setState(() => nameTouched = true);
    });
    attachTouched(aadhaarController, () {
      if (!aadhaarTouched) setState(() => aadhaarTouched = true);
    });
    attachTouched(nicRefController, () {
      if (!nicTouched) setState(() => nicTouched = true);
    });
    attachTouched(mobileController, () {
      if (!mobileTouched) setState(() => mobileTouched = true);
    });
    attachTouched(emergencyNameController, () {
      if (!emergencyNameTouched) setState(() => emergencyNameTouched = true);
    });
    attachTouched(emergencyMobileController, () {
      if (!emergencyMobileTouched) setState(() => emergencyMobileTouched = true);
    });
    attachTouched(addressController, () {
      if (!addressTouched) setState(() => addressTouched = true);
    });

    // Rebuild the dialog whenever any field changes, so the Add button
    // enable/disable state stays in sync with the form.
    for (final c in [
      nameController,
      aadhaarController,
      nicRefController,
      mobileController,
      emergencyNameController,
      emergencyMobileController,
      addressController,
    ]) {
      c.addListener(() {
        if (mounted && _dialogSetState != null) {
          _dialogSetState!(() {});
        }
      });
    }

    // Reset isAdding state when dialog is opened
    isAdding = false;

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            _dialogSetState = setStateDialog;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1257C7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: Color(0xFF1257C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Add Crew Member',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF07347F),
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
                  child: Form(
                    key: _dialogFormKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDialogTextField(
                          controller: nameController,
                          label: 'Crew Name',
                          isRequired: true,
                          hint: 'Enter crew name',
                          icon: Icons.person,
                          validator: _validateName,
                          inputFormatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                            CrewNameFormatter(),
                          ],
                          showValidation: nameTouched,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: aadhaarController,
                          label: 'Aadhaar Number',
                          isRequired: true,
                          hint: 'Enter 12-digit Aadhaar number',
                          icon: Icons.assignment_ind,
                          keyboardType: TextInputType.number,
                          validator: _validateAadhaar,
                          maxLength: 12,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12),
                          ],
                          showValidation: aadhaarTouched,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: nicRefController,
                          label: 'NIC Reference',
                          isRequired: true,
                          hint: 'e.g., NIC-AAD-2347',
                          icon: Icons.verified,
                          validator: _validateNicRef,
                          inputFormatters: [NicRefFormatter()],
                          showValidation: nicTouched,
                          maxLength: 30,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: mobileController,
                          label: 'Mobile Number',
                          isRequired: true,
                          hint: 'Enter 10-digit mobile number',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          validator: _validateMobile,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          showValidation: mobileTouched,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Gender *',
                                value: selectedGender,
                                options: genderOptions,
                                hint: 'Select gender',
                                onChanged: (value) {
                                  setStateDialog(() {
                                    selectedGender = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdownField(
                                label: 'Role *',
                                value: selectedRole,
                                options: roleOptions,
                                hint: 'Select role',
                                onChanged: (value) {
                                  setStateDialog(() {
                                    selectedRole = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSwitchField(
                                label: 'Is Captain',
                                value: isCaptain,
                                onChanged: (value) {
                                  setStateDialog(() {
                                    isCaptain = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: _buildSwitchField(
                                label: 'Can Login',
                                value: canLogin,
                                onChanged: (value) {
                                  setStateDialog(() {
                                    canLogin = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: emergencyNameController,
                          label: 'Emergency Contact Name',
                          isRequired: true,
                          hint: 'Enter emergency contact name',
                          icon: Icons.contact_emergency,
                          validator: _validateEmergencyName,
                          inputFormatters: [EmergencyNameFormatter()],
                          showValidation: emergencyNameTouched,
                          maxLength: 50,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: emergencyMobileController,
                          label: 'Emergency Contact No',
                          isRequired: true,
                          hint: 'Enter 10-digit mobile number',
                          icon: Icons.phone_android,
                          keyboardType: TextInputType.phone,
                          validator: _validateEmergencyMobile,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          showValidation: emergencyMobileTouched,
                        ),
                        const SizedBox(height: 12),
                        _buildDialogTextField(
                          controller: addressController,
                          label: 'Address',
                          isRequired: true,
                          hint: 'Enter address',
                          icon: Icons.location_on,
                          maxLines: 2,
                          validator: _validateAddress,
                          inputFormatters: [AddressFormatter()],
                          showValidation: addressTouched,
                          maxLength: 200,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null  // Disable cancel while adding
                      : () {
                    // Reset isAdding when dialog is closed
                    setStateDialog(() => isAdding = false);
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: isAdding ? Colors.grey[400] : Colors.grey[600],
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (isAdding || !_isFormComplete)
                      ? null
                      : () async {
                    if (_dialogFormKey.currentState!.validate()) {
                      if (selectedGender == null) {
                        _showErrorDialog(
                          'Please select gender',
                          null,
                          null,
                        );
                        return;
                      }
                      if (selectedRole == null) {
                        _showErrorDialog(
                          'Please select role',
                          null,
                          null,
                        );
                        return;
                      }

                      // Set loading state
                      setStateDialog(() => isAdding = true);

                      try {
                        final response = await _apiService.addCrew(
                          crewName: nameController.text.trim(),
                          aadhaarNo: aadhaarController.text.trim(),
                          nicRef: nicRefController.text.trim(),
                          mobileNo: mobileController.text.trim(),
                          gender: selectedGender!,
                          crewRole: selectedRole!,
                          isCaptain: isCaptain,
                          canLogin: canLogin,
                          emergencyContactName: emergencyNameController.text.trim(),
                          emergencyContactNo: emergencyMobileController.text.trim(),
                          address: addressController.text.trim(),
                        );

                        if (response['success'] == true) {
                          if (!mounted) return;
                          // Reset isAdding before closing dialog
                          setStateDialog(() => isAdding = false);
                          Navigator.pop(context);
                          _showSuccess('Crew member added successfully!');
                          _loadCrew(refresh: true);
                        } else {
                          // Reset isAdding on error
                          setStateDialog(() => isAdding = false);
                          _showErrorDialog(
                            response['message'] ?? 'Failed to add crew',
                            response['error_code'],
                            response['errors'],
                          );
                        }
                      } catch (e) {
                        // Reset isAdding on error
                        setStateDialog(() => isAdding = false);
                        _showErrorDialog(
                          'Error: ${e.toString()}',
                          null,
                          null,
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (isAdding || !_isFormComplete)
                        ? const Color(0xFFB0C4DE)   // grey when disabled
                        : const Color(0xFF1257C7),   // blue when enabled
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: isAdding
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool showValidation = false,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF07347F),
                ),
              ),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFDC2626),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          validator: validator,
          maxLength: maxLength,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
            prefixIcon: icon != null
                ? Icon(icon, size: 20, color: Colors.grey[500])
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4DFEE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4DFEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1257C7), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFD4DFEE)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF1257C7), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            counterStyle: const TextStyle(fontSize: 11),
          ),
        ),
        // No error text under the field — only the dot on the label row
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> options,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF07347F),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD4DFEE)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(
              hint,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
            isExpanded: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF07347F),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD4DFEE)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value ? 'Yes' : 'No',
                style: const TextStyle(fontSize: 14),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF1257C7),
              ),
            ],
          ),
        ),
      ],
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
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context, false),
        tooltip: 'Back',
      ),
      titleSpacing: 0,
      title: const Text(
        'Crew Members',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        // Refresh Button
        IconButton(
          onPressed: isLoading ? null : () => _loadCrew(refresh: true),
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
        // Add Crew Button with full text
        Container(
          margin: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: _showAddCrewDialog,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.15),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              children: const [
                Icon(Icons.add_rounded, size: 18),
                SizedBox(width: 4),
                Text(
                  'Add Crew',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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
              color: Color(0xFF1257C7),
            ),
            SizedBox(height: 16),
            Text(
              'Loading crew members...',
              style: TextStyle(
                color: Color(0xFF24365B),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),
        Expanded(
          child: filteredCrewMembers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
            onRefresh: () => _loadCrew(refresh: true),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCrewMembers.length,
              itemBuilder: (context, index) {
                final crew = filteredCrewMembers[index];
                return _buildCrewCard(crew, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search by name or mobile...',
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Colors.grey[400],
            size: 22,
          ),
          suffixIcon: searchController.text.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
            onPressed: () {
              searchController.clear();
              _filterCrew();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    final hasSearch = searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1257C7).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSearch ? Icons.search_off_rounded : Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'No matching crew found' : 'No crew members found',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasSearch
                ? 'Try a different search term'
                : 'Tap the Add Crew button to add crew members',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1257C7).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: const Color(0xFF1257C7),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'You can add crew members from the top right',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1257C7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CREW CARD
  // ============================================================

  Widget _buildCrewCard(Map<String, dynamic> crew, int index) {
    final crewName = crew['crew_name']?.toString().trim() ?? 'Unknown';
    final isCaptain = crew['is_captain'] == true;
    final status = crew['status'] ?? 'ACTIVE';

    final List<Color> avatarColors = [
      const Color(0xFF1257C7),
      const Color(0xFF2DA65A),
      const Color(0xFFE68A0B),
      const Color(0xFF5B4BB7),
      const Color(0xFFD94A4A),
    ];
    final Color avatarColor = avatarColors[index % avatarColors.length];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCrewDetails(crew),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: avatarColor.withOpacity(0.15),
                      child: Text(
                        _getInitials(crewName),
                        style: TextStyle(
                          color: avatarColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isCaptain)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1257C7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              crewName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF07347F),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getStatusLabel(status),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 12,
                        runSpacing: 2,
                        children: [
                          if (crew['crew_role'] != null)
                            _buildChipInfo(
                              Icons.work_outline_rounded,
                              _getRoleLabel(crew['crew_role']),
                            ),
                          if (crew['mobile_no'] != null)
                            _buildChipInfo(
                              Icons.phone_rounded,
                              crew['mobile_no'],
                            ),
                          if (crew['aadhaar_last4'] != null)
                            _buildChipInfo(
                              Icons.assignment_ind_rounded,
                              '****${crew['aadhaar_last4']}',
                            ),
                          if (crew['nic_verification_status'] != null)
                            _buildChipInfo(
                              Icons.verified_rounded,
                              crew['nic_verification_status'],
                              color: crew['nic_verification_status'] == 'VERIFIED'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipInfo(IconData icon, String label, {Color color = Colors.grey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INPUT FORMATTERS
// ============================================================================

/// Letters and spaces only — for Crew Name.
/// Allows: Ram Kumar, John, Priya
class CrewNameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    return regex.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

/// Letters, digits, hyphens, slashes only — for NIC Reference.
/// Allows: NIC-AAD-2347, NIC/2024/001, ABC123
class NicRefFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final regex = RegExp(r'^[a-zA-Z0-9\-/]+$');
    return regex.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

/// Letters, digits, spaces, commas, dots, hyphens, slashes, #, (), and &.
/// Used for Address.
class AddressFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final regex = RegExp(r'^[a-zA-Z0-9\s,.\-/#()&]+$');
    return regex.hasMatch(newValue.text) ? newValue : oldValue;
  }
}

/// Letters and spaces only — for Emergency Contact Name.
class EmergencyNameFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final regex = RegExp(r'^[a-zA-Z\s]+$');
    return regex.hasMatch(newValue.text) ? newValue : oldValue;
  }
}