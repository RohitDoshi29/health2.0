import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/favorite_model.dart';
import '../../../data/repositories/favorite_repository.dart';

class FavoritesSheet extends StatefulWidget {
  final FavoriteRepository? favoriteRepository;
  final Function(FavoriteModel favorite)? onLoadIntoPlate;
  final VoidCallback? onMealLogged;

  const FavoritesSheet({
    super.key,
    this.favoriteRepository,
    this.onLoadIntoPlate,
    this.onMealLogged,
  });

  @override
  State<FavoritesSheet> createState() => _FavoritesSheetState();
}

class _FavoritesSheetState extends State<FavoritesSheet> {
  late final FavoriteRepository _repository;
  List<FavoriteModel> _favorites = [];
  bool _isLoading = true;
  String? _loggingFavoriteId;

  @override
  void initState() {
    super.initState();
    _repository = widget.favoriteRepository ?? FavoriteRepository();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await _repository.getFavorites();
      if (mounted) {
        setState(() {
          _favorites = favs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _quickLog(FavoriteModel fav) async {
    setState(() {
      _loggingFavoriteId = fav.id;
    });

    try {
      await _repository.quickLogFavorite(fav.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logged "${fav.name}" to today\'s meals!'),
            backgroundColor: AppTheme.neonEmerald,
          ),
        );
        widget.onMealLogged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loggingFavoriteId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log favorite: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _deleteFavorite(String id) async {
    try {
      await _repository.deleteFavorite(id);
      setState(() {
        _favorites.removeWhere((f) => f.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Favorite template removed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E18),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0x3300F59B)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x3300F59B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Favorite Templates',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.neonEmerald))
                : _favorites.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _favorites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final fav = _favorites[index];
                          final isLogging = _loggingFavoriteId == fav.id;

                          return _buildFavoriteCard(fav, isLogging);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.star_border_rounded, size: 48, color: Colors.amber),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Favorites Saved Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'After analyzing a plate or barcode, tap "Save as Favorite" to re-log it here with 1 tap.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteModel fav, bool isLogging) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14241D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2200F59B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  fav.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0x3300F59B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  fav.mealType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.neonEmerald,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFF87171)),
                onPressed: () => _deleteFavorite(fav.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Text(
            fav.items.map((i) => '${i.foodName} (${i.quantity.round()}${i.unit})').join(', '),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '${fav.totalCalories.round()} kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.calorieColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'P: ${fav.totalProtein.round()}g  C: ${fav.totalCarbohydrates.round()}g  F: ${fav.totalFat.round()}g',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonEmerald,
                  foregroundColor: const Color(0xFF04130D),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: isLogging ? null : () => _quickLog(fav),
                icon: isLogging
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF04130D)),
                      )
                    : const Icon(Icons.bolt, size: 16),
                label: const Text('1-Tap Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
