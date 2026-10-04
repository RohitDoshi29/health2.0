import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../features/water/water_view_model.dart';
import 'glass_card.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({super.key});

  void _showCustomWaterDialog(BuildContext context, WaterViewModel waterVm) {
    final controller = TextEditingController(text: '300');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x4400F0FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.water_drop_rounded, color: Color(0xFF00F0FF)),
            SizedBox(width: 8),
            Text(
              'Log Water Intake',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter amount in milliliters (ml):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Amount (ml)',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                suffixText: 'ml',
                suffixStyle: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.local_drink_rounded, color: Color(0xFF00F0FF)),
                filled: true,
                fillColor: const Color(0xFF16251E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F0FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F0FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: const Color(0xFF041A16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                waterVm.quickLog(val);
              }
            },
            child: const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, WaterViewModel waterVm) {
    final controller = TextEditingController(
      text: waterVm.summary.targetMl.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D1814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x4400F0FF), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.flag_rounded, color: Color(0xFF00F0FF)),
            SizedBox(width: 8),
            Text(
              'Daily Water Target',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your daily hydration goal (ml):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Target (ml)',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                suffixText: 'ml',
                suffixStyle: const TextStyle(color: Color(0xFF00F0FF), fontWeight: FontWeight.bold),
                prefixIcon: const Icon(Icons.flag_outlined, color: Color(0xFF00F0FF)),
                filled: true,
                fillColor: const Color(0xFF16251E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F0FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F0FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: const Color(0xFF041A16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                waterVm.updateGoal(val);
              }
            },
            child: const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final waterVm = context.watch<WaterViewModel>();
    final summary = waterVm.summary;
    final progressRatio = summary.targetMl > 0
        ? (summary.totalMl / summary.targetMl).clamp(0.0, 1.0)
        : 0.0;
    final remainingMl = (summary.targetMl - summary.totalMl).clamp(0.0, double.infinity);

    return GlassCard(
      glowColor: const Color(0xFF00F0FF),
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0x2200F0FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0x4400F0FF)),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: Color(0xFF00F0FF), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hydration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Daily bio-fluid intake tracker',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showEditGoalDialog(context, waterVm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00F0FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x3300F0FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.totalMl.toStringAsFixed(0)} / ${summary.targetMl.toStringAsFixed(0)} ml',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF00F0FF)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress Bar with Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${summary.percentage.toStringAsFixed(0)}% completed',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: summary.percentage >= 100 ? AppTheme.neonEmerald : const Color(0xFF00F0FF),
                    ),
                  ),
                  Text(
                    summary.percentage >= 100
                        ? 'Target reached! 💧'
                        : '${remainingMl.toStringAsFixed(0)} ml remaining',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0x1800F0FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x2200F0FF)),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressRatio,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: summary.percentage >= 100
                              ? [const Color(0xFF00F59B), const Color(0xFF00F0FF)]
                              : [const Color(0xFF00B2FF), const Color(0xFF00F0FF)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x6600F0FF),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Quick Log Buttons
          Row(
            children: [
              _buildQuickAddButton(
                label: '+250 ml',
                sublabel: 'Glass',
                icon: Icons.local_drink_rounded,
                onPressed: () => waterVm.quickLog(250),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: '+500 ml',
                sublabel: 'Bottle',
                icon: Icons.water_drop_outlined,
                onPressed: () => waterVm.quickLog(500),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: '+750 ml',
                sublabel: 'Flask',
                icon: Icons.opacity_rounded,
                onPressed: () => waterVm.quickLog(750),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: 'Custom',
                sublabel: 'Any',
                icon: Icons.add_rounded,
                onPressed: () => _showCustomWaterDialog(context, waterVm),
              ),
            ],
          ),

          // Recent Logs Preview
          if (summary.logs.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0x2200F0FF)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Logs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  '${summary.logsCount} entries',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.logs.take(4).map((log) {
                final timeStr = DateFormat('h:mm a').format(log.loggedAt.toLocal());
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1800F0FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x3300F0FF)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${log.amountMl.toStringAsFixed(0)}ml',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF00F0FF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => waterVm.deleteLog(log.id),
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFFF6B6B)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddButton({
    required String label,
    required String sublabel,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0x3300F0FF),
          highlightColor: const Color(0x1A00F0FF),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x3300F0FF)),
              borderRadius: BorderRadius.circular(14),
              color: const Color(0x1200F0FF),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF00F0FF)),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF00F0FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
