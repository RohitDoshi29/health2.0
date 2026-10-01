import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../features/streak/streak_view_model.dart';

class DailyScoreCard extends StatelessWidget {
  const DailyScoreCard({super.key});

  void _showBreakdownSheet(BuildContext context, StreakViewModel vm) {
    final breakdown = vm.breakdown;
    final score = vm.todayScore;
    final streak = vm.currentStreak;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: score >= 60 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          score >= 60 ? '🌟' : '🎯',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Daily Score Breakdown',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '$score / 100 points today',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: score >= 60 ? AppTheme.primaryGreen : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: score >= 60 ? const Color(0xFFECFDF5) : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: score >= 60 ? const Color(0xFFA7F3D0) : const Color(0xFFFED7AA),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      score >= 60 ? '🔥' : '💡',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        score >= 60
                            ? 'Streak active! You have a $streak-day healthy habit streak.'
                            : 'Reach 60 points today to extend your streak (currently $streak days).',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: score >= 60 ? const Color(0xFF065F46) : const Color(0xFF9A3412),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (breakdown != null) ...[
                _buildBreakdownRow(
                  title: 'Calories (40 pts)',
                  rule: breakdown.calories.description,
                  points: breakdown.calories.points,
                  maxPoints: breakdown.calories.maxPoints,
                  achieved: breakdown.calories.achieved,
                  icon: Icons.local_fire_department,
                  color: AppTheme.calorieColor,
                ),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                  title: 'Protein (30 pts)',
                  rule: breakdown.protein.description,
                  points: breakdown.protein.points,
                  maxPoints: breakdown.protein.maxPoints,
                  achieved: breakdown.protein.achieved,
                  icon: Icons.fitness_center,
                  color: AppTheme.proteinColor,
                ),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                  title: 'Fiber (15 pts)',
                  rule: breakdown.fiber.description,
                  points: breakdown.fiber.points,
                  maxPoints: breakdown.fiber.maxPoints,
                  achieved: breakdown.fiber.achieved,
                  icon: Icons.eco,
                  color: AppTheme.fiberColor,
                ),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                  title: 'Hydration (15 pts)',
                  rule: breakdown.water.description,
                  points: breakdown.water.points,
                  maxPoints: breakdown.water.maxPoints,
                  achieved: breakdown.water.achieved,
                  icon: Icons.water_drop,
                  color: Colors.blue.shade600,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(modalCtx),
                  child: const Text('Got It'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownRow({
    required String title,
    required String rule,
    required double points,
    required double maxPoints,
    required bool achieved,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: achieved ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: achieved ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        achieved ? '+${points.toInt()} pts' : '0 / ${maxPoints.toInt()} pts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: achieved ? const Color(0xFF059669) : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  rule,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StreakViewModel?>(context);
    if (vm == null) return const SizedBox.shrink();

    final score = vm.todayScore;
    final breakdown = vm.breakdown;
    final progress = (score / 100.0).clamp(0.0, 1.0);
    final scoreColor = score >= 60 ? AppTheme.primaryGreen : (score >= 40 ? Colors.amber.shade700 : const Color(0xFFEF4444));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xCC111C17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x2200F59B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showBreakdownSheet(context, vm),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Circular Score Ring
                SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 7,
                          backgroundColor: const Color(0x22FFFFFF),
                          color: scoreColor,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                              height: 1.0,
                            ),
                          ),
                          const Text(
                            '/ 100',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                // Text and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daily Health Score',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondary),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score >= 60
                            ? 'Streak active today! (60+ pts reached)'
                            : 'Earn 60+ points to maintain streak',
                        style: TextStyle(
                          fontSize: 12,
                          color: score >= 60 ? AppTheme.primaryGreen : AppTheme.textSecondary,
                          fontWeight: score >= 60 ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Pills row for targets
                      Row(
                        children: [
                          _buildTargetPill('Cal', breakdown?.calories.achieved == true),
                          const SizedBox(width: 6),
                          _buildTargetPill('Prot', breakdown?.protein.achieved == true),
                          const SizedBox(width: 6),
                          _buildTargetPill('Fiber', breakdown?.fiber.achieved == true),
                          const SizedBox(width: 6),
                          _buildTargetPill('Water', breakdown?.water.achieved == true),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTargetPill(String label, bool achieved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: achieved ? const Color(0x2200F59B) : const Color(0x16FFFFFF),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: achieved ? const Color(0x4400F59B) : const Color(0x1FFFFFFF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achieved ? Icons.check : Icons.remove,
            size: 11,
            color: achieved ? AppTheme.neonEmerald : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: achieved ? AppTheme.neonEmerald : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
