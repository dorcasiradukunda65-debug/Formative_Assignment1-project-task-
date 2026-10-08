import 'package:flutter/material.dart';

/// Represents the Service Level Agreement (SLA) status of a task.
enum SlaStatus {
  onTrack,
  atRisk,
  overdue,
  completed;

  /// Human-readable label for UI display.
  String get displayName {
    switch (this) {
      case SlaStatus.onTrack:
        return 'On Track';
      case SlaStatus.atRisk:
        return 'At Risk';
      case SlaStatus.overdue:
        return 'Overdue';
      case SlaStatus.completed:
        return 'Completed';
    }
  }

  /// Primary color associated with the SLA status.
  Color get color {
    switch (this) {
      case SlaStatus.onTrack:
        return const Color(0xFF10B981); // Emerald Green
      case SlaStatus.atRisk:
        return const Color(0xFFF59E0B); // Amber / Orange
      case SlaStatus.overdue:
        return const Color(0xFFEF4444); // Crimson Red
      case SlaStatus.completed:
        return const Color(0xFF6366F1); // Indigo / Blue
    }
  }

  /// Subtle background color for chips and badges.
  Color get backgroundColor {
    switch (this) {
      case SlaStatus.onTrack:
        return const Color(0xFFECFDF5);
      case SlaStatus.atRisk:
        return const Color(0xFFFFFBEB);
      case SlaStatus.overdue:
        return const Color(0xFFFEF2F2);
      case SlaStatus.completed:
        return const Color(0xFFEEF2FF);
    }
  }

  /// Border color for chips and badges.
  Color get borderColor {
    switch (this) {
      case SlaStatus.onTrack:
        return const Color(0xFFA7F3D0);
      case SlaStatus.atRisk:
        return const Color(0xFFFDE68A);
      case SlaStatus.overdue:
        return const Color(0xFFFECACA);
      case SlaStatus.completed:
        return const Color(0xFFC7D2FE);
    }
  }

  /// Associated icon for visual clarity.
  IconData get icon {
    switch (this) {
      case SlaStatus.onTrack:
        return Icons.check_circle_outline_rounded;
      case SlaStatus.atRisk:
        return Icons.warning_amber_rounded;
      case SlaStatus.overdue:
        return Icons.alarm_off_rounded;
      case SlaStatus.completed:
        return Icons.task_alt_rounded;
    }
  }
}
