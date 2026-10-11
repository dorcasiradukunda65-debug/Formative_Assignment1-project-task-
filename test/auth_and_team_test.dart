import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sla_tracker/models/sla_status.dart';
import 'package:sla_tracker/models/task.dart';
import 'package:sla_tracker/models/team_member.dart';
import 'package:sla_tracker/screens/auth/sign_in_screen.dart';
import 'package:sla_tracker/screens/team/team_screen.dart';
import 'package:sla_tracker/services/sla_service.dart';
import 'package:sla_tracker/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storageService = StorageService(prefs);
    await storageService.clearAll();
  });

  group('Member 2: Session & Auth Storage Tests', () {
    test('Session active user ID can be saved, read, and cleared', () async {
      expect(storageService.getCurrentUserId(), isNull);

      await storageService.setCurrentUserId('user_test_123');
      expect(storageService.getCurrentUserId(), equals('user_test_123'));

      await storageService.setCurrentUserId(null);
      expect(storageService.getCurrentUserId(), isNull);
    });

    test('Team member CRUD operations persist accurately', () async {
      const member = TeamMember(
        id: 'user_alpha',
        name: 'Grace Hopper',
        email: 'grace@example.com',
        role: 'Chief Architect',
        avatarColorHex: '4F46E5',
      );

      await storageService.saveMember(member);
      var members = await storageService.getMembers();
      expect(members.length, equals(1));
      expect(members.first.name, equals('Grace Hopper'));

      // Update member
      final updated = member.copyWith(role: 'Distinguished Engineer');
      await storageService.saveMember(updated);
      members = await storageService.getMembers();
      expect(members.length, equals(1));
      expect(members.first.role, equals('Distinguished Engineer'));

      // Delete member
      await storageService.deleteMember('user_alpha');
      members = await storageService.getMembers();
      expect(members.isEmpty, isTrue);
    });
  });

  group('Member 2: Workload Calculation Logic Tests', () {
    test('Calculates open vs overdue vs completed workload accurately per member', () async {
      const memberId = 'user_workload_1';
      final now = DateTime.now();

      final tasks = [
        // 1 Open & On Track (deadline in future)
        Task(
          id: 't1',
          title: 'Future feature',
          assigneeId: memberId,
          priority: TaskPriority.medium,
          deadline: now.add(const Duration(days: 4)),
          status: TaskStatus.inProgress,
          createdAt: now,
        ),
        // 2 Open & Overdue (deadline in past)
        Task(
          id: 't2',
          title: 'Past due bugfix',
          assigneeId: memberId,
          priority: TaskPriority.urgent,
          deadline: now.subtract(const Duration(hours: 5)),
          status: TaskStatus.todo,
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        // 3 Completed (not counted in open or overdue)
        Task(
          id: 't3',
          title: 'Finished sprint goal',
          assigneeId: memberId,
          priority: TaskPriority.high,
          deadline: now.subtract(const Duration(days: 1)),
          status: TaskStatus.completed,
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        // Task assigned to someone else
        Task(
          id: 't4',
          title: 'Other person task',
          assigneeId: 'other_user',
          priority: TaskPriority.low,
          deadline: now.subtract(const Duration(hours: 2)),
          status: TaskStatus.todo,
          createdAt: now,
        ),
      ];

      // Workload for memberId:
      final memberTasks = tasks.where((t) => t.assigneeId == memberId).toList();
      final openCount = memberTasks.where((t) => !t.isCompleted).length;
      final overdueCount = memberTasks
          .where((t) => !t.isCompleted && SlaService.getStatus(t, now: now) == SlaStatus.overdue)
          .length;
      final completedCount = memberTasks.where((t) => t.isCompleted).length;

      expect(memberTasks.length, equals(3));
      expect(openCount, equals(2));
      expect(overdueCount, equals(1));
      expect(completedCount, equals(1));
    });
  });

  group('Member 2: Widget Rendering Tests', () {
    testWidgets('SignInScreen renders hero title, form inputs and mode tabs', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await storageService.resetToSampleData();

      await tester.pumpWidget(
        MaterialApp(
          home: SignInScreen(storageService: storageService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Project & SLA Task Tracker'), findsOneWidget);
      expect(find.text('Plan. Track. Deliver Together.'), findsOneWidget);
      expect(find.text('Sign In Form'), findsOneWidget);
      expect(find.text('Pick a User'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Switch to Pick a User tab
      await tester.tap(find.text('Pick a User'));
      await tester.pumpAndSettle();

      expect(find.text('Select Active User'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('TeamScreen renders member roster and workload statistics', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await storageService.resetToSampleData();

      await tester.pumpWidget(
        MaterialApp(
          home: TeamScreen(storageService: storageService),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Team Members'), findsOneWidget);
      expect(find.text('Add Member'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Sarah Lee'), findsOneWidget);

      // Verify search input is available
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
