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
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save as Favorite Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a name for this quick-log template:'),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Morning Protein Oats',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Template'),
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
      appBar: AppBar(
        title: const Text('Manual Food Entry'),
        actions: [
          IconButton(
            tooltip: 'Clear fields',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _clearInputs();
                _stagedItems.clear();
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meal Type Selector
              const Text(
                'Meal Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              _buildMealTypeSelector(),
              const SizedBox(height: 20),

              // Catalog Search / Quick Autofill
              _buildCatalogSearchBar(),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSearchResultsList(),
              ],
              const SizedBox(height: 14),

              // Recent Foods Chip List
              if (_recentFoods.isNotEmpty) ...[
                _buildRecentFoodsChips(),
                const SizedBox(height: 16),
              ],

              // Item Form
              _buildItemFormCard(),
              const SizedBox(height: 16),

              // Staged Items List (if multiple items added)
              if (_stagedItems.isNotEmpty) ...[
                _buildStagedItemsSection(),
                const SizedBox(height: 16),
              ],

              // Live Totals Card
              _buildNutritionSummaryCard(totalCals, totalProtein, totalCarbs, totalFat),
              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _handleSaveAsFavorite,
                      icon: const Icon(Icons.star_border, color: AppTheme.primaryDark),
                      label: const Text('Save Template', style: TextStyle(color: AppTheme.primaryDark)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.primaryGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              const SizedBox(height: 20),
            ],
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
            child: ChoiceChip(
              avatar: Text(icon, style: const TextStyle(fontSize: 16)),
              label: Text(
                type[0].toUpperCase() + type.substring(1),
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryGreen,
              backgroundColor: Colors.grey.shade100,
              onSelected: (selected) {
                if (selected) setState(() => _selectedMealType = type);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCatalogSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search food database to auto-fill (optional)...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryDark),
          suffixIcon: _isSearching
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : (_searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSearchResultsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final food = _searchResults[index];
          return ListTile(
            dense: true,
            title: Text(food.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${food.servingSize.toStringAsFixed(0)}${food.servingUnit} • ${food.calories.toStringAsFixed(0)} kcal • P: ${food.protein}g C: ${food.carbohydrates}g F: ${food.fat}g',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            trailing: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGreen),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryDark),
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                  avatar: const CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primaryLight,
                    child: Icon(Icons.restaurant_rounded, size: 12, color: AppTheme.primaryDark),
                  ),
                  label: Text(
                    '${recent.foodName} (${recent.quantity.toStringAsFixed(0)}${recent.unit} • ${recent.calories.toStringAsFixed(0)} kcal)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: const Color(0xFFF9FAFB),
                  side: BorderSide(color: Colors.grey.shade300),
                  onPressed: () => _selectRecentFood(recent),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItemFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Food Details & Nutritional Values',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 14),

          // Food Name
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Food Name *',
              hintText: 'e.g. Grilled Chicken, Oats, Rice Bowl',
              prefixIcon: const Icon(Icons.restaurant_menu, color: AppTheme.primaryDark),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 14),

          // Quantity and Unit
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Serving Quantity *',
                    hintText: '100',
                    prefixIcon: const Icon(Icons.scale, color: AppTheme.primaryDark),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _selectedUnit,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _units.map((u) {
                    return DropdownMenuItem(value: u, child: Text(u));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedUnit = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const Text(
            'Nutritional Values (Given by user)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 10),

          // Calories (Primary)
          TextField(
            controller: _caloriesController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Calories (kcal) *',
              hintText: 'e.g. 250',
              prefixIcon: const Icon(Icons.local_fire_department, color: Colors.orange),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),

          // Macros Row: Protein, Carbs, Fat
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _proteinController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Protein (g)',
                    hintText: '0.0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _carbsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Carbs (g)',
                    hintText: '0.0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _fatController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Fat (g)',
                    hintText: '0.0',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Fiber
          TextField(
            controller: _fiberController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Fiber (g) - Optional',
              hintText: '0.0',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),

          // Add to multi-item plate button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _addItemToStaged,
              icon: const Icon(Icons.add, color: AppTheme.primaryDark),
              label: const Text('+ Add Another Item to Meal', style: TextStyle(color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
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
              'Items in this Meal (${_stagedItems.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            TextButton(
              onPressed: () => setState(() => _stagedItems.clear()),
              child: const Text('Clear All', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._stagedItems.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${item.quantity.toStringAsFixed(0)} ${item.unit} • ${item.estimatedCalories.toStringAsFixed(0)} kcal • P: ${item.protein}g C: ${item.carbohydrates}g F: ${item.fat}g',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(idx),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNutritionSummaryCard(double calories, double protein, double carbs, double fat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meal Summary',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${calories.toStringAsFixed(0)} kcal',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMacroPill('Protein', '${protein.toStringAsFixed(1)}g', Colors.blue),
              _buildMacroPill('Carbs', '${carbs.toStringAsFixed(1)}g', Colors.orange),
              _buildMacroPill('Fat', '${fat.toStringAsFixed(1)}g', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
      ],
    );
  }
}

