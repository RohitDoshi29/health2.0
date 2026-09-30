import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/custom_button.dart';
import '../home/home_view.dart';
import '../home/home_view_model.dart';
import 'onboarding_view_model.dart';

class OnboardingView extends StatefulWidget {
  final bool isRecalculate;

  const OnboardingView({super.key, this.isRecalculate = false});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isRecalculate) {
        context.read<OnboardingViewModel>().loadCurrentProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.isRecalculate ? 'Recalculate Targets' : 'Personalize Your Plan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: (widget.isRecalculate || vm.currentStep > 1)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                onPressed: () {
                  if (vm.currentStep > 1) {
                    vm.prevStep();
                  } else if (widget.isRecalculate) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    if (vm.currentStep <= 3) ...[
                      _buildProgressBar(vm.currentStep),
                      const SizedBox(height: 24),
                    ],
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCurrentStep(context, vm),
                      ),
                    ),
                    if (vm.errorMessage != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          vm.errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    _buildBottomButtons(context, vm),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressBar(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final stepNum = index + 1;
        final isActive = stepNum <= currentStep;
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryGreen : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStep(BuildContext context, OnboardingViewModel vm) {
    switch (vm.currentStep) {
      case 1:
        return _buildStep1(vm);
      case 2:
        return _buildStep2(vm);
      case 3:
        return _buildStep3(vm);
      case 4:
      default:
        return _buildResultStep(context, vm);
    }
  }

  Widget _buildStep1(OnboardingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tell us about yourself',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'This helps calculate your baseline metabolic rate accurately.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),

        const Text('Biological Sex', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOptionTile(
                title: 'Male',
                icon: Icons.male_rounded,
                isSelected: vm.sex == 'male',
                onTap: () => vm.setSex('male'),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildOptionTile(
                title: 'Female',
                icon: Icons.female_rounded,
                isSelected: vm.sex == 'female',
                onTap: () => vm.setSex('female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Age', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${vm.age} years', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          ],
        ),
        Slider(
          value: vm.age.toDouble(),
          min: 13,
          max: 90,
          divisions: 77,
          activeColor: AppTheme.primaryGreen,
          onChanged: (val) => vm.setAge(val.toInt()),
        ),
      ],
    );
  }

  Widget _buildStep2(OnboardingViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Measurements',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'We use this to determine your daily energy expenditure.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 32),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Height', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${vm.heightCm.toStringAsFixed(0)} cm', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          ],
        ),
        Slider(
          value: vm.heightCm,
          min: 120,
          max: 220,
          divisions: 100,
          activeColor: AppTheme.primaryGreen,
          onChanged: vm.setHeight,
        ),
        const SizedBox(height: 28),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Weight', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('${vm.weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
          ],
        ),
        Slider(
          value: vm.weightKg,
          min: 35,
          max: 160,
          divisions: 250,
          activeColor: AppTheme.primaryGreen,
          onChanged: vm.setWeight,
        ),
      ],
    );
  }

  Widget _buildStep3(OnboardingViewModel vm) {
    final activities = [
      {'key': 'sedentary', 'label': 'Sedentary', 'desc': 'Little to no exercise, desk job'},
      {'key': 'light', 'label': 'Lightly Active', 'desc': 'Exercise 1–3 times a week'},
      {'key': 'moderate', 'label': 'Moderately Active', 'desc': 'Exercise 3–5 times a week'},
      {'key': 'active', 'label': 'Very Active', 'desc': 'Hard exercise 6–7 days a week'},
      {'key': 'very_active', 'label': 'Extra Active', 'desc': 'Physical job & intense training'},
    ];

    final goals = [
      {'key': 'lose', 'label': 'Weight Loss', 'desc': '-500 kcal deficit (sustainable fat loss)'},
      {'key': 'maintain', 'label': 'Maintain Weight', 'desc': 'Healthy equilibrium and energy'},
      {'key': 'gain', 'label': 'Build Muscle / Gain', 'desc': '+300 kcal surplus (lean gain)'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity & Goals',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose the option that best reflects your current routine.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),

        const Text('Activity Level', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...activities.map((a) {
          final isSelected = vm.activityLevel == a['key'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              tileColor: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.3) : AppTheme.surface,
              title: Text(a['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
              subtitle: Text(a['desc']!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              onTap: () => vm.setActivityLevel(a['key']!),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20) : null,
            ),
          );
        }),

        const SizedBox(height: 20),
        const Text('Primary Goal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...goals.map((g) {
          final isSelected = vm.goal == g['key'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              tileColor: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.3) : AppTheme.surface,
              title: Text(g['label']!, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
              subtitle: Text(g['desc']!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              onTap: () => vm.setGoal(g['key']!),
              trailing: isSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20) : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultStep(BuildContext context, OnboardingViewModel vm) {
    final targets = vm.previewTargets;
    if (targets == null) {
      return const Center(child: Text('Calculating targets...'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Daily Targets',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        const Text(
          'Calculated using the scientifically verified Mifflin-St Jeor equation.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 20),

        // Calorie Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('Daily Calorie Budget', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                '${targets.calorieTarget.toStringAsFixed(0)} kcal',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('BMR: ${targets.bmr.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  const Text('  •  ', style: TextStyle(color: Colors.white70)),
                  Text('TDEE: ${targets.tdee.toStringAsFixed(0)} kcal', style: const TextStyle(color: Colors.white, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Target Macros & Nutrients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        _buildNutrientRow('Protein (1.6g/kg)', '${targets.proteinTarget.toStringAsFixed(1)} g', const Color(0xFF3B82F6)),
        _buildNutrientRow('Carbohydrates', '${targets.carbohydratesTarget.toStringAsFixed(1)} g', const Color(0xFFF59E0B)),
        _buildNutrientRow('Healthy Fats (25%)', '${targets.fatTarget.toStringAsFixed(1)} g', const Color(0xFFEF4444)),
        _buildNutrientRow('Fiber (14g / 1000 kcal)', '${targets.fiberTarget.toStringAsFixed(1)} g', const Color(0xFF8B5CF6)),
        _buildNutrientRow('Hydration Target', '${targets.waterTargetMl.toStringAsFixed(0)} ml', const Color(0xFF06B6D4)),
      ],
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade200,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppTheme.primaryDark : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, OnboardingViewModel vm) {
    if (vm.currentStep < 4) {
      return CustomButton(
        text: vm.currentStep == 3 ? 'Calculate Targets' : 'Continue',
        onPressed: vm.nextStep,
        icon: Icons.arrow_forward_rounded,
      );
    }

    return Column(
      children: [
        CustomButton(
          text: widget.isRecalculate ? 'Update Targets' : 'Save & Start Tracking',
          isLoading: vm.isSaving,
          icon: Icons.check_circle_rounded,
          onPressed: () async {
            final success = await vm.saveProfile();
            if (success && context.mounted) {
              try {
                context.read<HomeViewModel>().loadMeals();
              } catch (_) {}

              if (widget.isRecalculate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Targets updated successfully!'),
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                );
                Navigator.pop(context);
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeView()),
                );
              }
            }
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: vm.prevStep,
          child: const Text('Edit Inputs', style: TextStyle(color: AppTheme.textSecondary)),
        ),
      ],
    );
  }
}
