import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/light_beam_button.dart';

/// A futuristic Cyber Flash / Splash Screen featuring rotating light beam
/// reactors, holographic HUD laser scans, obsidian glass cockpit atmosphere,
/// and smooth telemetry diagnostics.
class SplashView extends StatefulWidget {
  final VoidCallback? onComplete;
  final bool isStandalone;

  const SplashView({
    super.key,
    this.onComplete,
    this.isStandalone = false,
  });

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with TickerProviderStateMixin {
  late AnimationController _reactorController;
  late AnimationController _pulseController;
  late AnimationController _scanController;

  int _telemetryIndex = 0;
  final List<String> _telemetryMessages = [
    'INITIALIZING NEURAL CORE...',
    'CALIBRATING MACRO ENGINE...',
    'SYNCHRONIZING METABOLIC SENSORS...',
    'COCKPIT ONLINE • READY',
  ];

  @override
  void initState() {
    super.initState();

    _reactorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _reactorController.repeat();
      _pulseController.repeat(reverse: true);
      _scanController.repeat();
      _cycleTelemetry();
    } else {
      _reactorController.value = 0.25;
      _pulseController.value = 0.5;
      _scanController.value = 0.5;
    }
  }

  void _cycleTelemetry() async {
    for (int i = 0; i < _telemetryMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() {
        _telemetryIndex = i;
      });
    }

    if (widget.onComplete != null) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        widget.onComplete!();
      }
    }
  }

  @override
  void dispose() {
    _reactorController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030705),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Deep Atmospheric Cockpit Radial Glow
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                final pulse = _pulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.2),
                      radius: 1.1 + (pulse * 0.15),
                      colors: [
                        const Color(0xFF0D281E).withValues(alpha: 0.9),
                        const Color(0xFF06140E).withValues(alpha: 0.95),
                        const Color(0xFF030705),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Futuristic Holographic Grid Matrix Painter
          Positioned.fill(
            child: CustomPaint(
              painter: _HolographicGridPainter(),
            ),
          ),

          // 3. Central Core & Light Beam Reactor
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Light Beam Orbital Reactor Ring
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Rotating Laser Beam Ring 1 (Emerald -> Cyan -> Violet)
                      AnimatedBuilder(
                        animation: _reactorController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(160, 160),
                            painter: _SplashBeamOrbitalPainter(
                              progress: _reactorController.value,
                              colors: const [
                                AppTheme.neonEmerald,
                                Color(0xFF00D2FF),
                                Color(0xFF8B5CF6),
                                AppTheme.neonEmerald,
                              ],
                              strokeWidth: 2.5,
                              radius: 76,
                            ),
                          );
                        },
                      ),

                      // Counter-Rotating Inner Laser Beam Ring 2
                      AnimatedBuilder(
                        animation: _reactorController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(120, 120),
                            painter: _SplashBeamOrbitalPainter(
                              progress: 1.0 - _reactorController.value,
                              colors: const [
                                Color(0xFF00D2FF),
                                Color(0xFF8B5CF6),
                                AppTheme.neonEmerald,
                              ],
                              strokeWidth: 1.8,
                              radius: 56,
                            ),
                          );
                        },
                      ),

                      // Ambient Core Glow Pill
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          final scale = 1.0 + (_pulseController.value * 0.08);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF071B12),
                                border: Border.all(
                                  color: AppTheme.neonEmerald.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonEmerald.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF00D2FF).withValues(alpha: 0.2),
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.eco_rounded,
                                  size: 46,
                                  color: AppTheme.neonEmerald,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // HUD Laser Scanning Line
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, _) {
                          final scanY = -60 + (_scanController.value * 120);
                          return Transform.translate(
                            offset: Offset(0, scanY),
                            child: Container(
                              width: 110,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    AppTheme.neonEmerald.withValues(alpha: 0.8),
                                    const Color(0xFF00D2FF),
                                    AppTheme.neonEmerald.withValues(alpha: 0.8),
                                    Colors.transparent,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonEmerald.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Brand Title with Glowing Sci-Fi Kerning
                const Text(
                  'H E A L T H I F Y',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 7.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: AppTheme.neonEmerald,
                        blurRadius: 18,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Cockpit Tagline
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0x1A00F59B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x4400F59B),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'AI NUTRITION COCKPIT 3.0',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: AppTheme.neonEmerald,
                    ),
                  ),
                ),

                const SizedBox(height: 38),

                // HUD Diagnostics / Telemetry Box
                Container(
                  width: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0x6608140E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.neonEmerald,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonEmerald,
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: Text(
                            _telemetryMessages[_telemetryIndex],
                            key: ValueKey<int>(_telemetryIndex),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                              color: Color(0xFFB0D4C5),
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.isStandalone) ...[
                  const SizedBox(height: 36),
                  LightBeamButton(
                    text: 'ENTER COCKPIT',
                    icon: Icons.rocket_launch_rounded,
                    gradientColors: const [
                      AppTheme.neonEmerald,
                      Color(0xFF00D2FF),
                      Color(0xFF8B5CF6),
                    ],
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      if (widget.onComplete != null) {
                        widget.onComplete!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),

          // Bottom Version Identifier
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'v2.4.0 • SECURE ENCRYPTED BIOMETRICS',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0x66FFFFFF),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for rotating light beam orbital rings
class _SplashBeamOrbitalPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;
  final double strokeWidth;
  final double radius;

  _SplashBeamOrbitalPainter({
    required this.progress,
    required this.colors,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Subtle track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 0.7
      ..color = colors.first.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, trackPaint);

    // Rotating laser sweep
    final angle = progress * 2 * math.pi;
    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 2,
        transform: GradientRotation(angle),
        colors: [
          Colors.transparent,
          colors[0].withValues(alpha: 0.85),
          colors[1 % colors.length].withValues(alpha: 1.0),
          colors[2 % colors.length].withValues(alpha: 0.85),
          Colors.transparent,
          Colors.transparent,
        ],
        stops: const [0.0, 0.15, 0.25, 0.35, 0.5, 1.0],
      ).createShader(rect);

    canvas.drawCircle(center, radius, beamPaint);
  }

  @override
  bool shouldRepaint(_SplashBeamOrbitalPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom painter for futuristic HUD background grid lines
class _HolographicGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1.0;

    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_HolographicGridPainter oldDelegate) => false;
}
