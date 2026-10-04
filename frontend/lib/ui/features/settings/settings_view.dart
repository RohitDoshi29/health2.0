import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/sync_manager.dart';
import '../../core/widgets/badges_section.dart';
import '../../core/widgets/glass_card.dart';
import '../auth/auth_view_model.dart';
import '../home/home_view_model.dart';
import '../onboarding/onboarding_view.dart';
import '../streak/streak_view_model.dart';
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

    void applyMacroPreset(double pRatio, double cRatio, double fRatio) {
      final calories = double.tryParse(calCtrl.text.trim()) ?? 2000.0;
      final proteinG = (calories * pRatio) / 4.0;
      final carbsG = (calories * cRatio) / 4.0;
      final fatG = (calories * fRatio) / 9.0;
      final fiberG = (calories / 1000.0) * 14.0;

      proteinCtrl.text = proteinG.toStringAsFixed(0);
      carbsCtrl.text = carbsG.toStringAsFixed(0);
      fatCtrl.text = fatG.toStringAsFixed(0);
      fiberCtrl.text = fiberG.toStringAsFixed(0);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1814),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border.all(color: const Color(0x3300F59B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.65),
                    blurRadius: 30,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.neonEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.tune_rounded, color: AppTheme.neonEmerald, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Edit Daily Targets',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 22),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Customize your daily calorie intake, macronutrients balance, and hydration target.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 16),

                    // Quick Macro Distribution Presets
                    const Text(
                      'QUICK MACRO PRESETS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPresetChip(
                            label: 'Balanced (50C / 25P / 25F)',
                            onTap: () {
                              setModalState(() {
                                applyMacroPreset(0.25, 0.50, 0.25);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            label: 'High Protein (35P / 40C / 25F)',
                            onTap: () {
                              setModalState(() {
                                applyMacroPreset(0.35, 0.40, 0.25);
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildPresetChip(
                            label: 'Low Carb (30P / 20C / 50F)',
                            onTap: () {
                              setModalState(() {
                                applyMacroPreset(0.30, 0.20, 0.50);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    _buildGoalInputField('Daily Calories', calCtrl, Icons.local_fire_department_rounded, AppTheme.calorieColor, 'kcal'),
                    const SizedBox(height: 10),
                    _buildGoalInputField('Protein Target', proteinCtrl, Icons.fitness_center_rounded, AppTheme.proteinColor, 'g'),
                    const SizedBox(height: 10),
                    _buildGoalInputField('Carbohydrates Target', carbsCtrl, Icons.grain_rounded, AppTheme.carbsColor, 'g'),
                    const SizedBox(height: 10),
                    _buildGoalInputField('Fat Target', fatCtrl, Icons.opacity_rounded, AppTheme.fatColor, 'g'),
                    const SizedBox(height: 10),
                    _buildGoalInputField('Dietary Fiber Target', fiberCtrl, Icons.eco_rounded, AppTheme.fiberColor, 'g'),
                    const SizedBox(height: 10),
                    _buildGoalInputField('Daily Water Intake', waterCtrl, Icons.water_drop_rounded, AppTheme.waterColor, 'ml'),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonEmerald,
                          foregroundColor: const Color(0xFF041A0E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 4,
                          shadowColor: const Color(0x6600F59B),
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
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF041A0E), size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Daily nutrition & water goals updated!',
                                      style: TextStyle(color: Color(0xFF041A0E), fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                backgroundColor: AppTheme.neonEmerald,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Save All Targets',
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
      },
    );
  }

  Widget _buildPresetChip({required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x1F16231D),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x2200F59B)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.neonEmerald,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalInputField(
    String label,
    TextEditingController controller,
    IconData icon,
    Color accentColor,
    String unit,
  ) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        prefixIcon: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: accentColor, size: 20),
        ),
        suffixText: unit,
        suffixStyle: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF14241D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x2200F59B)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x2200F59B)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x3300F59B)),
        ),
        title: Row(
          children: const [
            Icon(Icons.delete_sweep_rounded, color: Color(0xFFFFB800), size: 22),
            SizedBox(width: 8),
            Text('Clear Local Cache', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This will purge locally cached meals and offline queues on this device. Synced data on the cloud backend remains safe.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService().clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Local storage cache purged successfully.'),
                    backgroundColor: AppTheme.surfaceLight,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthViewModel authVm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1814),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0x44EF4444)),
        ),
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFFF4D4D), size: 22),
            SizedBox(width: 8),
            Text('Log Out', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your current session on Heathify?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final streakVm = Provider.of<StreakViewModel?>(context);

    final user = authVm.currentUser;
    final goal = homeVm.goal;

    final userName = (user?.name.trim().isNotEmpty == true) ? user!.name : 'Heathify Explorer';
    final userEmail = (user?.email.trim().isNotEmpty == true) ? user!.email : 'Active Account';
    final initialLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'H';
    final isGoogle = user?.authProvider == 'google';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Settings'),
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
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // User Profile Glass Card
            GlassCard(
              glow: true,
              glowColor: AppTheme.neonEmerald,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar Pod with Neon Glow
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.neonEmerald,
                              AppTheme.neonTeal,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonEmerald.withValues(alpha: 0.35),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: const Color(0xFF0F1814),
                          child: Text(
                            initialLetter,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.neonEmerald,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              userEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isGoogle
                                        ? const Color(0x2AEC4899)
                                        : const Color(0x2200F59B),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isGoogle
                                          ? const Color(0x66EC4899)
                                          : const Color(0x4400F59B),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isGoogle ? Icons.g_mobiledata_rounded : Icons.mail_outline_rounded,
                                        size: 14,
                                        color: isGoogle ? const Color(0xFFF472B6) : AppTheme.neonEmerald,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isGoogle ? 'Google Account' : 'Verified Email',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isGoogle ? const Color(0xFFF472B6) : AppTheme.neonEmerald,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0x1A00F0FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0x3300F0FF)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.neonTeal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Text(
                                        'Active Session',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.neonTeal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  // User Quick Stat Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x2216231D),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x1FFFFFFF)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickMetric(
                          label: 'Daily Target',
                          value: '${(goal?.calorieTarget ?? 2000).toStringAsFixed(0)} kcal',
                          color: AppTheme.calorieColor,
                        ),
                        Container(width: 1, height: 26, color: Colors.white12),
                        _buildQuickMetric(
                          label: 'Active Streak',
                          value: '${streakVm?.currentStreak ?? 0} days 🔥',
                          color: const Color(0xFFFF8A00),
                        ),
                        Container(width: 1, height: 26, color: Colors.white12),
                        _buildQuickMetric(
                          label: 'Hydration',
                          value: '${(goal?.waterTargetMl ?? waterVm.summary.targetMl).toStringAsFixed(0)} ml',
                          color: AppTheme.waterColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Achievements & Badges Section
            const BadgesSection(),
            const SizedBox(height: 24),

            // Section 1: Nutrition & Hydration Goals
            _buildSectionHeader(
              title: 'Nutrition & Hydration Targets',
              actionLabel: 'Edit Goals',
              onAction: () => _showEditGoalsSheet(context, homeVm, waterVm),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.local_fire_department_rounded,
                    iconColor: AppTheme.calorieColor,
                    title: 'Daily Calories',
                    subtitle: 'Total daily energy requirement',
                    badgeText: '${(goal?.calorieTarget ?? 2000).toStringAsFixed(0)} kcal',
                    badgeColor: AppTheme.calorieColor,
                    onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.fitness_center_rounded,
                    iconColor: AppTheme.proteinColor,
                    title: 'Protein Target',
                    subtitle: 'Lean muscle recovery & satiety',
                    badgeText: '${(goal?.proteinTarget ?? 120).toStringAsFixed(0)} g',
                    badgeColor: AppTheme.proteinColor,
                    onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.grain_rounded,
                    iconColor: AppTheme.carbsColor,
                    title: 'Carbohydrates & Fats',
                    subtitle: 'Carbs: ${(goal?.carbohydratesTarget ?? 250).toStringAsFixed(0)}g • Fat: ${(goal?.fatTarget ?? 65).toStringAsFixed(0)}g',
                    badgeText: '${(goal?.carbohydratesTarget ?? 250).toStringAsFixed(0)}g / ${(goal?.fatTarget ?? 65).toStringAsFixed(0)}g',
                    badgeColor: AppTheme.carbsColor,
                    onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.water_drop_rounded,
                    iconColor: AppTheme.waterColor,
                    title: 'Daily Hydration Target',
                    subtitle: 'Target fluid intake for optimal metabolism',
                    badgeText: '${(goal?.waterTargetMl ?? waterVm.summary.targetMl).toStringAsFixed(0)} ml',
                    badgeColor: AppTheme.waterColor,
                    onTap: () => _showEditGoalsSheet(context, homeVm, waterVm),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.auto_fix_high_rounded,
                    iconColor: AppTheme.neonEmerald,
                    title: 'Recalculate BMR & TDEE',
                    subtitle: 'Use biometric calculator for precise metabolic targets',
                    badgeText: 'Recalculate',
                    badgeColor: AppTheme.neonEmerald,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnboardingView(isRecalculate: true),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Data & Connectivity
            _buildSectionHeader(title: 'Data & Connectivity'),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.dns_rounded,
                    iconColor: AppTheme.neonTeal,
                    title: 'Backend API Server',
                    subtitle: ApiConstants.baseUrl,
                    badgeText: 'ONLINE 🟢',
                    badgeColor: AppTheme.neonTeal,
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.sync_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: 'Offline Sync Queue',
                    subtitle: '${syncMgr.pendingCount} pending offline action(s)',
                    trailing: syncMgr.pendingCount > 0
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: syncMgr.isSyncing ? null : () => syncMgr.triggerSync(),
                            child: syncMgr.isSyncing
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('Sync Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0x1A10B981),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0x3310B981)),
                            ),
                            child: const Text('All Synced ⚡', style: TextStyle(fontSize: 11, color: AppTheme.neonEmerald, fontWeight: FontWeight.w600)),
                          ),
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.delete_sweep_rounded,
                    iconColor: const Color(0xFFFFB800),
                    title: 'Purge Local Cache',
                    subtitle: 'Reset cached database records stored locally',
                    onTap: () => _showClearCacheDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Information & Support
            _buildSectionHeader(title: 'About & Support'),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppTheme.neonEmerald,
                    title: 'About Heathify & Intelligence',
                    subtitle: 'v1.2.0 • Gemini Vision 2.5 Flash • OpenFoodFacts',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const InfoView()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0x1400F59B)),
                  _buildSettingTile(
                    icon: Icons.health_and_safety_rounded,
                    iconColor: const Color(0xFFFF5252),
                    title: 'Medical & Nutrition Disclaimer',
                    subtitle: 'AI estimations & wellness guidance policy',
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

            // Logout Glass Button
            GlassCard(
              borderColor: const Color(0x44EF4444),
              fillColor: const Color(0x1FEF4444),
              onTap: () => _showLogoutDialog(context, authVm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout_rounded, color: Color(0xFFFF4D4D), size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color(0xFFFF4D4D),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, String? actionLabel, VoidCallback? onAction}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.neonEmerald,
                borderRadius: BorderRadius.circular(2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x8800F59B),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null)
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.neonEmerald,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuickMetric({required String label, required String value, required Color color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: iconColor.withValues(alpha: 0.25)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeText != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppTheme.neonEmerald).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (badgeColor ?? AppTheme.neonEmerald).withValues(alpha: 0.35)),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? AppTheme.neonEmerald,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
