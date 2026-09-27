import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/image_bounding_box_overlay.dart';
import '../../core/widgets/macro_card.dart';
import 'scan_view_model.dart';

class AnalysisReviewView extends StatefulWidget {
  const AnalysisReviewView({super.key});

  @override
  State<AnalysisReviewView> createState() => _AnalysisReviewViewState();
}

class _AnalysisReviewViewState extends State<AnalysisReviewView> {
  int? _selectedItemIndex;

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
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          if (item.confidence != null) ...[
                                            const SizedBox(width: 8),
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
                                        scanVm.removeItem(index);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
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
}


