import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
//  FISHERIES OFFICER OCEAN — Design System
//  Dark ocean theme used across all officer screens.
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOcean {
  FisheriesOfficerOcean._();

  // ── Surfaces (light ocean theme) ────────────────────────────
  static const Color bg          = Color(0xFFF2F7FB); // soft ocean mist
  static const Color card        = Color(0xFFFFFFFF); // white cards
  static const Color cardSoft    = Color(0xFFE8F1FA); // pale sea foam
  static const Color border      = Color(0xFFCFE0EF); // light sea border
  static const Color borderLight = Color(0xFFE3EDF7); // subtle divider

  // ── Aliases used by report screens ──────────────────────────
  static const Color surface  = card;
  static const Color surface2 = cardSoft;

  // ── Text ─────────────────────────────────────────────────────
  static const Color text        = Color(0xFF0B2540); // deep ocean navy
  static const Color text2       = Color(0xFF3A5A78); // mid sea blue
  static const Color muted       = Color(0xFF6E8AA6); // muted ocean grey

  // ── Accents ─────────────────────────────────────────────────
  static const Color primary     = Color(0xFF0EA5E9); // ocean sky blue
  static const Color primaryDark = Color(0xFF0284C7);
  static const Color blue        = Color(0xFF3B82F6);
  static const Color cyan        = Color(0xFF06B6D4);
  static const Color green       = Color(0xFF10B981);
  static const Color orange      = Color(0xFFF59E0B);
  static const Color red         = Color(0xFFEF4444);

  // ── Header gradient (bright ocean) ──────────────────────────
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0EA5E9), // sky
      Color(0xFF0284C7), // sea
    ],
  );

  // ── Card decoration ─────────────────────────────────────────
  static BoxDecoration cardDecoration() => BoxDecoration(
    color: card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: borderLight),
    boxShadow: const [
      BoxShadow(
        color: Color(0x0F0B2540), // 6% ocean-navy shadow
        blurRadius: 6,
        offset: Offset(0, 2),
      ),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════
//  SOS HELPERS — boat colours + severity colours
// ══════════════════════════════════════════════════════════════════

/// Stable palette for boat colour-coding (deterministic hashing).
const List<Color> kOfficerOceanBoatPalette = [
  Color(0xFF1877F2), // blue
  Color(0xFF31A24C), // green
  Color(0xFFF7B928), // amber
  Color(0xFFFA383E), // red
  Color(0xFF9B51E0), // purple
  Color(0xFF00B2FF), // sky
  Color(0xFFE84393), // pink
  Color(0xFF00B894), // teal
  Color(0xFFFDCB6E), // sand
  Color(0xFF6C5CE7), // indigo
];

/// Same boat → same colour, every time.
Color boatColor(String? boatKey) {
  if (boatKey == null || boatKey.trim().isEmpty) {
    return FisheriesOfficerOcean.muted;
  }
  int h = 0;
  for (final c in boatKey.trim().codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return kOfficerOceanBoatPalette[h % kOfficerOceanBoatPalette.length];
}

/// Best-effort boat identifier from a record map.
String? boatKeyOf(Map<String, dynamic> s) {
  return (s['boat_reg_no']
          ?? s['boat_registration']
          ?? s['boat_number']
          ?? s['boat_name']
          ?? s['boat_id'])
      ?.toString();
}

/// Severity string → colour.
Color severityColor(String? sev) {
  switch ((sev ?? '').toUpperCase()) {
    case 'LOW':      return const Color(0xFF31A24C); // green
    case 'MEDIUM':   return const Color(0xFFF7B928); // amber
    case 'HIGH':     return const Color(0xFFFA383E); // red
    case 'CRITICAL': return const Color(0xFFB91C1C); // dark red
    default:         return FisheriesOfficerOcean.muted;
  }
}

/// Severity numeric (1–5) → colour.
Color severityFromInt(num? n) {
  if (n == null) return FisheriesOfficerOcean.muted;
  if (n >= 5) return const Color(0xFFB91C1C);
  if (n >= 4) return const Color(0xFFFA383E);
  if (n >= 3) return const Color(0xFFF7B928);
  if (n >= 2) return const Color(0xFF31A24C);
  return const Color(0xFF1877F2);
}

/// SOS type → colour (fallback when there's no severity field).
Color severityFromType(String? type) {
  switch ((type ?? '').toUpperCase()) {
    case 'MEDICAL':
    case 'FIRE':
      return const Color(0xFFFA383E);
    case 'ENGINE_FAILURE':
    case 'CAPSIZED':
      return const Color(0xFFF7B928);
    case 'WEATHER':
    case 'LOST_CONTACT':
      return const Color(0xFF1877F2);
    default:
      return FisheriesOfficerOcean.muted;
  }
}

// ══════════════════════════════════════════════════════════════════
//  PAGE SCAFFOLD
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanPage extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsets? padding;

  const FisheriesOfficerOceanPage({
    super.key,
    required this.child,
    this.scrollable = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final body = scrollable
        ? SingleChildScrollView(
      padding: padding ?? EdgeInsets.zero,
      child: child,
    )
        : (padding != null
        ? Padding(padding: padding!, child: child)
        : child);

    return Scaffold(
      backgroundColor: FisheriesOfficerOcean.bg,
      body: SafeArea(child: body),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  LOADING
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanLoading extends StatelessWidget {
  final String? label;
  const FisheriesOfficerOceanLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 2.4,
              color: FisheriesOfficerOcean.primary,
            ),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label!,
                  style: const TextStyle(
                      color: FisheriesOfficerOcean.muted, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const FisheriesOfficerOceanEmpty({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.title = 'Nothing here',
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: FisheriesOfficerOcean.primary.withOpacity(.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon,
                  size: 30, color: FisheriesOfficerOcean.primary),
            ),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FisheriesOfficerOcean.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                )),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.muted,
                    fontSize: 12,
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STAT CARD  (used by OfficerDashboardUI._statGrid)
// ══════════════════════════════════════════════════════════════════

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: FisheriesOfficerOcean.cardDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),

          // Value
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FisheriesOfficerOcean.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),

          // Label
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FisheriesOfficerOcean.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SEARCH FIELD
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  const FisheriesOfficerOceanSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FisheriesOfficerOcean.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          color: FisheriesOfficerOcean.text, fontSize: 13),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: FisheriesOfficerOcean.muted, fontSize: 12),
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded,
              color: FisheriesOfficerOcean.muted, size: 18),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DROPDOWN
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanDropdown<T> extends StatelessWidget {
  final String labelText;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const FisheriesOfficerOceanDropdown({
    super.key,
    required this.labelText,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: FisheriesOfficerOcean.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: FisheriesOfficerOcean.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text(labelText,
              style: const TextStyle(
                color: FisheriesOfficerOcean.muted,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              )),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              isDense: true,
              dropdownColor: FisheriesOfficerOcean.cardSoft,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: FisheriesOfficerOcean.muted, size: 18),
              style: const TextStyle(
                color: FisheriesOfficerOcean.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  FILTER CHIP
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const FisheriesOfficerOceanFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? FisheriesOfficerOcean.primary.withOpacity(.18)
              : FisheriesOfficerOcean.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? FisheriesOfficerOcean.primary
                : FisheriesOfficerOcean.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? FisheriesOfficerOcean.primary
                : FisheriesOfficerOcean.text2,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  BUTTON
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool outlined;

  const FisheriesOfficerOceanButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon,
              size: 16,
              color: outlined
                  ? FisheriesOfficerOcean.primary
                  : Colors.white),
          if (text.isNotEmpty) const SizedBox(width: 6),
        ],
        if (text.isNotEmpty)
          Text(text,
              style: TextStyle(
                color: outlined
                    ? FisheriesOfficerOcean.primary
                    : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
      ],
    );

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: outlined
              ? FisheriesOfficerOcean.card
              : FisheriesOfficerOcean.primary,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined
                ? FisheriesOfficerOcean.border
                : FisheriesOfficerOcean.primary,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  STATUS BADGE
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanStatusBadge extends StatelessWidget {
  final String status;

  const FisheriesOfficerOceanStatusBadge({
    super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toUpperCase()) {
      'ACTIVE' => FisheriesOfficerOcean.green,
      'SCHEDULED' => FisheriesOfficerOcean.primary,
      'COMPLETED' => FisheriesOfficerOcean.blue,
      'CANCELLED' => FisheriesOfficerOcean.red,
      _ => FisheriesOfficerOcean.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DATE BUTTON (used by Voyages, Citings, Reports)
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanDateButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;

  const FisheriesOfficerOceanDateButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon = Icons.calendar_today_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: FisheriesOfficerOcean.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FisheriesOfficerOcean.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: FisheriesOfficerOcean.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text2,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CARD (used by report screens with table layout)
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const FisheriesOfficerOceanCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(12),
      decoration: FisheriesOfficerOcean.cardDecoration(),
      child: child,
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  SECTION (used by OfficerDashboardUI._section equivalent)
// ══════════════════════════════════════════════════════════════════

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
      padding: const EdgeInsets.all(16),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FisheriesOfficerOcean.text,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  DIVIDER
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanDivider extends StatelessWidget {
  const FisheriesOfficerOceanDivider({super.key});

  @override
  Widget build(BuildContext context) => const Divider(
    height: 1,
    thickness: 1,
    color: FisheriesOfficerOcean.borderLight,
  );
}

// ══════════════════════════════════════════════════════════════════
//  PULL-TO-REFRESH
// ══════════════════════════════════════════════════════════════════

class FisheriesOfficerOceanRefresh extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const FisheriesOfficerOceanRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: FisheriesOfficerOcean.primary,
      backgroundColor: FisheriesOfficerOcean.card,
      onRefresh: onRefresh,
      child: child,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  OFFICER DASHBOARD UI
// ═══════════════════════════════════════════════════════════════════
class OfficerDashboardUI extends StatelessWidget {
  final Map<String, dynamic>? data;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  const OfficerDashboardUI({
    super.key,
    required this.data,
    required this.loading,
    this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const FisheriesOfficerOceanPage(
        child: FisheriesOfficerOceanLoading(label: 'Loading dashboard...'),
      );
    }

    if (error != null) {
      return FisheriesOfficerOceanPage(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: FisheriesOfficerOcean.red, size: 48),
                const SizedBox(height: 12),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: FisheriesOfficerOcean.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                FisheriesOfficerOceanButton(
                  text: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final d = data ?? {};
    final intimation = (d['intimation_status'] as Map?) ?? {};

    return FisheriesOfficerOceanPage(
      scrollable: true,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Officer Dashboard',
            style: TextStyle(
              color: FisheriesOfficerOcean.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Live overview of fisheries operations',
            style: TextStyle(
              color: FisheriesOfficerOcean.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              mainAxisExtent: 130,
            ),
            itemBuilder: (_, i) {
              final cards = [
                FisheriesOfficerOceanStatCard(
                  title: 'Open SOS',
                  value: '${d['open_sos'] ?? 0}',
                  icon: Icons.sos_rounded,
                  color: FisheriesOfficerOcean.red,
                ),
                FisheriesOfficerOceanStatCard(
                  title: 'Crew Not Returned',
                  value: '${d['crew_not_returned'] ?? 0}',
                  icon: Icons.person_off_rounded,
                  color: FisheriesOfficerOcean.orange,
                ),
                FisheriesOfficerOceanStatCard(
                  title: 'Overdue Voyages',
                  value: '${d['overdue_voyages'] ?? 0}',
                  icon: Icons.schedule_rounded,
                  color: FisheriesOfficerOcean.orange,
                ),
                FisheriesOfficerOceanStatCard(
                  title: 'Citings Pending',
                  value: '${d['citings_pending'] ?? 0}',
                  icon: Icons.report_rounded,
                  color: FisheriesOfficerOcean.primary,
                ),
                FisheriesOfficerOceanStatCard(
                  title: 'Licences Expiring',
                  value: '${d['licences_expiring'] ?? 0}',
                  icon: Icons.badge_outlined,
                  color: FisheriesOfficerOcean.cyan,
                ),
                FisheriesOfficerOceanStatCard(
                  title: 'Total Voyages',
                  value: '${intimation['total'] ?? 0}',
                  icon: Icons.sailing_rounded,
                  color: FisheriesOfficerOcean.green,
                ),
              ];
              return cards[i];
            },
          ),

          const SizedBox(height: 22),

          FisheriesOfficerOceanSection(
            title: 'Voyage Status',
            icon: Icons.directions_boat_rounded,
            color: FisheriesOfficerOcean.primary,
            child: Column(
              children: [
                _row('Upcoming', intimation['upcoming'],
                    FisheriesOfficerOcean.cyan),
                _row('Ongoing', intimation['ongoing'],
                    FisheriesOfficerOcean.green),
                _row('Overdue', intimation['overdue'],
                    FisheriesOfficerOcean.orange),
                _row('Completed', intimation['completed'],
                    FisheriesOfficerOcean.blue),
                _row('Cancelled', intimation['cancelled'],
                    FisheriesOfficerOcean.red),
              ],
            ),
          ),

          const SizedBox(height: 18),

          FisheriesOfficerOceanSection(
            title: 'Top Ports',
            icon: Icons.anchor_rounded,
            color: FisheriesOfficerOcean.cyan,
            child: _listOrEmpty(
              d['top_ports'] as List?,
              (item) => _row(
                item['port_name']?.toString() ?? '—',
                item['voyage_count'],
                FisheriesOfficerOcean.cyan,
              ),
            ),
          ),

          const SizedBox(height: 18),

          FisheriesOfficerOceanSection(
            title: 'Top Species',
            icon: Icons.set_meal_rounded,
            color: FisheriesOfficerOcean.green,
            child: _listOrEmpty(
              d['top_species'] as List?,
              (item) => _row(
                item['fish_name']?.toString() ?? '—',
                '${item['weight_kg'] ?? 0} kg',
                FisheriesOfficerOcean.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FisheriesOfficerOcean.text2,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value ?? 0}',
            style: TextStyle(
              color: color,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _listOrEmpty(List? list, Widget Function(dynamic) builder) {
    if (list == null || list.isEmpty) {
      return const FisheriesOfficerOceanEmpty(title: 'No data available');
    }
    return Column(children: list.map(builder).toList());
  }
}