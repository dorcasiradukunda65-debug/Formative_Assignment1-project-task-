import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/team_member.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/member_avatar.dart';

/// Screen 1: Sign In / User Selection Shell
/// Assigned to Member 2 (Branch: feature/auth-team)
class SignInScreen extends StatefulWidget {
  final StorageService storageService;

  const SignInScreen({super.key, required this.storageService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  List<TeamMember> _members = [];
  String? _selectedMemberId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await widget.storageService.getMembers();
    final activeId = widget.storageService.getCurrentUserId();
    setState(() {
      _members = members;
      _selectedMemberId = activeId ?? (members.isNotEmpty ? members.first.id : null);
      _isLoading = false;
    });
  }

  Future<void> _confirmLogin() async {
    if (_selectedMemberId != null) {
      await widget.storageService.setCurrentUserId(_selectedMemberId);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.foundationExplorer);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In / User Selection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Assigned to Member 2 • Branch: feature/auth-team\nProvides user selection & session handling.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Select Active Team Member', style: AppTypography.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Choose an account to simulate authenticated user workflow.',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _members.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final isSelected = member.id == _selectedMemberId;
                        return InkWell(
                          onTap: () {
                            setState(() => _selectedMemberId = member.id);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.border,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                MemberAvatar(member: member, radius: 22),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member.name, style: AppTypography.titleMedium),
                                      Text(
                                        '${member.role} • ${member.email}',
                                        style: AppTypography.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: AppColors.primary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  AppButton(
                    label: 'Continue as Selected User',
                    isFullWidth: true,
                    onPressed: _confirmLogin,
                  ),
                ],
              ),
            ),
    );
  }
}
