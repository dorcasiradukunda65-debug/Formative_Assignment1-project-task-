import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import '../../widgets/status_badge.dart';

/// Screen 4: Task Details Shell
/// Assigned to Member 4 (Branch: feature/task-details-form)
class TaskDetailsScreen extends StatelessWidget {
  final StorageService storageService;
  final Task? task;

  const TaskDetailsScreen({
    super.key,
    required this.storageService,
    this.task,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTask = task;
    final threshold = storageService.getAtRiskThresholdHours();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Assigned to Member 4 • Branch: feature/task-details-form\nProvides full task inspection, status updates, and delete confirmation.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
            ),
          ),
          const SizedBox(height: 20),
          if (effectiveTask != null) ...[
            Row(
              children: [
                SlaBadge(
                  status: SlaService.getStatus(
                    effectiveTask,
                    atRiskThresholdHours: threshold,
                  ),
                ),
                const SizedBox(width: 8),
                PriorityBadge(priority: effectiveTask.priority),
                const SizedBox(width: 8),
                StatusBadge(status: effectiveTask.status),
              ],
            ),
            const SizedBox(height: 16),
            Text(effectiveTask.title, style: AppTypography.displayMedium),
            const SizedBox(height: 12),
            Text(
              effectiveTask.description,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _infoRow(
                      'Deadline',
                      DateFormat('MMM d, y • HH:mm').format(effectiveTask.deadline),
                    ),
                    const Divider(),
                    _infoRow(
                      'Time Remaining',
                      SlaService.formattedTimeRemaining(
                        effectiveTask,
                        atRiskThresholdHours: threshold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Center(child: Text('No task selected.')),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium),
        Text(value, style: AppTypography.labelLarge),
      ],
    );
  }
}
