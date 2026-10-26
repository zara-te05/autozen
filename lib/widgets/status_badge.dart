import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

enum BadgeType { success, warning, danger, info, neutral }

/// Badge visual estandarizado para estados sin dejar que el usuario escriba cadenas arbitrarias.
class StatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color baseColor;
    switch (type) {
      case BadgeType.success:
        baseColor = AppTheme.success;
        break;
      case BadgeType.warning:
        baseColor = AppTheme.warning;
        break;
      case BadgeType.danger:
        baseColor = AppTheme.danger;
        break;
      case BadgeType.info:
        baseColor = AppTheme.info;
        break;
      case BadgeType.neutral:
        baseColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: baseColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: baseColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
