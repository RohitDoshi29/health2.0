import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/portion_model.dart';

class PortionPickerWidget extends StatefulWidget {
  final List<PortionGuideModel> portions;
  final double initialMultiplier;
  final String? initialSelectedPortionId;
  final double referenceCaloriesPer100g;
  final void Function(
    PortionGuideModel selectedPortion,
    double multiplier,
    double totalGrams,
    double totalCalories,
  )? onPortionChanged;

  const PortionPickerWidget({
    super.key,
    required this.portions,
    this.initialMultiplier = 1.0,
    this.initialSelectedPortionId,
    this.referenceCaloriesPer100g = 150.0,
    this.onPortionChanged,
  });

  @override
  State<PortionPickerWidget> createState() => _PortionPickerWidgetState();
}

class _PortionPickerWidgetState extends State<PortionPickerWidget> {
  late double _multiplier;
  late PortionGuideModel _selectedPortion;

  // Standard fallback portions if food doesn't have custom portions
  static final List<PortionGuideModel> defaultPortions = [
    const PortionGuideModel(
      id: 'def_katori',
      foodCanonicalName: 'generic',
      label: '1 katori',
      grams: 150.0,
      imageAsset: 'assets/portions/katori.png',
    ),
    const PortionGuideModel(
      id: 'def_roti',
      foodCanonicalName: 'generic',
      label: '1 roti',
      grams: 40.0,
      imageAsset: 'assets/portions/roti.png',
    ),
    const PortionGuideModel(
      id: 'def_slice',
      foodCanonicalName: 'generic',
      label: '1 slice',
      grams: 100.0,
      imageAsset: 'assets/portions/slice.png',
    ),
    const PortionGuideModel(
      id: 'def_cup',
      foodCanonicalName: 'generic',
      label: '1 cup',
      grams: 240.0,
      imageAsset: 'assets/portions/cup.png',
    ),
    const PortionGuideModel(
      id: 'def_bowl',
      foodCanonicalName: 'generic',
      label: '1 bowl',
      grams: 250.0,
      imageAsset: 'assets/portions/bowl.png',
    ),
    const PortionGuideModel(
      id: 'def_piece',
      foodCanonicalName: 'generic',
      label: '1 piece',
      grams: 50.0,
      imageAsset: 'assets/portions/piece.png',
    ),
    const PortionGuideModel(
      id: 'def_glass',
      foodCanonicalName: 'generic',
      label: '1 glass',
      grams: 240.0,
      imageAsset: 'assets/portions/glass.png',
    ),
    const PortionGuideModel(
      id: 'def_tbsp',
      foodCanonicalName: 'generic',
      label: '1 tbsp',
      grams: 15.0,
      imageAsset: 'assets/portions/tbsp.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _multiplier = widget.initialMultiplier > 0 ? widget.initialMultiplier : 1.0;
    final available = widget.portions.isNotEmpty ? widget.portions : defaultPortions;
    if (widget.initialSelectedPortionId != null) {
      _selectedPortion = available.firstWhere(
        (p) => p.id == widget.initialSelectedPortionId,
        orElse: () => available.first,
      );
    } else {
      _selectedPortion = available.first;
    }
  }

  @override
  void didUpdateWidget(covariant PortionPickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.portions != oldWidget.portions && widget.portions.isNotEmpty) {
      setState(() {
        _selectedPortion = widget.portions.first;
      });
      _notify();
    }
  }

  void _notify() {
    final rawGrams = _selectedPortion.grams * _multiplier;
    final cappedGrams = rawGrams > 1200.0 ? 1200.0 : rawGrams;
    final cals = (widget.referenceCaloriesPer100g * (cappedGrams / 100.0)).roundToDouble();
    widget.onPortionChanged?.call(_selectedPortion, _multiplier, cappedGrams, cals);
  }

  void _decrease() {
    if (_multiplier > 0.5) {
      setState(() {
        _multiplier = (_multiplier - 0.5);
      });
      _notify();
    }
  }

  void _increase() {
    if (_multiplier < 10.0) {
      setState(() {
        _multiplier = (_multiplier + 0.5);
      });
      _notify();
    }
  }

  IconData _getIconForPortion(PortionGuideModel portion) {
    final l = portion.label.toLowerCase();
    final c = portion.foodCanonicalName.toLowerCase();
    if (l.contains('katori') || c.contains('rice') || c.contains('dal')) {
      return Icons.rice_bowl_rounded;
    }
    if (l.contains('roti') || l.contains('chapati') || l.contains('paratha')) {
      return Icons.blur_circular_rounded;
    }
    if (l.contains('slice') || c.contains('pizza')) {
      return Icons.local_pizza_outlined;
    }
    if (l.contains('glass') || c.contains('milk')) {
      return Icons.local_drink_rounded;
    }
    if (l.contains('cup') || c.contains('coffee') || c.contains('tea')) {
      return Icons.coffee_rounded;
    }
    if (l.contains('egg')) {
      return Icons.egg_outlined;
    }
    if (l.contains('tbsp') || l.contains('tsp') || c.contains('ghee')) {
      return Icons.restaurant_rounded;
    }
    if (l.contains('bowl') || c.contains('soup') || c.contains('salad')) {
      return Icons.soup_kitchen_rounded;
    }
    if (l.contains('plate')) {
      return Icons.dinner_dining_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.portions.isNotEmpty ? widget.portions : defaultPortions;
    final rawGrams = _selectedPortion.grams * _multiplier;
    final isCapped = rawGrams > 1200.0;
    final totalGrams = isCapped ? 1200.0 : rawGrams;
    final totalCalories = (widget.referenceCaloriesPer100g * (totalGrams / 100.0)).roundToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Portion Guide',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            if (isCapped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x22FF8A00),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0x66FF8A00)),
                ),
                child: const Text(
                  'Capped at max 1200g',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF9E33),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Portion guide chip carousel
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: available.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final portion = available[idx];
              final isSelected = portion.id == _selectedPortion.id;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPortion = portion;
                  });
                  _notify();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0x2800F59B) : const Color(0x18FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppTheme.neonEmerald : const Color(0x22FFFFFF),
                      width: isSelected ? 1.6 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0x3300F59B) : const Color(0x22FFFFFF),
                          shape: BoxShape.circle,
                        ),
                        child: portion.imageAsset != null
                            ? ClipOval(
                                child: Image.asset(
                                  portion.imageAsset!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _getIconForPortion(portion),
                                    size: 20,
                                    color: isSelected ? AppTheme.neonEmerald : AppTheme.textSecondary,
                                  ),
                                ),
                              )
                            : Icon(
                                _getIconForPortion(portion),
                                size: 20,
                                color: isSelected ? AppTheme.neonEmerald : AppTheme.textSecondary,
                              ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            portion.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? AppTheme.neonEmerald : AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${portion.grams.toStringAsFixed(0)} g',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Stepper and live calculation card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0x18FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x22FFFFFF)),
          ),
          child: Row(
            children: [
              // Stepper
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 22),
                    color: _multiplier > 0.5 ? AppTheme.textPrimary : AppTheme.textMuted,
                    onPressed: _multiplier > 0.5 ? _decrease : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 42),
                    alignment: Alignment.center,
                    child: Text(
                      '${_multiplier.toStringAsFixed(1).replaceAll('.0', '')}×',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    color: _multiplier < 10.0 ? AppTheme.neonEmerald : AppTheme.textMuted,
                    onPressed: _multiplier < 10.0 ? _increase : null,
                  ),
                ],
              ),
              const Spacer(),
              // Live grams and kcal display
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalGrams.toStringAsFixed(0)} g',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '≈ ${totalCalories.toStringAsFixed(0)} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.neonEmerald,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
