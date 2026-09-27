import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/goal_model.dart';

class MacroProgressRing extends StatelessWidget {
  final DailyAnalyticsModel? analytics;
  final VoidCallback onEditGoals;

  const MacroProgressRing({
    super.key,
    required this.analytics,
    required this.onEditGoals,
  });

  @override
  Widget build(BuildContext context) {
    final goal = analytics?.goal;
    final consumedCals = analytics?.consumedCalories ?? 0.0;
    final targetCals = goal?.calorieTarget ?? 2000.0;
    final remainingCals = (targetCals - consumedCals).clamp(0.0, double.infinity);
    final calProgress = (analytics?.calorieProgress ?? 0.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Target & Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: onEditGoals,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: const [
                      Icon(Icons.tune, size: 16, color: AppTheme.primaryGreen),
                      SizedBox(width: 4),
                      Text(
                        'Edit Goals',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Circular progress ring and remaining text
          Row(
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 90,
                      height: 90,
                      child: CircularProgressIndicator(
                        value: calProgress,
                        strokeWidth: 8,
                        backgroundColor: const Color(0xFFF3F4F6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          calProgress >= 1.0 ? Colors.green.shade600 : AppTheme.calorieColor,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(calProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${consumedCals.toStringAsFixed(0)} / ${targetCals.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${remainingCals.toStringAsFixed(0)} kcal remaining',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),

          // Linear progress bars for macros
          _buildMacroProgressBar(
            label: 'Protein',
            consumed: analytics?.consumedProtein ?? 0.0,
            target: goal?.proteinTarget ?? 120.0,
            progress: analytics?.proteinProgress ?? 0.0,
            color: AppTheme.proteinColor,
          ),
          const SizedBox(height: 12),
          _buildMacroProgressBar(
            label: 'Carbs',
            consumed: analytics?.consumedCarbohydrates ?? 0.0,
            target: goal?.carbohydratesTarget ?? 250.0,
            progress: analytics?.carbohydratesProgress ?? 0.0,
            color: AppTheme.carbsColor,
          ),
          const SizedBox(height: 12),
          _buildMacroProgressBar(
            label: 'Fat',
            consumed: analytics?.consumedFat ?? 0.0,
            target: goal?.fatTarget ?? 65.0,
            progress: analytics?.fatProgress ?? 0.0,
            color: AppTheme.fatColor,
          ),
          const SizedBox(height: 12),
          _buildMacroProgressBar(
            label: 'Fiber',
            consumed: analytics?.consumedFiber ?? 0.0,
            target: goal?.fiberTarget ?? 30.0,
            progress: analytics?.fiberProgress ?? 0.0,
            color: AppTheme.fiberColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMacroProgressBar({
    required String label,
    required double consumed,
    required double target,
    required double progress,
    required Color color,
  }) {
    final clampedProg = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              '${consumed.toStringAsFixed(1)} / ${target.toStringAsFixed(0)}g (${(progress * 100).toInt()}%)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clampedProg,
            minHeight: 6,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

