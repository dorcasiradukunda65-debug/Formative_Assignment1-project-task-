import '../models/sla_status.dart';
import '../models/task.dart';

/// Core Service Level Agreement (SLA) business logic service.
///
/// SLA Classification Rules:
/// 1. COMPLETED: If the task has status [TaskStatus.completed], it is always [SlaStatus.completed].
/// 2. OVERDUE: If the task is incomplete and its [deadline] has passed relative to [now],
///    it is classified as [SlaStatus.overdue].
/// 3. AT RISK: If the task is incomplete, the deadline has not yet passed, but the remaining
///    time is within the configured threshold (default: 24 hours), it is [SlaStatus.atRisk].
/// 4. ON TRACK: Incomplete tasks with remaining time strictly greater than the threshold
///    are classified as [SlaStatus.onTrack].
class SlaService {
  /// Default threshold in hours when a task transitions to "At Risk".
  static const int defaultAtRiskThresholdHours = 24;

  /// Determines the SLA status of a given task.
  ///
  /// [now] can be injected for deterministic unit testing.
  /// [atRiskThresholdHours] overrides the default 24h threshold (supports the Unique Feature).
  static SlaStatus getStatus(
    Task task, {
    DateTime? now,
    int? atRiskThresholdHours,
  }) {
    final currentTime = now ?? DateTime.now();
    final thresholdHours =
        atRiskThresholdHours ?? defaultAtRiskThresholdHours;

    // Rule 1: Completed tasks are always marked Completed
    if (task.isCompleted) {
      return SlaStatus.completed;
    }

    // Rule 2: Deadline has already passed -> Overdue
    if (task.deadline.isBefore(currentTime)) {
      return SlaStatus.overdue;
    }

    // Rule 3: Remaining time is within the warning threshold -> At Risk
    final timeRemaining = task.deadline.difference(currentTime);
    final warningDuration = Duration(hours: thresholdHours);

    if (timeRemaining <= warningDuration) {
      return SlaStatus.atRisk;
    }

    // Rule 4: Ample time remaining -> On Track
    return SlaStatus.onTrack;
  }

  /// Calculates the duration between [now] and the task's deadline.
  /// If the deadline is in the past, returns a negative Duration.
  static Duration timeRemaining(Task task, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    return task.deadline.difference(currentTime);
  }

  /// Formats the remaining time or overdue duration into a human-friendly string.
  /// Examples:
  /// - Completed
  /// - Overdue by 1d 4h
  /// - Due in 3h 15m (At Risk)
  /// - Due in 4d
  static String formattedTimeRemaining(
    Task task, {
    DateTime? now,
    int? atRiskThresholdHours,
  }) {
    if (task.isCompleted) {
      return 'Completed';
    }

    final currentTime = now ?? DateTime.now();
    final diff = task.deadline.difference(currentTime);
    final isPast = diff.isNegative;
    final absDiff = diff.abs();

    final days = absDiff.inDays;
    final hours = absDiff.inHours % 24;
    final minutes = absDiff.inMinutes % 60;

    String timeSpan;
    if (days > 0) {
      timeSpan = '${days}d ${hours}h';
    } else if (hours > 0) {
      timeSpan = '${hours}h ${minutes}m';
    } else {
      timeSpan = '${minutes}m';
    }

    if (isPast) {
      return 'Overdue by $timeSpan';
    }

    final status = getStatus(
      task,
      now: currentTime,
      atRiskThresholdHours: atRiskThresholdHours,
    );

    if (status == SlaStatus.atRisk) {
      return 'Due in $timeSpan (At Risk)';
    }

    return 'Due in $timeSpan';
  }

  /// Aggregates SLA counts across all tasks.
  /// Useful for Dashboard metrics and charts.
  static Map<SlaStatus, int> getSlaBreakdown(
    List<Task> tasks, {
    DateTime? now,
    int? thresholdHours,
  }) {
    final counts = <SlaStatus, int>{
      SlaStatus.onTrack: 0,
      SlaStatus.atRisk: 0,
      SlaStatus.overdue: 0,
      SlaStatus.completed: 0,
    };

    for (final task in tasks) {
      final status = getStatus(
        task,
        now: now,
        atRiskThresholdHours: thresholdHours,
      );
      counts[status] = (counts[status] ?? 0) + 1;
    }

    return counts;
  }

  /// Filters tasks that require urgent attention (Overdue + At Risk),
  /// sorted by closest/most overdue deadline first.
  static List<Task> getNeedsAttentionTasks(
    List<Task> tasks, {
    DateTime? now,
    int? thresholdHours,
  }) {
    final currentTime = now ?? DateTime.now();

    final attentionTasks = tasks.where((task) {
      final status = getStatus(
        task,
        now: currentTime,
        atRiskThresholdHours: thresholdHours,
      );
      return status == SlaStatus.overdue || status == SlaStatus.atRisk;
    }).toList();

    // Sort by deadline ascending (most overdue first, then soonest at-risk)
    attentionTasks.sort((a, b) => a.deadline.compareTo(b.deadline));
    return attentionTasks;
  }

  /// Calculates a project health percentage (0.0 to 100.0)
  /// defined as: (onTrack + completed) / totalTasks * 100
  static double calculateProjectHealthScore(
    List<Task> tasks, {
    DateTime? now,
    int? thresholdHours,
  }) {
    if (tasks.isEmpty) return 100.0;
    final breakdown = getSlaBreakdown(
      tasks,
      now: now,
      thresholdHours: thresholdHours,
    );

    final healthyCount =
        (breakdown[SlaStatus.onTrack] ?? 0) +
        (breakdown[SlaStatus.completed] ?? 0);

    return (healthyCount / tasks.length) * 100;
  }
}
