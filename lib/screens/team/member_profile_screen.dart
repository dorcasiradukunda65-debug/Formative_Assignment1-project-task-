import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/priority_badge.dart';
import '../../widgets/sla_badge.dart';
import '../../widgets/status_badge.dart';
import 'widgets/add_edit_member_dialog.dart';

/// Screen 6 (Part B): Team Member Profile & Workload Screen
/// Assigned to Member 2 (Branch: irakora/auth-team)
///
/// Features:
/// 1. Comprehensive Workload breakdown: Open vs. Overdue counts, total assigned, completion rate
/// 2. Detailed list of tasks assigned to this specific member with SLA badges
/// 3. Profile editing (updating name, email, role, avatar color)
/// 4. Session management: Switch active user, sign out, remember session
class MemberProfileScreen extends StatefulWidget {
  final StorageService storageService;
  final TeamMember member;

  const MemberProfileScreen({
    super.key,
    required this.storageService,
    required this.member,
  });

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  late TeamMember _currentMember;
  List<Task> _memberTasks = [];
  bool _isLoading = true;
  bool _isActiveUser = false;
  int _thresholdHours = 24;

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    setState(() => _isLoading = true);

    // Refresh member data
    final members = await widget.storageService.getMembers();
    final updatedMember = members.cast<TeamMember?>().firstWhere(
      (m) => m?.id == _currentMember.id,
      orElse: () => _currentMember,
    );

    final allTasks = await widget.storageService.getTasks();
    final activeUserId = widget.storageService.getCurrentUserId();
    final threshold = widget.storageService.getAtRiskThresholdHours();

    final tasksForMember = allTasks
        .where((t) => t.assigneeId == _currentMember.id)
        .toList();

    // Sort: Overdue & At-risk first, then by deadline
    tasksForMember.sort((a, b) {
      final aSla = SlaService.getStatus(a, atRiskThresholdHours: threshold);
      final bSla = SlaService.getStatus(b, atRiskThresholdHours: threshold);
      if (aSla == SlaStatus.overdue && bSla != SlaStatus.overdue) return -1;
      if (bSla == SlaStatus.overdue && aSla != SlaStatus.overdue) return 1;
      return a.deadline.compareTo(b.deadline);
    });

    setState(() {
      if (updatedMember != null) {
        _currentMember = updatedMember;
      }
      _memberTasks = tasksForMember;
      _isActiveUser = activeUserId == _currentMember.id;
      _thresholdHours = threshold;
      _isLoading = false;
    });
  }

  Future<void> _toggleActiveSession() async {
    if (_isActiveUser) {
      await widget.storageService.setCurrentUserId(null);
      setState(() => _isActiveUser = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed out of session.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      await widget.storageService.setCurrentUserId(_currentMember.id);
      setState(() => _isActiveUser = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched active session to ${_currentMember.name}!'),
            backgroundColor: AppColors.slaOnTrack,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openEditDialog() async {
    final result = await showDialog<TeamMember>(
      context: context,
      builder: (ctx) => AddEditMemberDialog(
        storageService: widget.storageService,
        memberToEdit: _currentMember,
      ),
    );

    if (result != null) {
      setState(() => _currentMember = result);
      await _loadMemberData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Workload computations
    final totalAssigned = _memberTasks.length;
    final openTasks = _memberTasks.where((t) => !t.isCompleted).toList();
    final overdueTasks = openTasks
        .where((t) =>
            SlaService.getStatus(t, atRiskThresholdHours: _thresholdHours) ==
            SlaStatus.overdue)
        .toList();
    final atRiskTasks = openTasks
        .where((t) =>
            SlaService.getStatus(t, atRiskThresholdHours: _thresholdHours) ==
            SlaStatus.atRisk)
        .toList();
    final completedTasks = _memberTasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${_currentMember.name}\'s Profile'),
        actions: [
          IconButton(
            tooltip: 'Edit Profile',
            icon: const Icon(Icons.edit_outlined),
            onPressed: _openEditDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMemberData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 16),
                  _buildWorkloadMetricsCard(
                    total: totalAssigned,
                    openCount: openTasks.length,
                    overdueCount: overdueTasks.length,
                    atRiskCount: atRiskTasks.length,
                    completedCount: completedTasks.length,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickSettingsCard(),
                  const SizedBox(height: 20),
                  _buildAssignedTasksHeader(totalAssigned),
                  const SizedBox(height: 8),
                  if (_memberTasks.isEmpty)
                    _buildNoTasksCard()
                  else
                    ..._memberTasks.map((t) => _buildMemberTaskCard(t)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeaderCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                MemberAvatar(member: _currentMember, radius: 44),
                if (_isActiveUser)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.slaOnTrack,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(_currentMember.name, style: AppTypography.titleLarge),
            const SizedBox(height: 4),
            Text(
              _currentMember.role,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _currentMember.email,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: [
                if (_isActiveUser)
                  Chip(
                    avatar: const Icon(Icons.star, size: 16, color: AppColors.primary),
                    label: const Text('Currently Logged In'),
                    backgroundColor: AppColors.primaryLight,
                    side: BorderSide.none,
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _toggleActiveSession,
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Log In As This User'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _openEditDialog,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Details'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkloadMetricsCard({
    required int total,
    required int openCount,
    required int overdueCount,
    required int atRiskCount,
    required int completedCount,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Member Workload & SLA', style: AppTypography.titleMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total Tasks',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 4 Grid KPI Boxes
            Row(
              children: [
                _buildStatBox(
                  label: 'Open',
                  count: openCount,
                  color: AppColors.secondary,
                  bgColor: const Color(0xFFF0F9FF),
                ),
                const SizedBox(width: 8),
                _buildStatBox(
                  label: 'Overdue',
                  count: overdueCount,
                  color: AppColors.slaOverdue,
                  bgColor: AppColors.slaOverdueBg,
                  isAlert: overdueCount > 0,
                ),
                const SizedBox(width: 8),
                _buildStatBox(
                  label: 'At Risk',
                  count: atRiskCount,
                  color: AppColors.slaAtRisk,
                  bgColor: AppColors.slaAtRiskBg,
                ),
                const SizedBox(width: 8),
                _buildStatBox(
                  label: 'Done',
                  count: completedCount,
                  color: AppColors.slaOnTrack,
                  bgColor: AppColors.slaOnTrackBg,
                ),
              ],
            ),

            if (total > 0) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Completion Progress', style: AppTypography.caption),
                  Text(
                    '${((completedCount / total) * 100).toStringAsFixed(0)}%',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: completedCount / total,
                  minHeight: 7,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.slaOnTrack),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    bool isAlert = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isAlert ? color : color.withValues(alpha: 0.25),
            width: isAlert ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: AppTypography.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_note, color: AppColors.primary),
            title: const Text('Edit Profile Information'),
            subtitle: const Text('Update full name, role or email'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _openEditDialog,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              _isActiveUser ? Icons.logout : Icons.login,
              color: _isActiveUser ? AppColors.slaOverdue : AppColors.primary,
            ),
            title: Text(_isActiveUser ? 'Sign Out Current Session' : 'Switch Session To Member'),
            subtitle: Text(_isActiveUser ? 'Clear remembered user' : 'Make active user'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: _toggleActiveSession,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.tune_rounded, color: AppColors.slaAtRisk),
            title: const Text('Configurable SLA Threshold'),
            subtitle: Text('Current warning horizon: ${_thresholdHours}h'),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.slaSettings);
              _loadMemberData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignedTasksHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Assigned Tasks', style: AppTypography.titleMedium),
        Text(
          '$count Total',
          style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildMemberTaskCard(Task task) {
    final slaStatus = SlaService.getStatus(
      task,
      atRiskThresholdHours: _thresholdHours,
    );
    final timeStr = SlaService.formattedTimeRemaining(
      task,
      atRiskThresholdHours: _thresholdHours,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SlaBadge(status: slaStatus, isCompact: true),
                const SizedBox(width: 6),
                PriorityBadge(priority: task.priority),
                const SizedBox(width: 6),
                StatusBadge(status: task.status),
                const Spacer(),
                Text(
                  timeStr,
                  style: AppTypography.caption.copyWith(
                    color: slaStatus.color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category: ${task.category}',
                  style: AppTypography.caption,
                ),
                Text(
                  'Deadline: ${task.deadline.month}/${task.deadline.day} ${task.deadline.hour.toString().padLeft(2, '0')}:${task.deadline.minute.toString().padLeft(2, '0')}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTasksCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 36, color: AppColors.textTertiary),
            const SizedBox(height: 8),
            Text('No tasks assigned yet', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Tasks assigned to this member will appear here with SLA tracking.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

