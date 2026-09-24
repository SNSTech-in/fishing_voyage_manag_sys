import 'package:flutter/material.dart';

import 'boat_owner/boat_owner_login_screen.dart';
import '../officer/screens/officer_login_screen.dart';
import '../officer/officer_main_screen.dart';

class DepartLoginSelection extends StatelessWidget {
  const DepartLoginSelection({super.key});

  // ---------------------------------------------------------------------------
  // COLORS
  // ---------------------------------------------------------------------------

  static const Color primaryBlue = Color(0xFF0756C8);
  static const Color darkBlue = Color(0xFF082E70);
  static const Color textBlue = Color(0xFF082E70);
  static const Color lightBlue = Color(0xFFDDF3FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              _buildHeroSection(context),
              const SizedBox(height: 16),
              _buildExploreFeatures(context),
              const SizedBox(height: 16),
              _buildDepartmentFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HEADER - Slightly reduced
  // ===========================================================================

  Widget _buildHeader() {
    return SizedBox(
      height: 100,
      child: Stack(
        children: [
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              width: double.infinity,
              height: 100,
              color: primaryBlue,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 16,
              top: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.anchor,
                    color: primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fisheries Department',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'UT of Lakshadweep',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
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
    );
  }

  // ===========================================================================
  // HERO SECTION - Slightly reduced
  // ===========================================================================

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      color: lightBlue,
      child: Stack(
        children: [
          Positioned(
            right: 10,
            top: 25,
            child: _buildCloud(),
          ),
          Positioned(
            right: 80,
            top: 55,
            child: _buildSmallCloud(),
          ),
          Positioned(
            right: 175,
            top: 48,
            child: _buildBird(size: 16),
          ),
          Positioned(
            right: 215,
            top: 70,
            child: _buildBird(size: 12),
          ),
          Positioned(
            right: -3,
            bottom: 50,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildPalmTree(
                  height: 42,
                  width: 32,
                ),
                const SizedBox(width: 2),
                _buildPalmTree(
                  height: 58,
                  width: 36,
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            top: 15,
            right: 110,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fishing Voyage\nManagement\nSystem',
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.1,
                    fontWeight: FontWeight.w700,
                    color: textBlue,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Digital solution for safe, efficient\n'
                      'and transparent fishing operations.',
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.3,
                    color: Color(0xFF4C5968),
                  ),
                ),
                const SizedBox(height: 10),
                _buildGetStartedButton(context),
              ],
            ),
          ),
          Positioned(
            right: 8,
            bottom: 25,
            child: _buildBoatIllustration(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildWater(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // GET STARTED BUTTON - Original style with icon
  // ===========================================================================

  Widget _buildGetStartedButton(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 42,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to Boat Owner Login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BoatOwnerLoginScreen(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.anchor,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BOAT ILLUSTRATION - Slightly reduced
  // ===========================================================================

  Widget _buildBoatIllustration() {
    return SizedBox(
      width: 165,
      height: 105,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 5,
            left: 8,
            right: 4,
            child: Container(
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF5E9CB8).withOpacity(0.28),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            bottom: 14,
            left: 2,
            child: Transform.rotate(
              angle: -0.04,
              child: Container(
                width: 150,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0B65A5),
                      Color(0xFF06477C),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(38),
                    bottomRight: Radius.circular(19),
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                  border: Border.all(
                    color: const Color(0xFF073C66),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 38,
            left: 45,
            child: Container(
              width: 62,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF194F72),
                  width: 1.5,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0A6097),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _boatWindow(),
                      _boatWindow(),
                      _boatWindow(),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 66,
            left: 63,
            child: Container(
              width: 36,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: const Color(0xFF194F72),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Center(
                child: Icon(
                  Icons.window,
                  color: Color(0xFF1681B8),
                  size: 16,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 66,
            left: 80,
            child: Container(
              width: 2,
              height: 32,
              color: const Color(0xFF194F72),
            ),
          ),
          Positioned(
            bottom: 94,
            left: 82,
            child: Container(
              width: 18,
              height: 10,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF9933),
                    Colors.white,
                    Color(0xFF138808),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.circle,
                  size: 3.5,
                  color: Color(0xFF000080),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 46,
            right: 2,
            child: Container(
              width: 42,
              height: 18,
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFF194F72),
                    width: 1.5,
                  ),
                  left: BorderSide(
                    color: Color(0xFF194F72),
                    width: 1.5,
                  ),
                  right: BorderSide(
                    color: Color(0xFF194F72),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 22,
            right: 12,
            child: Icon(
              Icons.anchor,
              size: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boatWindow() {
    return Container(
      width: 10,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF1B86B9),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ===========================================================================
  // WATER
  // ===========================================================================

  Widget _buildWater() {
    return SizedBox(
      height: 42,
      child: CustomPaint(
        painter: WaterPainter(),
      ),
    );
  }

  // ===========================================================================
  // EXPLORE FEATURES - VERTICAL LIST WITH FULL DESCRIPTIONS
  // ===========================================================================

  Widget _buildExploreFeatures(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Explore Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textBlue,
            ),
          ),
          const SizedBox(height: 12),
          // Boat Owner - Navigates to Boat Owner Login
          _buildFeatureCard(
            context: context,
            icon: Icons.directions_boat,
            title: 'Boat Owner',
            description:
            'Register and manage your boat\ninformation and documents.',
            iconColor: const Color(0xFF0D5AA7),
            backgroundColor: const Color(0xFFDCEFFF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BoatOwnerLoginScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Crew Login
          _buildFeatureCard(
            context: context,
            icon: Icons.people_alt,
            title: 'Crew Login',
            description:
            'Crew members can login and manage\nvoyage and personal details.',
            iconColor: const Color(0xFF209B57),
            backgroundColor: const Color(0xFFE1F5E7),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Crew Login feature coming soon'),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          // Fisheries Officers
          _buildFeatureCard(
            context: context,
            icon: Icons.person,
            title: 'Fisheries Officers',
            description:
            'Officers can verify, approve and monitor\nvoyage activities.',
            iconColor: const Color(0xFF5B4BB7),
            backgroundColor: const Color(0xFFEAE4FF),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => OfficerLoginScreen()),
              );
            },
          ),
          const SizedBox(height: 10),
          // Administrator
          _buildFeatureCard(
            context: context,
            icon: Icons.admin_panel_settings,
            title: 'Administrator',
            description:
            'System administration, user management\nand configuration.',
            iconColor: const Color(0xFFE68A0B),
            backgroundColor: const Color(0xFFFFF0D9),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Administrator feature coming soon'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // FEATURE CARD - Original style with full description and onTap
  // ===========================================================================

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 26,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      color: Color(0xFF5B6570),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 2),
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF79A7D2),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // DEPARTMENT FOOTER
  // ===========================================================================

  Widget _buildDepartmentFooter() {
    return Container(
      width: double.infinity,
      height: 120,
      color: const Color(0xFFE8F7FF),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 30,
              child: CustomPaint(
                painter: FooterWavePainter(),
              ),
            ),
          ),
          Positioned(
            left: 60,
            top: 28,
            child: Icon(
              Icons.directions_boat,
              size: 22,
              color: const Color(0xFF2376AC).withOpacity(0.85),
            ),
          ),
          Positioned(
            right: 20,
            top: 20,
            child: Column(
              children: [
                const Icon(
                  Icons.wb_sunny,
                  size: 12,
                  color: Color(0xFF75A8C9),
                ),
                const Icon(
                  Icons.location_city,
                  size: 32,
                  color: Color(0xFF73A8CC),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 44,
            child: Column(
              children: const [
                Text(
                  'Foster Department',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textBlue,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Fisheries Department, UT of Lakshadweep',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF425D72),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Designed by SNS',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF255D94),
                    fontWeight: FontWeight.w500,
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
  // CLOUD
  // ===========================================================================

  Widget _buildCloud() {
    return SizedBox(
      width: 60,
      height: 30,
      child: Stack(
        children: [
          Positioned(
            left: 10,
            bottom: 0,
            child: Container(
              width: 48,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 34,
            top: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SMALL CLOUD
  // ===========================================================================

  Widget _buildSmallCloud() {
    return Container(
      width: 38,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ===========================================================================
  // BIRD
  // ===========================================================================

  Widget _buildBird({
    double size = 16,
  }) {
    return Icon(
      Icons.air,
      size: size,
      color: const Color(0xFF51A5C5),
    );
  }

  // ===========================================================================
  // PALM TREE
  // ===========================================================================

  Widget _buildPalmTree({
    required double height,
    required double width,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 3.5,
              height: height * 0.58,
              decoration: BoxDecoration(
                color: const Color(0xFF8D7448),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Icon(
              Icons.park,
              size: width * 0.85,
              color: const Color(0xFF5A9B46),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HEADER CURVE
// =============================================================================

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(
      size.width,
      size.height * 0.47,
    );
    path.cubicTo(
      size.width * 0.83,
      size.height * 0.66,
      size.width * 0.54,
      size.height * 0.82,
      size.width * 0.30,
      size.height * 0.89,
    );
    path.cubicTo(
      size.width * 0.14,
      size.height * 0.94,
      size.width * 0.04,
      size.height * 0.89,
      0,
      size.height * 0.77,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

// =============================================================================
// WATER PAINTER
// =============================================================================

class WaterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF39B8D6)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.20);
    path.quadraticBezierTo(
      size.width * 0.15,
      0,
      size.width * 0.30,
      size.height * 0.18,
    );
    path.quadraticBezierTo(
      size.width * 0.48,
      size.height * 0.40,
      size.width * 0.68,
      size.height * 0.17,
    );
    path.quadraticBezierTo(
      size.width * 0.84,
      0,
      size.width,
      size.height * 0.19,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final wavePaint = Paint()
      ..color = const Color(0xFF7BDAE8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 3; i++) {
      final wave = Path();
      wave.moveTo(-20, size.height * (0.38 + i * 0.22));
      wave.quadraticBezierTo(
        size.width * 0.20,
        size.height * (0.23 + i * 0.22),
        size.width * 0.40,
        size.height * (0.38 + i * 0.22),
      );
      wave.quadraticBezierTo(
        size.width * 0.65,
        size.height * (0.52 + i * 0.22),
        size.width + 20,
        size.height * (0.37 + i * 0.22),
      );
      canvas.drawPath(wave, wavePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

// =============================================================================
// FOOTER WAVE PAINTER
// =============================================================================

class FooterWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.18,
      size.height * 0.05,
      size.width * 0.36,
      size.height * 0.52,
    );
    path.quadraticBezierTo(
      size.width * 0.55,
      size.height * 0.98,
      size.width * 0.73,
      size.height * 0.46,
    );
    path.quadraticBezierTo(
      size.width * 0.87,
      size.height * 0.10,
      size.width,
      size.height * 0.48,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}