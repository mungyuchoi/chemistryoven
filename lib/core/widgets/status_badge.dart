import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.color = AppColors.burgundy,
    this.backgroundColor,
    super.key,
  });

  final String label;
  final Color color;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
