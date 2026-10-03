import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../features/weight/weight_view.dart';
import '../../features/weight/weight_view_model.dart';

class WeightTrackerCard extends StatefulWidget {
  const WeightTrackerCard({super.key});

  @override
  State<WeightTrackerCard> createState() => _WeightTrackerCardState();
}

class _WeightTrackerCardState extends State<WeightTrackerCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final vm = Provider.of<WeightViewModel?>(context, listen: false);
        if (vm != null && vm.history == null && !vm.isLoading) {
          vm.loadHistory();
        }
      } catch (_) {}
    });
  }

  void _showQuickLogDialog(BuildContext context, WeightViewModel vm) {
    final currentWt = vm.currentWeight ?? 70.0;
    final controller = TextEditingController(text: currentWt.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF140F24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x44A855F7)),
        ),
        title: const Row(
          children: [
            Icon(Icons.monitor_weight_outlined, color: Color(0xFFC084FC)),
            SizedBox(width: 8),
            Text('Log Weight', style: TextStyle(color: AppTheme.textPrimary)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your current weight in kg:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Weight (kg)',
                labelStyle: const TextStyle(color: AppTheme.textSecondary),
                suffixText: 'kg',
                suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.scale, color: Color(0xFFC084FC)),
                filled: true,
                fillColor: const Color(0xFF1D1633),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x33A855F7)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x33A855F7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFA855F7), width: 1.5),
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
              backgroundColor: const Color(0xFF9333EA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final val = double.tryParse(controller.text.trim());
              if (val != null && val >= 30.0 && val <= 300.0) {
                Navigator.pop(ctx);
                await vm.logWeight(val);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged ${val.toStringAsFixed(1)} kg'),
                      backgroundColor: const Color(0xFF9333EA),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<WeightViewModel?>(context);
    if (vm == null) return const SizedBox.shrink();

    final current = vm.currentWeight;
    final delta7d = vm.sevenDayDelta;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140F24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x33A855F7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WeightView()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
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
                            color: const Color(0x33A855F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x44A855F7)),
                          ),
                          child: const Icon(
                            Icons.monitor_weight_outlined,
                            color: Color(0xFFC084FC),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Body Weight',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Track progress & trends',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showQuickLogDialog(context, vm),
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFFC084FC)),
                      label: const Text(
                        'Log',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFC084FC),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0x22A855F7),
                        side: const BorderSide(color: Color(0x44A855F7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (current != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                current.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'No weight logged',
                            style: TextStyle(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (delta7d != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: delta7d <= 0
                              ? const Color(0x3300F59B)
                              : const Color(0x33EF4444),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: delta7d <= 0
                                ? const Color(0x6600F59B)
                                : const Color(0x66EF4444),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              delta7d <= 0 ? Icons.trending_down : Icons.trending_up,
                              size: 14,
                              color: delta7d <= 0
                                  ? AppTheme.neonEmerald
                                  : const Color(0xFFF87171),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${delta7d > 0 ? "+" : ""}${delta7d.toStringAsFixed(1)} kg (7d)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: delta7d <= 0
                                    ? AppTheme.neonEmerald
                                    : const Color(0xFFF87171),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const Row(
                        children: [
                          Text(
                            'View chart',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFC084FC),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: Color(0xFFC084FC)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
