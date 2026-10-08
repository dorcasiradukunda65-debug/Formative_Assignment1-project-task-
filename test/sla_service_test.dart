import 'package:flutter_test/flutter_test.dart';
import 'package:sla_tracker/models/sla_status.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/services/sla_service.dart';

void main() {
  group('SlaService Core Application Logic Tests', () {
    final fixedNow = DateTime(2026, 10, 10, 12, 0, 0);

    test('Rule 1: Completed task is ALWAYS SlaStatus.completed regardless of deadline', () {
      final pastCompletedTask = Task(
        id: 't1',
        title: 'Past Completed',
        description: 'Desc',
        priority: TaskPriority.high,
        deadline: fixedNow.subtract(const Duration(days: 2)),
        status: TaskStatus.completed,
        createdAt: fixedNow.subtract(const Duration(days: 5)),
      );

      final futureCompletedTask = Task(
        id: 't2',
        title: 'Future Completed',
        description: 'Desc',
        priority: TaskPriority.low,
        deadline: fixedNow.add(const Duration(days: 5)),
        status: TaskStatus.completed,
        createdAt: fixedNow.subtract(const Duration(days: 1)),
      );

      expect(
        SlaService.getStatus(pastCompletedTask, now: fixedNow),
        equals(SlaStatus.completed),
      );
      expect(
        SlaService.getStatus(futureCompletedTask, now: fixedNow),
        equals(SlaStatus.completed),
      );
    });

    test('Rule 2: Incomplete task with passed deadline is SlaStatus.overdue', () {
      final overdueTask = Task(
        id: 't3',
        title: 'Overdue Bug',
        description: 'Desc',
        priority: TaskPriority.urgent,
        deadline: fixedNow.subtract(const Duration(hours: 1)),
        status: TaskStatus.inProgress,
        createdAt: fixedNow.subtract(const Duration(days: 2)),
      );

      expect(
        SlaService.getStatus(overdueTask, now: fixedNow),
        equals(SlaStatus.overdue),
      );
    });

    test('Rule 3: Incomplete task within warning horizon (24h) is SlaStatus.atRisk', () {
      final atRiskTask = Task(
        id: 't4',
        title: 'At Risk Feature',
        description: 'Desc',
        priority: TaskPriority.high,
        deadline: fixedNow.add(const Duration(hours: 18)),
        status: TaskStatus.todo,
        createdAt: fixedNow.subtract(const Duration(days: 1)),
      );

      expect(
        SlaService.getStatus(atRiskTask, now: fixedNow, atRiskThresholdHours: 24),
        equals(SlaStatus.atRisk),
      );
    });

    test('Rule 4: Incomplete task with ample time remaining is SlaStatus.onTrack', () {
      final onTrackTask = Task(
        id: 't5',
        title: 'On Track Project',
        description: 'Desc',
        priority: TaskPriority.medium,
        deadline: fixedNow.add(const Duration(days: 5)),
        status: TaskStatus.inProgress,
        createdAt: fixedNow.subtract(const Duration(days: 1)),
      );

      expect(
        SlaService.getStatus(onTrackTask, now: fixedNow, atRiskThresholdHours: 24),
        equals(SlaStatus.onTrack),
      );
    });

    test('Unique Feature: Dynamic At-Risk threshold adjusts classification', () {
      // Deadline is in 36 hours
      final task = Task(
        id: 't6',
        title: 'Threshold Test',
        description: 'Desc',
        priority: TaskPriority.high,
        deadline: fixedNow.add(const Duration(hours: 36)),
        status: TaskStatus.todo,
        createdAt: fixedNow.subtract(const Duration(days: 1)),
      );

      // Under standard 24h policy: 36h remaining is On Track
      expect(
        SlaService.getStatus(task, now: fixedNow, atRiskThresholdHours: 24),
        equals(SlaStatus.onTrack),
      );

      // Under cautious 48h policy: 36h remaining becomes At Risk
      expect(
        SlaService.getStatus(task, now: fixedNow, atRiskThresholdHours: 48),
        equals(SlaStatus.atRisk),
      );
    });

    test('SlaService breakdown & health score calculations', () {
      final tasks = [
        Task(
          id: '1',
          title: 'Done',
          description: '',
          priority: TaskPriority.low,
          deadline: fixedNow.add(const Duration(days: 1)),
          status: TaskStatus.completed,
          createdAt: fixedNow,
        ),
        Task(
          id: '2',
          title: 'On Track',
          description: '',
          priority: TaskPriority.low,
          deadline: fixedNow.add(const Duration(days: 4)),
          status: TaskStatus.todo,
          createdAt: fixedNow,
        ),
        Task(
          id: '3',
          title: 'At Risk',
          description: '',
          priority: TaskPriority.low,
          deadline: fixedNow.add(const Duration(hours: 12)),
          status: TaskStatus.inProgress,
          createdAt: fixedNow,
        ),
        Task(
          id: '4',
          title: 'Overdue',
          description: '',
          priority: TaskPriority.low,
          deadline: fixedNow.subtract(const Duration(hours: 5)),
          status: TaskStatus.inProgress,
          createdAt: fixedNow,
        ),
      ];

      final breakdown = SlaService.getSlaBreakdown(tasks, now: fixedNow, thresholdHours: 24);
      expect(breakdown[SlaStatus.completed], equals(1));
      expect(breakdown[SlaStatus.onTrack], equals(1));
      expect(breakdown[SlaStatus.atRisk], equals(1));
      expect(breakdown[SlaStatus.overdue], equals(1));

      // Health score: (1 completed + 1 on track) / 4 tasks = 50%
      final healthScore = SlaService.calculateProjectHealthScore(tasks, now: fixedNow, thresholdHours: 24);
      expect(healthScore, equals(50.0));

      // Needs attention: should return only Overdue and At Risk tasks (2 tasks)
      final attention = SlaService.getNeedsAttentionTasks(tasks, now: fixedNow, thresholdHours: 24);
      expect(attention.length, equals(2));
      expect(attention.first.id, equals('4')); // Most urgent (overdue) first
    });
  });
}
