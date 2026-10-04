import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum MacroFocus { calories, protein, carbs, fat, fiber }

/// Premium Futuristic Health HUD Circular Nutrition & Calorie Tracker
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
  late AnimationController _waveController;

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
      duration: const Duration(seconds: 36),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _appearController.dispose();
    _pulseController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
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

  String _formatNumber(num number) {
    return number.round().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final calTarget = widget.targetCalories > 0 ? widget.targetCalories : 2000.0;
    final calCurrent = widget.currentCalories.clamp(0.0, calTarget * 2.5);
    final calProgress = (calCurrent / calTarget).clamp(0.0, 1.0);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        // Optimal proportions for mobile HUD
        final totalHeight = math.max(350.0, math.min(390.0, totalWidth * 0.98));
        final orbDiameter = math.min(210.0, totalWidth * 0.52);
        final orbRadius = orbDiameter / 2;
        final centerOffset = Offset(totalWidth / 2, totalHeight / 2);

        // Responsive card dimensions
        final cardWidth = math.min(124.0, totalWidth * 0.32);
        final cardHeight = 56.0;

        return AnimatedBuilder(
          animation: Listenable.merge([
            _appearController,
            _pulseController,
            _rotationController,
            _waveController,
          ]),
          builder: (context, child) {
            final appearVal = CurvedAnimation(
              parent: _appearController,
              curve: Curves.easeOutCubic,
            ).value;
            final pulseVal = _pulseController.value;
            final rotVal = _rotationController.value;
            final waveVal = _waveController.value;

            return SizedBox(
              width: totalWidth,
              height: totalHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Deep Atmospheric Radial Glow
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        width: orbDiameter * 1.5,
                        height: orbDiameter * 1.5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00F59B).withValues(
                                alpha: 0.18 + pulseVal * 0.10,
                              ),
                              blurRadius: 75,
                              spreadRadius: 15,
                            ),
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withValues(
                                alpha: 0.08 + pulseVal * 0.05,
                              ),
                              blurRadius: 110,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Custom HUD Painter (Connectors, Nodes, Energy Waves, Rings, Ticks)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _FuturisticHealthHudPainter(
                        progress: calProgress * appearVal,
                        pulse: pulseVal,
                        rotation: rotVal * 2 * math.pi,
                        wavePhase: waveVal * 2 * math.pi,
                        orbRadius: orbRadius,
                        center: centerOffset,
                        focusedMacro: _focusedMacro,
                        totalSize: Size(totalWidth, totalHeight),
                        cardWidth: cardWidth,
                        cardHeight: cardHeight,
                      ),
                    ),
                  ),

                  // 3. Central Calorie Core Interactive Display
                  Positioned(
                    left: centerOffset.dx - orbRadius,
                    top: centerOffset.dy - orbRadius,
                    width: orbDiameter,
                    height: orbDiameter,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _focusedMacro = MacroFocus.calories;
                          });
                          widget.onTap?.call();
                        },
                        customBorder: const CircleBorder(),
                        splashColor: const Color(0x3300F59B),
                        highlightColor: const Color(0x1A00F59B),
                        child: Center(
                          child: _buildCenterDisplay(
                            calCurrent: calCurrent.round(),
                            calTarget: calTarget.round(),
                            calPct: calPct,
                            focusedMacro: _focusedMacro,
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
                  ),

                  // 4. Macro Cards (Top-Left, Top-Right, Bottom-Left, Bottom-Right)
                  // Top-Left: Protein (Red/Coral)
                  Positioned(
                    left: 2,
                    top: 6,
                    width: cardWidth,
                    height: cardHeight,
                    child: _FuturisticMacroPill(
                      label: 'Protein',
                      value: '${protCurrent.round()}g',
                      target: '${protTarget.round()}g',
                      iconEmoji: '🥩',
                      accentColor: const Color(0xFFFF4D4D),
                      glowColor: const Color(0xFFFF3333),
                      isSelected: _focusedMacro == MacroFocus.protein,
                      onTap: () => _selectMacro(MacroFocus.protein),
                    ),
                  ),

                  // Top-Right: Carbs (Electric Blue)
                  Positioned(
                    right: 2,
                    top: 6,
                    width: cardWidth,
                    height: cardHeight,
                    child: _FuturisticMacroPill(
                      label: 'Carbs',
                      value: '${carbsCurrent.round()}g',
                      target: '${carbsTarget.round()}g',
                      iconEmoji: '🍚',
                      accentColor: const Color(0xFF00B2FF),
                      glowColor: const Color(0xFF0099FF),
                      isSelected: _focusedMacro == MacroFocus.carbs,
                      onTap: () => _selectMacro(MacroFocus.carbs),
                    ),
                  ),

                  // Bottom-Left: Fiber (Emerald Green)
                  Positioned(
                    left: 2,
                    bottom: 6,
                    width: cardWidth,
                    height: cardHeight,
                    child: _FuturisticMacroPill(
                      label: 'Fiber',
                      value: '${fiberCurrent.round()}g',
                      target: '${fiberTarget.round()}g',
                      iconEmoji: '🥦',
                      accentColor: const Color(0xFF00F59B),
                      glowColor: const Color(0xFF00E676),
                      isSelected: _focusedMacro == MacroFocus.fiber,
                      onTap: () => _selectMacro(MacroFocus.fiber),
                    ),
                  ),

                  // Bottom-Right: Fat (Violet Purple)
                  Positioned(
                    right: 2,
                    bottom: 6,
                    width: cardWidth,
                    height: cardHeight,
                    child: _FuturisticMacroPill(
                      label: 'Fat',
                      value: '${fatCurrent.round()}g',
                      target: '${fatTarget.round()}g',
                      iconEmoji: '🥑',
                      accentColor: const Color(0xFFA855F7),
                      glowColor: const Color(0xFF9333EA),
                      isSelected: _focusedMacro == MacroFocus.fat,
                      onTap: () => _selectMacro(MacroFocus.fat),
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

  Widget _buildCenterDisplay({
    required int calCurrent,
    required int calTarget,
    required int calPct,
    required MacroFocus focusedMacro,
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
    if (focusedMacro != MacroFocus.calories) {
      final String macroTitle;
      final int current;
      final int target;
      final int pct;
      final Color color;

      switch (focusedMacro) {
        case MacroFocus.protein:
          macroTitle = 'PROTEIN';
          current = protCurrent;
          target = protTarget;
          pct = protPct;
          color = const Color(0xFFFF4D4D);
          break;
        case MacroFocus.carbs:
          macroTitle = 'CARBS';
          current = carbsCurrent;
          target = carbsTarget;
          pct = carbsPct;
          color = const Color(0xFF00B2FF);
          break;
        case MacroFocus.fat:
          macroTitle = 'FAT';
          current = fatCurrent;
          target = fatTarget;
          pct = fatPct;
          color = const Color(0xFFA855F7);
          break;
        case MacroFocus.fiber:
          macroTitle = 'FIBER';
          current = fiberCurrent;
          target = fiberTarget;
          pct = fiberPct;
          color = const Color(0xFF00F59B);
          break;
        default:
          macroTitle = 'CALORIES';
          current = calCurrent;
          target = calTarget;
          pct = calPct;
          color = AppTheme.neonEmerald;
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            macroTitle,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$current',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 3),
              Text(
                'g',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '/ $target g',
            style: const TextStyle(
              color: Color(0xFF8E9E96),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Text(
              '$pct% completed',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      );
    }

    // Exact Match to Mockup
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _formatNumber(calCurrent),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'kcal',
          style: TextStyle(
            color: AppTheme.neonEmerald,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '/ ${_formatNumber(calTarget)} kcal',
          style: const TextStyle(
            color: Color(0xFF8E9E96),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4.5),
          decoration: BoxDecoration(
            color: const Color(0x2400F59B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x6600F59B),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0x2200F59B),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Text(
            '$calPct% completed',
            style: const TextStyle(
              color: AppTheme.neonEmerald,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// Futuristic Macro Card with 3D emoji and neon outer glow
class _FuturisticMacroPill extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final String iconEmoji;
  final Color accentColor;
  final Color glowColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FuturisticMacroPill({
    required this.label,
    required this.value,
    required this.target,
    required this.iconEmoji,
    required this.accentColor,
    required this.glowColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? glowColor.withValues(alpha: 0.22)
              : const Color(0xE608120D),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? glowColor : glowColor.withValues(alpha: 0.70),
            width: isSelected ? 1.8 : 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: isSelected ? 0.50 : 0.22),
              blurRadius: isSelected ? 18 : 10,
              spreadRadius: isSelected ? 1 : 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 3D Emoji / Food Asset with spherical badge
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: glowColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                iconEmoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      height: 1.0,
                    ),
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

/// Custom Painter for Central Glass Energy Orb, Concentric Rings, Ticks, Segmented Calorie Ring & Integrated Connectors
class _FuturisticHealthHudPainter extends CustomPainter {
  final double progress;
  final double pulse;
  final double rotation;
  final double wavePhase;
  final double orbRadius;
  final Offset center;
  final MacroFocus focusedMacro;
  final Size totalSize;
  final double cardWidth;
  final double cardHeight;

  _FuturisticHealthHudPainter({
    required this.progress,
    required this.pulse,
    required this.rotation,
    required this.wavePhase,
    required this.orbRadius,
    required this.center,
    required this.focusedMacro,
    required this.totalSize,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Integrated Curved Connectors to Cards
    _drawConnectors(canvas);

    // 2. Draw 3D Energy Core Glass Orb (fluid aurora filaments & glowing particles)
    _drawEnergyOrb(canvas);

    // 3. Draw Concentric Inner HUD Dial & Precision Ticks
    _drawInnerHudDial(canvas);

    // 4. Draw Segmented Progress Ring (4 distinct quadrants with neon glow)
    _drawSegmentedProgressRing(canvas);

    // 5. Draw Outer HUD Ring & Rotating Telemetry Arcs
    _drawOuterHudRings(canvas);

    // 6. Draw Glowing Connection Nodes & Quadrant Divider Dots
    _drawConnectorNodes(canvas);
  }

  void _drawConnectors(Canvas canvas) {
    final ringRadius = orbRadius + 18.0;

    // Node contact angles on HUD ring
    const tlAngle = math.pi * 1.20; // Top-Left (~216 deg)
    const trAngle = -math.pi * 0.20; // Top-Right (~-36 deg)
    const blAngle = math.pi * 0.80; // Bottom-Left (~144 deg)
    const brAngle = math.pi * 0.20; // Bottom-Right (~36 deg)

    // Contact points on the HUD ring
    final tlNode = Offset(center.dx + ringRadius * math.cos(tlAngle), center.dy + ringRadius * math.sin(tlAngle));
    final trNode = Offset(center.dx + ringRadius * math.cos(trAngle), center.dy + ringRadius * math.sin(trAngle));
    final blNode = Offset(center.dx + ringRadius * math.cos(blAngle), center.dy + ringRadius * math.sin(blAngle));
    final brNode = Offset(center.dx + ringRadius * math.cos(brAngle), center.dy + ringRadius * math.sin(brAngle));

    // Card anchors
    final tlCardAnchor = Offset(2.0 + cardWidth, 6.0 + cardHeight * 0.65);
    final trCardAnchor = Offset(totalSize.width - 2.0 - cardWidth, 6.0 + cardHeight * 0.65);
    final blCardAnchor = Offset(2.0 + cardWidth, totalSize.height - 6.0 - cardHeight * 0.65);
    final brCardAnchor = Offset(totalSize.width - 2.0 - cardWidth, totalSize.height - 6.0 - cardHeight * 0.65);

    _drawSmoothCurvedPointer(canvas, tlCardAnchor, tlNode, const Color(0xFFFF4D4D));
    _drawSmoothCurvedPointer(canvas, trCardAnchor, trNode, const Color(0xFF00B2FF));
    _drawSmoothCurvedPointer(canvas, blCardAnchor, blNode, const Color(0xFF00F59B));
    _drawSmoothCurvedPointer(canvas, brCardAnchor, brNode, const Color(0xFFA855F7));
  }

  void _drawSmoothCurvedPointer(Canvas canvas, Offset cardAnchor, Offset ringNode, Color color) {
    final path = Path();
    path.moveTo(cardAnchor.dx, cardAnchor.dy);

    final midX = (cardAnchor.dx + ringNode.dx) / 2;
    path.cubicTo(
      midX,
      cardAnchor.dy,
      midX,
      ringNode.dy,
      ringNode.dx,
      ringNode.dy,
    );

    // Glowing blur aura
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35 + pulse * 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(path, glowPaint);

    // Crisp neon laser line
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  void _drawEnergyOrb(Canvas canvas) {
    canvas.save();
    final orbPath = Path()..addOval(Rect.fromCircle(center: center, radius: orbRadius));
    canvas.clipPath(orbPath);

    // Deep Cosmic Obsidian Sphere Base
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF052417),
          const Color(0xFF03140C),
          const Color(0xFF010805),
        ],
        stops: const [0.0, 0.72, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: orbRadius));
    canvas.drawCircle(center, orbRadius, bgPaint);

    // Silk Aurora Wave Filaments
    final waveCount = 6;
    for (int i = 0; i < waveCount; i++) {
      final wavePath = Path();
      final phase = wavePhase + (i * math.pi / 3.0);
      final amplitude = 14.0 + (i * 3.0);
      final freq = 0.024 + (i * 0.005);
      final yOffset = center.dy + (math.sin(phase * 0.6) * (orbRadius * 0.38)) + ((i - 2.5) * 14.0);

      wavePath.moveTo(center.dx - orbRadius, yOffset);
      for (double x = center.dx - orbRadius; x <= center.dx + orbRadius; x += 3.5) {
        final relX = x - center.dx;
        final envelope = math.cos((relX / orbRadius).clamp(-1.0, 1.0) * (math.pi / 2.2));
        final y = yOffset + math.sin(relX * freq + phase) * amplitude * envelope;
        wavePath.lineTo(x, y);
      }

      final waveGlow = Paint()
        ..color = const Color(0xFF00F59B).withValues(alpha: 0.12 + (i % 2 == 0 ? 0.10 : 0.06))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);
      canvas.drawPath(wavePath, waveGlow);

      final waveCore = Paint()
        ..color = const Color(0xFF00F59B).withValues(alpha: 0.28 + (i % 2 == 0 ? 0.20 : 0.12))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1;
      canvas.drawPath(wavePath, waveCore);
    }

    // Floating Bioluminescent 3D Dust Particles
    final particleCount = 14;
    for (int i = 0; i < particleCount; i++) {
      final pAngle = (i * (2 * math.pi / particleCount)) + (wavePhase * 0.35);
      final pDist = (orbRadius * 0.70) * ((math.sin(pAngle * 2.5 + pulse * 2.0) + 1.2) / 2.4);
      final px = center.dx + pDist * math.cos(pAngle);
      final py = center.dy + pDist * math.sin(pAngle);

      final pAlpha = (0.25 + 0.45 * math.sin(wavePhase * 2.5 + i)).clamp(0.0, 1.0);
      final pPaint = Paint()
        ..color = const Color(0xFF00F59B).withValues(alpha: pAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(px, py), (i % 3 == 0) ? 2.2 : 1.4, pPaint);
    }

    // Spherical Glass Rim Caustic Glow
    final rimPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          const Color(0x3300F59B),
          const Color(0xCC00F59B),
        ],
        stops: const [0.72, 0.90, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: orbRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;
    canvas.drawCircle(center, orbRadius - 2.5, rimPaint);

    canvas.restore();

    // Orb Glass Highlight Border
    final edgePaint = Paint()
      ..color = const Color(0x6600F59B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, orbRadius, edgePaint);
  }

  void _drawInnerHudDial(Canvas canvas) {
    final dialRadius = orbRadius + 6.5;

    // Track ring
    final dialPaint = Paint()
      ..color = const Color(0x28FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, dialRadius, dialPaint);

    // 72 Radial Precision Ticks
    const totalTicks = 72;
    for (int i = 0; i < totalTicks; i++) {
      final angle = (i * 2 * math.pi / totalTicks);
      final isMajor = i % 9 == 0;
      final isMedium = i % 3 == 0;

      final tickLen = isMajor ? 5.5 : (isMedium ? 3.5 : 2.0);
      final startR = dialRadius + 1.2;
      final endR = startR + tickLen;

      final pStart = Offset(center.dx + startR * math.cos(angle), center.dy + startR * math.sin(angle));
      final pEnd = Offset(center.dx + endR * math.cos(angle), center.dy + endR * math.sin(angle));

      final tickPaint = Paint()
        ..color = isMajor
            ? const Color(0xEE00F59B)
            : (isMedium ? const Color(0x77FFFFFF) : const Color(0x28FFFFFF))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMajor ? 1.6 : 1.0;

      canvas.drawLine(pStart, pEnd, tickPaint);
    }
  }

  void _drawSegmentedProgressRing(Canvas canvas) {
    final trackRadius = orbRadius + 18.0;
    const strokeW = 9.0;

    // 4 distinct quadrants with 9-degree gaps at dividing points
    const numSegments = 4;
    const segmentSpan = (2 * math.pi) / numSegments;
    const gapAngle = 0.16; // ~9.2 degrees
    const startAngleOffset = -math.pi / 2;

    for (int i = 0; i < numSegments; i++) {
      final segStart = startAngleOffset + (i * segmentSpan) + (gapAngle / 2);
      final segSweep = segmentSpan - gapAngle;

      // Dark emerald recessed track
      final trackBgPaint = Paint()
        ..color = const Color(0x1C00F59B)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeW;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        segStart,
        segSweep,
        false,
        trackBgPaint,
      );

      // Track outer hairline
      final trackBorder = Paint()
        ..color = const Color(0x3500F59B)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius + (strokeW / 2)),
        segStart,
        segSweep,
        false,
        trackBorder,
      );
    }

    // Vibrant Glowing Active Calorie Progress
    if (progress > 0) {
      final totalActiveAngle = progress * (2 * math.pi);

      for (int i = 0; i < numSegments; i++) {
        final segStart = startAngleOffset + (i * segmentSpan) + (gapAngle / 2);
        final segSweep = segmentSpan - gapAngle;
        final segProgressStart = i * segmentSpan;

        if (totalActiveAngle > segProgressStart) {
          final activeSweepInSegment = (totalActiveAngle - segProgressStart).clamp(0.0, segSweep);

          if (activeSweepInSegment > 0) {
            final rect = Rect.fromCircle(center: center, radius: trackRadius);

            // Diffuse Neon Aura
            final glowPaint = Paint()
              ..shader = const SweepGradient(
                colors: [Color(0xFF00F59B), Color(0xFF00E5FF), Color(0xFF00F59B)],
              ).createShader(rect)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = strokeW + 4.5
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

            canvas.drawArc(rect, segStart, activeSweepInSegment, false, glowPaint);

            // Solid Radiant Neon Core
            final activePaint = Paint()
              ..shader = const SweepGradient(
                colors: [Color(0xFF00F59B), Color(0xFF00F0FF), Color(0xFF70FFB8)],
              ).createShader(rect)
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round
              ..strokeWidth = strokeW;

            canvas.drawArc(rect, segStart, activeSweepInSegment, false, activePaint);
          }
        }
      }
    }
  }

  void _drawOuterHudRings(Canvas canvas) {
    final outerRadius = orbRadius + 28.5;

    // Outer subtle baseline track
    final outerPaint = Paint()
      ..color = const Color(0x1F00F59B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, outerRadius, outerPaint);

    // Rotating outer telemetry bracket arcs
    final arcPaint = Paint()
      ..color = const Color(0x5500F59B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;

    canvas.drawArc(Rect.fromCircle(center: center, radius: outerRadius), rotation, math.pi * 0.35, false, arcPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: outerRadius), rotation + math.pi, math.pi * 0.35, false, arcPaint);

    // Orbiting Satellite Beacon Tick
    final satAngle = -rotation * 1.4;
    final satX = center.dx + outerRadius * math.cos(satAngle);
    final satY = center.dy + outerRadius * math.sin(satAngle);

    final satGlow = Paint()
      ..color = const Color(0xFF00F59B).withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
    canvas.drawCircle(Offset(satX, satY), 3.2, satGlow);

    final satCore = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(satX, satY), 1.6, satCore);
  }

  void _drawConnectorNodes(Canvas canvas) {
    final ringRadius = orbRadius + 18.0;

    // 4 Quadrant Divider Beads (Top, Right, Bottom, Left)
    const quadrantAngles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];
    for (final qAngle in quadrantAngles) {
      final qx = center.dx + ringRadius * math.cos(qAngle);
      final qy = center.dy + ringRadius * math.sin(qAngle);

      final qDotPaint = Paint()
        ..color = const Color(0x8800F59B)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(qx, qy), 2.5, qDotPaint);
    }

    // 4 Macro Connector Nodes
    final nodes = [
      (math.pi * 1.20, const Color(0xFFFF4D4D)), // Protein (Top-Left)
      (-math.pi * 0.20, const Color(0xFF00B2FF)), // Carbs (Top-Right)
      (math.pi * 0.80, const Color(0xFF00F59B)),  // Fiber (Bottom-Left)
      (math.pi * 0.20, const Color(0xFFA855F7)),  // Fat (Bottom-Right)
    ];

    for (final node in nodes) {
      final angle = node.$1;
      final color = node.$2;

      final nx = center.dx + ringRadius * math.cos(angle);
      final ny = center.dy + ringRadius * math.sin(angle);

      // Node Glow Halo
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.55 + pulse * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(nx, ny), 7.5, glowPaint);

      // Node Outer Ring
      final nodeBorder = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawCircle(Offset(nx, ny), 4.8, nodeBorder);

      // Node Center Core Dot
      final centerDot = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(nx, ny), 2.6, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _FuturisticHealthHudPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.rotation != rotation ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.focusedMacro != focusedMacro ||
        oldDelegate.orbRadius != orbRadius ||
        oldDelegate.center != center ||
        oldDelegate.cardWidth != cardWidth ||
        oldDelegate.cardHeight != cardHeight;
  }
}
