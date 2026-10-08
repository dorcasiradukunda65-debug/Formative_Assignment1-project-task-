import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import '../../widgets/status_badge.dart';

/// Interactive Foundation, Data & SLA Logic Explorer.
/// Primary screen for Member 1 to demonstrate:
/// 1. SLA Logic Engine & Live Classification
/// 2. Configurable At-Risk Warning Horizon (Unique Feature)
/// 3. SharedPreferences Persistence Layer (Load, Save, Update, Delete)
/// 4. Seed Data & State Management via setState()
class FoundationOverviewScreen extends StatefulWidget {
  final StorageService storageService;

  const FoundationOverviewScreen({super.key, required this.storageService});

  @override
  State<FoundationOverviewScreen> createState() =>
      _FoundationOverviewScreenState();
}

class _FoundationOverviewScreenState extends State<FoundationOverviewScreen> {
  List<Task> _tasks = [];
  List<TeamMember> _members = [];
  Map<String, TeamMember> _memberMap = {};
  int _atRiskThresholdHours = 24;
  bool _isLoading = true;
  String _persistenceStatusMessage = 'Connected to SharedPreferences';
  SlaStatus? _selectedStatusFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads tasks, team members, and configured SLA threshold from local storage.
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final tasks = await widget.storageService.getTasks();
    final members = await widget.storageService.getMembers();
    final threshold = widget.storageService.getAtRiskThresholdHours();

    setState(() {
      _tasks = tasks;
      _members = members;
      _memberMap = {for (var m in members) m.id: m};
      _atRiskThresholdHours = threshold;
      _isLoading = false;
      _persistenceStatusMessage =
          'Loaded ${tasks.length} tasks from SharedPreferences at ${TimeOfDay.now().format(context)}';
    });
  }

  /// Updates the SLA threshold and saves to SharedPreferences.
  Future<void> _updateThreshold(int newHours) async {
    setState(() {
      _atRiskThresholdHours = newHours;
    });
    await widget.storageService.setAtRiskThresholdHours(newHours);
  }

  /// Toggles task completion to showcase SLA completed rule.
  Future<void> _toggleTaskCompletion(Task task) async {
    final updatedStatus = task.isCompleted ? TaskStatus.inProgress : TaskStatus.completed;
    final updatedTask = task.copyWith(status: updatedStatus);
    await widget.storageService.saveTask(updatedTask);
    await _loadData();
  }

  /// Modifies deadline by a delta of hours to showcase live SLA state shifts.
  Future<void> _adjustDeadline(Task task, int hoursDelta) async {
    final updatedDeadline = task.deadline.add(Duration(hours: hoursDelta));
    final updatedTask = task.copyWith(deadline: updatedDeadline);
    await widget.storageService.saveTask(updatedTask);
    await _loadData();
  }

  /// Deletes task with instant persistent update.
  Future<void> _deleteTask(Task task) async {
    await widget.storageService.deleteTask(task.id);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Resets to default seed data to easily repeat demos.
  Future<void> _resetSeedData() async {
    setState(() => _isLoading = true);
    await widget.storageService.resetToSampleData();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Re-seeded default software tasks & members!'),
          backgroundColor: AppColors.slaOnTrack,
        ),
      );
    }
  }

  /// Adds a quick sample task to demonstrate live insertion and persistence.
  Future<void> _addQuickTask() async {
    final now = DateTime.now();
    final randomMemberId = _members.isNotEmpty ? _members.first.id : null;
    final newTask = Task(
      id: 'task_${now.millisecondsSinceEpoch}',
      title: 'Deploy Hotfix #${now.second % 100}',
      description: 'Patch generated at ${now.toIso8601String().substring(11, 19)} to test live insertion.',
      assigneeId: randomMemberId,
      priority: TaskPriority.urgent,
      deadline: now.add(const Duration(hours: 18)), // Enters At Risk by default
      status: TaskStatus.todo,
      createdAt: now,
    );

    await widget.storageService.saveTask(newTask);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = SlaService.getSlaBreakdown(
      _tasks,
      thresholdHours: _atRiskThresholdHours,
    );
    final healthScore = SlaService.calculateProjectHealthScore(
      _tasks,
      thresholdHours: _atRiskThresholdHours,
    );

    final filteredTasks = _selectedStatusFilter == null
        ? _tasks
        : _tasks.where((t) {
            return SlaService.getStatus(t, atRiskThresholdHours: _atRiskThresholdHours) ==
                _selectedStatusFilter;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SLA Tracker • Foundation & Core'),
        actions: [
          IconButton(
            tooltip: 'SLA Settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.slaSettings);
              _loadData();
            },
          ),
          IconButton(
            tooltip: 'Reload from SharedPreferences',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildHeaderBanner(),
                  const SizedBox(height: 16),
                  _buildSlaMetricsCard(breakdown, healthScore),
                  const SizedBox(height: 16),
                  _buildThresholdSliderCard(),
                  const SizedBox(height: 16),
                  _buildPersistenceControlBar(),
                  const SizedBox(height: 20),
                  _buildTeamNavigationHub(),
                  const SizedBox(height: 20),
                  _buildTaskListHeader(filteredTasks.length),
                  const SizedBox(height: 8),
                  if (filteredTasks.isEmpty)
                    _buildEmptyState()
                  else
                    ...filteredTasks.map((t) => _buildTaskCard(t)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  /// Banner identifying Member 1's role and focus areas
  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Member 1 • feature/data-sla-core',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.verified, color: AppColors.primary, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Foundation, Models, Storage & SLA Engine',
            style: AppTypography.titleMedium.copyWith(color: AppColors.primaryDark),
          ),
          const SizedBox(height: 4),
          Text(
            '$_persistenceStatusMessage. Drag threshold below to witness real-time SLA status re-evaluation.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Dashboard SLA Metrics Card with Health Gauge & Status Counts
  Widget _buildSlaMetricsCard(Map<SlaStatus, int> breakdown, double healthScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live SLA Health Score', style: AppTypography.titleMedium),
                    Text(
                      '${healthScore.toStringAsFixed(1)}% Healthy (On Track + Done)',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_tasks.length} Total Tasks',
                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: healthScore / 100,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  healthScore > 75
                      ? AppColors.slaOnTrack
                      : (healthScore > 50 ? AppColors.slaAtRisk : AppColors.slaOverdue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // SLA Breakdown row with tap-to-filter
            Row(
              children: SlaStatus.values.map((status) {
                final count = breakdown[status] ?? 0;
                final isSelected = _selectedStatusFilter == status;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatusFilter = isSelected ? null : status;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? status.backgroundColor : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? status.color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$count',
                            style: AppTypography.titleLarge.copyWith(
                              color: status.color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status.displayName,
                            style: AppTypography.caption.copyWith(
                              color: status.color,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// Interactive Unique Feature Card: Configurable At Risk Threshold
  Widget _buildThresholdSliderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.slaAtRisk, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Unique Feature: Dynamic "At Risk" Horizon',
                  style: AppTypography.titleMedium,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.slaAtRiskBg,
                    border: Border.all(color: AppColors.slaAtRiskBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_atRiskThresholdHours}h Warning',
                    style: AppTypography.badge.copyWith(color: AppColors.slaAtRisk),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tasks within this duration of their deadline are dynamically categorized as "At Risk". Adjust the slider to see SLA statuses recompute live:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 10),
            Slider(
              value: _atRiskThresholdHours.toDouble(),
              min: 6,
              max: 96,
              divisions: 15,
              label: '$_atRiskThresholdHours hours',
              activeColor: AppColors.slaAtRisk,
              onChanged: (val) {
                _updateThreshold(val.round());
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('6h (Strict)', style: AppTypography.caption),
                Text('24h (Standard)', style: AppTypography.caption),
                Text('48h (Cautious)', style: AppTypography.caption),
                Text('96h (Early Warning)', style: AppTypography.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Persistence Layer Controls (Add, Reset, Verify Persistence)
  Widget _buildPersistenceControlBar() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage & Persistence Controls', style: AppTypography.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: '+ Quick Task',
                  icon: Icons.add,
                  variant: AppButtonVariant.primary,
                  onPressed: _addQuickTask,
                ),
                AppButton(
                  label: 'Reset Seed Data',
                  icon: Icons.history,
                  variant: AppButtonVariant.secondary,
                  onPressed: _resetSeedData,
                ),
                AppButton(
                  label: 'Test Restart',
                  icon: Icons.cached_rounded,
                  variant: AppButtonVariant.outline,
                  onPressed: _loadData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Team Screen Launcher Hub (Connecting Members 2, 3, 4)
  Widget _buildTeamNavigationHub() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Team Branch Route Shells', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Ready-to-use screen shells for all 4 team members with shared navigation:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.login, size: 16),
                  label: const Text('M2: Sign In (/)'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.signIn),
                ),
                ActionChip(
                  avatar: const Icon(Icons.dashboard_outlined, size: 16),
                  label: const Text('M3: Dashboard (/dashboard)'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.dashboard),
                ),
                ActionChip(
                  avatar: const Icon(Icons.checklist, size: 16),
                  label: const Text('M3: Task List (/tasks)'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.taskList),
                ),
                ActionChip(
                  avatar: const Icon(Icons.add_task, size: 16),
                  label: const Text('M4: Create Task (/task-form)'),
                  onPressed: () async {
                    final res = await Navigator.pushNamed(context, AppRoutes.taskForm);
                    if (res == true) _loadData();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.group_outlined, size: 16),
                  label: const Text('M2: Team (/team)'),
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.team),
                ),
                ActionChip(
                  avatar: const Icon(Icons.settings, size: 16),
                  label: const Text('SLA Settings'),
                  onPressed: () async {
                    await Navigator.pushNamed(context, AppRoutes.slaSettings);
                    _loadData();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text('Tasks & SLA Status', style: AppTypography.titleLarge),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: AppTypography.badge),
            ),
          ],
        ),
        if (_selectedStatusFilter != null)
          TextButton.icon(
            onPressed: () => setState(() => _selectedStatusFilter = null),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear Filter'),
          ),
      ],
    );
  }

  /// Individual Task Card demonstrating all widgets & SLA calculation
  Widget _buildTaskCard(Task task) {
    final slaStatus = SlaService.getStatus(
      task,
      atRiskThresholdHours: _atRiskThresholdHours,
    );
    final timeRemainingLabel = SlaService.formattedTimeRemaining(
      task,
      atRiskThresholdHours: _atRiskThresholdHours,
    );
    final assignee = task.assigneeId != null ? _memberMap[task.assigneeId] : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Badges
            Row(
              children: [
                SlaBadge(status: slaStatus),
                const SizedBox(width: 6),
                PriorityBadge(priority: task.priority),
                const SizedBox(width: 6),
                StatusBadge(status: task.status),
                const Spacer(),
                if (assignee != null) MemberAvatar(member: assignee, radius: 14),
              ],
            ),
            const SizedBox(height: 10),

            // Title & Description
            Text(
              task.title,
              style: AppTypography.titleMedium.copyWith(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),

            // SLA Timing & Deadline row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: slaStatus.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(slaStatus.icon, size: 14, color: slaStatus.color),
                  const SizedBox(width: 6),
                  Text(
                    timeRemainingLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: slaStatus.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Deadline: ${task.deadline.month}/${task.deadline.day} ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Live Demo Action Buttons: Toggle, Shift Deadline, Delete
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _toggleTaskCompletion(task),
                  icon: Icon(
                    task.isCompleted ? Icons.replay : Icons.check_circle_outline,
                    size: 15,
                  ),
                  label: Text(task.isCompleted ? 'Reopen' : 'Complete'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
                const SizedBox(width: 6),
                // Shift Deadline -12h (pushes towards Overdue / At Risk)
                IconButton(
                  tooltip: 'Shift Deadline -12h (Push to At Risk/Overdue)',
                  icon: const Icon(Icons.fast_rewind_rounded, size: 18),
                  onPressed: () => _adjustDeadline(task, -12),
                  visualDensity: VisualDensity.compact,
                ),
                // Shift Deadline +12h (pushes towards On Track)
                IconButton(
                  tooltip: 'Shift Deadline +12h (Push to On Track)',
                  icon: const Icon(Icons.fast_forward_rounded, size: 18),
                  onPressed: () => _adjustDeadline(task, 12),
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Delete Task',
                  icon: const Icon(Icons.delete_outline, color: AppColors.slaOverdue, size: 18),
                  onPressed: () => _deleteTask(task),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(Icons.task_alt, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No tasks match the filter', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Reset sample data or click "+ Quick Task" to add tasks.',
              style: AppTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
