import 'package:flutter/material.dart';

import '../../database/database_helper.dart';
import '../../services/api_services/api_service.dart';
import 'boat_owner_details_screen.dart';
import 'boat_selection_screen.dart';

class BoatOwnerLoginScreen extends StatefulWidget {
  const BoatOwnerLoginScreen({super.key});

  @override
  State<BoatOwnerLoginScreen> createState() => _BoatOwnerLoginScreenState();
}

class _BoatOwnerLoginScreenState extends State<BoatOwnerLoginScreen> {
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool otpSent = false;
  bool isLoading = false;

  static const Color primaryBlue = Color(0xFF1257C7);
  static const Color darkBlue = Color(0xFF07347F);
  static const Color lightBlue = Color(0xFFE9F7FF);
  static const Color iconBackground = Color(0xFFE7F3FF);
  static const Color borderColor = Color(0xFFD4DFEE);

  final ApiService _apiService = ApiService();
  final DatabaseHelper _db = DatabaseHelper();

  @override
  void dispose() {
    mobileController.dispose();
    otpController.dispose();
    _apiService.dispose();
    super.dispose();
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
              _buildTopSection(context),
              _buildLoginCard(),
              const SizedBox(height: 16),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

// ===========================================================================
// TOP SECTION
// ===========================================================================

  Widget _buildTopSection(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: 220,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFD7EEFF),
                  Color(0xFFF3FBFF),
                ],
              ),
            ),
          ),

// Back button
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: darkBlue,
                  size: 22,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),

          Positioned(
            left: 60,
            top: 12,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFB8D8F0),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance,
                  size: 16,
                  color: darkBlue,
                ),
              ),
            ),
          ),

          Positioned(
            left: 100,
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'FISHERIES DEPARTMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: darkBlue,
                  ),
                ),
                Text(
                  'UT OF LAKSHADWEEP',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),

// UTLCRAFT
          Positioned(
            left: 16,
            top: 60,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primaryBlue,
                      width: 1.5,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.directions_boat,
                        color: darkBlue,
                        size: 18,
                      ),
                      Positioned(
                        bottom: 4,
                        child: Container(
                          width: 18,
                          height: 1.5,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'UTLCRAFT',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkBlue,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),

// Boat Owner title
          Positioned(
            left: 16,
            top: 108,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Boat Owner',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: darkBlue,
                  ),
                ),
                const Text(
                  'To manage fishing voyage.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),

// Clouds
          Positioned(
            right: 0,
            top: 55,
            child: SizedBox(
              width: 80,
              height: 50,
              child: Stack(
                children: [
                  Positioned(
                    bottom: 2,
                    left: 6,
                    child: Container(
                      width: 65,
                      height: 22,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 8,
                    child: _cloudCircle(28),
                  ),
                  Positioned(
                    left: 38,
                    top: 2,
                    child: _cloudCircle(32),
                  ),
                  Positioned(
                    right: 0,
                    top: 12,
                    child: _cloudCircle(22),
                  ),
                ],
              ),
            ),
          ),

// Birds
          Positioned(
            right: 50,
            top: 90,
            child: _buildBird(size: 12),
          ),

          Positioned(
            right: 85,
            top: 105,
            child: _buildBird(size: 9),
          ),

// Palm trees
          Positioned(
            right: -5,
            bottom: 30,
            child: SizedBox(
              width: 120,
              height: 65,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 120,
                      height: 25,
                      decoration: BoxDecoration(
                        color: const Color(0xFF92C6D9).withOpacity(0.6),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(60),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 12,
                    bottom: 14,
                    child: _palmTree(height: 32),
                  ),
                  Positioned(
                    right: 42,
                    bottom: 12,
                    child: _palmTree(height: 24),
                  ),
                  Positioned(
                    right: 68,
                    bottom: 10,
                    child: _palmTree(height: 18),
                  ),
                ],
              ),
            ),
          ),

// Boat
          Positioned(
            right: -3,
            bottom: 28,
            child: SizedBox(
              width: 180,
              height: 130,
              child: CustomPaint(
                painter: FishingBoatPainter(),
              ),
            ),
          ),

// Ocean
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 55,
              child: CustomPaint(
                painter: OceanPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloudCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildBird({double size = 12}) {
    return CustomPaint(
      size: Size(size, size / 2),
      painter: BirdPainter(),
    );
  }

  Widget _palmTree({required double height}) {
    return SizedBox(
      width: 22,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 2,
              height: height * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF806B45),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Icon(
              Icons.park,
              size: height * 0.4,
              color: const Color(0xFF63A56A),
            ),
          ),
        ],
      ),
    );
  }

// ===========================================================================
// LOGIN CARD
// ===========================================================================

  Widget _buildLoginCard() {
    return Transform.translate(
      offset: const Offset(0, -16),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF174E91).withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Login',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 30,
              height: 3,
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            _buildMobileField(),

            const SizedBox(height: 12),

            if (otpSent) ...[
              _buildOtpField(),
              const SizedBox(height: 12),
            ],

            _buildActionButton(),
          ],
        ),
      ),
    );
  }

// ===========================================================================
// MOBILE FIELD
// ===========================================================================

  Widget _buildMobileField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.phone_outlined,
              size: 16,
              color: darkBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              enabled: !otpSent,
              style: const TextStyle(
                fontSize: 14,
                color: darkBlue,
              ),
              decoration: const InputDecoration(
                hintText: 'Mobile Number',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7B8798),
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }

// ===========================================================================
// OTP FIELD
// ===========================================================================

  Widget _buildOtpField() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: primaryBlue,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),

          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 16,
              color: darkBlue,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 14,
                color: darkBlue,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter OTP',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF7B8798),
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),

          InkWell(
            onTap: isLoading ? null : _resendOtp,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Resend',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

// ===========================================================================
// ACTION BUTTON
// ===========================================================================

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
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
            : Text(
          otpSent ? 'Verify OTP & Login' : 'Send OTP',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

// ===========================================================================
// FOOTER
// ===========================================================================

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      height: 100,
      color: const Color(0xFFF0FAFF),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 25,
              child: CustomPaint(
                painter: FooterWavePainter(),
              ),
            ),
          ),

          Positioned(
            left: 20,
            top: 8,
            child: Column(
              children: const [
                Icon(
                  Icons.wb_sunny,
                  size: 8,
                  color: Color(0xFF72A9CD),
                ),
                Icon(
                  Icons.location_city,
                  size: 30,
                  color: Color(0xFF73A8CC),
                ),
              ],
            ),
          ),

          Positioned(
            right: 25,
            top: 16,
            child: Icon(
              Icons.directions_boat,
              size: 22,
              color: darkBlue.withOpacity(0.9),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: 50,
            child: Column(
              children: const [
                Text(
                  'Foster Department',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: darkBlue,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Fisheries Department, UT of Lakshadweep',
                  style: TextStyle(
                    fontSize: 9,
                    color: darkBlue,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Designed by SNS',
                  style: TextStyle(
                    fontSize: 9,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ===========================================================================
// HANDLE ACTION
// ===========================================================================

  Future<void> _handleAction() async {
// ========================================================================
// SEND OTP
// ========================================================================

    if (!otpSent) {
      await _sendOtp();
      return;
    }

// ========================================================================
// VERIFY OTP
// ========================================================================

    await _verifyOtp();
  }

// ===========================================================================
// SEND OTP
// ===========================================================================

  Future<void> _sendOtp() async {
    final mobile = mobileController.text.trim();

    if (mobile.length != 10) {
      _showError(
        'Please enter a valid 10 digit mobile number',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _apiService.sendOtp(mobile);

      print('📤 Send OTP Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
// ====================================================================
// IMPORTANT:
// API response:
//
// {
//   "success": true,
//   "data": {
//      "otp_sent": true,
//      "dev_otp": "744928"
//   }
// }
//
// Therefore dev_otp is inside response['data'].
// ====================================================================

        String devOtp = '';

        final data = response['data'];

        if (data is Map) {
          devOtp = data['dev_otp']?.toString().trim() ?? '';
        }

        print('🔐 DEV OTP FROM API: $devOtp');

// ====================================================================
// OTP MUST BE 6 DIGITS
// ====================================================================

        if (devOtp.isEmpty) {
          setState(() {
            isLoading = false;
          });

          _showError(
            'OTP received but dev_otp was not found in API response',
          );

          return;
        }

// ====================================================================
// AUTOMATICALLY FILL OTP
// ====================================================================

        otpController.text = devOtp;

        otpController.selection = TextSelection.fromPosition(
          TextPosition(
            offset: otpController.text.length,
          ),
        );

// ====================================================================
// CHANGE BUTTON FROM "SEND OTP"
// TO "VERIFY OTP & LOGIN"
// ====================================================================

        setState(() {
          isLoading = false;
          otpSent = true;
        });

        print('✅ OTP automatically filled: ${otpController.text}');
        print('✅ otpSent = true');
        print('✅ Button changed to Verify OTP & Login');

        _showSuccess(
          'OTP filled automatically',
        );
      } else {
        setState(() {
          isLoading = false;
        });

        _showError(
          response['message'] ??
              'Failed to send OTP',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print('❌ Send OTP Error: $e');

      _showError(
        'Network error: ${e.toString()}',
      );
    }
  }

// ===========================================================================
// VERIFY OTP
// ===========================================================================

  Future<void> _verifyOtp() async {
    final mobile = mobileController.text.trim();
    final otp = otpController.text.trim();

// ========================================================================
// Because OTP is automatically filled from dev_otp, the user does NOT
// need to type anything.
// ========================================================================

    if (mobile.length != 10) {
      _showError(
        'Please enter a valid mobile number',
      );
      return;
    }

    if (otp.length != 6) {
      _showError(
        'OTP is not available. Please resend OTP.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      print('🔑 VERIFY OTP');
      print('📱 Mobile: $mobile');
      print('🔐 OTP: $otp');

      final response = await _apiService.verifyOtp(
        mobile,
        otp,
      );

      print('📥 Verify OTP Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final data = response['data'];

        final int profileData =
            int.tryParse(
              data?['profile_data']?.toString() ?? '0',
            ) ??
                0;

// ==================================================================
// SAVE BOAT OWNER DETAILS
// ==================================================================

        if (data != null && data['user'] != null) {
          final user = data['user'];

          final String userName =
              user['name']?.toString() ?? 'Boat Owner';

          final String userMobile =
              user['mobile_no']?.toString() ?? mobile;

          await _db.insertBoatOwner({
            'owner_name': userName,
            'address': '',
            'aadhaar': '',
            'mobile': userMobile,
            'home_port_id': null,
            'home_port_name': null,
            'photo_path': null,
          });

          print(
            '✅ Boat owner saved to database: $userName',
          );
        }

        setState(() {
          isLoading = false;
        });

// ==================================================================
// NAVIGATION
// ==================================================================

        if (profileData == 0) {
          print(
            '🔑 New User - Navigating to BoatOwnerDetailsScreen',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const BoatOwnerDetailsScreen(),
            ),
          );
        } else if (profileData == 1) {
          print(
            '🔑 Existing User - Navigating to BoatSelectionScreen',
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
              const BoatSelectionScreen(),
            ),
          );
        } else {
          _showError(
            'Invalid profile data received',
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });

        _showError(
          response['message'] ??
              'OTP verification failed',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print('❌ Verify OTP Error: $e');

      _showError(
        'Network error: ${e.toString()}',
      );
    }
  }

// ===========================================================================
// RESEND OTP
// ===========================================================================

  Future<void> _resendOtp() async {
    final mobile = mobileController.text.trim();

    if (mobile.length != 10) {
      _showError(
        'Please enter a valid mobile number',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      print('🔄 RESEND OTP');

      final response = await _apiService.sendOtp(mobile);

      print('📤 Resend OTP Response: $response');

      if (!mounted) return;

      if (response['success'] == true) {
// ====================================================================
// AGAIN READ:
// response['data']['dev_otp']
// ====================================================================

        String devOtp = '';

        final data = response['data'];

        if (data is Map) {
          devOtp = data['dev_otp']?.toString().trim() ?? '';
        }

        print('🔐 RESEND DEV OTP: $devOtp');

        if (devOtp.isNotEmpty) {
// Replace old OTP
          otpController.text = devOtp;

          otpController.selection =
              TextSelection.fromPosition(
                TextPosition(
                  offset: otpController.text.length,
                ),
              );

          setState(() {
            isLoading = false;
            otpSent = true;
          });

          print(
            '✅ New OTP automatically filled: $devOtp',
          );

          _showSuccess(
            'New OTP filled automatically',
          );
        } else {
          setState(() {
            isLoading = false;
          });

          _showError(
            'New OTP was not found in API response',
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });

        _showError(
          response['message'] ??
              'Failed to resend OTP',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      print('❌ Resend OTP Error: $e');

      _showError(
        'Network error: ${e.toString()}',
      );
    }
  }

// ===========================================================================
// ERROR MESSAGE
// ===========================================================================

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

// ===========================================================================
// SUCCESS MESSAGE
// ===========================================================================

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

// =============================================================================
// FISHING BOAT PAINTER
// =============================================================================

class FishingBoatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 280;
    final scaleY = size.height / 200;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final hullPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF176EAA),
          Color(0xFF073B72),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(
        const Rect.fromLTWH(0, 100, 250, 70),
      );

    final hull = Path();

    hull.moveTo(25, 110);
    hull.lineTo(250, 115);
    hull.lineTo(230, 155);

    hull.quadraticBezierTo(
      195,
      180,
      95,
      170,
    );

    hull.quadraticBezierTo(
      50,
      165,
      25,
      110,
    );

    hull.close();

    canvas.drawPath(
      hull,
      hullPaint,
    );

    final outlinePaint = Paint()
      ..color = const Color(0xFF073C67)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(
      hull,
      outlinePaint,
    );

    final deckPaint = Paint()
      ..color = const Color(0xFFF7FAFC)
      ..style = PaintingStyle.fill;

    final deck = Path();

    deck.moveTo(30, 105);
    deck.lineTo(240, 108);
    deck.lineTo(230, 120);
    deck.lineTo(38, 118);
    deck.close();

    canvas.drawPath(
      deck,
      deckPaint,
    );

    final cabinPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cabin = Path();

    cabin.moveTo(75, 60);
    cabin.lineTo(180, 60);
    cabin.lineTo(192, 108);
    cabin.lineTo(70, 108);
    cabin.close();

    canvas.drawPath(
      cabin,
      cabinPaint,
    );

    canvas.drawPath(
      cabin,
      outlinePaint,
    );

    final topPaint = Paint()
      ..color = const Color(0xFF0E5B91)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(
        70,
        58,
        122,
        9,
      ),
      topPaint,
    );

    for (int i = 0; i < 3; i++) {
      final left = 80.0 + i * 30;

      final window = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          left,
          72,
          18,
          22,
        ),
        const Radius.circular(3),
      );

      final windowPaint = Paint()
        ..color = const Color(0xFF3B92B7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        window,
        windowPaint,
      );

      canvas.drawRRect(
        window,
        outlinePaint,
      );
    }

    final upperCabin = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final upper = Path();

    upper.moveTo(100, 32);
    upper.lineTo(158, 32);
    upper.lineTo(165, 60);
    upper.lineTo(95, 60);
    upper.close();

    canvas.drawPath(
      upper,
      upperCabin,
    );

    canvas.drawPath(
      upper,
      outlinePaint,
    );

    for (int i = 0; i < 2; i++) {
      final left = 103.0 + i * 24;

      canvas.drawRect(
        Rect.fromLTWH(
          left,
          38,
          16,
          14,
        ),
        Paint()
          ..color = const Color(0xFF3189AE),
      );
    }

    final mastPaint = Paint()
      ..color = const Color(0xFF17465F)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(135, 32),
      const Offset(135, 2),
      mastPaint,
    );

    canvas.drawLine(
      const Offset(135, 10),
      const Offset(170, 18),
      mastPaint,
    );

    canvas.drawLine(
      const Offset(135, 18),
      const Offset(170, 18),
      mastPaint,
    );

    final flagPaint = Paint()
      ..color = const Color(0xFFFF9933)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(
        137,
        3,
        25,
        5,
      ),
      flagPaint,
    );

    final flagWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(
        137,
        8,
        25,
        5,
      ),
      flagWhite,
    );

    final flagGreen = Paint()
      ..color = const Color(0xFF138808)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      const Rect.fromLTWH(
        137,
        13,
        25,
        5,
      ),
      flagGreen,
    );

    final railPaint = Paint()
      ..color = const Color(0xFF244D63)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final x = 45.0 + i * 45;

      canvas.drawLine(
        Offset(x, 95),
        Offset(x, 78),
        railPaint,
      );
    }

    canvas.drawLine(
      const Offset(42, 78),
      const Offset(240, 85),
      railPaint,
    );

    final ringPaint = Paint()
      ..color = const Color(0xFFE86D26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      const Offset(185, 100),
      10,
      ringPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

// =============================================================================
// OCEAN PAINTER
// =============================================================================

class OceanPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFBCEBFA),
          Color(0xFF66C8E6),
          Color(0xFF55BBD9),
        ],
      ).createShader(
        Rect.fromLTWH(
          0,
          0,
          size.width,
          size.height,
        ),
      );

    final waterPath = Path();

    waterPath.moveTo(
      0,
      size.height * 0.15,
    );

    waterPath.quadraticBezierTo(
      size.width * 0.20,
      0,
      size.width * 0.40,
      size.height * 0.12,
    );

    waterPath.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.25,
      size.width,
      size.height * 0.10,
    );

    waterPath.lineTo(
      size.width,
      size.height,
    );

    waterPath.lineTo(
      0,
      size.height,
    );

    waterPath.close();

    canvas.drawPath(
      waterPath,
      waterPaint,
    );

    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 3; i++) {
      final wave = Path();

      final y = 12.0 + i * 14;

      wave.moveTo(
        -20,
        y,
      );

      wave.quadraticBezierTo(
        size.width * 0.18,
        y - 7,
        size.width * 0.36,
        y,
      );

      wave.quadraticBezierTo(
        size.width * 0.56,
        y + 8,
        size.width * 0.75,
        y,
      );

      wave.quadraticBezierTo(
        size.width * 0.88,
        y - 5,
        size.width + 20,
        y + 2,
      );

      canvas.drawPath(
        wave,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

// =============================================================================
// BIRD PAINTER
// =============================================================================

class BirdPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF70B9D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path();

    path.moveTo(
      0,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.25,
      0,
      size.width * 0.5,
      size.height,
    );

    path.quadraticBezierTo(
      size.width * 0.75,
      0,
      size.width,
      size.height,
    );

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

// =============================================================================
// FOOTER WAVE
// =============================================================================

class FooterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();

    path.moveTo(
      0,
      size.height * 0.55,
    );

    path.quadraticBezierTo(
      size.width * 0.18,
      0,
      size.width * 0.36,
      size.height * 0.50,
    );

    path.quadraticBezierTo(
      size.width * 0.56,
      size.height,
      size.width * 0.74,
      size.height * 0.45,
    );

    path.quadraticBezierTo(
      size.width * 0.88,
      0,
      size.width,
      size.height * 0.48,
    );

    path.lineTo(
      size.width,
      0,
    );

    path.lineTo(
      0,
      0,
    );

    path.close();

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}
