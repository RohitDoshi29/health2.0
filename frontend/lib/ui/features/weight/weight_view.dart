import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/weight_model.dart';
import '../../core/widgets/custom_button.dart';
import 'weight_view_model.dart';

class WeightView extends StatefulWidget {
  const WeightView({super.key});

  @override
  State<WeightView> createState() => _WeightViewState();
}

class _WeightViewState extends State<WeightView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeightViewModel>().loadHistory();
    });
  }

  void _showLogWeightSheet(BuildContext context, WeightViewModel vm) {
    final currentWt = vm.history?.currentWeight ?? 70.0;
    final wtController = TextEditingController(text: currentWt.toStringAsFixed(1));
    final noteController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
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
                  const Text(
                    'Log Body Weight',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(modalCtx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 28),
                    color: AppTheme.textSecondary,
                    onPressed: () {
                      final val = double.tryParse(wtController.text) ?? 70.0;
                      if (val > 30.0) {
                        wtController.text = (val - 0.1).toStringAsFixed(1);
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: wtController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      decoration: const InputDecoration(
                        suffixText: 'kg',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 28),
                    color: AppTheme.primaryGreen,
                    onPressed: () {
                      final val = double.tryParse(wtController.text) ?? 70.0;
                      if (val < 300.0) {
                        wtController.text = (val + 0.1).toStringAsFixed(1);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: InputDecoration(
                  hintText: 'Note (optional, e.g. morning fasting)',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Save Weight Log',
                icon: Icons.check,
                isLoading: vm.isSaving,
                onPressed: () async {
                  final val = double.tryParse(wtController.text.trim());
                  if (val != null && val >= 20.0 && val <= 400.0) {
                    final ok = await vm.logWeight(val, note: noteController.text.trim());
                    if (ok && modalCtx.mounted) {
                      Navigator.pop(modalCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Weight logged successfully!'),
                          backgroundColor: AppTheme.primaryGreen,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WeightViewModel>();
    final history = vm.history;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Weight Tracker', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Weight', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () => _showLogWeightSheet(context, vm),
      ),
      body: SafeArea(
        child: vm.isLoading && history == null
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: () => vm.loadHistory(),
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  children: [
                    // Stat Cards Row
                    _buildStatCards(history),
                    const SizedBox(height: 20),

                    // Dual-Axis Chart Card
                    _buildDualAxisChartCard(context, vm, history),
                    const SizedBox(height: 24),

                    // Log history header
                    const Text(
                      'Logged Measurements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (history == null || history.points.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Text(
                          'No weight entries yet.\nTap "Log Weight" below to record your first weigh-in.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                        ),
                      )
                    else
                      ...history.points.reversed.map((p) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.date,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  if (p.caloriesConsumed != null && p.caloriesConsumed! > 0)
                                    Text(
                                      '${p.caloriesConsumed!.toStringAsFixed(0)} kcal consumed',
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                    ),
                                ],
                              ),
                              Text(
                                '${p.weightKg.toStringAsFixed(1)} kg',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatCards(WeightHistoryResponseModel? history) {
    final current = history?.currentWeight;
    final change7d = history?.change7dKg;
    final changeTotal = history?.changeTotalKg;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Current',
            value: current != null ? '${current.toStringAsFixed(1)} kg' : '--',
            color: AppTheme.primaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'vs 7 Days',
            value: change7d != null
                ? '${change7d > 0 ? "+" : ""}${change7d.toStringAsFixed(1)} kg'
                : '--',
            color: change7d == null
                ? AppTheme.textSecondary
                : (change7d <= 0 ? Colors.green.shade700 : Colors.orange.shade800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'Overall',
            value: changeTotal != null
                ? '${changeTotal > 0 ? "+" : ""}${changeTotal.toStringAsFixed(1)} kg'
                : '--',
            color: changeTotal == null
                ? AppTheme.textSecondary
                : (changeTotal <= 0 ? Colors.green.shade700 : Colors.blue.shade800),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDualAxisChartCard(
    BuildContext context,
    WeightViewModel vm,
    WeightHistoryResponseModel? history,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Days Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weight & Calorie Trend',
                style: TextStyle(
                  fontSize: 15,
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
                  children: [7, 30, 90].map((d) {
                    final isSelected = vm.selectedDays == d;
                    return GestureDetector(
                      onTap: () => vm.loadHistory(d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          '${d}D',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend
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
              const SizedBox(width: 5),
              const Text('Weight (kg)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              const Text('Calories (kcal)', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 18),

          // Chart Rendering
          if (history == null || history.points.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text('No history available for this period.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 180,
              child: _DualAxisChart(points: history.points),
            ),
        ],
      ),
    );
  }
}

class _DualAxisChart extends StatelessWidget {
  final List<WeightHistoryPointModel> points;

  const _DualAxisChart({required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    double minWeight = points.first.weightKg;
    double maxWeight = points.first.weightKg;
    double maxCal = 2000.0;

    for (final p in points) {
      if (p.weightKg < minWeight) minWeight = p.weightKg;
      if (p.weightKg > maxWeight) maxWeight = p.weightKg;
      final c = p.caloriesConsumed ?? 0.0;
      if (c > maxCal) maxCal = c;
    }

    if (maxWeight - minWeight < 2.0) {
      maxWeight += 1.0;
      minWeight = (minWeight - 1.0).clamp(0.0, double.infinity);
    }
    maxCal *= 1.15; // 15% headroom

    return CustomPaint(
      size: Size.infinite,
      painter: _DualAxisPainter(
        points: points,
        minWeight: minWeight,
        maxWeight: maxWeight,
        maxCalories: maxCal,
      ),
    );
  }
}

class _DualAxisPainter extends CustomPainter {
  final List<WeightHistoryPointModel> points;
  final double minWeight;
  final double maxWeight;
  final double maxCalories;

  _DualAxisPainter({
    required this.points,
    required this.minWeight,
    required this.maxWeight,
    required this.maxCalories,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final n = points.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width;

    // 1. Draw Calorie Bars in background
    final barPaint = Paint()
      ..color = const Color(0xFFFDE68A).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final barWidth = (size.width / n) * 0.55;

    for (int i = 0; i < n; i++) {
      final c = points[i].caloriesConsumed ?? 0.0;
      if (c > 0) {
        final barHeight = (c / maxCalories) * size.height;
        final x = (i * (size.width / n)) + (size.width / n - barWidth) / 2;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, barPaint);
      }
    }

    // 2. Draw Weight Trend Line
    final linePaint = Paint()
      ..color = AppTheme.primaryGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppTheme.primaryDark
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < n; i++) {
      final w = points[i].weightKg;
      final ratioY = (w - minWeight) / (maxWeight - minWeight);
      final y = size.height - (ratioY * size.height);
      final x = n > 1 ? i * stepX : size.width / 2;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // 3. Draw Dots for points
    for (int i = 0; i < n; i++) {
      final w = points[i].weightKg;
      final ratioY = (w - minWeight) / (maxWeight - minWeight);
      final y = size.height - (ratioY * size.height);
      final x = n > 1 ? i * stepX : size.width / 2;

      canvas.drawCircle(Offset(x, y), 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _DualAxisPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minWeight != minWeight ||
        oldDelegate.maxWeight != maxWeight;
  }
}
