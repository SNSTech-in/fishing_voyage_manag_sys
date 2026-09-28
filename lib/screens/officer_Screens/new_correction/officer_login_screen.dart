import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';
import '../../../services/api_services/officer_api_service.dart';
import 'officer_dashboard_screen.dart';

class OfficerLoginScreen extends StatefulWidget {
  const OfficerLoginScreen({super.key});

  @override
  State<OfficerLoginScreen> createState() => _OfficerLoginScreenState();
}

class _OfficerLoginScreenState extends State<OfficerLoginScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  final OfficersApiService _api = OfficersApiService();
  final DatabaseHelper _db = DatabaseHelper();

  // ---------------------------------------------------------------------------
  // THEME COLORS
  // ---------------------------------------------------------------------------
  static const Color primaryBlue = Color(0xFF1257C7);
  static const Color darkBlue = Color(0xFF07347F);
  static const Color iconBackground = Color(0xFFE7F3FF);
  static const Color borderColor = Color(0xFFD4DFEE);
  static const Color slate400 = Color(0xFF94A3B8);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final response = await _api.login(
        _userIdController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;

        // ── Extract token fields ────────────────────────────────
        final String? token = data['access_token']?.toString();
        final String? refreshToken = data['refresh_token']?.toString();
        final String? tokenType = data['token_type']?.toString();
        final int? expiresIn = data['expires_in'] is int
            ? data['expires_in'] as int
            : int.tryParse(data['expires_in']?.toString() ?? '');

        // ── Extract user identity (API uses 'user_id', not 'id') ──
        int? officerId;
        String? officerName;
        final user = data['user'];
        if (user is Map) {
          officerId = user['user_id'] is int
              ? user['user_id'] as int
              : int.tryParse(user['user_id']?.toString() ?? '');
          officerName = user['name']?.toString();
        }

        if (token == null || token.isEmpty) {
          setState(() {
            _loading = false;
            _errorMessage = 'Login succeeded but no token returned.';
          });
          return;
        }

        // ── Save to SQLite ──────────────────────────────────────
        await _db.saveOfficerSession(
          accessToken: token,
          refreshToken: refreshToken,
          tokenType: tokenType,
          expiresIn: expiresIn,
          officerId: officerId,
          officerName: officerName,
        );

        debugPrint('✅ Officer session saved: id=$officerId name=$officerName');

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OfficerDashboardScreen()),
          );
        }
      } else {
        setState(() {
          _loading = false;
          _errorMessage = response['message']?.toString() ??
              'Invalid Username or Password';
        });
      }
    } catch (e) {
      debugPrint('❌ Officer login error: $e');
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
  // TOP HERO SECTION
  // ===========================================================================
  Widget _buildTopSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD7EEFF), Color(0xFFF3FBFF)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: 8,
            child: IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, color: darkBlue),
            ),
          ),
          Positioned(
            left: 60,
            top: 60,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryBlue, width: 1.5),
                  ),
                  child: const Icon(Icons.directions_boat,
                      color: darkBlue, size: 20),
                ),
                const SizedBox(width: 8),
                const Text(
                  'UTLCRAFT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: darkBlue,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 16,
            top: 115,
            child: Text(
              'Fisheries Officer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkBlue,
              ),
            ),
          ),
          const Positioned(
            left: 16,
            top: 145,
            child: Text(
              'Enforcement & Coastal Control',
              style: TextStyle(fontSize: 11, color: darkBlue),
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
        child: Form(
          key: _formKey,
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
              _buildUsernameField(),
              const SizedBox(height: 12),
              _buildPasswordField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
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
            child: const Icon(Icons.person_outline, size: 16, color: darkBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _userIdController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 14, color: darkBlue),
              decoration: const InputDecoration(
                hintText: 'Username',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF7B8798)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Username is required'
                  : null,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1.5),
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
            child: const Icon(Icons.lock_outline, size: 16, color: darkBlue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _loading ? null : _login(),
              style: const TextStyle(fontSize: 14, color: darkBlue),
              decoration: const InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF7B8798)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              validator: (v) =>
              (v == null || v.isEmpty) ? 'Password is required' : null,
            ),
          ),
          IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: slate400,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      height: 80,
      color: const Color(0xFFF0FAFF),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Fisheries Department',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: darkBlue,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Fisheries Department, UT of Lakshadweep',
              style: TextStyle(fontSize: 9, color: darkBlue),
            ),
          ],
        ),
      ),
    );
  }
}