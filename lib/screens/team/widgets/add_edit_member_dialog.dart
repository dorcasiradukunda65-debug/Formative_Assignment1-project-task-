import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../models/team_member.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// Modal dialog for adding a new team member or editing an existing one.
/// Provides comprehensive input validation:
/// - Required fields
/// - Name length constraints
/// - Email regex validation & duplicate email detection
/// - Role selection & avatar color palette
class AddEditMemberDialog extends StatefulWidget {
  final StorageService storageService;
  final TeamMember? memberToEdit;

  const AddEditMemberDialog({
    super.key,
    required this.storageService,
    this.memberToEdit,
  });

  @override
  State<AddEditMemberDialog> createState() => _AddEditMemberDialogState();
}

class _AddEditMemberDialogState extends State<AddEditMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late String _selectedRole;
  late String _selectedColorHex;
  bool _isCustomRole = false;
  late final TextEditingController _customRoleController;
  bool _isSaving = false;

  static const List<String> _commonRoles = [
    'Project Manager',
    'UI/UX Designer',
    'Mobile Developer',
    'Backend Developer',
    'QA Tester',
    'DevOps Engineer',
    'Documentation',
    'Custom Role...',
  ];

  static const List<String> _colorPalette = [
    '4F46E5', // Indigo
    '2563EB', // Blue
    '10B981', // Emerald / Green
    '7C3AED', // Purple
    'F59E0B', // Amber
    'EF4444', // Red
    '0D9488', // Teal
    'EC4899', // Pink
  ];

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  bool get _isEditing => widget.memberToEdit != null;

  @override
  void initState() {
    super.initState();
    final member = widget.memberToEdit;
    _nameController = TextEditingController(text: member?.name ?? '');
    _emailController = TextEditingController(text: member?.email ?? '');

    if (member != null && _commonRoles.contains(member.role)) {
      _selectedRole = member.role;
      _isCustomRole = false;
      _customRoleController = TextEditingController();
    } else if (member != null) {
      _selectedRole = 'Custom Role...';
      _isCustomRole = true;
      _customRoleController = TextEditingController(text: member.role);
    } else {
      _selectedRole = _commonRoles.first;
      _isCustomRole = false;
      _customRoleController = TextEditingController();
    }

    _selectedColorHex = member?.avatarColorHex ?? _colorPalette.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _customRoleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final enteredEmail = _emailController.text.trim().toLowerCase();
    final allMembers = await widget.storageService.getMembers();

    // Check duplicate email (unless it belongs to the current member being edited)
    final duplicate = allMembers.any(
      (m) =>
          m.email.toLowerCase() == enteredEmail &&
          (!_isEditing || m.id != widget.memberToEdit!.id),
    );

    if (duplicate) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A team member with this email already exists.'),
          backgroundColor: AppColors.slaOverdue,
        ),
      );
      return;
    }

    final effectiveRole =
        _isCustomRole ? _customRoleController.text.trim() : _selectedRole;

    final member = TeamMember(
      id: widget.memberToEdit?.id ?? 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      email: enteredEmail,
      role: effectiveRole,
      avatarColorHex: _selectedColorHex,
    );

    await widget.storageService.saveMember(member);

    setState(() => _isSaving = false);

    if (!mounted) return;
    Navigator.of(context).pop(member);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit_outlined : Icons.person_add_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing ? 'Edit Team Member' : 'Add Team Member',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Full Name
                  AppTextField(
                    label: 'Full Name *',
                    hint: 'e.g. Alex Morgan',
                    controller: _nameController,
                    prefixIcon: Icons.badge_outlined,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Member name is required';
                      }
                      if (val.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AppTextField(
                    label: 'Email Address *',
                    hint: 'e.g. alex.morgan@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.mail_outline,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!_emailRegex.hasMatch(val.trim())) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Role Dropdown
                  Text(
                    'Team Role *',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    items: _commonRoles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedRole = val;
                        _isCustomRole = val == 'Custom Role...';
                      });
                    },
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.work_outline, size: 20),
                    ),
                  ),

                  if (_isCustomRole) ...[
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Specify Custom Role *',
                      hint: 'e.g. Security Lead',
                      controller: _customRoleController,
                      prefixIcon: Icons.edit_note,
                      validator: (val) {
                        if (_isCustomRole && (val == null || val.trim().isEmpty)) {
                          return 'Please enter the custom role title';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Avatar Color Picker
                  Text(
                    'Avatar Accent Color',
                    style: AppTypography.labelLarge.copyWith(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colorPalette.map((hex) {
                      final isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();
                      final color = Color(int.parse('FF$hex', radix: 16));
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black : Colors.white,
                              width: isSelected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      AppButton(
                        label: _isEditing ? 'Save Changes' : 'Add Member',
                        icon: _isEditing ? Icons.check : Icons.add,
                        isLoading: _isSaving,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

