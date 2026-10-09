import '../models/task.dart';
import '../models/team_member.dart';

/// Provides initial realistic sample data matching the reference UI exactly.
class SeedDataService {
  /// Default Team Members matching the UI wireframe
  static List<TeamMember> get sampleMembers => const [
        TeamMember(
          id: 'user_1',
          name: 'John Doe',
          email: 'john.doe@example.com',
          role: 'Project Manager',
          avatarColorHex: '2563EB', // Blue
        ),
        TeamMember(
          id: 'user_2',
          name: 'Sarah Lee',
          email: 'sarah.lee@example.com',
          role: 'UI/UX Designer',
          avatarColorHex: '10B981', // Green
        ),
        TeamMember(
          id: 'user_3',
          name: 'Michael Kim',
          email: 'michael.kim@example.com',
          role: 'Mobile Developer',
          avatarColorHex: '7C3AED', // Purple
        ),
        TeamMember(
          id: 'user_4',
          name: 'Emily Wong',
          email: 'emily.wong@example.com',
          role: 'QA Tester',
          avatarColorHex: '1E3A8A', // Dark Blue
        ),
        TeamMember(
          id: 'user_5',
          name: 'David Liu',
          email: 'david.liu@example.com',
          role: 'Documentation',
          avatarColorHex: '0D9488', // Teal
        ),
      ];

  /// Generates 12 sample tasks with relative timestamps to match the
  /// Dashboard distribution: 5 On Track, 3 At Risk, 2 Overdue, 2 Completed.
  static List<Task> getSampleTasks([DateTime? baseTime]) {
    final now = baseTime ?? DateTime.now();

    return [
      // --- 5 ON TRACK TASKS ---
      Task(
        id: 'task_1',
        title: 'Design Login Screen',
        description: 'Create a clean and modern login screen for the application.',
        category: 'UI/UX Design',
        assigneeId: 'user_2', // Sarah Lee
        priority: TaskPriority.high,
        deadline: now.add(const Duration(days: 3)), // On Track
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'task_4',
        title: 'Test Application',
        description: 'Perform end-to-end testing of the core user flows.',
        category: 'Quality Assurance',
        assigneeId: 'user_4', // Emily Wong
        priority: TaskPriority.medium,
        deadline: now.add(const Duration(days: 7)), // On Track
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'task_5',
        title: 'Prepare Demo',
        description: 'Create slides and script for the final project presentation.',
        category: 'Documentation',
        assigneeId: 'user_5', // David Liu
        priority: TaskPriority.low,
        deadline: now.add(const Duration(days: 10)), // On Track
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(hours: 12)),
      ),
      Task(
        id: 'task_6',
        title: 'Setup CI/CD Pipeline',
        description: 'Configure GitHub Actions for automated testing and deployment.',
        category: 'DevOps',
        assigneeId: 'user_1', // John Doe
        priority: TaskPriority.high,
        deadline: now.add(const Duration(days: 4)), // On Track
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: 'task_7',
        title: 'Write API Documentation',
        description: 'Document all REST endpoints using Swagger/OpenAPI.',
        category: 'Documentation',
        assigneeId: 'user_5', // David Liu
        priority: TaskPriority.medium,
        deadline: now.add(const Duration(days: 5)), // On Track
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 3)),
      ),

      // --- 3 AT RISK TASKS ---
      Task(
        id: 'task_2',
        title: 'Implement Local Storage',
        description: 'Integrate SharedPreferences to persist task data locally.',
        category: 'Mobile Development',
        assigneeId: 'user_3', // Michael Kim
        priority: TaskPriority.urgent,
        deadline: now.add(const Duration(hours: 18)), // At Risk (within 24h)
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: 'task_8',
        title: 'Fix Navigation Bug',
        description: 'Resolve issue where back button crashes the app on the Dashboard.',
        category: 'Bug Fix',
        assigneeId: 'user_3', // Michael Kim
        priority: TaskPriority.high,
        deadline: now.add(const Duration(hours: 12)), // At Risk
        status: TaskStatus.todo,
        createdAt: now.subtract(const Duration(hours: 48)),
      ),
      Task(
        id: 'task_9',
        title: 'Update Dependencies',
        description: 'Upgrade Flutter packages to their latest compatible versions.',
        category: 'Maintenance',
        assigneeId: 'user_1', // John Doe
        priority: TaskPriority.low,
        deadline: now.add(const Duration(hours: 22)), // At Risk
        status: TaskStatus.review,
        createdAt: now.subtract(const Duration(days: 5)),
      ),

      // --- 2 OVERDUE TASKS ---
      Task(
        id: 'task_3',
        title: 'Create Task Model',
        description: 'Define the Task data structure and JSON serialization methods.',
        category: 'Backend (Local)',
        assigneeId: 'user_1', // John Doe
        priority: TaskPriority.high,
        deadline: now.subtract(const Duration(days: 1)), // Overdue
        status: TaskStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Task(
        id: 'task_10',
        title: 'Review PR #42',
        description: 'Review the pull request for the new authentication flow.',
        category: 'Code Review',
        assigneeId: 'user_2', // Sarah Lee
        priority: TaskPriority.medium,
        deadline: now.subtract(const Duration(hours: 5)), // Overdue
        status: TaskStatus.review,
        createdAt: now.subtract(const Duration(days: 2)),
      ),

      // --- 2 COMPLETED TASKS ---
      Task(
        id: 'task_11',
        title: 'Initialize Repository',
        description: 'Set up the initial Flutter project structure on GitHub.',
        category: 'Project Setup',
        assigneeId: 'user_1', // John Doe
        priority: TaskPriority.urgent,
        deadline: now.subtract(const Duration(days: 5)), // Doesn't matter, it's completed
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      Task(
        id: 'task_12',
        title: 'Design Dashboard Mockups',
        description: 'Create high-fidelity Figma mockups for the main dashboard.',
        category: 'UI/UX Design',
        assigneeId: 'user_2', // Sarah Lee
        priority: TaskPriority.high,
        deadline: now.subtract(const Duration(days: 2)),
        status: TaskStatus.completed,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }
}
