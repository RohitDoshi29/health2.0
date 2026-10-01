import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChartDataPoint {
  final String label;
  final double value;
  final String dateStr;

  const ChartDataPoint({
    required this.label,
    required this.value,
    required this.dateStr,
  });
}

class InteractiveWaveChart extends StatefulWidget {
  final List<ChartDataPoint> points;
  final double targetValue;
  final Color primaryColor;
  final String unit;
  final double height;

  const InteractiveWaveChart({
    super.key,
    required this.points,
    this.targetValue = 2000,
    this.primaryColor = AppTheme.primaryGreen,
    this.unit = 'kcal',
    this.height = 190,
  });

  @override
  State<InteractiveWaveChart> createState() => _InteractiveWaveChartState();
}

class _InteractiveWaveChartState extends State<InteractiveWaveChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPos, Size size) {
    if (widget.points.isEmpty) return;
    final step = size.width / (widget.points.length - 1).clamp(1, 999);
    final index = ((localPos.dx + (step / 2)) / step).floor().clamp(0, widget.points.length - 1);
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'No data available',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    final activePoint = _selectedIndex != null ? widget.points[_selectedIndex!] : widget.points.last;

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final animProgress = CurvedAnimation(
          parent: _animController,
          curve: Curves.easeOutCubic,
        ).value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floating Tooltip Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activePoint.dateStr,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          activePoint.value.round().toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.unit,
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x3310B981),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Target: ${widget.targetValue.round()} ${widget.unit}',
                    style: TextStyle(
                      color: widget.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Wave Chart Canvas
            GestureDetector(
              onPanDown: (d) => _handleTouch(d.localPosition, Size(double.infinity, widget.height)),
              onPanUpdate: (d) => _handleTouch(d.localPosition, Size(double.infinity, widget.height)),
              onTapUp: (d) => _handleTouch(d.localPosition, Size(double.infinity, widget.height)),
              child: SizedBox(
                height: widget.height,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WaveChartPainter(
                    points: widget.points,
                    targetValue: widget.targetValue,
                    primaryColor: widget.primaryColor,
                    progress: animProgress,
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _WaveChartPainter extends CustomPainter {
  final List<ChartDataPoint> points;
  final double targetValue;
  final Color primaryColor;
  final double progress;
  final int? selectedIndex;

  _WaveChartPainter({
    required this.points,
    required this.targetValue,
    required this.primaryColor,
    required this.progress,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double bottomPadding = 24.0;
    final double topPadding = 12.0;
    final double chartHeight = size.height - bottomPadding - topPadding;
    final double chartWidth = size.width;

    double maxVal = points.map((p) => p.value).fold(targetValue * 1.2, math.max);
    if (maxVal == 0) maxVal = 100;

    final stepX = chartWidth / (points.length - 1).clamp(1, 999);

    final List<Offset> pixelPoints = [];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalizedY = (points[i].value / maxVal).clamp(0.0, 1.0);
      final y = topPadding + chartHeight * (1 - (normalizedY * progress));
      pixelPoints.add(Offset(x, y));
    }

    // Draw Target Dashed Line
    final targetY = topPadding + chartHeight * (1 - ((targetValue / maxVal) * progress));
    final targetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double currentX = 0;
    while (currentX < chartWidth) {
      canvas.drawLine(
        Offset(currentX, targetY),
        Offset(math.min(currentX + dashWidth, chartWidth), targetY),
        targetPaint,
      );
      currentX += dashWidth + dashSpace;
    }

    // Build Smooth Spline Path
    final path = Path();
    path.moveTo(pixelPoints.first.dx, pixelPoints.first.dy);

    for (int i = 0; i < pixelPoints.length - 1; i++) {
      final p0 = pixelPoints[i];
      final p1 = pixelPoints[i + 1];
      final controlX1 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY1 = p0.dy;
      final controlX2 = p0.dx + (p1.dx - p0.dx) / 2;
      final controlY2 = p1.dy;

      path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
    }

    // Draw Gradient Area Fill below curve
    final fillPath = Path.from(path)
      ..lineTo(pixelPoints.last.dx, topPadding + chartHeight)
      ..lineTo(pixelPoints.first.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withValues(alpha: 0.35),
          primaryColor.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, topPadding, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Draw Glowing Neon Stroke Line
    final strokeGlowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawPath(path, strokeGlowPaint);

    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw Bottom Date Labels and Nodes
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final p = pixelPoints[i];
      final isSelected = selectedIndex == i;

      // Vertical guideline if selected
      if (isSelected) {
        final guidePaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(p.dx, topPadding), Offset(p.dx, topPadding + chartHeight), guidePaint);
      }

      // Point circle
      final circlePaint = Paint()
        ..color = isSelected ? Colors.white : primaryColor
        ..style = PaintingStyle.fill;

      if (isSelected) {
        canvas.drawCircle(p, 6.0, Paint()..color = primaryColor.withValues(alpha: 0.5));
      }
      canvas.drawCircle(p, isSelected ? 4.5 : 3.0, circlePaint);

      // Label
      textPainter.text = TextSpan(
        text: points[i].label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(p.dx - (textPainter.width / 2), size.height - bottomPadding + 6));
    }
  }

  @override
  bool shouldRepaint(covariant _WaveChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.points != points;
  }
}
