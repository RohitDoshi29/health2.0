import 'package:flutter/material.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class InfoView extends StatelessWidget {
  const InfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About & Information'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Branding Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2), width: 2),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 56,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Heathify',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'AI-Assisted Nutrition & Meal Intelligence',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Version 1.2.0 (Build 2026)',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),

            // Mission Statement Card
            _buildSectionCard(
              icon: Icons.lightbulb_outline,
              iconColor: Colors.amber.shade700,
              title: 'Our Mission',
              content:
                  'Heathify is designed to make nutrition tracking effortless, accurate, and insightful. By combining Google Gemini multimodal AI with global food databases, Heathify estimates portion sizes, calories, and macronutrients in seconds from a single food photo.',
            ),
            const SizedBox(height: 16),

            // How It Works Cards
            _buildSectionCard(
              icon: Icons.auto_awesome,
              iconColor: Colors.purple.shade600,
              title: 'Core Technologies',
              child: Column(
                children: [
                  _buildTechRow(
                    icon: Icons.visibility_outlined,
                    title: 'Google Gemini 2.5 Flash',
                    description: 'Computer vision food recognition, portion size estimation, and spatial bounding boxes.',
                  ),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildTechRow(
                    icon: Icons.qr_code_scanner,
                    title: 'OpenFoodFacts Global API',
                    description: 'Barcode database for packaged food products, Nutri-Scores, and verified nutrition facts.',
                  ),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildTechRow(
                    icon: Icons.water_drop_outlined,
                    title: 'Smart Hydration Engine',
                    description: 'Personalized daily water tracking with 1-tap quick logging and intake analytics.',
                  ),
                  const Divider(height: 16, color: Color(0xFFF3F4F6)),
                  _buildTechRow(
                    icon: Icons.cloud_done_outlined,
                    title: 'Offline-First Synchronization',
                    description: 'Automatic SQLite local caching and seamless background sync when network reconnects.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // System Diagnostics Card
            _buildSectionCard(
              icon: Icons.dns_outlined,
              iconColor: Colors.blue.shade600,
              title: 'System Diagnostics',
              child: Column(
                children: [
                  _buildDiagRow('Backend API', ApiConstants.baseUrl),
                  _buildDiagRow('Environment', 'Local Development (Docker)'),
                  _buildDiagRow('Database', 'PostgreSQL + asyncpg / SQLite Cache'),
                  _buildDiagRow('AI Engine', 'Gemini Vision 2.5 Flash'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Medical & Health Disclaimer Card
            _buildSectionCard(
              icon: Icons.health_and_safety_outlined,
              iconColor: Colors.red.shade600,
              title: 'Medical & Nutrition Disclaimer',
              content:
                  'Nutrition values, calories, and food identifications presented in Heathify are estimates generated by AI models and nutritional databases. They are intended for lifestyle, wellness, and self-monitoring purposes only and should not be used as medical diagnoses or formal clinical prescriptions.',
            ),
            const SizedBox(height: 28),

            // Footer
            const Text(
              'Crafted with ❤️ for healthy living.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? content,
    Widget? child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: 12),
            child,
          ],
        ],
      ),
    );
  }

  Widget _buildTechRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryDark),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 2),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

