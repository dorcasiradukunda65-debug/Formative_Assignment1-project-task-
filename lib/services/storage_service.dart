import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/team_member.dart';
import 'seed_data_service.dart';
import 'sla_service.dart';

/// Single persistent storage service using SharedPreferences.
/// Adheres strictly to the interface contract agreed by the team:
/// - getTasks(), saveTask(), deleteTask()
/// - getMembers(), saveMember()
/// - Session & threshold management
class StorageService {
  static const String _keyTasks = 'sla_tracker_tasks_v1';
  static const String _keyMembers = 'sla_tracker_members_v1';
  static const String _keyActiveUserId = 'sla_tracker_active_user_id';
  static const String _keyAtRiskThreshold = 'sla_tracker_at_risk_threshold_hours';
  static const String _keyHasSeeded = 'sla_tracker_has_seeded_initial_data';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Factory helper to initialize StorageService with SharedPreferences instance.
  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    await service.seedInitialDataIfEmpty();
    return service;
  }

  // ==========================================
  // TASK STORAGE METHODS
  // ==========================================

  /// Retrieves all tasks from local persistent storage.
  Future<List<Task>> getTasks() async {
    final jsonStringList = _prefs.getStringList(_keyTasks);
    if (jsonStringList == null || jsonStringList.isEmpty) {
      return [];
    }

    try {
      return jsonStringList.map((raw) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return Task.fromJson(decoded);
      }).toList();
    } catch (e) {
      // In case of corrupt stored data, fail gracefully
      return [];
    }
  }

  /// Inserts a new task or updates an existing task matching [task.id].
  Future<void> saveTask(Task task) async {
    final currentTasks = await getTasks();
    final existingIndex = currentTasks.indexWhere((t) => t.id == task.id);

    if (existingIndex >= 0) {
      currentTasks[existingIndex] = task;
    } else {
      currentTasks.add(task);
    }

    await _persistTasks(currentTasks);
  }

  /// Deletes a task by its ID.
  Future<void> deleteTask(String id) async {
    final currentTasks = await getTasks();
    currentTasks.removeWhere((t) => t.id == id);
    await _persistTasks(currentTasks);
  }

  /// Looks up a single task by its ID.
  Future<Task?> getTaskById(String id) async {
    final currentTasks = await getTasks();
    try {
      return currentTasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Internal helper to write task list to SharedPreferences.
  Future<void> _persistTasks(List<Task> tasks) async {
    final stringList = tasks.map((t) => jsonEncode(t.toJson())).toList();
    await _prefs.setStringList(_keyTasks, stringList);
  }

  // ==========================================
  // TEAM MEMBER STORAGE METHODS
  // ==========================================

  /// Retrieves all team members from local persistent storage.
  Future<List<TeamMember>> getMembers() async {
    final jsonStringList = _prefs.getStringList(_keyMembers);
    if (jsonStringList == null || jsonStringList.isEmpty) {
      return [];
    }

    try {
      return jsonStringList.map((raw) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return TeamMember.fromJson(decoded);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  /// Inserts or updates a team member.
  Future<void> saveMember(TeamMember member) async {
    final currentMembers = await getMembers();
    final existingIndex = currentMembers.indexWhere((m) => m.id == member.id);

    if (existingIndex >= 0) {
      currentMembers[existingIndex] = member;
    } else {
      currentMembers.add(member);
    }

    await _persistMembers(currentMembers);
  }

  /// Deletes a team member by ID.
  Future<void> deleteMember(String id) async {
    final currentMembers = await getMembers();
    currentMembers.removeWhere((m) => m.id == id);
    await _persistMembers(currentMembers);
  }

  /// Finds a member by ID.
  Future<TeamMember?> getMemberById(String id) async {
    final currentMembers = await getMembers();
    try {
      return currentMembers.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistMembers(List<TeamMember> members) async {
    final stringList = members.map((m) => jsonEncode(m.toJson())).toList();
    await _prefs.setStringList(_keyMembers, stringList);
  }

  // ==========================================
  // SESSION & ACTIVE USER (For Member 2 Auth)
  // ==========================================

  /// Gets the currently selected user ID for the session.
  String? getCurrentUserId() {
    return _prefs.getString(_keyActiveUserId);
  }

  /// Sets or clears the active user ID for the session.
  Future<void> setCurrentUserId(String? userId) async {
    if (userId == null) {
      await _prefs.remove(_keyActiveUserId);
    } else {
      await _prefs.setString(_keyActiveUserId, userId);
    }
  }

  // ==========================================
  // CONFIGURABLE SLA THRESHOLD (Unique Feature)
  // ==========================================

  /// Retrieves the configurable At Risk warning threshold in hours.
  /// Defaults to 24 hours.
  int getAtRiskThresholdHours() {
    return _prefs.getInt(_keyAtRiskThreshold) ??
        SlaService.defaultAtRiskThresholdHours;
  }

  /// Saves an updated At Risk warning threshold in hours.
  Future<void> setAtRiskThresholdHours(int hours) async {
    await _prefs.setInt(_keyAtRiskThreshold, hours);
  }

  // ==========================================
  // SEED & RESET DATA
  // ==========================================

  /// Seeds realistic initial data if storage is empty on first launch.
  Future<void> seedInitialDataIfEmpty() async {
    final hasSeeded = _prefs.getBool(_keyHasSeeded) ?? false;
    final existingTasks = await getTasks();

    if (!hasSeeded || existingTasks.isEmpty) {
      await resetToSampleData();
      await _prefs.setBool(_keyHasSeeded, true);
    }
  }

  /// Re-populates storage with fresh sample tasks and team members.
  /// Invaluable for testing and live video demos.
  Future<void> resetToSampleData() async {
    final sampleMembers = SeedDataService.sampleMembers;
    final sampleTasks = SeedDataService.getSampleTasks();

    await _persistMembers(sampleMembers);
    await _persistTasks(sampleTasks);
    await setAtRiskThresholdHours(SlaService.defaultAtRiskThresholdHours);
    if (sampleMembers.isNotEmpty) {
      await setCurrentUserId(sampleMembers.first.id);
    }
  }

  /// Clears all stored data (useful for demonstration testing).
  Future<void> clearAll() async {
    await _prefs.remove(_keyTasks);
    await _prefs.remove(_keyMembers);
    await _prefs.remove(_keyActiveUserId);
    await _prefs.remove(_keyAtRiskThreshold);
    await _prefs.remove(_keyHasSeeded);
  }
}
