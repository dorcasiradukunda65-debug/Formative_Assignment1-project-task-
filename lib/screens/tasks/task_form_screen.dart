
import 'package:flutter/material.dart';

import '../../models/task.dart';
import '../../models/team_member.dart';
import '../../services/storage_service.dart';

class TaskFormScreen extends StatefulWidget {
  final StorageService storageService;
  final Task? task;

  const TaskFormScreen({
    super.key,
    required this.storageService,
    this.task,
  });

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _notesController;

  List<TeamMember> _members = [];
  String? _assigneeId;
  late TaskPriority _priority;
  late TaskStatus _status;
  late DateTime _deadline;

  bool _isLoadingMembers = true;
  bool _isSaving = false;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    final task = widget.task;

    _titleController = TextEditingController(
      text: task?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: task?.category ?? 'General',
    );
    _notesController = TextEditingController(
      text: task?.notes ?? '',
    );

    _assigneeId = task?.assigneeId;
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;
    _deadline = task?.deadline ??
        DateTime.now().add(const Duration(days: 1));

    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final members = await widget.storageService.getMembers();

      if (!mounted) return;

      setState(() {
        _members = members;
        _isLoadingMembers = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => _isLoadingMembers = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load team members.')),
      );
    }
  }

  Future<void> _chooseDeadline() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now) ? now : _deadline,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );

    if (pickedTime == null || !mounted) return;

    setState(() {
      _deadline = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEditing && !_deadline.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new task deadline must be in the future.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final oldTask = widget.task;

    final task = Task(
      id: oldTask?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _categoryController.text.trim().isEmpty
          ? 'General'
          : _categoryController.text.trim(),
      assigneeId: _assigneeId,
      priority: _priority,
      deadline: _deadline,
      status: _status,
      notes: _notesController.text.trim(),
      createdAt: oldTask?.createdAt ?? DateTime.now(),
    );

    try {
      await widget.storageService.saveTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Task updated successfully.' : 'Task created successfully.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the task. Please try again.')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final assigneeExists =
        _members.any((member) => member.id == _assigneeId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Create Task'),
      ),
      body: _isLoadingMembers
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  TextFormField(
                    controller: _titleController,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Task title *',
                      hintText: 'Enter a clear task title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Task title is required.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 1000,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _categoryController,
                    maxLength: 40,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Development, Design',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: assigneeExists ? _assigneeId : null,
                    decoration: const InputDecoration(
                      labelText: 'Assignee',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Unassigned'),
                      ),
                      ..._members.map(
                        (member) => DropdownMenuItem<String>(
                          value: member.id,
                          child: Text(member.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _assigneeId = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<TaskPriority>(
                    initialValue: _priority,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskPriority.values.map((priority) {
                      return DropdownMenuItem(
                        value: priority,
                        child: Text(priority.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _priority = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<TaskStatus>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: TaskStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _status = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  OutlinedButton.icon(
                    onPressed: _chooseDeadline,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      'Deadline: ${MaterialLocalizations.of(context).formatMediumDate(_deadline)} '
                      'at ${TimeOfDay.fromDateTime(_deadline).format(context)}',
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _notesController,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Additional notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 24),

                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveTask,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSaving
                          ? 'Saving...'
                          : _isEditing
                              ? 'Save Changes'
                              : 'Create Task',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}