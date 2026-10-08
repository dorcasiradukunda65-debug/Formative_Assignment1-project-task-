import 'package:flutter/material.dart';
import '../core/constants/app_typography.dart';
import '../models/task.dart';

/// Reusable Priority Badge widget.
class PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  final bool showIcon;
  final bool isCompact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6.0 : 8.0,
        vertical: isCompact ? 2.5 : 4.0,
      ),
      decoration: BoxDecoration(
        color: priority.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: priority.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              priority.icon,
              size: isCompact ? 12 : 14,
              color: priority.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            priority.displayName,
            style: AppTypography.badge.copyWith(
              color: priority.color,
              fontSize: isCompact ? 10.5 : 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
