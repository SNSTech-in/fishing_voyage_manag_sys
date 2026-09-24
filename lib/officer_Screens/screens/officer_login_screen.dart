import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../officer_main_screen.dart'; // Corrected path
import '../../services/api_services/officer_api_service.dart';

class OfficerLoginScreen extends StatefulWidget {
  @override
  _OfficerLoginScreenState createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final OfficerApiService _api = OfficerApiService();

  // ---------------------------------------------------------------------------
  // MARINE THEME COLORS
  // ---------------------------------------------------------------------------
  static const Color bgPage = Color(0xFFECF5FB);
  static const Color marine600 = Color(0xFF1565C0);
  static const Color marine700 = Color(0xFF0D47A1);
  static const Color marine900 = Color(0xFF092B65);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color sky100 = Color(0xFFE0EFFF);
  static const Color sky200 = Color(0xFFBAE0FD);
  static const Color emerald = Color(0xFF10B981);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMessage = null; });

    try {
      // CALL THE REAL SERVER: /auth/admin/login
      final response = await _api.loginAdmin(
        _userIdController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success'] == true) {
        // EXTRACT REAL TOKEN FROM SERVER RESPONSE
        String token = response['data']['access_token'];
        String? refreshToken = response['data']['refresh_token']?.toString();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('officer_token', token);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await prefs.setString('refresh_token', refreshToken);
        }
        await prefs.setBool('officer_logged_in', true);

        print('🔑 Officer token saved: ${token.substring(0, 20)}...');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => OfficerMainScreen()),
          );
        }
      } else {
        setState(() {
          _loading = false;
          _errorMessage = response['message'] ?? 'Invalid Username or Password';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = 'Network Error. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopHeader(context),
              _buildHeroSection(),
              _buildLoginCard(),
              _buildBottomFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP HEADER - Back button + building icon + dept text + Online pill
  // ===========================================================================

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 14,
        bottom: 10,
      ),
      child: Row(
        children: [
          // Back button
          _circleIconButton(
            icon: Icons.arrow_back,
            onTap: () {
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          // Building icon
          _circleIconButton(
            icon: Icons.account_balance,
          ),
          const SizedBox(width: 12),
          // Department text
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FISHERIES DEPARTMENT',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: slate900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'UT OF LAKSHADWEEP',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: slate500,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Online pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: sky200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: emerald,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: marine600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 22, color: const Color(0xFF334155)),
      ),
    );
  }

  // ===========================================================================
  // HERO SECTION - UTLCRAFT badge + title + crest + marine waves
  // ===========================================================================

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 6,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UTLCRAFT pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: sky200, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [marine600, indigo800],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.verified_user,
                              size: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'UTLCRAFT',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: marine900,
                              letterSpacing: 0.7,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: emerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Fisheries Officer',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: slate900,
                        height: 1.15,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: marine600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Enforcement & Coastal Control',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: slate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right crest
              Container(
                width: 96,
                height: 96,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sky200, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: marine600.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: CustomPaint(painter: _CrestPainter()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Marine waves at bottom of hero
          SizedBox(
            height: 32,
            child: CustomPaint(painter: _HeroWavePainter()),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // LOGIN CARD - white card with crest, title, credentials, sign-in
  // ===========================================================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Maritime Regulatory Service pill
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sky100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sky200, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: emerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'MARITIME REGULATORY SERVICE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: marine600,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Crest shield
            Center(
              child: Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: sky200, width: 1),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [marine600, indigo800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.shield_moon_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fisheries Officer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: slate900,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: slate500,
              ),
            ),
            const SizedBox(height: 26),

            // Username field
            TextFormField(
              controller: _userIdController,
              style: const TextStyle(fontSize: 15, color: slate900),
              decoration: _inputDecoration(
                hint: 'Username',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Username is required' : null,
            ),
            const SizedBox(height: 16),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 15, color: slate900),
              decoration: _inputDecoration(
                hint: 'Password',
                icon: Icons.lock_outline_rounded,
              ).copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    size: 20,
                    color: slate400,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Password is required' : null,
            ),

            // Reset access code link
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Reset Access Code?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: marine600,
                  ),
                ),
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFDC2626).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Sign In button
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: marine600,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: marine600.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),

            // Card sub-footer: Encrypted channel
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: marine600,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Encrypted Channel',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: slate500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'v4.2-COAST',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: slate500,
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

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: slate400, fontSize: 15),
      prefixIcon: Icon(icon, size: 22, color: slate400),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: marine600, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM FOOTER - Branding
  // ===========================================================================

  Widget _buildBottomFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      color: bgPage,
      child: Row(
        children: [
          _footerIcon(Icons.apartment),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Foster Department',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: slate900,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fisheries Department, UT of Lakshadweep',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: slate600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Designed by SNS',
                  style: TextStyle(fontSize: 11, color: slate500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _footerIcon(Icons.directions_boat),
        ],
      ),
    );
  }

  Widget _footerIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: sky100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 22, color: marine600),
    );
  }
}

// =============================================================================
// HERO WAVE PAINTER - 3-layer marine waves
// =============================================================================

class _HeroWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Cyan layer
    final cyan = Paint()
      ..color = const Color(0xFFA2E1F6)
      ..style = PaintingStyle.fill;
    final cyanPath = Path()
      ..moveTo(0, size.height * 0.50)
      ..cubicTo(
        size.width * 0.20, size.height * 0.25,
        size.width * 0.30, size.height * 0.75,
        size.width * 0.50, size.height * 0.38,
      )
      ..cubicTo(
        size.width * 0.70, size.height * 0.10,
        size.width * 0.82, size.height * 0.55,
        size.width, size.height * 0.30,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(cyanPath, cyan);

    // Sky layer
    final sky = Paint()
      ..color = const Color(0xFF5BBCE4).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final skyPath = Path()
      ..moveTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.15, size.height * 0.44,
        size.width * 0.33, size.height * 0.82,
        size.width * 0.53, size.height * 0.52,
      )
      ..cubicTo(
        size.width * 0.72, size.height * 0.26,
        size.width * 0.85, size.height * 0.70,
        size.width, size.height * 0.50,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(skyPath, sky);

    // Deep layer
    final deep = Paint()
      ..color = const Color(0xFF2B8DC7).withOpacity(0.9)
      ..style = PaintingStyle.fill;
    final deepPath = Path()
      ..moveTo(0, size.height * 0.80)
      ..cubicTo(
        size.width * 0.22, size.height * 0.62,
        size.width * 0.38, size.height * 0.88,
        size.width * 0.60, size.height * 0.68,
      )
      ..cubicTo(
        size.width * 0.78, size.height * 0.50,
        size.width * 0.90, size.height * 0.80,
        size.width, size.height * 0.62,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(deepPath, deep);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// CREST PAINTER - circular officer shield emblem
// =============================================================================

class _CrestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer dashed circle
    final dashPaint = Paint()
      ..color = const Color(0xFF1E40AF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    const dashCount = 30;
    for (int i = 0; i < dashCount; i++) {
      final start = (i * 2 * 3.14159 / dashCount);
      final end = start + (3.14159 / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 1),
        start,
        end - start,
        false,
        dashPaint,
      );
    }

    // Inner filled circle
    final innerPaint = Paint()
      ..color = const Color(0xFFEFF6FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.86, innerPaint);

    final innerBorder = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.86, innerBorder);

    // Anchor-like emblem
    final linePaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.55),
      Offset(center.dx, center.dy + radius * 0.45),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius * 0.28, center.dy - radius * 0.30),
      Offset(center.dx + radius * 0.28, center.dy - radius * 0.30),
      linePaint,
    );
    final hullPath = Path()
      ..moveTo(center.dx - radius * 0.55, center.dy + radius * 0.10)
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.70,
        center.dx + radius * 0.55,
        center.dy + radius * 0.10,
      );
    canvas.drawPath(hullPath, linePaint);

    final dotPaint = Paint()
      ..color = const Color(0xFF1D4ED8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy - radius * 0.55),
      2.5,
      dotPaint,
    );

    // Amber triangle top
    final trianglePath = Path()
      ..moveTo(center.dx, center.dy - radius * 0.95)
      ..lineTo(center.dx + 4, center.dy - radius * 0.75)
      ..lineTo(center.dx - 4, center.dy - radius * 0.75)
      ..close();
    final amberPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.fill;
    canvas.drawPath(trianglePath, amberPaint);

    // Green side strokes
    final greenPaint = Paint()
      ..color = const Color(0xFF059669)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final leftWave = Path()
      ..moveTo(center.dx - radius * 0.72, center.dy + radius * 0.25)
      ..quadraticBezierTo(
        center.dx - radius * 0.85,
        center.dy - radius * 0.05,
        center.dx - radius * 0.72,
        center.dy - radius * 0.35,
      );
    canvas.drawPath(leftWave, greenPaint);

    final rightWave = Path()
      ..moveTo(center.dx + radius * 0.72, center.dy + radius * 0.25)
      ..quadraticBezierTo(
        center.dx + radius * 0.85,
        center.dy - radius * 0.05,
        center.dx + radius * 0.72,
        center.dy - radius * 0.35,
      );
    canvas.drawPath(rightWave, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}