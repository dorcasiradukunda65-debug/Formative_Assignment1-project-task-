import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  final StorageService storageService;

  const DashboardScreen({super.key, required this.storageService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];
  int _atRiskThresholdHours = 24;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    final tasks = await widget.storageService.getTasks();
    final threshold = widget.storageService.getAtRiskThresholdHours();

    setState(() {
      _tasks = tasks;
      _atRiskThresholdHours = threshold;
      _isLoading = false;
    });
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

    // Filter tasks that need attention (At Risk or Overdue)
    final urgentTasks = _tasks.where((t) {
      if (t.isCompleted) return false;
      final status = SlaService.getStatus(t, atRiskThresholdHours: _atRiskThresholdHours);
      return status == SlaStatus.atRisk || status == SlaStatus.overdue;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh Dashboard',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Health Score Card
                  _buildHealthScoreCard(healthScore),
                  const SizedBox(height: 16),

                  // SLA Status Breakdown
                  Text('SLA Status Breakdown', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  _buildSlaBreakdownRow(breakdown),
                  const SizedBox(height: 20),

                  // Needs Attention Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Needs Attention', style: AppTypography.titleMedium),
                      Text('${urgentTasks.length} items', style: AppTypography.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (urgentTasks.isEmpty)
                    _buildAllClearState()
                  else
                    ...urgentTasks.map((t) => _buildAttentionCard(t)),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHealthScoreCard(double healthScore) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project Health Score', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${healthScore.toStringAsFixed(1)}%',
              style: AppTypography.displayLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: healthScore / 100,
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation(
                  healthScore > 75
                      ? AppColors.slaOnTrack
                      : (healthScore > 50 ? AppColors.slaAtRisk : AppColors.slaOverdue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlaBreakdownRow(Map<SlaStatus, int> breakdown) {
    return Row(
      children: SlaStatus.values.map((status) {
        final count = breakdown[status] ?? 0;

        return Expanded(
          child: InkWell(
            onTap: () {
              // Pass the tapped status (Completed, Overdue, At Risk, On Track) as an argument
              Navigator.pushNamed(
                context,
                AppRoutes.taskList,
                arguments: status,
              );
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: status.color, width: 1.5),
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
                  const SizedBox(height: 4),
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
    );
  }

  Widget _buildAttentionCard(Task task) {
    final status = SlaService.getStatus(task, atRiskThresholdHours: _atRiskThresholdHours);
    final isOverdue = status == SlaStatus.overdue;

    return InkWell(
      onTap: () {
        // Tapping an attention card opens the Task List pre-filtered to this task's status
        Navigator.pushNamed(
          context,
          AppRoutes.taskList,
          arguments: status,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isOverdue ? AppColors.slaOverdueBg : AppColors.slaAtRiskBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOverdue ? AppColors.slaOverdueBorder : AppColors.slaAtRiskBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isOverdue ? Icons.error_rounded : Icons.warning_amber_rounded,
              color: isOverdue ? AppColors.slaOverdue : AppColors.slaAtRisk,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due: ${task.deadline.month}/${task.deadline.day} ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}',
                    style: AppTypography.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status.backgroundColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: status.color),
              ),
              child: Text(
                status.displayName,
                style: AppTypography.caption.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearState() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.slaOnTrack, size: 40),
              SizedBox(height: 8),
              Text('All tasks are on track!', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
