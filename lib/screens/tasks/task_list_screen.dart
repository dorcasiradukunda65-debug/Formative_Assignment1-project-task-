import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

/// Screen 3: Task List Screen Shell
/// Assigned to Member 3 (Branch: feature/dashboard-tasklist)
class TaskListScreen extends StatefulWidget {
  final StorageService storageService;

  const TaskListScreen({super.key, required this.storageService});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tasks = await widget.storageService.getTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }
  
Future<void> _openTaskForm({Task? task}) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => TaskFormScreen(
        storageService: widget.storageService,
        task: task,
      ),
    ),
  );

  if (result == true && mounted) {
    setState(() => _isLoading = true);
    await _load();
  }
}

Future<void> _openTaskDetails(Task task) async {
  await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => TaskDetailsScreen(
        storageService: widget.storageService,
        task: task,
      ),
    ),
  );

  if (mounted) {
    setState(() => _isLoading = true);
    await _load();
  }
}

  @override
  Widget build(BuildContext context) {
    final threshold = widget.storageService.getAtRiskThresholdHours();

    return Scaffold(
      appBar: AppBar(
  title: const Text('All Tasks'),
  actions: [
    IconButton(
      onPressed: () => _openTaskForm(),
      tooltip: 'Create task',
      icon: const Icon(Icons.add),
    ),
  ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Assigned to Member 3 • Branch: feature/dashboard-tasklist\nImplements task search, filters (SLA, priority, assignee), and sorting.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 16),
                ..._tasks.map((task) {
                  final slaStatus = SlaService.getStatus(task, atRiskThresholdHours: threshold);
                  final timeLabel = SlaService.formattedTimeRemaining(task, atRiskThresholdHours: threshold);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _openTaskDetails(task),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PriorityBadge(priority: task.priority),
                              SlaBadge(status: slaStatus),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(task.title, style: AppTypography.titleMedium),
                          const SizedBox(height: 6),
                          Text(
                            timeLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: slaStatus.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                }),
              ],
            ),
    );
  }
}
