import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/analysis_model.dart';
import '../../../data/models/nutrition_model.dart';
import '../../../data/models/portion_model.dart';
import '../../../data/models/recent_food_model.dart';
import '../../../data/repositories/favorite_repository.dart';
import '../../../data/repositories/meal_repository.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/glass_card.dart';
import '../home/home_view_model.dart';
import '../portion/portion_picker_widget.dart';

class ManualFoodEntryView extends StatefulWidget {
  final MealRepository? mealRepository;
  final FavoriteRepository? favoriteRepository;

  const ManualFoodEntryView({
    super.key,
    this.mealRepository,
    this.favoriteRepository,
  });

  @override
  State<ManualFoodEntryView> createState() => _ManualFoodEntryViewState();
}

class _ManualFoodEntryViewState extends State<ManualFoodEntryView> {
  late final MealRepository _mealRepo;
  late final FavoriteRepository _favRepo;

  String _selectedMealType = 'lunch';
  final List<String> _mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];

  // Current item inputs
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '100');
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  String _selectedUnit = 'g';
  final List<String> _units = [
    'g',
    'ml',
    'katori',
    'roti',
    'idli',
    'dosa',
    'glass',
    'piece',
    'cup',
    'tbsp',
    'tsp',
    'slice',
    'bowl',
    'serving',
    'plate',
  ];

  // Portion guides
  List<PortionGuideModel> _availablePortions = [];
  double _baseCaloriesPer100g = 0.0;
  double _baseProteinPer100g = 0.0;
  double _baseCarbsPer100g = 0.0;
  double _baseFatPer100g = 0.0;
  double _baseFiberPer100g = 0.0;

  // Search catalog state
  final _searchController = TextEditingController();
  List<FoodItemModel> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Staged meal items
  final List<MealItemAnalysisModel> _stagedItems = [];
  bool _isSaving = false;

  // Recent foods
  List<RecentFoodModel> _recentFoods = [];

  @override
  void initState() {
    super.initState();
    _mealRepo = widget.mealRepository ?? MealRepository();
    _favRepo = widget.favoriteRepository ?? FavoriteRepository();
    _loadRecentFoods();
  }

  Future<void> _loadRecentFoods() async {
    try {
      final recents = await _mealRepo.getRecentFoods(limit: 15);
      if (mounted) {
        setState(() {
          _recentFoods = recents;
        });
      }
    } catch (_) {}
  }

  void _selectRecentFood(RecentFoodModel food) async {
    setState(() {
      _nameController.text = food.foodName;
      _quantityController.text = food.quantity.toStringAsFixed(0);
      _selectedUnit = _units.contains(food.unit) ? food.unit : 'g';
      _caloriesController.text = food.calories.toStringAsFixed(0);
      _proteinController.text = food.protein.toStringAsFixed(1);
      _carbsController.text = food.carbohydrates.toStringAsFixed(1);
      _fatController.text = food.fat.toStringAsFixed(1);
      _fiberController.text = food.fiber.toStringAsFixed(1);

      if (food.quantity > 0) {
        _baseCaloriesPer100g = (food.calories / food.quantity) * 100.0;
        _baseProteinPer100g = (food.protein / food.quantity) * 100.0;
        _baseCarbsPer100g = (food.carbohydrates / food.quantity) * 100.0;
        _baseFatPer100g = (food.fat / food.quantity) * 100.0;
        _baseFiberPer100g = (food.fiber / food.quantity) * 100.0;
      }
    });

    try {
      final portions = await _mealRepo.searchPortions(query: food.foodName);
      if (mounted && portions.isNotEmpty) {
        setState(() => _availablePortions = portions);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _quantityController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final results = await _mealRepo.searchFoods(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _selectCatalogFood(FoodItemModel food) async {
    final size = food.servingSize > 0 ? food.servingSize : 100.0;
    setState(() {
      _nameController.text = food.name;
      _quantityController.text = food.servingSize.toStringAsFixed(0);
      _selectedUnit = _units.contains(food.servingUnit) ? food.servingUnit : 'g';
      _caloriesController.text = food.calories.toStringAsFixed(0);
      _proteinController.text = food.protein.toStringAsFixed(1);
      _carbsController.text = food.carbohydrates.toStringAsFixed(1);
      _fatController.text = food.fat.toStringAsFixed(1);
      _fiberController.text = food.fiber.toStringAsFixed(1);
      _searchResults = [];
      _searchController.clear();

      _baseCaloriesPer100g = (food.calories / size) * 100.0;
      _baseProteinPer100g = (food.protein / size) * 100.0;
      _baseCarbsPer100g = (food.carbohydrates / size) * 100.0;
      _baseFatPer100g = (food.fat / size) * 100.0;
      _baseFiberPer100g = (food.fiber / size) * 100.0;
    });

    try {
      final portions = await _mealRepo.getPortionsForFood(food.id);
      if (mounted && portions.isNotEmpty) {
        setState(() => _availablePortions = portions);
      }
    } catch (_) {}
  }

  void _addItemToStaged() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showToast('Please enter a food name');
      return;
    }

    final quantity = double.tryParse(_quantityController.text.trim()) ?? 100.0;
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
    final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
    final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;
    final fiber = double.tryParse(_fiberController.text.trim()) ?? 0.0;

    final item = MealItemAnalysisModel(
      name: name,
      quantity: quantity,
      unit: _selectedUnit,
      estimatedCalories: calories,
      protein: protein,
      carbohydrates: carbs,
      fat: fat,
      fiber: fiber,
      confidence: 1.0,
    );

    setState(() {
      _stagedItems.add(item);
      _clearInputs();
    });
  }

  void _clearInputs() {
    _nameController.clear();
    _quantityController.text = '100';
    _caloriesController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatController.clear();
    _fiberController.clear();
  }

  void _removeItem(int index) {
    setState(() {
      _stagedItems.removeAt(index);
    });
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppTheme.surfaceLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x3300F59B)),
        ),
      ),
    );
  }

  List<MealItemAnalysisModel> _getAllItemsToSave() {
    final items = List<MealItemAnalysisModel>.from(_stagedItems);
    final activeName = _nameController.text.trim();
    if (activeName.isNotEmpty) {
      final quantity = double.tryParse(_quantityController.text.trim()) ?? 100.0;
      final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
      final protein = double.tryParse(_proteinController.text.trim()) ?? 0.0;
      final carbs = double.tryParse(_carbsController.text.trim()) ?? 0.0;
      final fat = double.tryParse(_fatController.text.trim()) ?? 0.0;
      final fiber = double.tryParse(_fiberController.text.trim()) ?? 0.0;

      items.add(MealItemAnalysisModel(
        name: activeName,
        quantity: quantity,
        unit: _selectedUnit,
        estimatedCalories: calories,
        protein: protein,
        carbohydrates: carbs,
        fat: fat,
        fiber: fiber,
        confidence: 1.0,
      ));
    }
    return items;
  }

  Future<void> _handleSaveMeal() async {
    final items = _getAllItemsToSave();
    if (items.isEmpty) {
      _showToast('Please enter at least one food item with nutrition values');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _mealRepo.saveMeal(
        mealType: _selectedMealType,
        items: items,
      );

      if (mounted) {
        try {
          context.read<HomeViewModel>().loadDashboard();
        } catch (_) {}

        _showToast('Meal successfully logged!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to save meal: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleSaveAsFavorite() async {
    final items = _getAllItemsToSave();
    if (items.isEmpty) {
      _showToast('Please enter food items before saving as favorite template');
      return;
    }

    final defaultName = items.length == 1 ? items.first.name : '$_selectedMealType Combo';
    final nameCtrl = TextEditingController(text: defaultName);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0x3300F59B), width: 1.2),
        ),
        title: const Text(
          'Save as Favorite Template',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a name for this quick-log template:',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g. Morning Protein Oats',
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F59B)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0x2200F59B)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: AppTheme.neonEmerald, width: 2),
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
            onPressed: () async {
              final templateName = nameCtrl.text.trim();
              if (templateName.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  await _favRepo.createFavorite(
                    name: templateName,
                    mealType: _selectedMealType,
                    items: items,
                  );
                  _showToast('⭐ Saved "$templateName" to Favorites!');
                } catch (e) {
                  _showToast('Failed to save favorite: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonEmerald,
              foregroundColor: const Color(0xFF041A0E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Template', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _getAllItemsToSave();
    final totalCals = allItems.fold(0.0, (sum, i) => sum + i.estimatedCalories);
    final totalProtein = allItems.fold(0.0, (sum, i) => sum + i.protein);
    final totalCarbs = allItems.fold(0.0, (sum, i) => sum + i.carbohydrates);
    final totalFat = allItems.fold(0.0, (sum, i) => sum + i.fat);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Manual Food Entry',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear fields',
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.neonEmerald),
            onPressed: () {
              setState(() {
                _clearInputs();
                _stagedItems.clear();
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.3,
            colors: [
              Color(0xFF0F241A),
              Color(0xFF080D0B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Meal Type Selector
                const Text(
                  'Meal Category',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMealTypeSelector(),
                const SizedBox(height: 18),

                // Catalog Search / Quick Autofill
                _buildCatalogSearchBar(),
                if (_searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildSearchResultsList(),
                ],
                const SizedBox(height: 16),

                // Recent Foods Chip List
                if (_recentFoods.isNotEmpty) ...[
                  _buildRecentFoodsChips(),
                  const SizedBox(height: 18),
                ],

                // Item Form Card
                _buildItemFormCard(),
                const SizedBox(height: 18),

                // Staged Items List (if multiple items added)
                if (_stagedItems.isNotEmpty) ...[
                  _buildStagedItemsSection(),
                  const SizedBox(height: 18),
                ],

                // Live Totals Card
                _buildNutritionSummaryCard(totalCals, totalProtein, totalCarbs, totalFat),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0x6600F59B), width: 1.2),
                        ),
                        child: OutlinedButton.icon(
                          onPressed: _isSaving ? null : _handleSaveAsFavorite,
                          icon: const Icon(Icons.star_border_rounded, color: AppTheme.neonEmerald, size: 18),
                          label: const Text(
                            'Save Template',
                            style: TextStyle(
                              color: AppTheme.neonEmerald,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Log Meal',
                        isLoading: _isSaving,
                        onPressed: _handleSaveMeal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _mealTypes.map((type) {
          final isSelected = _selectedMealType == type;
          String icon = '🍎';
          if (type == 'breakfast') icon = '🍳';
          if (type == 'lunch') icon = '🥗';
          if (type == 'dinner') icon = '🍲';

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0x2800F59B) : const Color(0x18FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppTheme.neonEmerald : const Color(0x22FFFFFF),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x3300F59B),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(icon, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      type[0].toUpperCase() + type.substring(1),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppTheme.neonEmerald : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatalogSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search food database to auto-fill (optional)...',
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.neonEmerald, size: 20),
          suffixIcon: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.neonEmerald,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: AppTheme.textSecondary),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3300F59B), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0x18FFFFFF)),
        itemBuilder: (context, index) {
          final food = _searchResults[index];
          return ListTile(
            dense: true,
            title: Text(
              food.name,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary, fontSize: 14),
            ),
            subtitle: Text(
              '${food.servingSize.toStringAsFixed(0)}${food.servingUnit} • ${food.calories.toStringAsFixed(0)} kcal • P: ${food.protein}g C: ${food.carbohydrates}g F: ${food.fat}g',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            trailing: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonEmerald, size: 22),
            onTap: () => _selectCatalogFood(food),
          );
        },
      ),
    );
  }

  Widget _buildRecentFoodsChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: AppTheme.neonEmerald),
                SizedBox(width: 6),
                Text(
                  'Recent Foods',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            Text(
              'Tap to autofill',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _recentFoods.map((recent) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _selectRecentFood(recent),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0x18FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x22FFFFFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0x2800F59B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant_rounded, size: 11, color: AppTheme.neonEmerald),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${recent.foodName} (${recent.quantity.toStringAsFixed(0)}${recent.unit} • ${recent.calories.toStringAsFixed(0)} kcal)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemFormCard() {
    return GlassCard(
      glowColor: AppTheme.neonEmerald,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppTheme.neonEmerald, size: 20),
              SizedBox(width: 8),
              Text(
                'Food Details & Nutrition',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Food Name
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Food Name *',
              hintText: 'e.g. Grilled Chicken, Oats, Rice Bowl',
              prefixIcon: const Icon(Icons.restaurant_menu_rounded, color: AppTheme.neonEmerald),
              filled: true,
              fillColor: const Color(0x18FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x22FFFFFF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x22FFFFFF)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppTheme.neonEmerald, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Portion Guide Picker & Stepper
          PortionPickerWidget(
            portions: _availablePortions,
            initialMultiplier: 1.0,
            referenceCaloriesPer100g: _baseCaloriesPer100g > 0 ? _baseCaloriesPer100g : 150.0,
            onPortionChanged: (portion, mult, totalGrams, totalCals) {
              setState(() {
                _quantityController.text = totalGrams.toStringAsFixed(0);
                _selectedUnit = 'g';
                if (_baseCaloriesPer100g > 0) {
                  _caloriesController.text = totalCals.toStringAsFixed(0);
                  final ratio = totalGrams / 100.0;
                  _proteinController.text = (_baseProteinPer100g * ratio).toStringAsFixed(1);
                  _carbsController.text = (_baseCarbsPer100g * ratio).toStringAsFixed(1);
                  _fatController.text = (_baseFatPer100g * ratio).toStringAsFixed(1);
                  _fiberController.text = (_baseFiberPer100g * ratio).toStringAsFixed(1);
                }
              });
            },
          ),
          const SizedBox(height: 16),

          // Quantity and Unit
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Serving Quantity *',
                    hintText: '100',
                    prefixIcon: const Icon(Icons.scale_rounded, color: AppTheme.neonTeal),
                    filled: true,
                    fillColor: const Color(0x18FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppTheme.neonEmerald, width: 1.8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  dropdownColor: AppTheme.surfaceLight,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    filled: true,
                    fillColor: const Color(0x18FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0x22FFFFFF)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppTheme.neonEmerald, width: 1.8),
                    ),
                  ),
                  items: _units.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(u, style: const TextStyle(color: AppTheme.textPrimary)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text(
            'Nutritional Values (Estimated or Manual)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Calories (Primary)
          TextField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Calories (kcal) *',
              labelStyle: const TextStyle(color: AppTheme.calorieColor),
              hintText: 'e.g. 250',
              prefixIcon: const Icon(Icons.local_fire_department_rounded, color: AppTheme.calorieColor),
              filled: true,
              fillColor: const Color(0x18FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x44FF8A00)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x44FF8A00)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppTheme.calorieColor, width: 1.8),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Macros Row: Protein, Carbs, Fat
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Protein (g)',
                    labelStyle: const TextStyle(color: AppTheme.proteinColor, fontSize: 12),
                    hintText: '0.0',
                    filled: true,
                    fillColor: const Color(0x18FFFFFF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x33FF4D4D)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x33FF4D4D)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.proteinColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Carbs (g)',
                    labelStyle: const TextStyle(color: AppTheme.carbsColor, fontSize: 12),
                    hintText: '0.0',
                    filled: true,
                    fillColor: const Color(0x18FFFFFF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x3300B2FF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x3300B2FF)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.carbsColor, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Fat (g)',
                    labelStyle: const TextStyle(color: AppTheme.fatColor, fontSize: 12),
                    hintText: '0.0',
                    filled: true,
                    fillColor: const Color(0x18FFFFFF),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x33A855F7)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x33A855F7)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: AppTheme.fatColor, width: 1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fiber
          TextField(
            controller: _fiberController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'Fiber (g) - Optional',
              labelStyle: const TextStyle(color: AppTheme.fiberColor, fontSize: 13),
              hintText: '0.0',
              prefixIcon: const Icon(Icons.eco_rounded, color: AppTheme.fiberColor, size: 18),
              filled: true,
              fillColor: const Color(0x18FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x3310B981)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x3310B981)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppTheme.fiberColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Add to multi-item plate button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addItemToStaged,
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonEmerald, size: 18),
              label: const Text(
                '+ Add Item to Multi-Plate',
                style: TextStyle(color: AppTheme.neonEmerald, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Staged Items in Meal (${_stagedItems.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _stagedItems.clear()),
              child: const Text('Clear All', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._stagedItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0x18FFFFFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity.toStringAsFixed(0)} ${item.unit} • ${item.estimatedCalories.toStringAsFixed(0)} kcal • P: ${item.protein}g C: ${item.carbohydrates}g F: ${item.fat}g',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFF6B6B), size: 20),
                  onPressed: () => _removeItem(idx),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNutritionSummaryCard(double calories, double protein, double carbs, double fat) {
    return GlassCard(
      glow: true,
      glowColor: AppTheme.neonEmerald,
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppTheme.neonEmerald, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Meal Plate Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2800F59B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0x6600F59B)),
                ),
                child: Text(
                  '${calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(
                    color: AppTheme.neonEmerald,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroPill('Protein', '${protein.toStringAsFixed(1)}g', AppTheme.proteinColor),
              _buildMacroPill('Carbs', '${carbs.toStringAsFixed(1)}g', AppTheme.carbsColor),
              _buildMacroPill('Fat', '${fat.toStringAsFixed(1)}g', AppTheme.fatColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
