import 'package:flutter/material.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/auth/sign_in_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/navigation/main_navigation_screen.dart';
import 'screens/settings/sla_settings_screen.dart';
import 'screens/shell/foundation_overview_screen.dart';
import 'screens/tasks/create_edit_task_screen.dart';
import 'screens/tasks/task_details_screen.dart';
import 'screens/tasks/task_list_screen.dart';
import 'models/team_member.dart';
import 'screens/team/member_profile_screen.dart';
import 'screens/team/team_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences and auto-seed sample data if first run
  final storageService = await StorageService.init();

  runApp(SlaTrackerApp(storageService: storageService));
}

class SlaTrackerApp extends StatelessWidget {
  final StorageService storageService;

  const SlaTrackerApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SLA Task Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.dashboard,
      routes: {
        '/': (context) => MainNavigationScreen(storageService: storageService),
        AppRoutes.foundationExplorer: (context) =>
            FoundationOverviewScreen(storageService: storageService),
        AppRoutes.signIn: (context) =>
            SignInScreen(storageService: storageService),
        AppRoutes.dashboard: (context) =>
            DashboardScreen(storageService: storageService),
        AppRoutes.taskList: (context) =>
            TaskListScreen(storageService: storageService),
        AppRoutes.taskDetails: (context) =>
            TaskDetailsScreen(storageService: storageService),
        AppRoutes.taskForm: (context) =>
            CreateEditTaskScreen(storageService: storageService),
        AppRoutes.team: (context) =>
            TeamScreen(storageService: storageService),
        AppRoutes.memberProfile: (context) {
          final member =
              ModalRoute.of(context)?.settings.arguments as TeamMember?;
          if (member != null) {
            return MemberProfileScreen(
              storageService: storageService,
              member: member,
            );
          }
          return TeamScreen(storageService: storageService);
        },
        AppRoutes.slaSettings: (context) =>
            SlaSettingsScreen(storageService: storageService),
      },
    );
  }
}
