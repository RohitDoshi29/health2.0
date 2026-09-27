import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/sync_manager.dart';
import '../auth/auth_view_model.dart';
import '../home/home_view_model.dart';
import '../water/water_view_model.dart';
import 'info_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  void _showEditGoalsSheet(BuildContext context, HomeViewModel homeVm, WaterViewModel waterVm) {
    final goal = homeVm.goal;
    final calCtrl = TextEditingController(text: (goal?.calorieTarget ?? 2000.0).toStringAsFixed(0));
    final proteinCtrl = TextEditingController(text: (goal?.proteinTarget ?? 120.0).toStringAsFixed(0));
    final carbsCtrl = TextEditingController(text: (goal?.carbohydratesTarget ?? 250.0).toStringAsFixed(0));
    final fatCtrl = TextEditingController(text: (goal?.fatTarget ?? 65.0).toStringAsFixed(0));
    final fiberCtrl = TextEditingController(text: (goal?.fiberTarget ?? 30.0).toStringAsFixed(0));
    final waterCtrl = TextEditingController(text: (goal?.waterTargetMl ?? waterVm.summary.targetMl).toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Nutrition & Water Goals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set your personal daily targets for calories, macros, and hydration.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                _buildGoalInputField('Daily Calories (kcal)', calCtrl, Icons.local_fire_department, AppTheme.calorieColor),
                const SizedBox(height: 12),
                _buildGoalInputField('Protein (g)', proteinCtrl, Icons.fitness_center, AppTheme.proteinColor),
                const SizedBox(height: 12),
                _buildGoalInputField('Carbohydrates (g)', carbsCtrl, Icons.grain, AppTheme.carbsColor),
                const SizedBox(height: 12),
                _buildGoalInputField('Fat (g)', fatCtrl, Icons.opacity, AppTheme.fatColor),
                const SizedBox(height: 12),
                _buildGoalInputField('Fiber (g)', fiberCtrl, Icons.eco, AppTheme.fiberColor),
                const SizedBox(height: 12),
                _buildGoalInputField('Daily Water (ml)', waterCtrl, Icons.water_drop, Colors.blue.shade600),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final c = double.tryParse(calCtrl.text.trim()) ?? 2000.0;
                      final p = double.tryParse(proteinCtrl.text.trim()) ?? 120.0;
                      final cb = double.tryParse(carbsCtrl.text.trim()) ?? 250.0;
                      final f = double.tryParse(fatCtrl.text.trim()) ?? 65.0;
                      final fb = double.tryParse(fiberCtrl.text.trim()) ?? 30.0;
                      final w = double.tryParse(waterCtrl.text.trim()) ?? 2500.0;

                      Navigator.pop(modalCtx);
                      await homeVm.updateGoal(
                        calorieTarget: c,
                        proteinTarget: p,
                        carbohydratesTarget: cb,
                        fatTarget: f,
                        fiberTarget: fb,
                        waterTargetMl: w,
                      );
                      await waterVm.updateGoal(w);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Daily goals updated successfully!'),
                            backgroundColor: AppTheme.primaryDark,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Save All Goals',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color accentColor,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Heathify?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              authVm.logout();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final homeVm = context.watch<HomeViewModel>();
    final waterVm = context.watch<WaterViewModel>();
    final syncMgr = context.watch<SyncManager>();

    final user = authVm.currentUser;
    final goal = homeVm.goal;

    final initialLetter = (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // User Profile Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Heathify User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? 'Logged in',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: user?.authProvider == 'google'
                              ? Colors.red.shade50
                              : AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user?.authProvider == 'google' ? 'Google Account' : 'Email / Password',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user?.authProvider == 'google'
                                ? Colors.red.shade700
                                : AppTheme.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Nutrition & Hydration Goals
          const Text(
            'Nutrition & Hydration Targets',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.local_fire_department,
                  iconColor: AppTheme.calorieColor,
                  title: 'Daily Calories',
                  subtitle: '${(goal?.calorieTarget ?? 2000).toStringAsFixed(0)} kcal',
                  onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                _buildSettingTile(
                  icon: Icons.fitness_center,
                  iconColor: AppTheme.proteinColor,
                  title: 'Macronutrient Targets',
                  subtitle:
                      'P: ${(goal?.proteinTarget ?? 120).toStringAsFixed(0)}g • C: ${(goal?.carbohydratesTarget ?? 250).toStringAsFixed(0)}g • F: ${(goal?.fatTarget ?? 65).toStringAsFixed(0)}g',
                  onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                _buildSettingTile(
                  icon: Icons.water_drop,
                  iconColor: Colors.blue.shade600,
                  title: 'Daily Hydration Target',
                  subtitle: '${(goal?.waterTargetMl ?? waterVm.summary.targetMl).toStringAsFixed(0)} ml',
                  onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: App & Data Management
          const Text(
            'Data & Connectivity',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.cloud_outlined,
                  iconColor: Colors.teal.shade600,
                  title: 'Backend API Server',
                  subtitle: ApiConstants.baseUrl,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                _buildSettingTile(
                  icon: Icons.sync,
                  iconColor: Colors.indigo.shade600,
                  title: 'Offline Sync Queue',
                  subtitle: '${syncMgr.pendingCount} pending offline action(s)',
                  trailing: syncMgr.pendingCount > 0
                      ? TextButton(
                          onPressed: () => syncMgr.triggerSync(),
                          child: const Text('Sync Now'),
                        )
                      : null,
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                _buildSettingTile(
                  icon: Icons.delete_sweep_outlined,
                  iconColor: Colors.orange.shade700,
                  title: 'Clear Local Cache',
                  subtitle: 'Reset cached meals stored on this device',
                  onTap: () async {
                    await LocalStorageService().clearAll();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Local cache cleared successfully.'),
                          backgroundColor: AppTheme.primaryDark,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Information & Support
          const Text(
            'About & Support',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                _buildSettingTile(
                  icon: Icons.info_outline,
                  iconColor: AppTheme.primaryDark,
                  title: 'About Heathify & Technology',
                  subtitle: 'Version 1.2.0 • AI Engine • Food DB',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InfoView()),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56, color: Color(0xFFF3F4F6)),
                _buildSettingTile(
                  icon: Icons.health_and_safety_outlined,
                  iconColor: Colors.red.shade600,
                  title: 'Medical & Nutrition Disclaimer',
                  subtitle: 'View guidelines on AI estimates & wellness',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const InfoView()),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => _showLogoutDialog(context, authVm),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
              : null),
      onTap: onTap,
    );
  }
}

