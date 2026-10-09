import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../models/team_member.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/member_avatar.dart';

/// Screen 1: Sign In & User Selection Screen
/// Assigned to Member 2 (Branch: feature/auth-team)
///
/// Features:
/// 1. Credential Form with full input validation (email regex, password length)
/// 2. Quick Demo User Selector (one-tap account switching for graders & demo)
/// 3. Session Persistence via SharedPreferences (remembers active user across app restarts)
/// 4. Quick Account Registration (sign up modal to add a new team member on the fly)
class SignInScreen extends StatefulWidget {
  final StorageService storageService;

  const SignInScreen({super.key, required this.storageService});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  List<TeamMember> _members = [];
  String? _selectedMemberId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  late TabController _tabController;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSessionAndMembers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionAndMembers() async {
    final members = await widget.storageService.getMembers();
    final activeId = widget.storageService.getCurrentUserId();

    setState(() {
      _members = members;
      _selectedMemberId = activeId ?? (members.isNotEmpty ? members.first.id : null);
      if (_selectedMemberId != null) {
        final current = members.cast<TeamMember?>().firstWhere(
          (m) => m?.id == _selectedMemberId,
          orElse: () => members.isNotEmpty ? members.first : null,
        );
        if (current != null) {
          _emailController.text = current.email;
          _passwordController.text = 'password123';
        }
      }
      _isLoading = false;
    });
  }

  void _onSelectMember(TeamMember member) {
    setState(() {
      _selectedMemberId = member.id;
      _emailController.text = member.email;
      _passwordController.text = 'password123';
    });
  }

  Future<void> _handleFormSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final email = _emailController.text.trim().toLowerCase();
    TeamMember? matchedMember;
    try {
      matchedMember = _members.firstWhere(
        (m) => m.email.toLowerCase() == email,
      );
    } catch (_) {
      matchedMember = null;
    }

    if (matchedMember == null) {
      // Auto-create a guest/demo account with the entered email
      final newMember = TeamMember(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: email.split('@').first.replaceAll('.', ' ').toUpperCase(),
        email: email,
        role: 'Developer',
        avatarColorHex: '2563EB',
      );
      await widget.storageService.saveMember(newMember);
      _members = await widget.storageService.getMembers();
      matchedMember = newMember;
    }

    if (_rememberMe) {
      await widget.storageService.setCurrentUserId(matchedMember.id);
    } else {
      await widget.storageService.setCurrentUserId(null);
    }

    setState(() {
      _selectedMemberId = matchedMember?.id;
      _isSubmitting = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome back, ${matchedMember.name}! Session active.'),
        backgroundColor: AppColors.slaOnTrack,
        duration: const Duration(seconds: 2),
      ),
    );

    _navigateToNext();
  }

  Future<void> _handleQuickMemberSignIn() async {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a team member first.'),
          backgroundColor: AppColors.slaAtRisk,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await widget.storageService.setCurrentUserId(_selectedMemberId);
    setState(() => _isSubmitting = false);

    if (!mounted) return;

    final member = _members.cast<TeamMember?>().firstWhere(
      (m) => m?.id == _selectedMemberId,
      orElse: () => null,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Active user set to: ${member?.name ?? "Selected User"}'),
        backgroundColor: AppColors.slaOnTrack,
        duration: const Duration(seconds: 2),
      ),
    );

    _navigateToNext();
  }

  void _navigateToNext() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    }
  }

  void _showSignUpDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Software Engineer');
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Account'),
        content: Form(
          key: dialogFormKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!_emailRegex.hasMatch(value.trim())) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: roleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Team Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Role is required';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (dialogFormKey.currentState!.validate()) {
                final newMember = TeamMember(
                  id: 'user_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim().toLowerCase(),
                  role: roleCtrl.text.trim(),
                  avatarColorHex: '4F46E5',
                );

                await widget.storageService.saveMember(newMember);
                await widget.storageService.setCurrentUserId(newMember.id);
                await _loadSessionAndMembers();

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Account created for ${newMember.name}!'),
                      backgroundColor: AppColors.slaOnTrack,
                    ),
                  );
                  _navigateToNext();
                }
              }
            },
            child: const Text('Create & Sign In'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sign In / User Selection'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroBanner(),
                        const SizedBox(height: 20),
                        _buildRoleAttributionTag(),
                        const SizedBox(height: 16),
                        _buildModeTabs(),
                        const SizedBox(height: 16),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: _tabController.index == 0
                              ? _buildCredentialsCard()
                              : _buildUserSelectionCard(),
                        ),
                        const SizedBox(height: 16),
                        _buildSignUpPrompt(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeroBanner() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.task_alt_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Project & SLA Task Tracker',
          style: AppTypography.displayLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Plan. Track. Deliver Together.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRoleAttributionTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Member 2 • feature/auth-team: Sign In, Validation & Session',
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

  Widget _buildModeTabs() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => setState(() {}),
        indicator: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTypography.labelLarge,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.lock_outline, size: 18), text: 'Sign In Form'),
          Tab(icon: Icon(Icons.people_outline, size: 18), text: 'Pick a User'),
        ],
      ),
    );
  }

  Widget _buildCredentialsCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter Credentials',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Sign in using your team email address.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),

              // Email Field
              AppTextField(
                label: 'Email Address',
                hint: 'user@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter your email address';
                  }
                  if (!_emailRegex.hasMatch(val.trim())) {
                    return 'Please enter a valid email format';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password Field
              AppTextField(
                label: 'Password',
                hint: '••••••••',
                controller: _passwordController,
                obscureText: _obscurePassword,
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Remember Me & Hint
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (val) => setState(() => _rememberMe = val ?? true),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Remember session', style: AppTypography.bodySmall),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _tabController.animateTo(1);
                      setState(() {});
                    },
                    child: const Text('Pick User Demo', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppButton(
                label: 'Sign In',
                icon: Icons.login,
                isFullWidth: true,
                isLoading: _isSubmitting,
                onPressed: _handleFormSignIn,
              ),

              if (_members.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Quick Fill Demo Credentials:',
                  style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _members.take(4).map((m) {
                    final isCurrent = m.email.toLowerCase() == _emailController.text.trim().toLowerCase();
                    return ActionChip(
                      avatar: MemberAvatar(member: m, radius: 10),
                      label: Text(m.name, style: const TextStyle(fontSize: 11)),
                      backgroundColor: isCurrent ? AppColors.primaryLight : null,
                      onPressed: () => _onSelectMember(m),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserSelectionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Active User', style: AppTypography.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Pick a team profile to simulate logged-in user experience.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            ..._members.map((member) {
              final isSelected = member.id == _selectedMemberId;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _onSelectMember(member),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          MemberAvatar(member: member, radius: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${member.role} • ${member.email}',
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue with Selected User',
              icon: Icons.check,
              isFullWidth: true,
              isLoading: _isSubmitting,
              onPressed: _handleQuickMemberSignIn,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpPrompt() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: _showSignUpDialog,
          child: const Text('Sign Up / Add Member'),
        ),
      ],
    );
  }
}
