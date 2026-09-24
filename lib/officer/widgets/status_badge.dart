import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final upper = status.toUpperCase();

    late final Color color;
    late final IconData icon;

    switch (upper) {
      case 'ONGOING':
      case 'ACTIVE':
        color = const Color(0xFF16A34A); // green
        icon = Icons.play_circle_filled_rounded;
        break;
      case 'COMPLETED':
        color = const Color(0xFF2563EB); // blue
        icon = Icons.check_circle_rounded;
        break;
      case 'OVERDUE':
        color = const Color(0xFFF59E0B); // amber
        icon = Icons.schedule_rounded;
        break;
      case 'CANCELLED':
        color = const Color(0xFFDC2626); // red
        icon = Icons.cancel_rounded;
        break;
      default:
        color = const Color(0xFF6B7280); // grey (fallback)
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            upper == 'ONGOING' ? 'ACTIVE' : upper,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}