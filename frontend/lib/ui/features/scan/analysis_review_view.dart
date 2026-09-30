import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/models/recent_food_model.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/image_bounding_box_overlay.dart';
import '../../core/widgets/macro_card.dart';
import '../home/home_view_model.dart';
import 'scan_view_model.dart';

class AnalysisReviewView extends StatefulWidget {
  const AnalysisReviewView({super.key});

  @override
  State<AnalysisReviewView> createState() => _AnalysisReviewViewState();
}

class _AnalysisReviewViewState extends State<AnalysisReviewView> {
  int? _selectedItemIndex;
  final Set<int> _expandedVerificationIndices = {};
  List<RecentFoodModel> _recentFoods = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    try {
      final recents = await MealRepository().getRecentFoods(limit: 10);
      if (mounted) {
        setState(() => _recentFoods = recents);
      }
    } catch (_) {}
  }

  void _showSaveFavoriteDialog(BuildContext context, ScanViewModel scanVm) {
    final defaultName = scanVm.editableItems.isNotEmpty
        ? scanVm.editableItems.first.name
        : 'My Favorite Meal';
    final nameCtrl = TextEditingController(text: defaultName);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.star_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text('Save as Favorite', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Save this meal configuration as a favorite template for 1-tap quick logging later.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'e.g. Morning Protein Shake',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(dialogCtx);
                try {
                  final repo = FavoriteRepository();
                  await repo.createFavorite(
                    name: name,
                    mealType: scanVm.selectedMealType,
                    items: scanVm.editableItems,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved "$name" as favorite!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save favorite: $e'), backgroundColor: Colors.red.shade700),
                    );
                  }
                }
              },
              child: const Text('Save Template'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanVm = context.watch<ScanViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Food Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            scanVm.reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo with interactive bounding box annotations
                    ImageBoundingBoxOverlay(
                      imageBytes: scanVm.imageBytes,
                      items: scanVm.editableItems,
                      selectedIndex: _selectedItemIndex,
                      onItemSelected: (index) {
                        setState(() {
                          _selectedItemIndex = (_selectedItemIndex == index) ? null : index;
                        });
                      },
                    ),
                    const SizedBox(height: 18),

                    // Dynamic Total Macro Card
                    MacroCard(
                      calories: scanVm.totalCalories,
                      protein: scanVm.totalProtein,
                      carbs: scanVm.totalCarbs,
                      fat: scanVm.totalFat,
                      fiber: scanVm.totalFiber,
                    ),
                    const SizedBox(height: 20),

                    // Meal Type Selector
                    const Text(
                      'Meal Category',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
                        final isSelected = scanVm.selectedMealType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => scanVm.setMealType(type),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryLight : AppTheme.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryGreen : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Detected Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Detected Food Items',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${scanVm.editableItems.length} items',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // List of items
                    if (scanVm.editableItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: const Text('No food items remaining.'),
                      )
                    else
                      ...scanVm.editableItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isSelected = _selectedItemIndex == index;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedItemIndex = isSelected ? null : index;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryLight.withValues(alpha: 0.3)
                                  : AppTheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryGreen
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.8 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              if (item.isComponent) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blueGrey.shade50,
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.layers_outlined,
                                                          size: 12, color: Colors.blueGrey.shade700),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Included in ${item.parentFood ?? "primary dish"}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.blueGrey.shade800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ] else if (item.verification != null)
                                                _buildVerificationBadge(item)
                                              else if (!item.matched) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.help_outline_rounded,
                                                          size: 11, color: Colors.orange.shade800),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Unmatched',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.orange.shade800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ] else if (item.confidence != null) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.shade50,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    '${(item.confidence! * 100).toInt()}% match',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green.shade700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (item.isComponent)
                                            Text(
                                              'Topping / ingredient • Included in ${item.parentFood ?? "primary dish"}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          else if (!item.matched && item.estimatedCalories == 0.0)
                                            Text(
                                              'Nutrition unavailable in database • Please confirm portion',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange.shade900,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            )
                                          else
                                            Text(
                                              '${item.estimatedCalories.toStringAsFixed(0)} kcal • P: ${item.protein}g • C: ${item.carbohydrates}g • F: ${item.fat}g',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Portion Modifier
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, size: 20),
                                          color: AppTheme.textSecondary,
                                          onPressed: item.quantity > 10
                                              ? () => scanVm.updateItemQuantity(
                                                  index, item.quantity - 10)
                                              : null,
                                        ),
                                        Text(
                                          '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline, size: 20),
                                          color: AppTheme.primaryGreen,
                                          onPressed: () => scanVm.updateItemQuantity(
                                              index, item.quantity + 10),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 20),
                                          color: Colors.red.shade400,
                                          onPressed: () {
                                            if (_selectedItemIndex == index) {
                                              _selectedItemIndex = null;
                                            }
                                            _expandedVerificationIndices.remove(index);
                                            scanVm.removeItem(index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (item.verification != null) ...[
                                  const SizedBox(height: 6),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (_expandedVerificationIndices.contains(index)) {
                                          _expandedVerificationIndices.remove(index);
                                        } else {
                                          _expandedVerificationIndices.add(index);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _expandedVerificationIndices.contains(index)
                                                ? 'Hide verification details ▴'
                                                : 'How was this verified? ▾',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryGreen,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (_expandedVerificationIndices.contains(index))
                                    _buildVerificationDetails(item),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    if (_recentFoods.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Row(
                        children: [
                          Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryDark),
                          SizedBox(width: 6),
                          Text(
                            'Quick Add Recent Food',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _recentFoods.map((recent) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                avatar: const Icon(Icons.add_circle, size: 16, color: AppTheme.primaryGreen),
                                label: Text(
                                  '${recent.foodName} (${recent.quantity.toStringAsFixed(0)}${recent.unit})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: const Color(0xFFF9FAFB),
                                side: BorderSide(color: Colors.grey.shade300),
                                onPressed: () {
                                  scanVm.addRecentFood(recent);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${recent.foodName} to meal plate!'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Column(
                children: [
                  CustomButton(
                    text: 'Save as Favorite Template',
                    icon: Icons.star_border_rounded,
                    isOutlined: true,
                    onPressed: () => _showSaveFavoriteDialog(context, scanVm),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Save Meal to Diary',
                    icon: Icons.check_circle_outline,
                    isLoading: scanVm.state == ScanState.saving,
                    onPressed: () async {
                      final success = await scanVm.saveMeal();
                      if (success && context.mounted) {
                        try {
                          context.read<HomeViewModel>().loadMeals();
                        } catch (_) {}
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meal saved successfully!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                        Navigator.pop(context);
                      } else if (!success && context.mounted && scanVm.errorMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(scanVm.errorMessage!),
                            backgroundColor: Colors.red.shade700,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(MealItemAnalysisModel item) {
    final v = item.verification;
    if (v == null) return const SizedBox.shrink();

    final status = v.verificationStatus;
    final conf = v.confidenceScore.toInt();

    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'verified':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        icon = Icons.check_circle_rounded;
        label = '✓ Verified ($conf%)';
        break;
      case 'verified_with_warning':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade900;
        icon = Icons.warning_amber_rounded;
        label = '⚠ Discrepancy (${v.discrepancyPercent.toStringAsFixed(0)}%)';
        break;
      case 'corrected':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        icon = Icons.restart_alt_rounded;
        label = '↻ Adjusted (${v.originalCalories.toStringAsFixed(0)} → ${v.finalCalories.toStringAsFixed(0)} kcal)';
        break;
      case 'needs_confirmation':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        icon = Icons.help_outline_rounded;
        label = '⚠ Needs Review';
        break;
      case 'low_confidence':
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        icon = Icons.info_outline_rounded;
        label = '⚠ Low Confidence';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationDetails(MealItemAnalysisModel item) {
    final v = item.verification;
    if (v == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (v.verificationNote.isNotEmpty) ...[
            Text(
              v.verificationNote,
              style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),
          ],
          ...v.sourceBreakdown.entries.map((entry) {
            String sourceLabel = entry.key.replaceAll('_', ' ').toUpperCase();
            if (entry.key == 'local_database') sourceLabel = 'Local Reference DB';
            if (entry.key == 'usda_fdc') sourceLabel = 'USDA FoodData Central';
            if (entry.key == 'macro_consistency') sourceLabel = 'Macro Calc (4-9-4)';
            if (entry.key == 'barcode_label') sourceLabel = 'Barcode Nutrition Label';
            if (entry.key == 'ingredient_decomposition') sourceLabel = 'Ingredient Recipe Sum';
            if (entry.key == 'ai_estimate') sourceLabel = 'AI Visual Estimate';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sourceLabel, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  Text('${entry.value.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Caloric Value', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
              Text('${v.finalCalories.toStringAsFixed(0)} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Confidence: Food ${(v.confidenceBreakdown.foodConfidence).toInt()}% • Portion ${(v.confidenceBreakdown.portionConfidence).toInt()}% • Nutrition ${(v.confidenceBreakdown.nutritionConfidence).toInt()}%',
                style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


