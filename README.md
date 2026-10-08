# Mobile SLA Task Tracker 🚀

A mobile project management and Service Level Agreement (SLA) task tracker designed for software engineering teams. Built with Flutter, utilizing Material 3, clean architectural boundaries, and local data persistence via `SharedPreferences`.

---

## 👥 Team Work Split & Architecture

| Member | Focus Area | Git Branch | Core Responsibilities |
|---|---|---|---|
| **Member 1 (You)** | **Foundation, Data & SLA Core** | `feature/data-sla-core` | Project architecture, `Task` & `TeamMember` models, `SharedPreferences` persistence (`StorageService`), SLA calculation rules & engine (`SlaService`), seed data, shared widgets, and unit tests. |
| **Member 2** | Auth & Team Management | `feature/auth-team` | Sign In/User Selection screen, Team Members & Profiles, workload distribution, and user session handling. |
| **Member 3** | Dashboard & Task List | `feature/dashboard-tasklist` | Project Dashboard (health ring/charts, SLA metrics), Task List screen with filtering/search, and bottom navigation shell. |
| **Member 4** | Task Details & Form | `feature/task-details-form` | Create/Edit Task screen with rich validation, date/time pickers, Task Details view, and confirmation dialogs. |

---

## ⏱️ SLA Logic Engine & Business Rules

Each task is evaluated based on its completion state and deadline against the current timestamp:

1. **Completed (`SlaStatus.completed` - Blue/Indigo):**
   - *Rule:* If `task.status == TaskStatus.completed`, the task is marked **Completed** regardless of its deadline.
2. **Overdue (`SlaStatus.overdue` - Crimson Red):**
   - *Rule:* If the task is incomplete and `task.deadline.isBefore(now)`, it is flagged as **Overdue**.
3. **At Risk (`SlaStatus.atRisk` - Amber Orange):**
   - *Rule:* If the task is incomplete, its deadline is still in the future, but the remaining duration is less than or equal to the warning horizon:
     $$\text{deadline} - \text{now} \le \text{Threshold Hours}$$
     *(Default horizon is 24 hours).*
4. **On Track (`SlaStatus.onTrack` - Emerald Green):**
   - *Rule:* If the task is incomplete and the remaining duration strictly exceeds the warning threshold:
     $$\text{deadline} - \text{now} > \text{Threshold Hours}$$

### 🌟 Unique Feature: Configurable "At-Risk" Warning Horizon
Teams have differing sprint cadences and risk tolerances. This project implements a **dynamically configurable SLA warning policy** stored in `SharedPreferences`:
- Users can adjust the warning horizon from **6 hours (strict/hotfix mode)** up to **96 hours (cautious/enterprise mode)** via the in-app slider or `SlaSettingsScreen`.
- When the threshold is changed, the UI immediately recomputes all task statuses in real-time using `setState()`.
- Implemented by **Member 1 (logic & persistence)** + **Member 3 (UI integration)**.

---

## 🗄️ Persistence Layer (`StorageService`)

Local data persistence is powered by `SharedPreferences` without requiring an external backend:
- **`getTasks()`**: Loads and deserializes all tasks from JSON storage.
- **`saveTask(Task task)`**: Inserts or updates an existing task.
- **`deleteTask(String id)`**: Removes a task by unique identifier.
- **`getMembers()` & `saveMember(TeamMember member)`**: Manages team member profiles.
- **`getAtRiskThresholdHours()` & `setAtRiskThresholdHours(int hours)`**: Persists the SLA policy.
- **`getCurrentUserId()` & `setCurrentUserId(String? id)`**: Persists the active session user.
- **`seedInitialDataIfEmpty()` & `resetToSampleData()`**: Auto-populates 4 realistic software developers and 8 sample tasks spanning all 4 SLA statuses on first run or on demand.

---

## 📂 Project Structure

```text
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # Unified brand & SLA status color palette
│   │   ├── app_routes.dart        # Named route definitions for all 6 team screens
│   │   └── app_typography.dart    # Hierarchy typography scales
│   └── theme/
│       └── app_theme.dart         # Material 3 light & dark theme configs
├── models/
│   ├── sla_status.dart            # SLA enum with styling & display helpers
│   ├── task.dart                  # Task, TaskPriority, TaskStatus with JSON serialization
│   └── team_member.dart           # TeamMember model with initials and serialization
├── services/
│   ├── seed_data_service.dart     # Sample data with realistic software tasks
│   ├── sla_service.dart           # Core SLA business logic, countdowns & health metrics
│   └── storage_service.dart       # SharedPreferences persistence layer
├── widgets/
│   ├── app_button.dart            # Standardized action buttons (primary, outline, danger)
│   ├── app_text_field.dart        # Form input field with validation decoration
│   ├── member_avatar.dart         # Circle avatar with initials and dynamic color
│   ├── priority_badge.dart        # Chip indicating task priority (Urgent, High, etc.)
│   ├── sla_badge.dart             # Status chip with icons and color coding
│   └── status_badge.dart          # Chip indicating workflow step (To Do, In Progress, etc.)
├── screens/
│   ├── shell/
│   │   └── foundation_overview_screen.dart # Interactive Live Explorer for Member 1 demo
│   ├── auth/
│   │   └── sign_in_screen.dart             # Screen 1 shell (Member 2)
│   ├── dashboard/
│   │   └── dashboard_screen.dart           # Screen 2 shell (Member 3)
│   ├── tasks/
│   │   ├── task_list_screen.dart           # Screen 3 shell (Member 3)
│   │   ├── task_details_screen.dart         # Screen 4 shell (Member 4)
│   │   └── create_edit_task_screen.dart    # Screen 5 shell (Member 4)
│   ├── team/
│   │   └── team_screen.dart                # Screen 6 shell (Member 2)
│   └── settings/
│       └── sla_settings_screen.dart        # Unique feature settings screen
└── main.dart
```

---

## 🧪 Running Automated Tests

A comprehensive unit test suite validates SLA business logic and data serialization:

```bash
flutter test
```

### Test Suite Highlights:
- **`test/sla_service_test.dart`**: Tests all 4 SLA rules, edge boundaries, deadline shifts, live threshold recalculation, breakdown counts, and project health scores.
- **`test/models_and_storage_test.dart`**: Validates JSON round-trip serialization and initials extraction.

---

## 🎬 Member 1 Demo Guide (For the 10–15 Min Recorded Video)

When speaking during your section of the demo video:
1. **Explain the Interface Contract:** Point out the shared models (`Task`, `TeamMember`), enums (`SlaStatus`, `TaskPriority`, `TaskStatus`), and single `StorageService`.
2. **Demonstrate the SLA Rules Live:**
   - Show how tasks are classified: Green for On Track, Orange for At Risk, Red for Overdue, Blue for Completed.
   - Click **"Complete"** on an overdue task: observe how the SLA badge transitions immediately to **Completed**.
   - Use the **"-12h / +12h"** deadline nudge buttons to show live transitions between On Track, At Risk, and Overdue.
3. **Demonstrate the Unique Feature (Configurable SLA Threshold):**
   - Drag the warning horizon slider from 24h to 48h.
   - Point out how tasks that were previously "On Track" dynamically flip to "At Risk" because they now fall within the enlarged warning window.
4. **Demonstrate Persistence:**
   - Click **"+ Quick Task"** to add a task.
   - Click **"Test Restart / Reload"** (or restart the app in the emulator) to prove data is saved and restored from `SharedPreferences`.
5. **Show Code & Tests:**
   - Open `lib/services/sla_service.dart` and `test/sla_service_test.dart` and run `flutter test` live in the terminal to showcase automated verification.
