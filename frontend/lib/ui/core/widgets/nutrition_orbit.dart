import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum MacroFocus { calories, protein, carbs, fat, fiber }

class NutritionOrbit extends StatefulWidget {
  final double currentCalories;
  final double targetCalories;
  final double currentProtein;
  final double targetProtein;
  final double currentCarbs;
  final double targetCarbs;
  final double currentFat;
  final double targetFat;
  final double currentFiber;
  final double targetFiber;
  final VoidCallback? onTap;

  const NutritionOrbit({
    super.key,
    required this.currentCalories,
    required this.targetCalories,
    required this.currentProtein,
    required this.targetProtein,
    required this.currentCarbs,
    required this.targetCarbs,
    required this.currentFat,
    required this.targetFat,
    this.currentFiber = 0,
    this.targetFiber = 30,
    this.onTap,
  });

  @override
  State<NutritionOrbit> createState() => _NutritionOrbitState();
}

class _NutritionOrbitState extends State<NutritionOrbit>
    with TickerProviderStateMixin {
  late AnimationController _appearController;
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  MacroFocus _focusedMacro = MacroFocus.calories;

  @override
  void initState() {
    super.initState();
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _appearController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _selectMacro(MacroFocus focus) {
    setState(() {
      if (_focusedMacro == focus) {
        _focusedMacro = MacroFocus.calories;
      } else {
        _focusedMacro = focus;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final calTarget = widget.targetCalories > 0 ? widget.targetCalories : 2000.0;
    final calCurrent = widget.currentCalories.clamp(0.0, calTarget * 2.0);
    final calProgress = (calCurrent / calTarget).clamp(0.0, 1.0);
    final calRemaining = math.max(0, (calTarget - calCurrent).round());
    final calPct = (calProgress * 100).round();

    // Protein
    final protTarget = widget.targetProtein > 0 ? widget.targetProtein : 120.0;
    final protCurrent = widget.currentProtein;
    final protPct = ((protCurrent / protTarget) * 100).round();

    // Carbs
    final carbsTarget = widget.targetCarbs > 0 ? widget.targetCarbs : 250.0;
    final carbsCurrent = widget.currentCarbs;
    final carbsPct = ((carbsCurrent / carbsTarget) * 100).round();

    // Fat
    final fatTarget = widget.targetFat > 0 ? widget.targetFat : 65.0;
    final fatCurrent = widget.currentFat;
    final fatPct = ((fatCurrent / fatTarget) * 100).round();

    // Fiber
    final fiberTarget = widget.targetFiber > 0 ? widget.targetFiber : 30.0;
    final fiberCurrent = widget.currentFiber;
    final fiberPct = ((fiberCurrent / fiberTarget) * 100).round();

    return AnimatedBuilder(
      animation: Listenable.merge([_appearController, _pulseController, _rotationController]),
      builder: (context, child) {
        final appearVal = CurvedAnimation(
          parent: _appearController,
          curve: Curves.easeOutCubic,
        ).value;
        final pulseVal = _pulseController.value;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double availableWidth = constraints.maxWidth;
            final double orbitSize = math.min(availableWidth, 340.0);
            final double radius = orbitSize / 2;

            return Center(
              child: SizedBox(
                width: orbitSize,
                height: orbitSize + 50,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Glowing ambient halo
                    Positioned(
                      top: 20,
                      child: Container(
                        width: orbitSize * 0.7,
                        height: orbitSize * 0.7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getGlowColor().withValues(alpha: 0.18 + pulseVal * 0.08),
                              blurRadius: 45,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Custom Orbit Canvas
                    Positioned(
                      top: 20,
                      child: CustomPaint(
                        size: Size(orbitSize, orbitSize),
                        painter: _OrbitRingPainter(
                          progress: calProgress * appearVal,
                          pulse: pulseVal,
                          rotation: _rotationController.value * 2 * math.pi,
                          focus: _focusedMacro,
                        ),
                      ),
                    ),

                    // Central Interactive Data Hub
                    Positioned(
                      top: 20 + radius - 65,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _focusedMacro = MacroFocus.calories;
                          });
                          widget.onTap?.call();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: _buildCenterDisplay(
                            calCurrent: calCurrent.round(),
                            calTarget: calTarget.round(),
                            calRemaining: calRemaining,
                            calPct: calPct,
                            protCurrent: protCurrent.round(),
                            protTarget: protTarget.round(),
                            protPct: protPct,
                            carbsCurrent: carbsCurrent.round(),
                            carbsTarget: carbsTarget.round(),
                            carbsPct: carbsPct,
                            fatCurrent: fatCurrent.round(),
                            fatTarget: fatTarget.round(),
                            fatPct: fatPct,
                            fiberCurrent: fiberCurrent.round(),
                            fiberTarget: fiberTarget.round(),
                            fiberPct: fiberPct,
                          ),
                        ),
                      ),
                    ),

                    // Orbital Nodes (Protein, Carbs, Fat, Fiber)
                    ..._buildMacroNodes(
                      orbitRadius: radius * 0.86,
                      centerOffset: const Offset(0, 0),
                      protCurrent: protCurrent.round(),
                      protPct: protPct,
                      carbsCurrent: carbsCurrent.round(),
                      carbsPct: carbsPct,
                      fatCurrent: fatCurrent.round(),
                      fatPct: fatPct,
                      fiberCurrent: fiberCurrent.round(),
                      fiberPct: fiberPct,
                      orbitCenterY: 20 + radius,
                      orbitCenterX: orbitSize / 2,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getGlowColor() {
    switch (_focusedMacro) {
      case MacroFocus.protein:
        return AppTheme.proteinColor;
      case MacroFocus.carbs:
        return AppTheme.carbsColor;
      case MacroFocus.fat:
        return AppTheme.fatColor;
      case MacroFocus.fiber:
        return AppTheme.fiberColor;
      case MacroFocus.calories:
        return AppTheme.primaryGreen;
    }
  }

  Widget _buildCenterDisplay({
    required int calCurrent,
    required int calTarget,
    required int calRemaining,
    required int calPct,
    required int protCurrent,
    required int protTarget,
    required int protPct,
    required int carbsCurrent,
    required int carbsTarget,
    required int carbsPct,
    required int fatCurrent,
    required int fatTarget,
    required int fatPct,
    required int fiberCurrent,
    required int fiberTarget,
    required int fiberPct,
  }) {
    switch (_focusedMacro) {
      case MacroFocus.protein:
        return _CenterMetricBox(
          key: const ValueKey('protein'),
          title: 'PROTEIN',
          value: '$protCurrent',
          unit: 'g',
          target: '/ $protTarget g',
          subtext: '$protPct% of goal',
          accentColor: AppTheme.proteinColor,
        );
      case MacroFocus.carbs:
        return _CenterMetricBox(
          key: const ValueKey('carbs'),
          title: 'CARBOHYDRATES',
          value: '$carbsCurrent',
          unit: 'g',
          target: '/ $carbsTarget g',
          subtext: '$carbsPct% of goal',
          accentColor: AppTheme.carbsColor,
        );
      case MacroFocus.fat:
        return _CenterMetricBox(
          key: const ValueKey('fat'),
          title: 'HEALTHY FATS',
          value: '$fatCurrent',
          unit: 'g',
          target: '/ $fatTarget g',
          subtext: '$fatPct% of goal',
          accentColor: AppTheme.fatColor,
        );
      case MacroFocus.fiber:
        return _CenterMetricBox(
          key: const ValueKey('fiber'),
          title: 'DIETARY FIBER',
          value: '$fiberCurrent',
          unit: 'g',
          target: '/ $fiberTarget g',
          subtext: '$fiberPct% of goal',
          accentColor: AppTheme.fiberColor,
        );
      case MacroFocus.calories:
        return Container(
          key: const ValueKey('calories'),
          width: 130,
          height: 130,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(calCurrent),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '/ ${_formatNumber(calTarget)} kcal',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$calPct% completed',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  List<Widget> _buildMacroNodes({
    required double orbitRadius,
    required Offset centerOffset,
    required int protCurrent,
    required int protPct,
    required int carbsCurrent,
    required int carbsPct,
    required int fatCurrent,
    required int fatPct,
    required int fiberCurrent,
    required int fiberPct,
    required double orbitCenterY,
    required double orbitCenterX,
  }) {
    // 4 positions around the circle: Top-Left (Protein), Top-Right (Carbs), Bottom-Right (Fat), Bottom-Left (Fiber)
    final nodes = [
      _MacroNodeData(
        type: MacroFocus.protein,
        label: 'Protein',
        value: '${protCurrent}g',
        color: AppTheme.proteinColor,
        angle: - math.pi * 0.75, // Top-Left
      ),
      _MacroNodeData(
        type: MacroFocus.carbs,
        label: 'Carbs',
        value: '${carbsCurrent}g',
        color: AppTheme.carbsColor,
        angle: - math.pi * 0.25, // Top-Right
      ),
      _MacroNodeData(
        type: MacroFocus.fat,
        label: 'Fat',
        value: '${fatCurrent}g',
        color: AppTheme.fatColor,
        angle: math.pi * 0.28, // Bottom-Right
      ),
      _MacroNodeData(
        type: MacroFocus.fiber,
        label: 'Fiber',
        value: '${fiberCurrent}g',
        color: AppTheme.fiberColor,
        angle: math.pi * 0.72, // Bottom-Left
      ),
    ];

    return nodes.map((node) {
      final isSelected = _focusedMacro == node.type;
      final x = orbitCenterX + orbitRadius * math.cos(node.angle);
      final y = orbitCenterY + orbitRadius * math.sin(node.angle);

      return Positioned(
        left: x - 42,
        top: y - 24,
        child: GestureDetector(
          onTap: () => _selectMacro(node.type),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 9,
              vertical: isSelected ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? node.color.withValues(alpha: 0.25)
                  : const Color(0xE613201B),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? node.color : node.color.withValues(alpha: 0.35),
                width: isSelected ? 1.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? node.color.withValues(alpha: 0.4)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.label,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      node.value,
                      style: TextStyle(
                        color: isSelected ? node.color : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }
}

class _MacroNodeData {
  final MacroFocus type;
  final String label;
  final String value;
  final Color color;
  final double angle;

  _MacroNodeData({
    required this.type,
    required this.label,
    required this.value,
    required this.color,
    required this.angle,
  });
}

class _CenterMetricBox extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String target;
  final String subtext;
  final Color accentColor;

  const _CenterMetricBox({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.target,
    required this.subtext,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 130,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                unit,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Text(
            target,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitRingPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double rotation;
  final MacroFocus focus;

  _OrbitRingPainter({
    required this.progress,
    required this.pulse,
    required this.rotation,
    required this.focus,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.width / 2) - 16;
    final innerRadius = outerRadius - 16;

    // Background track ring
    final bgPaint = Paint()
      ..color = const Color(0x1F00E676)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;

    canvas.drawCircle(center, outerRadius, bgPaint);

    // Subtle dotted decorative ring
    final dotPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(center, innerRadius + 4, dotPaint);

    // Dynamic color gradient based on focus
    final List<Color> arcColors;
    switch (focus) {
      case MacroFocus.protein:
        arcColors = [const Color(0xFFFF8A80), AppTheme.proteinColor];
        break;
      case MacroFocus.carbs:
        arcColors = [const Color(0xFF82B1FF), AppTheme.carbsColor];
        break;
      case MacroFocus.fat:
        arcColors = [const Color(0xFFEA80FC), AppTheme.fatColor];
        break;
      case MacroFocus.fiber:
        arcColors = [const Color(0xFFB9F6CA), AppTheme.fiberColor];
        break;
      case MacroFocus.calories:
        arcColors = [const Color(0xFF00B0FF), const Color(0xFF00E676), const Color(0xFF76FF03)];
        break;
    }

    if (progress > 0) {
      final sweepAngle = 2 * math.pi * progress;
      final startAngle = -math.pi / 2;

      // Glow paint behind the arc
      final glowPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          colors: arcColors,
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
        glowPaint,
      );

      // Main active arc
      final activePaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: 2 * math.pi,
          colors: arcColors,
          transform: GradientRotation(startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: outerRadius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 9;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );

      // Glowing dot at the tip
      final tipAngle = startAngle + sweepAngle;
      final tipX = center.dx + outerRadius * math.cos(tipAngle);
      final tipY = center.dy + outerRadius * math.sin(tipAngle);

      final tipGlowPaint = Paint()
        ..color = arcColors.last.withValues(alpha: 0.5)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(tipX, tipY), 7, tipGlowPaint);

      final tipPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(tipX, tipY), 4.5, tipPaint);
    }

    // Floating orbital sci-fi particles
    final particleCount = 6;
    for (int i = 0; i < particleCount; i++) {
      final pAngle = rotation + (i * (2 * math.pi / particleCount));
      final pRadius = innerRadius + (math.sin(pAngle * 2 + pulse) * 4);
      final px = center.dx + pRadius * math.cos(pAngle);
      final py = center.dy + pRadius * math.sin(pAngle);

      final particlePaint = Paint()
        ..color = AppTheme.primaryGreen.withValues(alpha: 0.3 + (i % 2 == 0 ? 0.3 : 0.1))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(px, py), 1.8, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.rotation != rotation ||
        oldDelegate.focus != focus;
  }
}
