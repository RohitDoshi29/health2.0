import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/barcode_model.dart';
import 'custom_button.dart';

class BarcodeResultDialog extends StatefulWidget {
  final BarcodeProductModel product;
  final Function(BarcodeProductModel product, double multiplier) onAddToPlate;
  final Function(BarcodeProductModel product, double multiplier)? onLogMealDirectly;

  const BarcodeResultDialog({
    super.key,
    required this.product,
    required this.onAddToPlate,
    this.onLogMealDirectly,
  });

  @override
  State<BarcodeResultDialog> createState() => _BarcodeResultDialogState();
}

class _BarcodeResultDialogState extends State<BarcodeResultDialog> {
  double _multiplier = 1.0;

  Color _getNutriscoreColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'a':
        return const Color(0xFF038141);
      case 'b':
        return const Color(0xFF85BB2F);
      case 'c':
        return const Color(0xFFFECB02);
      case 'd':
        return const Color(0xFFEE8100);
      case 'e':
        return const Color(0xFFE63E11);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final totalCalories = (p.calories * _multiplier).round();
    final totalProtein = (p.protein * _multiplier).toStringAsFixed(1);
    final totalCarbs = (p.carbohydrates * _multiplier).toStringAsFixed(1);
    final totalFat = (p.fat * _multiplier).toStringAsFixed(1);
    final totalFiber = (p.fiber * _multiplier).toStringAsFixed(1);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header: Image + Title + Brand + NutriScore
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      p.imageUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                    ),
                  )
                else
                  _buildFallbackIcon(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (p.brand != null && p.brand!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          p.brand!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Badges: NutriScore + NOVA
                      Wrap(
                        spacing: 8,
                        children: [
                          if (p.nutriscoreGrade != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getNutriscoreColor(p.nutriscoreGrade!),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NUTRI-SCORE ${p.nutriscoreGrade!.toUpperCase()}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          if (p.novaGroup != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade800,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'NOVA ${p.novaGroup}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Servings / Portion Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Serving Size',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      Text(
                        p.servingSize ?? '${p.servingQuantity.round()} ${p.servingUnit}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        color: _multiplier > 0.5 ? AppTheme.primaryGreen : Colors.grey,
                        onPressed: _multiplier > 0.5
                            ? () {
                                setState(() {
                                  _multiplier = double.parse((_multiplier - 0.5).toStringAsFixed(1));
                                });
                              }
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          '${_multiplier}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        color: AppTheme.primaryGreen,
                        onPressed: () {
                          setState(() {
                            _multiplier = double.parse((_multiplier + 0.5).toStringAsFixed(1));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Calories & Macros Grid
            Row(
              children: [
                Expanded(
                  child: _buildMacroPill(
                    label: 'Calories',
                    value: '$totalCalories',
                    unit: 'kcal',
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroPill(
                    label: 'Protein',
                    value: totalProtein,
                    unit: 'g',
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroPill(
                    label: 'Carbs',
                    value: totalCarbs,
                    unit: 'g',
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroPill(
                    label: 'Fat',
                    value: totalFat,
                    unit: 'g',
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Micro nutrients row (Fiber, Sugars, Sodium)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  'Fiber: ${totalFiber}g',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                if (p.sugars != null)
                  Text(
                    'Sugar: ${(p.sugars! * _multiplier).toStringAsFixed(1)}g',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                if (p.sodium != null)
                  Text(
                    'Sodium: ${(p.sodium! * _multiplier).toStringAsFixed(2)}g',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
              ],
            ),

            if (p.ingredients != null && p.ingredients!.isNotEmpty) ...[
              const SizedBox(height: 14),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: const Text(
                  'Ingredients',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                children: [
                  Text(
                    p.ingredients!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Action buttons
            CustomButton(
              text: 'Add to Current Meal Plate',
              icon: Icons.add_circle,
              onPressed: () {
                Navigator.pop(context);
                widget.onAddToPlate(p, _multiplier);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.qr_code_2_rounded,
        size: 38,
        color: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildMacroPill({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

