import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/constants/app_typography.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';

class SlaSettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SlaSettingsScreen({super.key, required this.storageService});

  @override
  State<SlaSettingsScreen> createState() => _SlaSettingsScreenState();
}

class _SlaSettingsScreenState extends State<SlaSettingsScreen> {
  late int _thresholdHours;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _thresholdHours = widget.storageService.getAtRiskThresholdHours();
  }

  Future<void> _saveThreshold() async {
    setState(() => _isSaving = true);
    await widget.storageService.setAtRiskThresholdHours(_thresholdHours);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SLA warning threshold updated to $_thresholdHours hours!',
          ),
          backgroundColor: AppColors.slaOnTrack,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),

          Text(
            'SLA POLICY CONFIGURATION',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          Card(
            color: AppColors.primaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SLA Threshold Business Rule',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tasks whose deadline is less than the specified hours away will automatically be tagged with the "At Risk" SLA warning.',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text('At-Risk Warning Horizon', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Current threshold: $_thresholdHours hours (${(_thresholdHours / 24).toStringAsFixed(1)} days)',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 12),

          Slider(
            value: _thresholdHours.toDouble(),
            min: 6,
            max: 96,
            divisions: 15,
            label: '$_thresholdHours hours',
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              setState(() {
                _thresholdHours = val.round();
              });
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [12, 24, 48, 72].map((hours) {
              final isSelected = _thresholdHours == hours;
              return ChoiceChip(
                label: Text('${hours}h'),
                selected: isSelected,
                selectedColor: AppColors.primaryLight,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _thresholdHours = hours);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          AppButton(
            label: 'Save SLA Policy',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _saveThreshold,
            isFullWidth: true,
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'SYSTEM & TOOLS',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.analytics_outlined, color: AppColors.primary),
            title: const Text('SLA Foundation Explorer'),
            subtitle: const Text('Inspect underlying engine, algorithms & data logs'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.foundationExplorer);
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About SLA Task Tracker'),
            subtitle: const Text('Version 1.0.0 • Mobile Architecture'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SLA Task Tracker',
                applicationVersion: 'v1.0.0',
                applicationIcon: const Icon(Icons.task_alt_rounded, size: 40, color: AppColors.primary),
                children: [
                  const Text('Built collaboratively with Flutter & Material 3.'),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log Out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      child: const Text('Cancel'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                    TextButton(
                      child: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.signIn,
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary,
              child: Text(
                'M3',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Project Lead / Admin', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('admin@slatracker.app', style: AppTypography.bodySmall),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Active',
                style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}