import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../features/water/water_view_model.dart';

class WaterTrackerCard extends StatelessWidget {
  const WaterTrackerCard({super.key});

  void _showCustomWaterDialog(BuildContext context, WaterViewModel waterVm) {
    final controller = TextEditingController(text: '300');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.water_drop, color: Colors.blue),
            SizedBox(width: 8),
            Text('Log Water Intake'),
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
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount (ml)',
                suffixText: 'ml',
                prefixIcon: Icon(Icons.local_drink),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                waterVm.quickLog(val);
              }
            },
            child: const Text('Log'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Daily Water Target'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your daily hydration goal (ml):',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Target (ml)',
                suffixText: 'ml',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val > 0) {
                Navigator.pop(ctx);
                waterVm.updateGoal(val);
              }
            },
            child: const Text('Save Goal'),
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
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
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.water_drop, color: Colors.blue.shade600, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Hydration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _showEditGoalDialog(context, waterVm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${summary.totalMl.toStringAsFixed(0)} / ${summary.targetMl.toStringAsFixed(0)} ml',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Colors.blue.shade700),
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
                      fontWeight: FontWeight.w700,
                      color: summary.percentage >= 100 ? Colors.green.shade700 : Colors.blue.shade700,
                    ),
                  ),
                  Text(
                    summary.percentage >= 100
                        ? 'Goal reached! 🎉'
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
                child: LinearProgressIndicator(
                  value: progressRatio,
                  minHeight: 10,
                  backgroundColor: Colors.blue.shade50,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    summary.percentage >= 100 ? Colors.green.shade500 : Colors.blue.shade500,
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
                icon: Icons.local_drink_outlined,
                onPressed: () => waterVm.quickLog(250),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: '+500 ml',
                sublabel: 'Bottle',
                icon: Icons.sports_bar_outlined,
                onPressed: () => waterVm.quickLog(500),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: '+750 ml',
                sublabel: 'Large',
                icon: Icons.water_outlined,
                onPressed: () => waterVm.quickLog(750),
              ),
              const SizedBox(width: 8),
              _buildQuickAddButton(
                label: 'Custom',
                sublabel: 'Any',
                icon: Icons.add,
                onPressed: () => _showCustomWaterDialog(context, waterVm),
              ),
            ],
          ),

          // Recent Logs Preview
          if (summary.logs.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 8),
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
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.logs.take(4).map((log) {
                final timeStr = DateFormat('h:mm a').format(log.loggedAt.toLocal());
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${log.amountMl.toStringAsFixed(0)}ml',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => waterVm.deleteLog(log.id),
                        child: Icon(Icons.close, size: 13, color: Colors.red.shade400),
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
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade100),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blue.shade50.withValues(alpha: 0.5),
            ),
            child: Column(
              children: [
                Icon(icon, size: 18, color: Colors.blue.shade700),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                Text(
                  sublabel,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.blue.shade600,
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
