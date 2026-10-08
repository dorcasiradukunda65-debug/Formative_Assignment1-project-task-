import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../services/storage_service.dart';
import '../../widgets/app_button.dart';

/// Screen allowing configuration of the SLA "At Risk" warning threshold.
/// This fulfills the Unique Feature requirement (Member 1 logic + Member 3 UI).
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
        title: const Text('SLA Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Informational card
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
          const SizedBox(height: 24),

          Text('At-Risk Warning Horizon', style: AppTypography.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Current threshold: $_thresholdHours hours (${(_thresholdHours / 24).toStringAsFixed(1)} days)',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Slider control
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

          // Quick preset buttons
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

          const SizedBox(height: 32),
          AppButton(
            label: 'Save SLA Policy',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _saveThreshold,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }
}
