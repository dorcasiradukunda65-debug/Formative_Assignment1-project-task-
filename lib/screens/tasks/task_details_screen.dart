
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_typography.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import '../../widgets/status_badge.dart';
import 'task_form_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final StorageService storageService;
  final Task? task;

  const TaskDetailsScreen({
    super.key,
    required this.storageService,
    this.task,
  });

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  Task? _task;
  TeamMember? _assignee;
  bool _isLoading = true;
  bool _isWorking = false;

  @override
  void initState() {
    super.initState();
    _loadTask();
  }

  Future<void> _loadTask() async {
    try {
      final task = widget.task == null
          ? null
          : await widget.storageService.getTaskById(widget.task!.id);

      final members = await widget.storageService.getMembers();

      if (!mounted) return;

      setState(() {
        _task = task;
        _assignee = task?.assigneeId == null
            ? null
            : members.where((m) => m.id == task!.assigneeId).firstOrNull;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Could not load task details.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _editTask() async {
    final task = _task;
    if (task == null) return;

    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(
          storageService: widget.storageService,
          task: task,
        ),
      ),
    );

    if (updated == true && mounted) {
      setState(() => _isLoading = true);
      await _loadTask();
    }
  }

  Future<void> _updateStatus(TaskStatus? status) async {
    final task = _task;
    if (task == null || status == null || status == task.status) return;

    setState(() => _isWorking = true);

    try {
      final updatedTask = Task(
        id: task.id,
        title: task.title,
        description: task.description,
        category: task.category,
        assigneeId: task.assigneeId,
        priority: task.priority,
        deadline: task.deadline,
        status: status,
        notes: task.notes,
        createdAt: task.createdAt,
      );

      await widget.storageService.saveTask(updatedTask);

      if (!mounted) return;

      setState(() {
        _task = updatedTask;
        _isWorking = false;
      });

      _showMessage('Task status updated.');
      await _loadTask();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _showMessage('Could not update task status.');
    }
  }

  Future<void> _deleteTask() async {
    final task = _task;
    if (task == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(
          'Are you sure you want to delete "${task.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isWorking = true);

    try {
      await widget.storageService.deleteTask(task.id);

      if (!mounted) return;

      _showMessage('Task deleted.');
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isWorking = false);
      _showMessage('Could not delete task.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final task = _task;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task Details')),
        body: const Center(child: Text('Task not found.')),
      );
    }

    final threshold = widget.storageService.getAtRiskThresholdHours();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            onPressed: _isWorking ? null : _editTask,
            tooltip: 'Edit task',
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: _isWorking ? null : _deleteTask,
            tooltip: 'Delete task',
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SlaBadge(
                status: SlaService.getStatus(
                  task,
                  atRiskThresholdHours: threshold,
                ),
              ),
              PriorityBadge(priority: task.priority),
              StatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 20),
          Text(task.title, style: AppTypography.displayMedium),
          const SizedBox(height: 12),
          Text(
            task.description.isEmpty
                ? 'No description provided.'
                : task.description,
            style: AppTypography.bodyLarge,
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Category', task.category),
                  const Divider(),
                  _infoRow('Assignee', _assignee?.name ?? 'Unassigned'),
                  const Divider(),
                  _infoRow('Priority', task.priority.displayName),
                  const Divider(),
                  _infoRow('Deadline',
                      DateFormat('MMM d, y • HH:mm').format(task.deadline)),
                  const Divider(),
                  _infoRow(
                    'Time remaining',
                    SlaService.formattedTimeRemaining(
                      task,
                      atRiskThresholdHours: threshold,
                    ),
                  ),
                  const Divider(),
                  _infoRow(
                    'Created',
                    DateFormat('MMM d, y • HH:mm').format(task.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Update status', style: AppTypography.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<TaskStatus>(
            initialValue: task.status,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Task status',
            ),
            items: TaskStatus.values.map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status.displayName),
              );
            }).toList(),
            onChanged: _isWorking ? null : _updateStatus,
          ),
          if (task.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Additional notes', style: AppTypography.titleMedium),
            const SizedBox(height: 8),
            Text(task.notes, style: AppTypography.bodyLarge),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: AppTypography.bodyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: AppTypography.labelLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}