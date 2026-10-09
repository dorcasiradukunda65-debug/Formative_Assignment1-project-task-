/// Standardized named route definitions across all 4 team members.
class AppRoutes {
  /// Screen 1: Sign In / User Selection (Member 2)
  static const String signIn = '/sign-in';

  /// Screen 2: Project Dashboard (Member 3)
  static const String dashboard = '/dashboard';

  /// Screen 3: Task List (Member 3)
  static const String taskList = '/tasks';

  /// Screen 4: Task Details (Member 4)
  static const String taskDetails = '/task-details';

  /// Screen 5: Create / Edit Task (Member 4)
  static const String taskForm = '/task-form';

  /// Screen 6: Team Members / Profile (Member 2)
  static const String team = '/team';
  static const String memberProfile = '/member-profile';

  /// Unique Feature: Configurable SLA Threshold Settings (Member 1 logic + Member 3 UI)
  static const String slaSettings = '/sla-settings';

  /// Foundation Showcase & Core Inspector (Member 1 Live Verification)
  static const String foundationExplorer = '/foundation-explorer';

  /// Initial route for the application
  static const String initial = foundationExplorer;
}
