import '../models/task.dart';
import '../models/team_member.dart';

/// Provides initial realistic sample data for the software engineering team.
class SeedDataService {
  /// Default Team Members
  static List<TeamMember> get sampleMembers => const [
        TeamMember(
          id: 'user_1',
          name: 'Alex Rivera',
          email: 'alex.rivera@teamtracker.dev',
          role: 'Tech Lead / Architect',
          avatarColorHex: '4F46E5', // Indigo
        ),
        TeamMember(
          id: 'user_2',
          name: 'Maya Chen',
          email: 'maya.chen@teamtracker.dev',
          role: 'Frontend Engineer',
          avatarColorHex: '06B6D4', // Cyan
        ),
        TeamMember(
          id: 'user_3',
          name: 'Liam Vance',
          email: 'liam.vance@teamtracker.dev',
          role: 'Backend & Cloud Specialist',
          avatarColorHex: '10B981', // Emerald
        ),
        TeamMember(
          id: 'user_4',
          name: 'Sophia Patel',
          email: 'sophia.patel@teamtracker.dev',
          role: 'QA & Security Engineer',
          avatarColorHex: 'F59E0B', // Amber
        ),
      ];

  /// Generates sample tasks with relative timestamps to always guarantee
  /// realistic SLA distribution (On Track, At Risk, Overdue, and Completed).
  static List<Task> getSampleTasks([DateTime? baseTime]) {
    final now = baseTime ?? DateTime.now();

    return [
      // 1. OVERDUE TASK (Critical Bug)
      Task(
        id: 'task_1',
        title: 'Fix race condition in payment webhook handler',
        description:
            'Concurrent transactions cause duplicate credit logs under peak traffic. Needs immediate mutex or transaction lock fix.',
        assigneeId: 'user_3',
        priority: TaskPriority.urgent,
        deadline: now.subtract(const Duration(hours: 36)), // Overdue by 1.5 days
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 4)),
      ),

      // 2. OVERDUE TASK (Missed QA Review)
      Task(
        id: 'task_2',
        title: 'Security audit on JWT refresh token rotation',
        description:
            'Audit token invalidation upon password reset and verify redis blacklist expiry edge cases.',
        assigneeId: 'user_4',
        priority: TaskPriority.high,
        deadline: now.subtract(const Duration(hours: 14)), // Overdue by 14 hours
        status: TaskStatus.review,
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // 3. AT RISK TASK (Due in 12 hours)
      Task(
        id: 'task_3',
        title: 'Refactor Task Details UI and validation logic',
        description:
            'Implement rich error states, date pickers, and ensure responsive form controls across device sizes.',
        assigneeId: 'user_2',
        priority: TaskPriority.high,
        deadline: now.add(const Duration(hours: 12)), // At Risk (within 24h)
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 2)),
      ),

      // 4. AT RISK TASK (Due in 20 hours)
      Task(
        id: 'task_4',
        title: 'Database migration script for multi-tenant tenancy',
        description:
            'Generate Flyway SQL migration scripts and verify zero-downtime schema evolution in staging environment.',
        assigneeId: 'user_3',
        priority: TaskPriority.medium,
        deadline: now.add(const Duration(hours: 20)), // At Risk (within 24h)
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(days: 1)),
      ),

      // 5. ON TRACK TASK (Due in 4 days)
      Task(
        id: 'task_5',
        title: 'Design interactive SLA metrics dashboard widgets',
        description:
            'Build custom painter or charts displaying team velocity, completion ratios, and SLA compliance gauges.',
        assigneeId: 'user_2',
        priority: TaskPriority.medium,
        deadline: now.add(const Duration(days: 4)), // On Track
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(hours: 18)),
      ),

      // 6. ON TRACK TASK (Due in 7 days)
      Task(
        id: 'task_6',
        title: 'Automate release build pipeline with fastlane',
        description:
            'Configure CI pipeline steps to automatically build signed APKs and submit test builds to internal testers.',
        assigneeId: 'user_1',
        priority: TaskPriority.low,
        deadline: now.add(const Duration(days: 7)), // On Track
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),

      // 7. COMPLETED TASK
      Task(
        id: 'task_7',
        title: 'Initialize repository architecture and core models',
        description:
            'Define folder structure, Task and TeamMember models, SharedPreferences storage, and SLA calculation logic.',
        assigneeId: 'user_1',
        priority: TaskPriority.high,
        deadline: now.add(const Duration(days: 2)),
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // 8. COMPLETED TASK
      Task(
        id: 'task_8',
        title: 'Implement unit tests for SLA calculation engine',
        description:
            'Verify all SLA state branches: onTrack, atRisk, overdue, completed, and edge conditions.',
        assigneeId: 'user_4',
        priority: TaskPriority.medium,
        deadline: now.subtract(const Duration(hours: 5)),
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
