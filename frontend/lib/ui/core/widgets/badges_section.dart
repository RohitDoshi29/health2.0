import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/streak_model.dart';
import '../../features/streak/streak_view_model.dart';

class BadgesSection extends StatelessWidget {
  const BadgesSection({super.key});

  IconData _getBadgeIcon(String id) {
    switch (id) {
      case 'streak_3':
        return Icons.local_fire_department;
      case 'streak_7':
        return Icons.military_tech;
      case 'streak_14':
        return Icons.workspace_premium;
      case 'streak_30':
        return Icons.stars;
      case 'hit_protein_today':
        return Icons.fitness_center;
      default:
        return Icons.emoji_events;
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeItemModel badge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: badge.unlocked ? const Color(0xFFFEF3C7) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.unlocked ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: Icon(
                _getBadgeIcon(badge.id),
                size: 36,
                color: badge.unlocked ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              badge.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badge.unlocked ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: badge.unlocked ? const Color(0xFFA7F3D0) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                badge.unlocked
                    ? 'Unlocked ${badge.earnedAt ?? "Recently"} 🎉'
                    : 'Locked 🔒 Keep tracking to unlock',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: badge.unlocked ? const Color(0xFF059669) : const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<StreakViewModel?>(context);
    if (vm == null) return const SizedBox.shrink();

    final badges = vm.badges;
    if (badges.isEmpty) return const SizedBox.shrink();

    final unlockedCount = badges.where((b) => b.unlocked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements & Badges',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '$unlockedCount of ${badges.length} Unlocked',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return InkWell(
                onTap: () => _showBadgeDetail(context, badge),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 130,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badge.unlocked ? Colors.white : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: badge.unlocked ? const Color(0xFFFDE68A) : const Color(0xFFE5E7EB),
                      width: badge.unlocked ? 1.5 : 1.0,
                    ),
                    boxShadow: badge.unlocked
                        ? const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: badge.unlocked ? const Color(0xFFFEF3C7) : const Color(0xFFE5E7EB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getBadgeIcon(badge.id),
                          size: 24,
                          color: badge.unlocked ? const Color(0xFFD97706) : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        badge.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: badge.unlocked ? AppTheme.textPrimary : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            badge.unlocked ? Icons.check_circle : Icons.lock_outline,
                            size: 11,
                            color: badge.unlocked ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            badge.unlocked ? 'Earned' : 'Locked',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: badge.unlocked ? const Color(0xFF059669) : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
