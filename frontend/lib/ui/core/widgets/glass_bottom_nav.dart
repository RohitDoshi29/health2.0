import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'magnification_dock.dart';

export 'magnification_dock.dart';

/// Healthify Futuristic Magnification Navigation Dock
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final VoidCallback? onScanTap;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      DockItemData(
        icon: Icons.info_outline_rounded,
        label: 'Info',
        activeColor: AppTheme.neonTeal,
        onClick: () => onIndexChanged(0),
      ),
      DockItemData(
        icon: Icons.center_focus_strong_rounded,
        label: 'Scan Food',
        isSpecial: true,
        specialGradient: const LinearGradient(
          colors: [Color(0xFF00FF88), Color(0xFF00B0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        activeColor: AppTheme.neonEmerald,
        onClick: () {
          onIndexChanged(1);
          onScanTap?.call();
        },
      ),
      DockItemData(
        icon: Icons.home_rounded,
        label: 'Home',
        activeColor: AppTheme.neonEmerald,
        onClick: () => onIndexChanged(2),
      ),
      DockItemData(
        icon: Icons.history_rounded,
        label: 'History',
        activeColor: AppTheme.carbsColor,
        onClick: () => onIndexChanged(3),
      ),
      DockItemData(
        icon: Icons.settings_rounded,
        label: 'Settings',
        activeColor: AppTheme.fatColor,
        onClick: () => onIndexChanged(4),
      ),
    ];

    return MagnificationDock(
      items: items,
      selectedIndex: currentIndex,
      onItemSelected: onIndexChanged,
      panelHeight: 66,
      baseItemSize: 38,
      magnification: 56,
      distance: 120,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );
  }
}
