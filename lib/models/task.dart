import 'package:flutter/material.dart';

/// Task priority levels matching the reference UI
enum TaskPriority {
  low,
  medium,
  high,
  urgent;

  String get displayName {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return const Color(0xFF64748B); // Slate
      case TaskPriority.medium:
        return const Color(0xFF0284C7); // Sky Blue
      case TaskPriority.high:
        return const Color(0xFFF97316); // Orange
      case TaskPriority.urgent:
        return const Color(0xFFDC2626); // Red
    }
  }

  IconData get icon {
    switch (this) {
      case TaskPriority.low:
        return Icons.arrow_downward_rounded;
      case TaskPriority.medium:
        return Icons.remove_rounded;
      case TaskPriority.high:
        return Icons.flag_rounded;
      case TaskPriority.urgent:
        return Icons.priority_high_rounded;
    }
  }
}

/// Task workflow statuses matching the reference UI
enum TaskStatus {
  todo,
  inProgress,
  review,
  completed;

  String get displayName {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'In Review';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.todo:
        return const Color(0xFF64748B);
      case TaskStatus.inProgress:
        return const Color(0xFF2563EB);
      case TaskStatus.review:
        return const Color(0xFF7C3AED);
      case TaskStatus.completed:
        return const Color(0xFF10B981);
    }
  }
}

/// Core Task model for the SLA Tracker.
/// Contains all fields required by the reference screenshots:
/// title, description, category, assigneeId, priority, deadline, status, notes, createdAt
class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? assigneeId;
  final TaskPriority priority;
  final DateTime deadline;
  final TaskStatus status;
  final String notes;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'General',
    this.assigneeId,
    required this.priority,
    required this.deadline,
    required this.status,
    this.notes = '',
    required this.createdAt,
  });

  /// True if task has been marked completed.
  bool get isCompleted => status == TaskStatus.completed;

  /// Serializes task to JSON map for SharedPreferences persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'assigneeId': assigneeId,
      'priority': priority.name,
      'deadline': deadline.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Deserializes JSON map back to a Task object.
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      assigneeId: json['assigneeId'] as String?,
      priority: TaskPriority.values.firstWhere(
        (p) => p.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      deadline: DateTime.parse(json['deadline'] as String),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TaskStatus.todo,
      ),
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Implements copyWith for clean immutable updates.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? assigneeId,
    TaskPriority? priority,
    DateTime? deadline,
    TaskStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      assigneeId: assigneeId ?? this.assigneeId,
      priority: priority ?? this.priority,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Task(id: $id, title: $title, category: $category, status: ${status.name}, deadline: $deadline)';
}
