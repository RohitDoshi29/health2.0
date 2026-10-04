import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/weekly_model.dart';
import '../../core/widgets/glass_card.dart';
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
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Weekly Nutrition Report',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.neonEmerald),
            tooltip: 'Refresh Report',
            onPressed: vm.isLoading ? null : () => vm.loadReport(),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.3,
            colors: [
              Color(0xFF0F241A),
              Color(0xFF080D0B),
            ],
          ),
        ),
        child: vm.isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.neonEmerald,
                ),
              )
            : report == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load weekly report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => vm.loadReport(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.neonEmerald,
                            foregroundColor: const Color(0xFF041A0E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Week-switcher navigation header
                        _buildWeekSwitcher(context, vm, report),
                        const SizedBox(height: 16),

                        // Prior-week comparison badges
                        _buildPriorWeekBadges(report.priorWeekComparison),
                        const SizedBox(height: 16),

                        // Summary stat cards (Averages & Weight change)
                        _buildSummaryStats(report.dailyAverages, report.weightChange),
                        const SizedBox(height: 18),

                        // Daily Calorie vs Target Bar Chart
                        _buildCalorieBarChart(report.dailyPoints),
                        const SizedBox(height: 18),

                        // Best Day & Needs Focus cards
                        _buildBestWorstDayCards(report.bestDay, report.worstDay),
                        const SizedBox(height: 18),

                        // Nutrient Compliance Checklist
                        _buildNutrientCompliance(report.nutrientHits),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildWeekSwitcher(
    BuildContext context,
    WeeklyViewModel vm,
    WeeklyReportResponseModel report,
  ) {
    return GlassCard(
      glowColor: AppTheme.neonEmerald,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.neonEmerald),
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
                letterSpacing: -0.2,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right_rounded,
              color: vm.canGoNext ? AppTheme.neonEmerald : AppTheme.textMuted,
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: calPct <= 5 && calPct >= -5
                    ? const Color(0x2200F59B)
                    : (calPct > 5 ? const Color(0x22FF8A00) : const Color(0x2200B2FF)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: calPct <= 5 && calPct >= -5
                      ? const Color(0x6600F59B)
                      : (calPct > 5 ? const Color(0x66FF8A00) : const Color(0x6600B2FF)),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    calPct >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 16,
                    color: calPct >= 0 ? const Color(0xFFFF9E33) : const Color(0xFF38BDF8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${calPct >= 0 ? "+" : ""}${calPct.toStringAsFixed(1)}% cal vs prior',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: protPct >= 0 ? const Color(0x2200F59B) : const Color(0x22FF4D4D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: protPct >= 0 ? const Color(0x6600F59B) : const Color(0x66FF4D4D),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    protPct >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    size: 16,
                    color: protPct >= 0 ? AppTheme.neonEmerald : const Color(0xFFFF6B6B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${protPct >= 0 ? "+" : ""}${protPct.toStringAsFixed(1)}% prot vs prior',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x18FFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x22FFFFFF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textSecondary),
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
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.calorieColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            title: 'Avg Protein',
            value: avgs.protein.toStringAsFixed(1),
            unit: 'g/day',
            icon: Icons.fitness_center_rounded,
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
            color: AppTheme.fatColor,
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
    return GlassCard(
      glowColor: color,
      padding: const EdgeInsets.all(12),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 5),
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
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 1),
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

    return GlassCard(
      glowColor: AppTheme.neonEmerald,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
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
                  letterSpacing: -0.3,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: AppTheme.neonEmerald,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6600F59B),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Hit', style: TextStyle(fontSize: 11, color: AppTheme.neonEmerald, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 10),
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0x44FFFFFF),
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
                final barHeight = (barRatio * 110.0).clamp(6.0, 110.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      p.calories > 0 ? '${p.calories.toInt()}' : '–',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: p.targetHit ? AppTheme.neonEmerald : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: barHeight,
                      decoration: BoxDecoration(
                        gradient: p.targetHit
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF00F59B),
                                  Color(0xFF00A86B),
                                ],
                              )
                            : (p.calories > 0
                                ? const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0x4400F59B),
                                      Color(0x1800F59B),
                                    ],
                                  )
                                : const LinearGradient(
                                    colors: [
                                      Color(0x11FFFFFF),
                                      Color(0x08FFFFFF),
                                    ],
                                  )),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        border: Border.all(
                          color: p.targetHit
                              ? const Color(0xAA00F59B)
                              : const Color(0x22FFFFFF),
                          width: 1,
                        ),
                        boxShadow: p.targetHit
                            ? [
                                const BoxShadow(
                                  color: Color(0x4400F59B),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.dayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: p.targetHit ? FontWeight.bold : FontWeight.w500,
                        color: p.targetHit ? AppTheme.textPrimary : AppTheme.textSecondary,
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
              color: const Color(0x1800F59B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x5500F59B), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A00F59B),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 18, color: AppTheme.neonEmerald),
                    SizedBox(width: 6),
                    Text(
                      'Best Day',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonEmerald,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  best.dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${best.score} pts • ${best.calories.toInt()} kcal',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6EE7B7), fontWeight: FontWeight.w500),
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
              color: const Color(0x18FF8A00),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x55FF8A00), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1AFF8A00),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, size: 18, color: Color(0xFFFF9E33)),
                    SizedBox(width: 6),
                    Text(
                      'Needs Focus',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFB366),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  worst.dayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${worst.score} pts • ${worst.calories.toInt()} kcal',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFFDBA74), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutrientCompliance(NutrientHitsModel hits) {
    return GlassCard(
      glowColor: AppTheme.neonEmerald,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nutrient Compliance Checklist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Number of days each target was satisfied (out of 7 days)',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          _buildComplianceRow('Calories', hits.calories, AppTheme.calorieColor, Icons.local_fire_department_rounded),
          const SizedBox(height: 12),
          _buildComplianceRow('Protein', hits.protein, AppTheme.proteinColor, Icons.fitness_center_rounded),
          const SizedBox(height: 12),
          _buildComplianceRow('Carbohydrates', hits.carbohydrates, AppTheme.carbsColor, Icons.grain_rounded),
          const SizedBox(height: 12),
          _buildComplianceRow('Fat', hits.fat, AppTheme.fatColor, Icons.opacity_rounded),
          const SizedBox(height: 12),
          _buildComplianceRow('Fiber', hits.fiber, AppTheme.fiberColor, Icons.eco_rounded),
          const SizedBox(height: 12),
          _buildComplianceRow('Hydration', hits.water, AppTheme.waterColor, Icons.water_drop_rounded),
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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
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
                color: daysHit >= 5 ? AppTheme.neonEmerald : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: const Color(0x18FFFFFF),
            valueColor: AlwaysStoppedAnimation<Color>(
              daysHit >= 5 ? color : color.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
