import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/trend_model.dart';

class NutritionTrendsChart extends StatefulWidget {
  final TrendsAnalyticsModel? trends;
  final int selectedDays;
  final ValueChanged<int> onPeriodChanged;
  final bool isLoading;

  const NutritionTrendsChart({
    super.key,
    required this.trends,
    required this.selectedDays,
    required this.onPeriodChanged,
    this.isLoading = false,
  });

  @override
  State<NutritionTrendsChart> createState() => _NutritionTrendsChartState();
}

class _NutritionTrendsChartState extends State<NutritionTrendsChart> {
  int? _selectedDayIndex;

  String _formatAverage(double? val, String unit) {
    if (val == null || val == 0.0) return '0$unit';
    if (val < 10) return '${val.toStringAsFixed(1)}$unit';
    return '${val.toStringAsFixed(0)}$unit';
  }

  @override
  Widget build(BuildContext context) {
    final trends = widget.trends;
    final points = trends?.dataPoints ?? [];
    final targetCals = trends?.goal.calorieTarget ?? 2000.0;

    double maxCal = targetCals;
    for (final p in points) {
      if (p.calories > maxCal) maxCal = p.calories;
    }
    if (maxCal <= 0) maxCal = 2000.0;
    maxCal = (maxCal * 1.15); // Add 15% headroom for clean chart visualization

    final selectedPoint = (_selectedDayIndex != null &&
            _selectedDayIndex! >= 0 &&
            _selectedDayIndex! < points.length)
        ? points[_selectedDayIndex!]
        : null;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Period Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Nutrition Trends',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildPeriodButton('7 Days', 7),
                    _buildPeriodButton('30 Days', 30),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.isLoading)
            const SizedBox(
              height: 220,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else ...[
            // Period Daily Averages
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAverageItem('Avg Cal', _formatAverage(trends?.averageCalories, ' kcal'), AppTheme.calorieColor),
                  _buildAverageItem('Avg Protein', _formatAverage(trends?.averageProtein, 'g'), AppTheme.proteinColor),
                  _buildAverageItem('Avg Carbs', _formatAverage(trends?.averageCarbohydrates, 'g'), AppTheme.carbsColor),
                  _buildAverageItem('Avg Fat', _formatAverage(trends?.averageFat, 'g'), AppTheme.fatColor),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bar Chart Canvas
            if (points.isNotEmpty)
              SizedBox(
                height: 160,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: points.asMap().entries.map((entry) {
                    final index = entry.key;
                    final point = entry.value;
                    final isSelected = _selectedDayIndex == index;
                    final heightRatio = (point.calories / maxCal).clamp(0.02, 1.0);
                    final isOverTarget = point.calories >= targetCals;

                    final barColor = isSelected
                        ? AppTheme.primaryDark
                        : (isOverTarget
                            ? AppTheme.primaryGreen
                            : (point.calories > 0 ? AppTheme.calorieColor : const Color(0xFFE5E7EB)));

                    final dateParts = point.date.split('-');
                    final label = (dateParts.length >= 3 && widget.selectedDays <= 7)
                        ? '${dateParts[1]}/${dateParts[2]}'
                        : (index % 5 == 0 && dateParts.length >= 3 ? '${dateParts[1]}/${dateParts[2]}' : '');

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          setState(() {
                            _selectedDayIndex = (_selectedDayIndex == index) ? null : index;
                          });
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: FractionallySizedBox(
                                heightFactor: heightRatio,
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: widget.selectedDays <= 7 ? 4 : 1.5),
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(widget.selectedDays <= 7 ? 6 : 3),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primaryDark.withValues(alpha: 0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: widget.selectedDays <= 7 ? 10 : 8,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Target baseline marker
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Target: ${targetCals.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Tap any bar to view day details',
                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),

            // Selected Day Breakdown Callout
            if (selectedPoint != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedPoint.date,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedPoint.mealsCount} meal${selectedPoint.mealsCount == 1 ? "" : "s"} logged',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    Text(
                      '${selectedPoint.calories.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'P: ${selectedPoint.protein.toStringAsFixed(0)}g • C: ${selectedPoint.carbohydrates.toStringAsFixed(0)}g • F: ${selectedPoint.fat.toStringAsFixed(0)}g',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String title, int days) {
    final isSelected = widget.selectedDays == days;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _selectedDayIndex = null;
          });
          widget.onPeriodChanged(days);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAverageItem(String label, String value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }
}

