import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/macro_progress_ring.dart';
import '../../core/widgets/nutrition_trends_chart.dart';
import '../../core/widgets/favorites_sheet.dart';
import '../../core/widgets/water_tracker_card.dart';
import '../../../data/services/sync_manager.dart';
import '../auth/auth_view_model.dart';
import '../history/history_view.dart';
import '../manual/manual_food_entry_view.dart';
import '../scan/scan_view.dart';
import '../settings/info_view.dart';
import '../settings/settings_view.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const InfoView(),
      const ScanView(),
      const _DashboardTab(),
      const HistoryView(),
      const SettingsView(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 2 || index == 3) {
            context.read<HomeViewModel>().loadMeals();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info, color: AppTheme.primaryDark),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt, color: AppTheme.primaryDark),
            label: 'Scan Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.primaryDark),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: AppTheme.primaryDark),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.primaryDark),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

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
                      'Daily Nutrition Goals',
                      style: TextStyle(
                        fontSize: 20,
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
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Save Goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heathify Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsView()),
                );
              },
              child: Tooltip(
                message: 'Profile & Settings',
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.primaryLight,
                  child: Text(
                    (authVm.currentUser?.name.isNotEmpty == true)
                        ? authVm.currentUser!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => homeVm.loadMeals(),
        color: AppTheme.primaryGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Sync Status Banner
              if (syncMgr.pendingCount > 0) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${syncMgr.pendingCount} meal${syncMgr.pendingCount == 1 ? "" : "s"} saved offline',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
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
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD97706)),
                              )
                            : const Text(
                                'Sync Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],

              // User Greeting
              Text(
                'Hello, ${authVm.currentUser?.name.split(" ").first ?? "Friend"} 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Here is your nutrition summary for today",
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Daily Macro Progress & Ring Card
              MacroProgressRing(
                analytics: homeVm.analytics,
                onEditGoals: () => _showEditGoalsSheet(context, homeVm),
              ),
              const SizedBox(height: 24),

              // Nutrition Trends & History Chart
              NutritionTrendsChart(
                trends: homeVm.trends,
                selectedDays: homeVm.trendDays,
                isLoading: homeVm.isTrendsLoading,
                onPeriodChanged: (days) => homeVm.loadTrends(days),
              ),
              const SizedBox(height: 28),

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
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Favorites',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  Text(
                                    '1-tap quick log',
                                    style: TextStyle(fontSize: 10, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Manual Entry',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF1E40AF),
                                    ),
                                  ),
                                  Text(
                                    'Custom values',
                                    style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
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

              // Hydration Tracker Card
              const WaterTrackerCard(),
              const SizedBox(height: 24),

              // Recent Meals Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Meals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
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
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (homeVm.meals.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Text(
                    'No meals logged yet today.\nTap "Scan Food" to get started!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
                  ),
                )
              else
                ...homeVm.meals.take(5).map((meal) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meal.mealType.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              meal.items.map((i) => i.foodName).join(', '),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${meal.totalCalories.toStringAsFixed(0)} kcal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

