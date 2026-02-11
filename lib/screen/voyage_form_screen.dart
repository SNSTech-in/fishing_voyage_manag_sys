import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class VoyageFormScreen extends StatefulWidget {
  final Map<String, dynamic> ownerData;

  const VoyageFormScreen({
    super.key,
    required this.ownerData,
  });

  @override
  State<VoyageFormScreen> createState() => _VoyageFormScreenState();
}

class _VoyageFormScreenState extends State<VoyageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Controllers
  final TextEditingController _voyageNumberController = TextEditingController();
  final TextEditingController _fishingLicenseController = TextEditingController();
  final TextEditingController _freshWaterController = TextEditingController();
  final TextEditingController _dieselController = TextEditingController();
  final TextEditingController _lifeJacketsController = TextEditingController();
  final TextEditingController _lifeBuoysController = TextEditingController();
  final TextEditingController _communicationDevicesController = TextEditingController();
  final List<TextEditingController> _crewControllers = [TextEditingController()];

  // Variables
  String? _selectedDestinationPort;
  DateTime? _voyageDate;
  DateTime? _expectedReturnDate;
  bool _previousCatchSubmitted = false;
  bool _isSubmitting = false;

  // Ports list
  final List<String> _ports = [
    'Agati',
    'Kavarati',
    'Androdh',
    'Kalpeni',
    'Kadmat',
    'Amini',
    'Chetlat',
    'Bitra'
  ];

  @override
  void initState() {
    super.initState();
    // Set default dates
    _voyageDate = DateTime.now();
    _expectedReturnDate = DateTime.now().add(const Duration(days: 7));
  }

  void _addCrewMember() {
    setState(() {
      _crewControllers.add(TextEditingController());
    });
  }

  void _removeCrewMember(int index) {
    if (_crewControllers.length > 1) {
      setState(() {
        _crewControllers.removeAt(index);
      });
    }
  }

  Future<void> _submitVoyage() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDestinationPort == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select destination port'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Prepare voyage data
        Map<String, dynamic> voyageData = {
          'boat_owner_id': widget.ownerData['id'],
          'voyage_number': _voyageNumberController.text.isNotEmpty
              ? _voyageNumberController.text
              : 'VOY-${DateTime.now().millisecondsSinceEpoch}',
          'fishing_license': _fishingLicenseController.text,
          'departure_port': widget.ownerData['home_port'],
          'destination_port': _selectedDestinationPort,
          'voyage_date': _voyageDate!.toIso8601String(),
          'expected_return_date': _expectedReturnDate!.toIso8601String(),
          'fresh_water': int.tryParse(_freshWaterController.text) ?? 0,
          'diesel': int.tryParse(_dieselController.text) ?? 0,
          'life_jackets': int.tryParse(_lifeJacketsController.text) ?? 0,
          'life_buoys': int.tryParse(_lifeBuoysController.text) ?? 0,
          'communication_devices': int.tryParse(_communicationDevicesController.text) ?? 0,
          'previous_catch_submitted': _previousCatchSubmitted ? 1 : 0,
          'crew_count': _crewControllers.where((c) => c.text.isNotEmpty).length,
          'crew_names': _crewControllers
              .where((controller) => controller.text.isNotEmpty)
              .map((controller) => controller.text)
              .join(', '),
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Insert into database
        int voyageId = await _databaseHelper.insertVoyage(voyageData);

        if (voyageId > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voyage submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit voyage. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isVoyageDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isVoyageDate ? DateTime.now() : DateTime.now().add(const Duration(days: 7)),
      firstDate: isVoyageDate ? DateTime.now() : DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1976D2),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isVoyageDate) {
          _voyageDate = picked;
        } else {
          _expectedReturnDate = picked;
        }
      });
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0D47A1),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isRequired = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF1976D2)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
            validator: isRequired
                ? (value) {
              if (value == null || value.isEmpty) {
                return 'Required';
              }
              return null;
            }
                : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: const Color(0xFF1976D2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.day}/${date.month}/${date.year}'
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 13,
                      color: date != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  size: 20,
                  color: Colors.grey.shade500,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPortField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Destination Port',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0D47A1),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedDestinationPort,
            decoration: const InputDecoration(
              hintText: 'Select destination port',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
              prefixIcon: Icon(Icons.anchor, size: 18, color: Color(0xFF1976D2)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            items: _ports.map((String port) {
              return DropdownMenuItem<String>(
                value: port,
                child: Text(
                  port,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDestinationPort = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select destination port';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildResourceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Voyage Resources'),
        _buildInputField(
          label: 'Fresh Water (liters)',
          hint: 'Enter liters',
          icon: Icons.water_drop,
          controller: _freshWaterController,
          keyboardType: TextInputType.number,
        ),
        _buildInputField(
          label: 'Diesel (liters)',
          hint: 'Enter liters',
          icon: Icons.local_gas_station,
          controller: _dieselController,
          keyboardType: TextInputType.number,
        ),
        _buildInputField(
          label: 'Life Jackets',
          hint: 'Enter quantity',
          icon: Icons.health_and_safety,
          controller: _lifeJacketsController,
          keyboardType: TextInputType.number,
        ),
        _buildInputField(
          label: 'Life Buoys',
          hint: 'Enter quantity',
          icon: Icons.safety_divider,
          controller: _lifeBuoysController,
          keyboardType: TextInputType.number,
        ),
        _buildInputField(
          label: 'Communication Devices',
          hint: 'Enter quantity',
          icon: Icons.radio,
          controller: _communicationDevicesController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPreviousCatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Fish catch data of previous voyage'),
        const SizedBox(height: 4),
        const Text(
          'Has the previous voyage catch data been submitted?',
          style: TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _previousCatchSubmitted = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _previousCatchSubmitted
                        ? Colors.green.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _previousCatchSubmitted
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: _previousCatchSubmitted
                            ? Colors.green
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Yes',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _previousCatchSubmitted = false),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_previousCatchSubmitted
                        ? Colors.red.shade50
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: !_previousCatchSubmitted
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        size: 14,
                        color: !_previousCatchSubmitted
                            ? Colors.red
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'No',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCrewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Crew Members'),
            TextButton.icon(
              onPressed: _addCrewMember,
              icon: const Icon(Icons.add, size: 14),
              label: const Text(
                'Add Member',
                style: TextStyle(fontSize: 12),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Add crew member names (excluding yourself)',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        ..._crewControllers.asMap().entries.map((entry) {
          int index = entry.key;
          TextEditingController controller = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Crew Member ${index + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: controller,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter crew member name',
                            hintStyle:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                            prefixIcon: Icon(Icons.person,
                                size: 18, color: const Color(0xFF1976D2)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_crewControllers.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 20),
                    child: IconButton(
                      onPressed: () => _removeCrewMember(index),
                      icon:
                      const Icon(Icons.remove_circle, size: 18, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 18,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  void dispose() {
    _voyageNumberController.dispose();
    _fishingLicenseController.dispose();
    _freshWaterController.dispose();
    _dieselController.dispose();
    _lifeJacketsController.dispose();
    _lifeBuoysController.dispose();
    _communicationDevicesController.dispose();
    for (var controller in _crewControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text(
          'New Voyage Intimation',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Owner Info Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1976D2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 18,
                        color: Colors.white,
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0D47A1),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Boat: ${widget.ownerData['boat_name'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Home Port: ${widget.ownerData['home_port'] ?? ''}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Voyage Basic Info
              _buildSectionTitle('Voyage Information'),

              _buildInputField(
                label: 'Voyage Number',
                hint: 'Enter voyage number (auto-generates if empty)',
                icon: Icons.confirmation_number,
                controller: _voyageNumberController,
                isRequired: false,
              ),

              _buildInputField(
                label: 'Fishing License Number',
                hint: 'Enter license number',
                icon: Icons.assignment,
                controller: _fishingLicenseController,
              ),

              _buildPortField(),

              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: 'Voyage Date',
                      date: _voyageDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Expected Return',
                      date: _expectedReturnDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Resources Section
              _buildResourceSection(),

              const SizedBox(height: 8),

              // Previous Catch Section
              _buildPreviousCatchSection(),

              const SizedBox(height: 8),

              // Crew Section
              _buildCrewSection(),

              // Submit Button
              _isSubmitting
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  strokeWidth: 2,
                ),
              )
                  : SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _submitVoyage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Submit Intimation',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}