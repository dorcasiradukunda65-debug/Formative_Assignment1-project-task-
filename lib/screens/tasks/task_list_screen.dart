import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sla_badge.dart';

class TaskListScreen extends StatefulWidget {
  final StorageService storageService;

  const TaskListScreen({super.key, required this.storageService});

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
    // Catch any SlaStatus filter argument passed when navigating from Dashboard
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is SlaStatus) {
      _selectedStatusFilter = args;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final tasks = await widget.storageService.getTasks();
    final members = await widget.storageService.getMembers();
    final threshold = widget.storageService.getAtRiskThresholdHours();

    setState(() {
      _tasks = tasks;
      _memberMap = {for (var m in members) m.id: m};
      _atRiskThresholdHours = threshold;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _tasks.where((task) {
      final status = SlaService.getStatus(task, atRiskThresholdHours: _atRiskThresholdHours);

      final matchesFilter = _selectedStatusFilter == null || status == _selectedStatusFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesFilter && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.taskForm),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'New Task',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                        final isSelected = _selectedStatusFilter == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.displayName),
                            selected: isSelected,
                            selectedColor: status.backgroundColor,
                            onSelected: (_) {
                              setState(() {
                                _selectedStatusFilter = isSelected ? null : status;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const Divider(),

                // Task List Content
                Expanded(
                  child: filteredTasks.isEmpty
                      ? const Center(child: Text('No matching tasks found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // extra bottom padding for FAB
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final slaStatus = SlaService.getStatus(
                              task,
                              atRiskThresholdHours: _atRiskThresholdHours,
                            );
                            final assignee =
                                task.assigneeId != null ? _memberMap[task.assigneeId] : null;

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: SlaBadge(status: slaStatus),
                                title: Text(task.title, style: AppTypography.titleMedium),
                                subtitle: Text(
                                  'Due: ${task.deadline.month}/${task.deadline.day} • Assigned: ${assignee?.name ?? 'Unassigned'}',
                                  style: AppTypography.bodySmall,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.taskDetails,
                                    arguments: task.id,
                                  );
                                },
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
