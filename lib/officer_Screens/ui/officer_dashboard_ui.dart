// fisheries_officer_ocean_ui.dart
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════
//  COLOR TOKENS
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOcean {
  FisheriesOfficerOcean._();

  // Brand
  static const Color cyan    = Color(0xFF22D3EE);
  static const Color blue    = Color(0xFF3B82F6);
  static const Color primary = Color(0xFF0EA5E9);
  static const Color green   = Color(0xFF22C55E);
  static const Color orange  = Color(0xFFF59E0B);
  static const Color red     = Color(0xFFEF4444);

  // Surfaces
  static const Color bg      = Color(0xFF0B1220);
  static const Color card    = Color(0xFF111A2E);
  static const Color border  = Color(0xFF1E2A44);

  // Text
  static const Color text    = Color(0xFFE5EAF3);
  static const Color text2   = Color(0xFFB7C0D1);
  static const Color muted   = Color(0xFF7C879B);
}

// ═══════════════════════════════════════════════════════════════════
//  PAGE SCAFFOLD
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanPage extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  const FisheriesOfficerOceanPage({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            FisheriesOfficerOcean.bg,
            Color(0xFF0E1A30),
          ],
        ),
      ),
      child: SafeArea(
        child: scrollable
            ? SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: content,
        )
            : content,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LOADING
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanLoading extends StatelessWidget {
  final String? label;

  const FisheriesOfficerOceanLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                FisheriesOfficerOcean.cyan,
              ),
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  BUTTON
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outlined;

  const FisheriesOfficerOceanButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.loading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: outlined
                ? Colors.transparent
                : FisheriesOfficerOcean.cyan.withOpacity(.16),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: FisheriesOfficerOcean.cyan.withOpacity(.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FisheriesOfficerOcean.cyan,
                    ),
                  ),
                )
              else if (icon != null)
                Icon(icon, size: 15, color: FisheriesOfficerOcean.cyan),
              if (loading || icon != null) const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STAT CARD  (used by OfficerDashboardUI._statGrid)
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const FisheriesOfficerOceanStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FisheriesOfficerOcean.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FisheriesOfficerOcean.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION CARD (optional – useful elsewhere)
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const FisheriesOfficerOceanSection({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FisheriesOfficerOcean.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════════════
class FisheriesOfficerOceanEmpty extends StatelessWidget {
  final String text;

  const FisheriesOfficerOceanEmpty(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 14),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          color: FisheriesOfficerOcean.muted,
          fontSize: 11,
        ),
      ),
    ),
  );
}