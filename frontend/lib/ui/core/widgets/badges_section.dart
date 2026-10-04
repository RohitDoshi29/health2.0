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
        return Icons.local_fire_department_rounded;
      case 'streak_7':
        return Icons.military_tech_rounded;
      case 'streak_14':
        return Icons.workspace_premium_rounded;
      case 'streak_30':
        return Icons.stars_rounded;
      case 'hit_protein_today':
        return Icons.fitness_center_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }

  void _showBadgeDetail(BuildContext context, BadgeItemModel badge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1814),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: badge.unlocked ? const Color(0x66F59E0B) : const Color(0x2200F59B),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: badge.unlocked
                    ? const RadialGradient(
                        colors: [Color(0x55F59E0B), Color(0x15F59E0B)],
                      )
                    : const RadialGradient(
                        colors: [Color(0x22FFFFFF), Color(0x0AFFFFFF)],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: badge.unlocked ? const Color(0xFFFFB800) : const Color(0x33FFFFFF),
                  width: 2,
                ),
                boxShadow: badge.unlocked
                    ? [
                        BoxShadow(
                          color: const Color(0x66F59E0B),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getBadgeIcon(badge.id),
                size: 42,
                color: badge.unlocked ? const Color(0xFFFFC107) : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: badge.unlocked ? const Color(0x2610B981) : const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: badge.unlocked ? const Color(0x6610B981) : const Color(0x22FFFFFF),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    badge.unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                    size: 14,
                    color: badge.unlocked ? AppTheme.neonEmerald : AppTheme.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    badge.unlocked
                        ? 'Unlocked ${badge.earnedAt ?? "Recently"} 🎉'
                        : 'Locked • Keep logging meals & water to unlock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badge.unlocked ? AppTheme.neonEmerald : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonEmerald,
                  foregroundColor: const Color(0xFF041A0E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
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
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB800),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x88FFB800),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'ACHIEVEMENTS & BADGES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x22FFB800),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x66FFB800)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, size: 13, color: Color(0xFFFFC107)),
                  const SizedBox(width: 5),
                  Text(
                    '$unlockedCount / ${badges.length} Unlocked',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 142,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final badge = badges[index];
              return InkWell(
                onTap: () => _showBadgeDetail(context, badge),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 132,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: badge.unlocked
                        ? const LinearGradient(
                            colors: [
                              Color(0x332E2410),
                              Color(0x221A160E),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [
                              Color(0x2216231D),
                              Color(0x140F1814),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: badge.unlocked ? const Color(0x88F59E0B) : const Color(0x1FFFFFFF),
                      width: badge.unlocked ? 1.4 : 1.0,
                    ),
                    boxShadow: badge.unlocked
                        ? [
                            BoxShadow(
                              color: const Color(0x33F59E0B),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
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
                          color: badge.unlocked ? const Color(0x33FFB800) : const Color(0x14FFFFFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: badge.unlocked ? const Color(0x66FFB800) : Colors.white10,
                          ),
                        ),
                        child: Icon(
                          _getBadgeIcon(badge.id),
                          size: 24,
                          color: badge.unlocked ? const Color(0xFFFFC107) : const Color(0xFF6B7280),
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
                          color: badge.unlocked ? AppTheme.textPrimary : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: badge.unlocked ? const Color(0x2210B981) : const Color(0x12FFFFFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: badge.unlocked ? const Color(0x4410B981) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badge.unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                              size: 10,
                              color: badge.unlocked ? AppTheme.neonEmerald : AppTheme.textMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              badge.unlocked ? 'Earned' : 'Locked',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: badge.unlocked ? AppTheme.neonEmerald : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
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
