import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/config/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../core/widgets/meal_photo_viewer_dialog.dart';
import '../gallery/photo_gallery_view.dart';
import '../home/home_view_model.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  String _resolveImageUrl(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final base = ApiConstants.baseUrl;
    final prefix = url.startsWith('/') ? '' : '/';
    return '$base$prefix$url';
  }

  @override
  Widget build(BuildContext context) {
    final homeVm = context.watch<HomeViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Photo Gallery',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PhotoGalleryView()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => homeVm.loadMeals(),
        color: AppTheme.primaryGreen,
        child: homeVm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : homeVm.meals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'No meals logged yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use the AI scanner to log your first meal!',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: homeVm.meals.length,
                    itemBuilder: (context, index) {
                      final meal = homeVm.meals[index];
                      final formattedDate =
                          DateFormat('EEE, MMM d • h:mm a').format(meal.createdAt.toLocal());
                      final hasImage = meal.imageUrl != null && meal.imageUrl!.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        meal.mealType.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryLight,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.replay_rounded, size: 12, color: AppTheme.primaryDark),
                                            SizedBox(width: 3),
                                            Text(
                                              'Log again',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      color: Colors.red.shade400,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => homeVm.deleteMeal(meal.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Main Meal Content (Thumbnail + Macros)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (hasImage) ...[
                                  GestureDetector(
                                    onTap: () => MealPhotoViewerDialog.show(context, meal),
                                    child: Hero(
                                      tag: 'meal_img_${meal.id}',
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        clipBehavior: Clip.antiAlias,
                                        child: Image.network(
                                          _resolveImageUrl(meal.imageUrl!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFF3F4F6),
                                            child: const Icon(Icons.restaurant,
                                                color: Colors.grey, size: 28),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${meal.totalCalories.toStringAsFixed(0)} kcal',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'P: ${meal.totalProtein.toStringAsFixed(1)}g • C: ${meal.totalCarbohydrates.toStringAsFixed(1)}g • F: ${meal.totalFat.toStringAsFixed(1)}g',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (meal.items.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1, color: Color(0xFFF3F4F6)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: meal.items.map((item) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Text(
                                      '${item.foodName} (${item.quantity.toStringAsFixed(0)}${item.unit})',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

