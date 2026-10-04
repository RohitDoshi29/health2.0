import 'package:flutter/material.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';

class InfoView extends StatelessWidget {
  const InfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('About Heathify'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // App Branding Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const RadialGradient(
                    colors: [
                      Color(0x4400F59B),
                      Color(0x1100F59B),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.neonEmerald.withValues(alpha: 0.6), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.neonEmerald.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  size: 52,
                  color: AppTheme.neonEmerald,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Heathify',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AI-Powered Nutrition & Metabolic Intelligence',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.neonEmerald,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0x2200F59B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x4400F59B)),
                ),
                child: const Text(
                  'Version 1.2.0 (Build 2026)',
                  style: TextStyle(fontSize: 11, color: AppTheme.neonEmerald, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 28),

              // Mission Statement Card
              GlassCard(
                glow: true,
                glowColor: AppTheme.neonEmerald,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x33FFB800),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFFFFB800)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Our Mission',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Heathify combines Google Gemini multimodal vision AI with global food intelligence databases to make nutrition tracking seamless, instantaneous, and highly personalized. Scan any meal to estimate calories, macros, portions, and water in seconds.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Core Technologies Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x33A855F7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, size: 20, color: AppTheme.fatColor),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Core Technologies',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTechRow(
                      icon: Icons.visibility_rounded,
                      iconColor: AppTheme.neonEmerald,
                      title: 'Google Gemini 2.5 Flash Vision',
                      description: 'Real-time meal recognition, portion weight estimation, and spatial visual bounding boxes.',
                    ),
                    const Divider(height: 20, color: Color(0x1FFFFFFF)),
                    _buildTechRow(
                      icon: Icons.qr_code_scanner_rounded,
                      iconColor: AppTheme.carbsColor,
                      title: 'OpenFoodFacts Global API',
                      description: 'Instant barcode lookup with verified macronutrients, ingredient analysis, and Nutri-Scores.',
                    ),
                    const Divider(height: 20, color: Color(0x1FFFFFFF)),
                    _buildTechRow(
                      icon: Icons.water_drop_rounded,
                      iconColor: AppTheme.waterColor,
                      title: 'Smart Hydration Engine',
                      description: 'Adaptive daily water target calculations with dynamic wave visualization and quick logging.',
                    ),
                    const Divider(height: 20, color: Color(0x1FFFFFFF)),
                    _buildTechRow(
                      icon: Icons.cloud_sync_rounded,
                      iconColor: AppTheme.neonTeal,
                      title: 'Offline-First Synchronization',
                      description: 'Automatic SQLite local caching and seamless background sync queues when reconnecting.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // System Diagnostics Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x3300B2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.dns_rounded, size: 20, color: AppTheme.carbsColor),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'System Diagnostics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildDiagRow('Backend API Host', ApiConstants.baseUrl),
                    _buildDiagRow('Environment', 'Active • Connected 🟢'),
                    _buildDiagRow('Database Backend', 'PostgreSQL (asyncpg) + SQLite'),
                    _buildDiagRow('Vision AI Model', 'Gemini 2.5 Flash Vision'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Medical & Nutrition Disclaimer Card
              GlassCard(
                borderColor: const Color(0x44EF4444),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0x33EF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.health_and_safety_rounded, size: 20, color: Color(0xFFFF5252)),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Medical & Nutrition Disclaimer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'All nutrition values, calorie counts, and food identifications in Heathify are estimates generated by AI models and nutritional databases. They are designed for lifestyle, fitness, and self-monitoring purposes and should not be used as clinical medical prescriptions or formal diagnoses.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Built with ',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  Icon(Icons.favorite, size: 14, color: AppTheme.neonEmerald),
                  Text(
                    ' for Healthy Living & Longevity',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTechRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiagRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

