import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/nutrition_orbit.dart';
import '../../core/widgets/floating_food_widget.dart';
import '../../core/widgets/nutrition_trends_chart.dart';
import '../../core/widgets/favorites_sheet.dart';
import '../../core/widgets/water_tracker_card.dart';
import '../../core/widgets/weight_tracker_card.dart';
import '../../core/widgets/daily_score_card.dart';
import '../../../data/services/sync_manager.dart';
import '../auth/auth_view_model.dart';
import '../streak/streak_view_model.dart';
import '../history/history_view.dart';
import '../manual/manual_food_entry_view.dart';
import '../scan/scan_view.dart';
import '../settings/info_view.dart';
import '../settings/settings_view.dart';
import '../weekly/weekly_view.dart';
import 'home_view_model.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 2; // Default to 'Home'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadMeals();
      try {
        Provider.of<StreakViewModel?>(context, listen: false)?.loadStreaks();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const InfoView(),
      const ScanView(),
      const _CockpitDashboardView(),
      const HistoryView(),
      const SettingsView(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xE6080D0B),
        indicatorColor: const Color(0x3300F59B),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2 || index == 3) {
            context.read<HomeViewModel>().loadMeals();
            try {
              Provider.of<StreakViewModel?>(context, listen: false)?.loadStreaks();
            } catch (_) {}
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info, color: AppTheme.neonEmerald),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: AppTheme.neonEmerald),
            label: 'Scan Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.neonEmerald),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.neonEmerald),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.neonEmerald),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _CockpitDashboardView extends StatelessWidget {
  const _CockpitDashboardView();

  void _showEditGoalsSheet(BuildContext context, HomeViewModel homeVm) {
    final goal = homeVm.goal;
    final calCtrl = TextEditingController(text: (goal?.calorieTarget ?? 2000.0).toStringAsFixed(0));
    final proteinCtrl = TextEditingController(text: (goal?.proteinTarget ?? 120.0).toStringAsFixed(0));
    final carbsCtrl = TextEditingController(text: (goal?.carbohydratesTarget ?? 250.0).toStringAsFixed(0));
    final fatCtrl = TextEditingController(text: (goal?.fatTarget ?? 65.0).toStringAsFixed(0));
    final fiberCtrl = TextEditingController(text: (goal?.fiberTarget ?? 30.0).toStringAsFixed(0));

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
            color: Color(0xFF0F1814),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: Color(0x3300F59B), width: 1.5)),
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
                      'Daily Nutrition Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set your personal daily targets for calories and macronutrients.',
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonEmerald,
                      foregroundColor: const Color(0xFF041A0E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                      shadowColor: const Color(0x6600F59B),
                    ),
                    onPressed: () async {
                      final cal = double.tryParse(calCtrl.text.trim());
                      final prot = double.tryParse(proteinCtrl.text.trim());
                      final carbs = double.tryParse(carbsCtrl.text.trim());
                      final fat = double.tryParse(fatCtrl.text.trim());
                      final fiber = double.tryParse(fiberCtrl.text.trim());

                      Navigator.pop(modalCtx);
                      await homeVm.updateGoals(
                        calorieTarget: cal,
                        proteinTarget: prot,
                        carbohydratesTarget: carbs,
                        fatTarget: fat,
                        fiberTarget: fiber,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nutrition goals updated!'),
                            backgroundColor: AppTheme.primaryDark,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Save Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: const Color(0xFF16231D),
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
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final syncMgr = context.watch<SyncManager>();
    final streakVm = Provider.of<StreakViewModel?>(context);

    final rawName = authVm.currentUser?.name.trim() ?? '';
    final firstName = rawName.isNotEmpty ? rawName.split(' ').first : 'Friend';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Heathify Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                );
              },
              child: Tooltip(
                message: 'Profile & Settings',
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.neonEmerald.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 17,
                    backgroundColor: const Color(0xFF162A20),
                    child: Text(
                      rawName.isNotEmpty ? rawName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.neonEmerald,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [
              Color(0xFF0F241A),
              Color(0xFF080D0B),
            ],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            await homeVm.loadMeals();
            if (context.mounted) {
              try {
                await Provider.of<StreakViewModel?>(context, listen: false)?.loadStreaks();
              } catch (_) {}
            }
          },
          color: AppTheme.neonEmerald,
          backgroundColor: AppTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Offline Sync Status Banner
                if (syncMgr.pendingCount > 0) ...[
                  GlassCard(
                    glowColor: const Color(0xFFF59E0B),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off, color: Color(0xFFF59E0B), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${syncMgr.pendingCount} meal${syncMgr.pendingCount == 1 ? "" : "s"} saved offline',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFCD34D),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: syncMgr.isSyncing
                              ? null
                              : () async {
                                  final count = await syncMgr.syncPendingActions();
                                  if (context.mounted && count > 0) {
                                    context.read<HomeViewModel>().loadMeals();
                                  }
                                },
                          child: syncMgr.isSyncing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                                )
                              : const Text(
                                  'Sync Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFCD34D),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Futuristic Greeting Header & Streak Glow Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good evening, $firstName 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Let's make today count.",
                            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (streakVm != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF6B00),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0x88FF8A00)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0x44FF8A00),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 5),
                            Text(
                              '${streakVm.currentStreak} day${streakVm.currentStreak == 1 ? "" : "s"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFFFFB366),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),

                // 3D Nutrition Orbit Cockpit
                NutritionOrbit(
                  currentCalories: homeVm.analytics?.consumedCalories ?? 0,
                  targetCalories: homeVm.goal?.calorieTarget ?? 2000,
                  currentProtein: homeVm.analytics?.consumedProtein ?? 0,
                  targetProtein: homeVm.goal?.proteinTarget ?? 120,
                  currentCarbs: homeVm.analytics?.consumedCarbohydrates ?? 0,
                  targetCarbs: homeVm.goal?.carbohydratesTarget ?? 250,
                  currentFat: homeVm.analytics?.consumedFat ?? 0,
                  targetFat: homeVm.goal?.fatTarget ?? 65,
                  currentFiber: homeVm.analytics?.consumedFiber ?? 0,
                  targetFiber: homeVm.goal?.fiberTarget ?? 30,
                  onTap: () => _showEditGoalsSheet(context, homeVm),
                ),
                const SizedBox(height: 20),

                // Floating 3D Signature Food Object Widget
                const FloatingFoodWidget(),
                const SizedBox(height: 20),

                // Daily Health Score Cockpit Card
                const DailyScoreCard(),
                const SizedBox(height: 20),

                // Nutrition Trends Interactive Wave Chart
                NutritionTrendsChart(
                  trends: homeVm.trends,
                  selectedDays: homeVm.trendDays,
                  isLoading: homeVm.isTrendsLoading,
                  onPeriodChanged: (days) => homeVm.loadTrends(days),
                ),
                const SizedBox(height: 20),

                // Weekly Nutrition Report Cockpit Card
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WeeklyView()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: GlassCard(
                    glowColor: AppTheme.neonEmerald,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0x2200F59B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0x4400F59B)),
                          ),
                          child: const Icon(Icons.assessment_rounded, color: AppTheme.neonEmerald, size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Nutrition Report',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Compare weeks, compliance & best days',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Quick Log Action Cards Row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => FavoritesSheet(
                              onMealLogged: () => homeVm.loadMeals(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: GlassCard(
                          glowColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0x33FFB300),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Favorites',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '1-tap quick log',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final logged = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(builder: (_) => const ManualFoodEntryView()),
                          );
                          if (logged == true) {
                            homeVm.loadDashboard();
                          }
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: GlassCard(
                          glowColor: const Color(0xFF00B2FF),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0x3300B2FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.edit_note_rounded, color: Color(0xFF00B2FF), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Manual Entry',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'Custom values',
                                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hydration Tracker Cockpit Card
                const WaterTrackerCard(),
                const SizedBox(height: 16),

                // Weight Tracker Cockpit Card
                const WeightTrackerCard(),
                const SizedBox(height: 24),

                // Recent Meals Timeline Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Meals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${homeVm.meals.length} total',
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (homeVm.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: AppTheme.neonEmerald),
                    ),
                  )
                else if (homeVm.meals.isEmpty)
                  GlassCard(
                    padding: const EdgeInsets.all(28),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.restaurant_rounded, size: 36, color: AppTheme.neonEmerald.withValues(alpha: 0.5)),
                          const SizedBox(height: 10),
                          const Text(
                            'No meals logged yet today.\nTap "Scan Food" to activate AI recognition!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary, height: 1.4, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...homeVm.meals.take(5).map((meal) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0x2200F59B),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0x4400F59B)),
                                        ),
                                        child: Text(
                                          meal.mealType.toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.neonEmerald,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () async {
                                          try {
                                            final newMeal = await homeVm.relogMeal(meal.id);
                                            if (context.mounted) {
                                              final label = newMeal.mealType.isNotEmpty
                                                  ? '${newMeal.mealType[0].toUpperCase()}${newMeal.mealType.substring(1)}'
                                                  : 'Meal';
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Logged $label again!'),
                                                  action: SnackBarAction(
                                                    label: 'Undo',
                                                    onPressed: () => homeVm.deleteMeal(newMeal.id),
                                                  ),
                                                  duration: const Duration(seconds: 4),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Could not relog meal: $e')),
                                              );
                                            }
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1AFFFFFF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0x2AFFFFFF)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.replay_rounded, size: 12, color: AppTheme.textSecondary),
                                              SizedBox(width: 4),
                                              Text(
                                                'Log again',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    meal.items.map((i) => i.foodName).join(', '),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${meal.totalCalories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.calorieColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
