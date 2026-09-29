import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Small KPI card, e.g. "Total Appointments — 48"
/// Pass [valueColor] to override (e.g. red for Inventory Alerts).
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color? iconBackground;
  final Color? valueColor;

  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    this.iconBackground,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground ?? AppColors.gold.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: valueColor ?? AppColors.gold),
          ),
          const SizedBox(height: 8),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.lightGray, fontSize: 10, letterSpacing: 0.5)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? AppColors.gold,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF7A7E9E), fontSize: 10.5)),
        ],
      ),
    );
  }
}
