import 'package:flutter/material.dart';
import 'owner_dashboard.dart';
import '../database/database_helper.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _boatNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedHomePort;
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  final List<String> _homePorts = [
    'Agati',
    'Kavarati',
    'Androdh',
    'Kalpeni',
    'Kadmat',
    'Amini',
    'Chetlat',
    'Bitra'
  ];

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  void _submitRegistration() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedHomePort == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select home port'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if mobile number already exists
      setState(() {
        _isLoading = true;
      });

      try {
        bool mobileExists = await _databaseHelper.checkMobileExists(_mobileNumberController.text);
        if (mobileExists) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mobile number already registered'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Directly proceed with registration without confirmation dialog
        await _performRegistration();

      } catch (e) {
        print('Registration error: $e');
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _performRegistration() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
              ),
              const SizedBox(height: 16),
              const Text('Clearing old data and registering...'),
            ],
          ),
        ),
      );

      // First, clear all existing data directly
      await _databaseHelper.clearAllData();
      print('All previous data cleared successfully');

      // Prepare owner data
      Map<String, dynamic> ownerData = {
        'owner_name': _ownerNameController.text,
        'boat_name': _boatNameController.text,
        'address': _addressController.text,
        'registration_number': _registrationNumberController.text,
        'aadhar_number': _aadharNumberController.text,
        'mobile_number': _mobileNumberController.text,
        'home_port': _selectedHomePort!,
        'password': _passwordController.text,
        'registration_date': DateTime.now().toIso8601String(),
      };

      // Insert into database
      int ownerId = await _databaseHelper.insertBoatOwner(ownerData);

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (ownerId > 0) {
        // Get the inserted owner data
        Map<String, dynamic>? owner = await _databaseHelper.getBoatOwnerById(ownerId);

        if (owner != null) {
          // Save login session immediately after registration
          await _databaseHelper.saveLoginSession(
            ownerId,
            _mobileNumberController.text,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate directly to dashboard
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => OwnerDashboard(ownerData: owner),
              ),
                  (route) => false,
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Registration process error: $e');
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during registration: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Header with Back Button
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2), // Blue background for app bar
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: Colors.white, // White back arrow
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Boat Owner Registration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text
                      ),
                    ),
                  ],
                ),
              ),

              // Profile Image
              Container(
                padding: const EdgeInsets.only(top: 20),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1976D2),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Container(
                          color: Colors.blue.shade50,
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Registration Title
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: const Text(
                  'One-Time Registration',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),

              // Important Notice - Data Clearing Warning
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.red.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'All fields are mandatory',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Registration Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Owner Name
                      _buildFormField(
                        controller: _ownerNameController,
                        label: 'Owner Name',
                        hintText: 'Enter Owner full name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Owner name is required';
                          }
                          if (value.length < 3) {
                            return 'Enter valid name (min 3 chars)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Boat Name
                      _buildFormField(
                        controller: _boatNameController,
                        label: 'Boat Name',
                        hintText: 'Enter fishing boat name',
                        prefixIcon: Icons.directions_boat,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Boat name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Address
                      _buildFormField(
                        controller: _addressController,
                        label: 'Address',
                        hintText: 'Enter complete address',
                        prefixIcon: Icons.location_on_outlined,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Address is required';
                          }
                          if (value.length < 10) {
                            return 'Enter complete address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Registration Number
                      _buildFormField(
                        controller: _registrationNumberController,
                        label: 'Registration Number',
                        hintText: 'Enter boat registration number',
                        prefixIcon: Icons.confirmation_number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Registration number is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Aadhar Number
                      _buildFormField(
                        controller: _aadharNumberController,
                        label: 'Aadhar Number',
                        hintText: '12-digit Aadhar number',
                        prefixIcon: Icons.badge_outlined,
                        keyboardType: TextInputType.number,
                        maxLength: 12,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Aadhar number is required';
                          }
                          if (value.length != 12) {
                            return 'Enter 12-digit Aadhar number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Mobile Number
                      _buildFormField(
                        controller: _mobileNumberController,
                        label: 'Mobile Number',
                        hintText: '10-digit mobile number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mobile number is required';
                          }
                          if (value.length != 10) {
                            return 'Enter valid 10-digit number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Home Port Dropdown
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue.shade300,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedHomePort,
                          decoration: InputDecoration(
                            labelText: 'Home Port (Base of Operation)',
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1976D2),
                            ),
                            hintText: 'Select your home port',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF1976D2).withOpacity(0.7),
                            ),
                            prefixIcon: const Icon(
                              Icons.anchor,
                              size: 22,
                              color: Color(0xFF1976D2),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                          ),
                          items: _homePorts.map((String port) {
                            return DropdownMenuItem<String>(
                              value: port,
                              child: Text(
                                port,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedHomePort = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select home port';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1976D2),
                          ),
                          hintText: 'Create secure password',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1976D2).withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 22,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF1976D2),
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              color: Color(0xFF1976D2),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1976D2),
                          ),
                          hintText: 'Re-enter password',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF1976D2).withOpacity(0.7),
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            size: 22,
                            color: Color(0xFF1976D2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xFF1976D2),
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible = !_confirmPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.blue.shade300,
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(
                              color: Color(0xFF1976D2),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm password';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 25),

                      // Submit Button
                      _isLoading
                          ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF1976D2),
                        ),
                      )
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            shadowColor: Colors.blue.shade300,
                          ),
                          child: const Text(
                            'Submit Registration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Data Clearing Information
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Note:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Your Registration will be\nreviewed and verified by the port \nofficer before you can login and apply\n for permits')
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData prefixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF1976D2),
        ),
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 13,
          color: const Color(0xFF1976D2).withOpacity(0.7),
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 22,
          color: const Color(0xFF1976D2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.blue.shade300,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          borderSide: BorderSide(
            color: Color(0xFF1976D2),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildInfoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red.shade800,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _boatNameController.dispose();
    _addressController.dispose();
    _registrationNumberController.dispose();
    _aadharNumberController.dispose();
    _mobileNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}