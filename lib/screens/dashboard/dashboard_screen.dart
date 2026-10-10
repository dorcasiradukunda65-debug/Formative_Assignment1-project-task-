import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/sla_badge.dart';

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
    _loadData();
  }

  Future<void> _loadData() async {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Health Score Card
                  Card(
                    elevation: 2,
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
                  const SizedBox(height: 20),

                  // SLA Status Breakdown
                  Text('SLA Status Breakdown', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    children: SlaStatus.values.map((status) {
                      final count = breakdown[status] ?? 0;
                      return Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
                  const SizedBox(height: 24),

                  // Needs Attention Section
                  Text('Needs Attention', style: AppTypography.titleMedium),
                  const SizedBox(height: 8),
                  ..._tasks.where((task) {
                    final status = SlaService.getStatus(task, atRiskThresholdHours: threshold);
                    return status == SlaStatus.atRisk || status == SlaStatus.overdue;
                  }).map((task) {
                    final status = SlaService.getStatus(task, atRiskThresholdHours: threshold);
                    return Card(
                      color: status == SlaStatus.overdue ? Colors.red.shade50 : Colors.orange.shade50,
                      child: ListTile(
                        leading: Icon(
                          status == SlaStatus.overdue ? Icons.error : Icons.warning,
                          color: status == SlaStatus.overdue ? Colors.red : Colors.orange,
                        ),
                        title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Due: ${task.deadline.toLocal().toString().split(' ')[0]}'),
                        trailing: SlaBadge(status: status, isCompact: true),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}