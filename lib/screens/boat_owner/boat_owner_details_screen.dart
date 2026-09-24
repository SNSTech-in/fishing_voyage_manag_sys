// lib/screens/boat_owner/boat_owner_details_screen.dart

import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../services/api_services/api_service.dart';
import 'boat_selection_screen.dart';

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

  List<Map<String, dynamic>> ports = [];
  List<Map<String, dynamic>> filteredPorts = [];

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

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
      mobileController.text = session['mobile_no'];
    }
  }

  Future<void> _loadPorts() async {
    setState(() {
      isLoadingPorts = true;
    });

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
      if (mounted) {
        setState(() {
          isLoadingPorts = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 20),
                    _buildPhotoUpload(),
                    const SizedBox(height: 20),
                    _buildFormFields(),
                    const SizedBox(height: 16),
                    if (selectedHomePortId != null) _buildSelectedPortInfo(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SELECTED PORT INFO
  // ===========================================================================

  Widget _buildSelectedPortInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.blue[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.blue[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Port',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedHomePortName ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF07347F),
                  ),
                ),
                if (selectedHomePortDistrict != null ||
                    selectedHomePortCode != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (selectedHomePortDistrict != null) ...[
                        Text(
                          selectedHomePortDistrict!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                      if (selectedHomePortDistrict != null &&
                          selectedHomePortCode != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (selectedHomePortCode != null) ...[
                        Text(
                          'ID: ${selectedHomePortCode!}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedHomePortId = null;
                selectedHomePortName = null;
                selectedHomePortCode = null;
                selectedHomePortDistrict = null;
              });
            },
            icon: Icon(
              Icons.close,
              size: 18,
              color: Colors.grey[600],
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF07347F)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Boat Owner Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF07347F),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _saveDetails,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Color(0xFF1257C7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TITLE SECTION
  // ===========================================================================

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF07347F),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Please provide your details to complete registration',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // PHOTO UPLOAD
  // ===========================================================================

  Widget _buildPhotoUpload() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Owner Photo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF07347F),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Photo upload feature coming soon')),
              );
            },
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
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

  // ===========================================================================
  // FORM FIELDS
  // ===========================================================================

  Widget _buildFormFields() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTextField(
            label: 'Owner Name',
            hint: 'Enter owner name',
            controller: ownerNameController,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Address',
            hint: 'Enter address',
            controller: addressController,
            isRequired: true,
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Aadhaar No',
            hint: 'Enter Aadhaar number',
            controller: aadhaarController,
            isRequired: true,
            keyboardType: TextInputType.number,
            maxLength: 12,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Mobile No',
            hint: 'Enter mobile number',
            controller: mobileController,
            isRequired: true,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            enabled: false,
          ),
          const SizedBox(height: 16),
          _buildSearchableDropdownField(),
        ],
      ),
    );
  }

  // ===========================================================================
  // TEXT FIELD
  // ===========================================================================

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF07347F),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF1257C7),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            counterText: '',
            fillColor: enabled ? Colors.white : Colors.grey[50],
            filled: !enabled,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SEARCHABLE DROPDOWN FIELD
  // ===========================================================================

  Widget _buildSearchableDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Home Port',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF07347F),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: isLoadingPorts ? null : _refreshPorts,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: isLoadingPorts
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF1257C7),
                  ),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      color: Colors.blue[700],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isLoadingPorts
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1257C7),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loading ports...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
              : ports.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 32,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No ports available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _refreshPorts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )
              : Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: TextField(
                  controller: searchController,
                  onChanged: _filterPorts,
                  decoration: InputDecoration(
                    hintText: 'Search port by name, code or district...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.grey[400],
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: 18,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        searchController.clear();
                        _filterPorts('');
                      },
                    )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey[300],
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35,
                  minHeight: 50,
                ),
                child: filteredPorts.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No ports match your search',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredPorts.length,
                  itemBuilder: (context, index) {
                    final port = filteredPorts[index];
                    final portName = port['port_name'] ?? port['port_code'] ?? '';
                    final district = port['district'] ?? '';
                    final portCode = port['port_code'] ?? '';
                    final isSelected = selectedHomePortId == port['port_id'].toString();

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedHomePortId = port['port_id'].toString();
                          selectedHomePortName = portName;
                          selectedHomePortCode = portCode;
                          selectedHomePortDistrict = district;
                          searchController.clear();
                          filteredPorts = List<Map<String, dynamic>>.from(ports);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[200]!,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: Colors.blue[700],
                                size: 18,
                              )
                            else
                              SizedBox(
                                width: 18,
                                child: Icon(
                                  Icons.radio_button_unchecked,
                                  color: Colors.grey[400],
                                  size: 18,
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    portName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      color: isSelected ? Color(0xFF07347F) : Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (district.isNotEmpty || portCode.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        if (district.isNotEmpty) ...[
                                          Text(
                                            district,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                        if (district.isNotEmpty && portCode.isNotEmpty) ...[
                                          const SizedBox(width: 4),
                                          Text(
                                            '•',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        if (portCode.isNotEmpty) ...[
                                          Text(
                                            portCode,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (port['port_type'] != null) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getPortTypeLabel(port['port_type']),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredPorts.length} of ${ports.length} ports',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (selectedHomePortId != null)
                      Text(
                        'Selected: $selectedHomePortName',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPortTypeLabel(String? portType) {
    if (portType == null) return '';
    switch (portType) {
      case 'FISHING_HARBOUR':
        return 'Harbour';
      case 'FISH_LANDING_CENTRE':
        return 'Landing';
      default:
        return portType.replaceAll('_', ' ').toLowerCase();
    }
  }

  // ===========================================================================
  // REFRESH PORTS
  // ===========================================================================

  Future<void> _refreshPorts() async {
    setState(() {
      isLoadingPorts = true;
    });

    try {
      setState(() {
        ports = [];
        filteredPorts = [];
      });

      final response = await _apiService.getPorts();

      if (response['success'] == true) {
        final items = response['data']['items'] as List?;
        if (items != null && items.isNotEmpty) {
          setState(() {
            ports = List<Map<String, dynamic>>.from(items);
            filteredPorts = List<Map<String, dynamic>>.from(items);
          });
          _showSuccess('Ports refreshed successfully! ${ports.length} ports loaded');
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
        _showError(response['message'] ?? 'Failed to refresh ports');
      }
    } catch (e) {
      setState(() {
        ports = [];
        filteredPorts = [];
      });
      _showError('Network error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingPorts = false;
        });
      }
    }
  }

  // ===========================================================================
  // SAVE BUTTON
  // ===========================================================================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveDetails,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1257C7),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Text(
          'Save & Continue',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // SAVE FUNCTION
  // ===========================================================================

  void _saveDetails() async {
    // Validate fields
    if (ownerNameController.text.trim().isEmpty) {
      _showError('Please enter owner name');
      return;
    }
    if (addressController.text.trim().isEmpty) {
      _showError('Please enter address');
      return;
    }
    if (aadhaarController.text.trim().isEmpty) {
      _showError('Please enter Aadhaar number');
      return;
    }
    if (aadhaarController.text.trim().length != 12) {
      _showError('Please enter a valid 12-digit Aadhaar number');
      return;
    }
    if (mobileController.text.trim().isEmpty) {
      _showError('Please enter mobile number');
      return;
    }
    if (mobileController.text.trim().length != 10) {
      _showError('Please enter a valid 10-digit mobile number');
      return;
    }
    if (selectedHomePortId == null) {
      _showError('Please select a home port');
      return;
    }

    setState(() => isLoading = true);

    try {
      // Build request with ONLY the required fields
      final response = await _apiService.createProfile(
        ownerName: ownerNameController.text.trim(),
        aadhaarNo: aadhaarController.text.trim(),
        primaryPortId: selectedHomePortId!,
        otp: '000000',
        mobileNo: mobileController.text.trim(),
        address: addressController.text.trim(),
      );

      print('📥 Create Profile Response: $response');

      if (response['success'] == true) {
        final responseData = response['data'];

        // Save boat owner to local database
        await _db.insertBoatOwner({
          'owner_name': ownerNameController.text.trim(),
          'address': addressController.text.trim(),
          'aadhaar': aadhaarController.text.trim(),
          'mobile': mobileController.text.trim(),
          'home_port_id': selectedHomePortId,
          'home_port_name': selectedHomePortName,
          'photo_path': null,
        });

        // Insert sample boats
        if (selectedHomePortName != null) {
          final owner = await _db.getBoatOwner();
          if (owner != null) {
            await _db.insertSampleBoats(owner['id'], selectedHomePortName!);
          }
        }

        setState(() => isLoading = false);

        _showSuccess('Profile created successfully!');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const BoatSelectionScreen(),
            ),
          );
        }
      } else {
        setState(() => isLoading = false);
        _showError(response['message'] ?? 'Failed to create profile');
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showError('Error saving data: ${e.toString()}');
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}