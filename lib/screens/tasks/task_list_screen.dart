import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';

class TaskListScreen extends StatefulWidget {
  final StorageService storageService;

  const TaskListScreen({super.key, required this.storageService});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final tasks = await widget.storageService.getTasks();
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final threshold = widget.storageService.getAtRiskThresholdHours();

    // Filter tasks based on search and chip selection
    final filteredTasks = _tasks.where((task) {
      final matchesSearch = task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase());
      
      if (_selectedFilter == 'All') return matchesSearch;

      final slaStatus = SlaService.getStatus(task, atRiskThresholdHours: threshold);
      final statusName = slaStatus.name.replaceAllMapped(
        RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}'
      ).trim();

      return matchesSearch && statusName.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Field & Filter Chips
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['All', 'On Track', 'At Risk', 'Overdue', 'Completed'].map((filter) {
                            final isSelected = _selectedFilter == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(filter),
                                selected: isSelected,
                                selectedColor: AppColors.primaryLight,
                                onSelected: (selected) {
                                  if (selected) setState(() => _selectedFilter = filter);
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Task List Cards
                Expanded(
                  child: filteredTasks.isEmpty
                      ? const Center(child: Text('No tasks found matching your filter.'))
                      : ListView.builder(
                          itemCount: filteredTasks.length,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final slaStatus = SlaService.getStatus(task, atRiskThresholdHours: threshold);
                            final timeLabel = SlaService.formattedTimeRemaining(task, atRiskThresholdHours: threshold);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
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
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}