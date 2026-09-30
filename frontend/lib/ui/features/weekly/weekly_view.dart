import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/weekly_model.dart';
import 'weekly_view_model.dart';

class WeeklyView extends StatefulWidget {
  const WeeklyView({super.key});

  @override
  State<WeeklyView> createState() => _WeeklyViewState();
}

class _WeeklyViewState extends State<WeeklyView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeeklyViewModel>().loadReport();
    });
  }

  String _formatDateRange(String startStr, String endStr, int offset) {
    try {
      final start = DateTime.parse(startStr);
      final end = DateTime.parse(endStr);
      final f = DateFormat('MMM d');
      final yearF = DateFormat(', yyyy');
      final range = '${f.format(start)} – ${f.format(end)}${yearF.format(end)}';
      if (offset == 0) return '$range (This Week)';
      if (offset == -1) return '$range (Last Week)';
      return range;
    } catch (_) {
      return '$startStr to $endStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeeklyViewModel>();
    final report = vm.report;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Nutrition Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: vm.isLoading ? null : () => vm.loadReport(),
          ),
        ],
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Failed to load weekly report',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => vm.loadReport(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Week-switcher navigation header
                      _buildWeekSwitcher(context, vm, report),
                      const SizedBox(height: 20),

                      // Prior-week comparison badges
                      _buildPriorWeekBadges(report.priorWeekComparison),
                      const SizedBox(height: 20),

                      // Summary stat cards (Averages & Weight change)
                      _buildSummaryStats(report.dailyAverages, report.weightChange),
                      const SizedBox(height: 24),

                      // Daily Calorie vs Target Bar Chart
                      _buildCalorieBarChart(report.dailyPoints),
                      const SizedBox(height: 24),

                      // Best Day & Worst Day cards
                      _buildBestWorstDayCards(report.bestDay, report.worstDay),
                      const SizedBox(height: 24),

                      // Nutrient Compliance Checklist
                      _buildNutrientCompliance(report.nutrientHits),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildWeekSwitcher(
    BuildContext context,
    WeeklyViewModel vm,
    WeeklyReportResponseModel report,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous Week',
            onPressed: () => vm.previousWeek(),
          ),
          Expanded(
            child: Text(
              _formatDateRange(report.startDate, report.endDate, vm.weekOffset),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next Week',
            onPressed: vm.canGoNext ? () => vm.nextWeek() : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPriorWeekBadges(PriorWeekComparisonModel prior) {
    final calPct = prior.caloriesPctChange;
    final protPct = prior.proteinPctChange;

    return Row(
      children: [
        if (calPct != null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: calPct <= 5 && calPct >= -5
                    ? const Color(0xFFECFDF5)
                    : (calPct > 5 ? const Color(0xFFFFF7ED) : const Color(0xFFEFF6FF)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: calPct <= 5 && calPct >= -5
                      ? const Color(0xFFA7F3D0)
                      : (calPct > 5 ? const Color(0xFFFED7AA) : const Color(0xFFBFDBFE)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    calPct >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: calPct >= 0 ? const Color(0xFFC2410C) : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${calPct >= 0 ? "+" : ""}${calPct.toStringAsFixed(1)}% calories vs prior week',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (protPct != null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: protPct >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: protPct >= 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    protPct >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 16,
                    color: protPct >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${protPct >= 0 ? "+" : ""}${protPct.toStringAsFixed(1)}% protein vs prior week',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (calPct == null && protPct == null) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    'No prior week data for comparison',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryStats(DailyAveragesModel avgs, WeightChangeModel? wtChange) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Avg Calories',
            value: '${avgs.calories.toInt()}',
            unit: 'kcal/day',
            icon: Icons.local_fire_department,
            color: AppTheme.calorieColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Avg Protein',
            value: avgs.protein.toStringAsFixed(1),
            unit: 'g/day',
            icon: Icons.fitness_center,
            color: AppTheme.proteinColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Weight Change',
            value: wtChange != null
                ? '${wtChange.changeKg >= 0 ? "+" : ""}${wtChange.changeKg.toStringAsFixed(1)}'
                : '–',
            unit: wtChange != null ? 'kg this week' : 'No logs',
            icon: Icons.monitor_weight_outlined,
            color: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieBarChart(List<DailyBarPointModel> points) {
    if (points.isEmpty) return const SizedBox.shrink();

    final maxVal = points.fold<double>(
      2500.0,
      (max, p) => p.calories > max ? p.calories : max,
    );

    final targetVal = points.first.calorieTarget;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Calories vs Target',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Target Hit', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  const SizedBox(width: 10),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Other', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${targetVal.toInt()} kcal/day (±10% range: ${(targetVal * 0.9).toInt()}–${(targetVal * 1.1).toInt()} kcal)',
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),

          // 7 Bars
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: points.map((p) {
                final barRatio = (p.calories / maxVal).clamp(0.0, 1.0);
                final barHeight = (barRatio * 110.0).clamp(4.0, 110.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      p.calories > 0 ? '${p.calories.toInt()}' : '–',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: p.targetHit ? AppTheme.primaryGreen : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: p.targetHit
                            ? AppTheme.primaryGreen
                            : (p.calories > 0 ? const Color(0xFFD1D5DB) : const Color(0xFFF3F4F6)),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.dayName,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestWorstDayCards(DaySummaryModel best, DaySummaryModel worst) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events, size: 18, color: Color(0xFF059669)),
                    SizedBox(width: 6),
                    Text(
                      'Best Day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  best.dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                Text(
                  '${best.score} pts • ${best.calories.toInt()} kcal',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights, size: 18, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Text(
                      'Needs Focus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  worst.dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                Text(
                  '${worst.score} pts • ${worst.calories.toInt()} kcal',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientCompliance(NutrientHitsModel hits) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrient Compliance Checklist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Number of days each target was satisfied (out of 7 days)',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildComplianceRow('Calories', hits.calories, AppTheme.calorieColor, Icons.local_fire_department),
          const SizedBox(height: 10),
          _buildComplianceRow('Protein', hits.protein, AppTheme.proteinColor, Icons.fitness_center),
          const SizedBox(height: 10),
          _buildComplianceRow('Carbohydrates', hits.carbohydrates, AppTheme.carbsColor, Icons.grain),
          const SizedBox(height: 10),
          _buildComplianceRow('Fat', hits.fat, AppTheme.fatColor, Icons.opacity),
          const SizedBox(height: 10),
          _buildComplianceRow('Fiber', hits.fiber, AppTheme.fiberColor, Icons.eco),
          const SizedBox(height: 10),
          _buildComplianceRow('Hydration', hits.water, Colors.blue.shade600, Icons.water_drop),
        ],
      ),
    );
  }

  Widget _buildComplianceRow(String label, int daysHit, Color color, IconData icon) {
    final ratio = (daysHit / 7.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
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
              'Hit $daysHit / 7 days',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: daysHit >= 5 ? AppTheme.primaryGreen : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFF3F4F6),
            valueColor: AlwaysStoppedAnimation<Color>(
              daysHit >= 5 ? color : color.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
