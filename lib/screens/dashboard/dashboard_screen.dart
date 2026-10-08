import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sla_badge.dart';

/// Screen 2: Project Dashboard Shell
/// Assigned to Member 3 (Branch: feature/dashboard-tasklist)
class DashboardScreen extends StatefulWidget {
  final StorageService storageService;

  const DashboardScreen({super.key, required this.storageService});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final threshold = widget.storageService.getAtRiskThresholdHours();
    final breakdown = SlaService.getSlaBreakdown(_tasks, thresholdHours: threshold);
    final healthScore = SlaService.calculateProjectHealthScore(_tasks, thresholdHours: threshold);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Dashboard'),
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
                    'Assigned to Member 3 • Branch: feature/dashboard-tasklist\nShows SLA charts, health score, and attention lists.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Project Health Score', style: AppTypography.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${healthScore.toStringAsFixed(1)}%',
                          style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: healthScore / 100,
                            minHeight: 10,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation(AppColors.slaOnTrack),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('SLA Status Breakdown', style: AppTypography.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: SlaStatus.values.map((status) {
                    final count = breakdown[status] ?? 0;
                    return Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          child: Column(
                            children: [
                              Text('$count', style: AppTypography.titleLarge.copyWith(color: status.color)),
                              const SizedBox(height: 4),
                              SlaBadge(status: status, isCompact: true, showIcon: false),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
