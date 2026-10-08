import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/team_member.dart';
import '../../services/storage_service.dart';
import '../../widgets/member_avatar.dart';

/// Screen 6: Team Members / Profile Shell
/// Assigned to Member 2 (Branch: feature/auth-team)
class TeamScreen extends StatefulWidget {
  final StorageService storageService;

  const TeamScreen({super.key, required this.storageService});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  List<TeamMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final members = await widget.storageService.getMembers();
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members & Profiles'),
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
                    'Assigned to Member 2 • Branch: feature/auth-team\nDisplays member roster, workloads, and profile views.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                  ),
                ),
                const SizedBox(height: 16),
                ..._members.map((m) => Card(
                      child: ListTile(
                        leading: MemberAvatar(member: m),
                        title: Text(m.name, style: AppTypography.titleMedium),
                        subtitle: Text('${m.role}\n${m.email}'),
                        isThreeLine: true,
                      ),
                    )),
              ],
            ),
    );
  }
}
