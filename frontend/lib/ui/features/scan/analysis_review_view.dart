import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/models/portion_model.dart';
import '../../../data/models/recent_food_model.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/image_bounding_box_overlay.dart';
import '../../core/widgets/macro_card.dart';
import '../home/home_view_model.dart';
import '../portion/portion_picker_widget.dart';
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

  void _showPortionEditSheet(BuildContext context, ScanViewModel scanVm, int itemIndex) async {
    final item = scanVm.editableItems[itemIndex];
    final repo = MealRepository();
    List<PortionGuideModel> fetchedPortions = [];
    try {
      fetchedPortions = await repo.searchPortions(query: item.name);
    } catch (_) {}

    if (!context.mounted) return;

    double selectedGrams = item.quantity;
    String selectedUnit = item.unit;
    double refCaloriesPer100g = item.quantity > 0
        ? (item.estimatedCalories / item.quantity) * 100.0
        : 150.0;
    if (refCaloriesPer100g <= 0) refCaloriesPer100g = 150.0;
    double selectedCalories = item.estimatedCalories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Adjust Portion: ${item.name}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PortionPickerWidget(
                    portions: fetchedPortions,
                    initialMultiplier: 1.0,
                    referenceCaloriesPer100g: refCaloriesPer100g,
                    onPortionChanged: (portion, mult, totalGrams, totalCals) {
                      setSheetState(() {
                        selectedGrams = totalGrams;
                        selectedUnit = portion.label.replaceAll(RegExp(r'^\d+\s*'), '');
                        selectedCalories = totalCals;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      final ratio = item.quantity > 0 ? selectedGrams / item.quantity : 1.0;
                      scanVm.updateItemPortion(
                        itemIndex,
                        newQuantity: selectedGrams,
                        newUnit: selectedUnit,
                        newCalories: selectedCalories,
                        newProtein: (item.protein * ratio).clamp(0.0, 999.0),
                        newCarbs: (item.carbohydrates * ratio).clamp(0.0, 999.0),
                        newFat: (item.fat * ratio).clamp(0.0, 999.0),
                        newFiber: (item.fiber * ratio).clamp(0.0, 999.0),
                      );
                      Navigator.pop(sheetCtx);
                    },
                    child: Text(
                      'Apply Portion (${selectedGrams.toStringAsFixed(0)} g • ${selectedCalories.toStringAsFixed(0)} kcal)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanVm = context.watch<ScanViewModel>();
    final result = scanVm.analysisResult;

    // Handle validation failure: non-food or uncertain/blurry image
    if (result != null && (result.isNonFood || result.isUncertain)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(result.isNonFood ? 'Image Validation' : 'Unclear Image'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              scanVm.reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: _buildValidationFailureView(context, scanVm, result),
        ),
      );
    }

    // Handle barcode image detection
    if (result != null && result.isBarcode && scanVm.editableItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Barcode Detected'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              scanVm.reset();
              Navigator.pop(context);
            },
          ),
        ),
        body: SafeArea(
          child: _buildBarcodeDetectedView(context, scanVm, result),
        ),
      );
    }

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
                                          icon: const Icon(Icons.tune_rounded, size: 19),
                                          tooltip: 'Portion Guide',
                                          color: AppTheme.primaryGreen,
                                          onPressed: () => _showPortionEditSheet(context, scanVm, index),
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

  Widget _buildValidationFailureView(
    BuildContext context,
    ScanViewModel scanVm,
    MealAnalysisResponseModel result,
  ) {
    final isNonFood = result.isNonFood;
    final title = isNonFood ? 'Non-Food Item Detected' : 'Unclear Image';
    final defaultMsg = isNonFood
        ? '⚠️ Non-eatable item detected. Please upload an image of food or a food barcode.'
        : '⚠️ We couldn\'t identify food in this image. Please upload a clearer image of your food or barcode.';
    final message = result.validationMessage ?? defaultMsg;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview of the analyzed image
            if (scanVm.imageBytes != null) ...[
              Center(
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isNonFood ? Colors.red.shade300 : Colors.amber.shade400,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isNonFood ? Colors.red : Colors.amber).withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.memory(
                          scanVm.imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isNonFood ? Colors.red.shade600 : Colors.amber.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isNonFood ? Icons.close_rounded : Icons.priority_high_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Validation Warning Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isNonFood ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isNonFood ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isNonFood ? Icons.no_food_rounded : Icons.image_not_supported_rounded,
                        color: isNonFood ? Colors.red.shade700 : Colors.amber.shade900,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isNonFood ? Colors.red.shade900 : Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isNonFood ? const Color(0xFF7F1D1D) : const Color(0xFF78350F),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isNonFood
                        ? 'Healthify analyzes meals, snacks, ingredients, and barcodes to calculate nutrition accurately.'
                        : 'Make sure your meal is well-lit, in focus, and clearly visible from above.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            CustomButton(
              text: 'Take New Photo',
              icon: Icons.camera_alt_rounded,
              onPressed: () async {
                await scanVm.pickAndAnalyze(ImageSource.camera);
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Choose from Gallery',
              icon: Icons.photo_library_outlined,
              isOutlined: true,
              onPressed: () async {
                await scanVm.pickAndAnalyze(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                scanVm.reset();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back, size: 18, color: AppTheme.textSecondary),
              label: const Text(
                'Back to Food Logging',
                style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeDetectedView(
    BuildContext context,
    ScanViewModel scanVm,
    MealAnalysisResponseModel result,
  ) {
    final product = result.barcodeProduct ?? scanVm.scannedProduct;

    if (product != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryGreen, width: 1.5),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, color: AppTheme.primaryDark, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Barcode Product Detected',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (product.brand != null && product.brand!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.brand!,
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 16),
                  MacroCard(
                    calories: product.calories,
                    protein: product.protein,
                    carbs: product.carbohydrates,
                    fat: product.fat,
                    fiber: product.fiber,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Add Product to Plate',
              icon: Icons.add_circle_outline,
              onPressed: () {
                scanVm.addBarcodeProductToPlate(product);
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Scan Another Item',
              icon: Icons.camera_alt_outlined,
              isOutlined: true,
              onPressed: () => scanVm.pickAndAnalyze(ImageSource.camera),
            ),
          ],
        ),
      );
    }

    return _buildValidationFailureView(context, scanVm, result);
  }
}


