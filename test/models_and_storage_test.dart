import 'package:flutter_test/flutter_test.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/models/team_member.dart';

void main() {
  group('Model Serialization Tests', () {
    test('Task toJson and fromJson roundtrip serialization', () {
      final original = Task(
        id: 'task_abc',
        title: 'Implement OAuth',
        description: 'Detailed description',
        assigneeId: 'user_1',
        priority: TaskPriority.urgent,
        deadline: DateTime(2026, 10, 15, 18, 0, 0),
        status: TaskStatus.inProgress,
        createdAt: DateTime(2026, 10, 8, 9, 30, 0),
      );

      final json = original.toJson();
      final restored = Task.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.description, equals(original.description));
      expect(restored.assigneeId, equals(original.assigneeId));
      expect(restored.priority, equals(original.priority));
      expect(restored.deadline, equals(original.deadline));
      expect(restored.status, equals(original.status));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.isCompleted, isFalse);
    });

    test('TeamMember serialization and initials derivation', () {
      const member = TeamMember(
        id: 'u1',
        name: 'Alex Rivera',
        email: 'alex@example.com',
        role: 'Tech Lead',
        avatarColorHex: '4F46E5',
      );

      expect(member.initials, equals('AR'));

      const singleNameMember = TeamMember(
        id: 'u2',
        name: 'Cher',
        email: 'cher@example.com',
        role: 'Designer',
      );
      expect(singleNameMember.initials, equals('C'));

      final json = member.toJson();
      final restored = TeamMember.fromJson(json);

      expect(restored.id, equals(member.id));
      expect(restored.name, equals(member.name));
      expect(restored.email, equals(member.email));
      expect(restored.role, equals(member.role));
      expect(restored.avatarColorHex, equals(member.avatarColorHex));
    });
  });
}
