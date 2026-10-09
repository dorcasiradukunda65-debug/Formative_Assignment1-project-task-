import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/member_avatar.dart';
import 'member_profile_screen.dart';
import 'widgets/add_edit_member_dialog.dart';

enum MemberSortOption {
  name,
  mostOpen,
  mostOverdue,
}

/// Screen 6 (Part A): Team Members Roster & Workload Management Screen
/// Assigned to Member 2 (Branch: feature/auth-team)
///
/// Features:
/// 1. Real-time Member Workload calculation (Open and Overdue counts per person)
/// 2. Add / Edit Member with full input validation via [AddEditMemberDialog]
/// 3. Delete Member with confirmation dialog & task assignment safeguards
/// 4. Session Handling: Visual indicator of current active user + one-tap session switcher
/// 5. Live Search & Sorting (by Name, Open Workload, Overdue Workload)
/// 6. Seamless Navigation to [MemberProfileScreen]
class TeamScreen extends StatefulWidget {
  final StorageService storageService;

  const TeamScreen({super.key, required this.storageService});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _members = [];
  List<Task> _tasks = [];
  String? _activeUserId;
  int _thresholdHours = 24;
  bool _isLoading = true;

  // Search & Filter
  final _searchController = TextEditingController();
  String _searchQuery = '';
  MemberSortOption _sortOption = MemberSortOption.name;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final members = await widget.storageService.getMembers();
    final tasks = await widget.storageService.getTasks();
    final activeId = widget.storageService.getCurrentUserId();
    final threshold = widget.storageService.getAtRiskThresholdHours();

    setState(() {
      _members = members;
      _tasks = tasks;
      _activeUserId = activeId;
      _thresholdHours = threshold;
      _isLoading = false;
    });
  }

  // Workload calculations per member
  int _getOpenCount(String memberId) {
    return _tasks
        .where((t) => t.assigneeId == memberId && !t.isCompleted)
        .length;
  }

  int _getOverdueCount(String memberId) {
    return _tasks.where((t) {
      if (t.assigneeId != memberId || t.isCompleted) return false;
      return SlaService.getStatus(t, atRiskThresholdHours: _thresholdHours) ==
          SlaStatus.overdue;
    }).length;
  }

  int _getCompletedCount(String memberId) {
    return _tasks
        .where((t) => t.assigneeId == memberId && t.isCompleted)
        .length;
  }

  Future<void> _openAddMemberDialog() async {
    final newMember = await showDialog<TeamMember>(
      context: context,
      builder: (ctx) => AddEditMemberDialog(storageService: widget.storageService),
    );

    if (newMember != null) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${newMember.name} to the team!'),
            backgroundColor: AppColors.slaOnTrack,
          ),
        );
      }
    }
  }

  Future<void> _openEditMemberDialog(TeamMember member) async {
    final updated = await showDialog<TeamMember>(
      context: context,
      builder: (ctx) => AddEditMemberDialog(
        storageService: widget.storageService,
        memberToEdit: member,
      ),
    );

    if (updated != null) {
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Updated ${updated.name}\'s profile!'),
            backgroundColor: AppColors.slaOnTrack,
          ),
        );
      }
    }
  }

  Future<void> _switchActiveUser(TeamMember member) async {
    await widget.storageService.setCurrentUserId(member.id);
    setState(() => _activeUserId = member.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched active session to ${member.name}!'),
          backgroundColor: AppColors.slaOnTrack,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteMemberWithConfirmation(TeamMember member) async {
    final assignedCount = _tasks.where((t) => t.assigneeId == member.id).length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${member.name}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove this member from the team?'),
            if (assignedCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.slaAtRiskBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slaAtRiskBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.slaAtRisk, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This member is assigned to $assignedCount task(s). Deleting will unassign their tasks.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.slaOverdue),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Member', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Unassign tasks assigned to this member
      for (final task in _tasks.where((t) => t.assigneeId == member.id)) {
        final unassigned = task.copyWith(assigneeId: null);
        await widget.storageService.saveTask(unassigned);
      }

      // Delete member
      await widget.storageService.deleteMember(member.id);

      // If deleted member was active session, clear session
      if (_activeUserId == member.id) {
        await widget.storageService.setCurrentUserId(null);
      }

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${member.name} from team.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToMemberProfile(TeamMember member) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemberProfileScreen(
          storageService: widget.storageService,
          member: member,
        ),
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    // Filter by search
    var displayedMembers = _members.where((m) {
      if (_searchQuery.isEmpty) return true;
      return m.name.toLowerCase().contains(_searchQuery) ||
          m.role.toLowerCase().contains(_searchQuery) ||
          m.email.toLowerCase().contains(_searchQuery);
    }).toList();

    // Sort
    switch (_sortOption) {
      case MemberSortOption.name:
        displayedMembers.sort((a, b) => a.name.compareTo(b.name));
        break;
      case MemberSortOption.mostOpen:
        displayedMembers.sort((a, b) => _getOpenCount(b.id).compareTo(_getOpenCount(a.id)));
        break;
      case MemberSortOption.mostOverdue:
        displayedMembers.sort((a, b) => _getOverdueCount(b.id).compareTo(_getOverdueCount(a.id)));
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          IconButton(
            tooltip: 'Add Team Member',
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _openAddMemberDialog,
          ),
          IconButton(
            tooltip: 'Refresh Roster',
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMemberDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  _buildRubricBanner(),
                  const SizedBox(height: 12),
                  _buildSearchAndSortBar(),
                  const SizedBox(height: 12),
                  _buildTeamSummaryStats(),
                  const SizedBox(height: 16),
                  if (displayedMembers.isEmpty)
                    _buildEmptyState()
                  else
                    ...displayedMembers.map((m) => _buildMemberCard(m)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildRubricBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Member 2: Team Roster, Profiles & Workload (Open & Overdue KPIs)',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, role or email...',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        PopupMenuButton<MemberSortOption>(
          tooltip: 'Sort Members',
          icon: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.sort, color: AppColors.textPrimary, size: 20),
          ),
          onSelected: (option) => setState(() => _sortOption = option),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: MemberSortOption.name,
              child: Text('Sort by Name (A-Z)'),
            ),
            const PopupMenuItem(
              value: MemberSortOption.mostOpen,
              child: Text('Sort by Most Open Tasks'),
            ),
            const PopupMenuItem(
              value: MemberSortOption.mostOverdue,
              child: Text('Sort by Most Overdue Tasks'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTeamSummaryStats() {
    final totalOpen = _tasks.where((t) => !t.isCompleted).length;
    final totalOverdue = _tasks.where((t) {
      if (t.isCompleted) return false;
      return SlaService.getStatus(t, atRiskThresholdHours: _thresholdHours) ==
          SlaStatus.overdue;
    }).length;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.people, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_members.length}', style: AppTypography.titleMedium),
                    Text('Members', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: AppColors.secondary, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$totalOpen', style: AppTypography.titleMedium),
                    Text('Open Tasks', style: AppTypography.caption),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.slaOverdueBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.slaOverdueBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.slaOverdue, size: 18),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalOverdue',
                      style: AppTypography.titleMedium.copyWith(color: AppColors.slaOverdue),
                    ),
                    Text(
                      'Overdue',
                      style: AppTypography.caption.copyWith(color: AppColors.slaOverdue),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    final openCount = _getOpenCount(member.id);
    final overdueCount = _getOverdueCount(member.id);
    final completedCount = _getCompletedCount(member.id);
    final isCurrentUser = member.id == _activeUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isCurrentUser ? AppColors.primary : AppColors.border,
          width: isCurrentUser ? 1.8 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToMemberProfile(member),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // Row 1: Avatar, Name, Role, Actions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MemberAvatar(member: member, radius: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.name,
                                style: AppTypography.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'YOU',
                                  style: AppTypography.badge.copyWith(
                                    color: AppColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          member.role,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          member.email,
                          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                    onSelected: (val) {
                      switch (val) {
                        case 'profile':
                          _navigateToMemberProfile(member);
                          break;
                        case 'edit':
                          _openEditMemberDialog(member);
                          break;
                        case 'switch_user':
                          _switchActiveUser(member);
                          break;
                        case 'delete':
                          _deleteMemberWithConfirmation(member);
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('View Profile'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Edit Member'),
                          ],
                        ),
                      ),
                      if (!isCurrentUser)
                        const PopupMenuItem(
                          value: 'switch_user',
                          child: Row(
                            children: [
                              Icon(Icons.login, size: 18),
                              SizedBox(width: 8),
                              Text('Set as Active User'),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: AppColors.slaOverdue),
                            SizedBox(width: 8),
                            Text('Delete Member', style: TextStyle(color: AppColors.slaOverdue)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Row 2: Workload KPIs per member (Open, Overdue, Completed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Open count
                    _buildWorkloadChip(
                      icon: Icons.assignment_outlined,
                      label: 'Open',
                      count: openCount,
                      color: AppColors.secondary,
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    // Overdue count (Highlighted if > 0)
                    _buildWorkloadChip(
                      icon: Icons.warning_amber_rounded,
                      label: 'Overdue',
                      count: overdueCount,
                      color: overdueCount > 0 ? AppColors.slaOverdue : AppColors.textSecondary,
                      isAlert: overdueCount > 0,
                    ),
                    Container(width: 1, height: 24, color: AppColors.border),
                    // Done count
                    _buildWorkloadChip(
                      icon: Icons.check_circle_outline,
                      label: 'Completed',
                      count: completedCount,
                      color: AppColors.slaOnTrack,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkloadChip({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    bool isAlert = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '$count',
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontWeight: isAlert ? FontWeight.w800 : FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.person_search_outlined, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text('No team members found', style: AppTypography.titleMedium),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term.'
                  : 'Click "+ Add Member" to add the first teammate.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
