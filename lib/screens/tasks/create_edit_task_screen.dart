import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

/// Screen 5: Create / Edit Task Screen Shell
/// Assigned to Member 4 (Branch: feature/task-details-form)
class CreateEditTaskScreen extends StatefulWidget {
  final StorageService storageService;
  final Task? initialTask;

  const CreateEditTaskScreen({
    super.key,
    required this.storageService,
    this.initialTask,
  });

  @override
  State<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends State<CreateEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _categoryController;
  late TextEditingController _notesController;
  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime _deadline = DateTime.now().add(const Duration(days: 3));
  String? _assigneeId;
  List<TeamMember> _members = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _categoryController = TextEditingController(text: task?.category ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    if (task != null) {
      _deadline = task.deadline;
      _assigneeId = task.assigneeId;
    }
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final members = await widget.storageService.getMembers();
    setState(() {
      _members = members;
      if (_assigneeId == null && members.isNotEmpty) {
        _assigneeId = members.first.id;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final isEditing = widget.initialTask != null;
    final task = Task(
      id: widget.initialTask?.id ?? 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      category: _categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim(),
      notes: _notesController.text.trim(),
      assigneeId: _assigneeId,
      priority: _priority,
      deadline: _deadline,
      status: _status,
      createdAt: widget.initialTask?.createdAt ?? DateTime.now(),
    );

    await widget.storageService.saveTask(task);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Task updated!' : 'Task created!'),
          backgroundColor: AppColors.slaOnTrack,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialTask != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Create New Task'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Assigned to Member 4 • Branch: feature/task-details-form\nImplements form inputs, date/time pickers, priority chips & error validation.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _titleController,
              label: 'Task Title',
              hint: 'e.g. Implement OAuth 2.0 PKCE flow',
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descController,
              label: 'Description',
              hint: 'Detailed requirements and acceptance criteria',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _categoryController,
              label: 'Category',
              hint: 'e.g. UI/UX Design',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _notesController,
              label: 'Notes',
              hint: 'Any additional notes',
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Text('Assignee', style: AppTypography.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _assigneeId,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: _members.map((m) {
                return DropdownMenuItem<String>(
                  value: m.id,
                  child: Text('${m.name} (${m.role})'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _assigneeId = val);
              },
            ),
            const SizedBox(height: 20),
            Text('Priority', style: AppTypography.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TaskPriority.values.map((p) {
                final isSelected = _priority == p;
                return ChoiceChip(
                  label: Text(p.displayName),
                  selected: isSelected,
                  selectedColor: p.color.withValues(alpha: 0.2),
                  onSelected: (val) {
                    if (val) setState(() => _priority = p);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: isEditing ? 'Save Changes' : 'Create Task',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _save,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
