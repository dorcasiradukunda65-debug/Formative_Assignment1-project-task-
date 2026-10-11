
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  final StorageService storageService;

  const TaskListScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];
  Map<String, TeamMember> _memberMap = {};
  int _atRiskThresholdHours = 24;

  SlaStatus? _selectedStatusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Accept an SLA filter passed from the dashboard.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SlaStatus) {
      _selectedStatusFilter = args;
    }
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final tasks = await widget.storageService.getTasks();
      final members = await widget.storageService.getMembers();
      final threshold =
          widget.storageService.getAtRiskThresholdHours();

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
        _memberMap = {
          for (final member in members) member.id: member,
        };
        _atRiskThresholdHours = threshold;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load tasks: $error')),
      );
    }
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
      await _loadData();
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
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) {
      final slaStatus = SlaService.getStatus(
        task,
        atRiskThresholdHours: _atRiskThresholdHours,
      );

      final matchesFilter = _selectedStatusFilter == null ||
          slaStatus == _selectedStatusFilter;

      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query);

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(
          Icons.add_rounded,
          color: Colors.white,
        ),
        label: const Text(
          'New Task',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search tasks by title or description.
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),

                // Filter tasks by SLA status.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Tasks'),
                        selected: _selectedStatusFilter == null,
                        onSelected: (_) {
                          setState(() => _selectedStatusFilter = null);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...SlaStatus.values.map((status) {
                        final isSelected =
                            _selectedStatusFilter == status;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.displayName),
                            selected: isSelected,
                            selectedColor: status.backgroundColor,
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter =
                                    isSelected ? null : status;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const Divider(),

                Expanded(
                  child: filteredTasks.isEmpty
                      ? const Center(
                          child: Text('No matching tasks found.'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            88,
                          ),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];

                            final slaStatus = SlaService.getStatus(
                              task,
                              atRiskThresholdHours:
                                  _atRiskThresholdHours,
                            );

                            final assignee = task.assigneeId == null
                                ? null
                                : _memberMap[task.assigneeId];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _openTaskDetails(task),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          PriorityBadge(
                                            priority: task.priority,
                                          ),
                                          SlaBadge(status: slaStatus),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        task.title,
                                        style: AppTypography.titleMedium,
                                      ),
                                      if (task.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          task.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTypography.bodySmall,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Text(
                                        'Due: ${task.deadline.month}/${task.deadline.day}/${task.deadline.year}',
                                        style: AppTypography.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Assigned: ${assignee?.name ?? 'Unassigned'}',
                                        style: AppTypography.bodySmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${task.status.displayName}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}