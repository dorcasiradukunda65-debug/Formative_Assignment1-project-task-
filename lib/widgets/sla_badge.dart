import 'package:flutter/material.dart';
import '../core/constants/app_typography.dart';
import '../models/sla_status.dart';

/// Reusable SLA Badge widget for displaying task SLA status with icon and colors.
class SlaBadge extends StatelessWidget {
  final SlaStatus status;
  final bool showIcon;
  final bool isCompact;

  const SlaBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = isCompact ? 8.0 : 10.0;
    final verticalPadding = isCompact ? 3.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              status.icon,
              size: isCompact ? 13 : 15,
              color: status.color,
            ),
            const SizedBox(width: 5),
          ],
          Text(
            status.displayName,
            style: AppTypography.badge.copyWith(
              color: status.color,
              fontSize: isCompact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
