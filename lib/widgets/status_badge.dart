import 'package:flutter/material.dart';
import '../core/constants/app_typography.dart';
import '../models/task.dart';

/// Reusable TaskStatus Badge widget.
class StatusBadge extends StatelessWidget {
  final TaskStatus status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7.0 : 9.0,
        vertical: isCompact ? 2.5 : 4.0,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: status.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Text(
        status.displayName,
        style: AppTypography.badge.copyWith(
          color: status.color,
          fontSize: isCompact ? 10.5 : 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
