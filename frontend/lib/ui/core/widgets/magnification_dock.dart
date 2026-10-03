import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

/// Data definition for a single dock item in the Magnification Dock
class DockItemData {
  final Widget? iconWidget;
  final IconData? icon;
  final String label;
  final VoidCallback? onClick;
  final Color? activeColor;
  final Color? iconColor;
  final bool isSpecial;
  final Gradient? specialGradient;

  const DockItemData({
    this.iconWidget,
    this.icon,
    required this.label,
    this.onClick,
    this.activeColor,
    this.iconColor,
    this.isSpecial = false,
    this.specialGradient,
  }) : assert(iconWidget != null || icon != null, 'Either icon or iconWidget must be provided');
}

/// A macOS-inspired Magnification Dock widget with fluid magnification effects,
/// spring physics, floating tooltips, and futuristic glassmorphism.
class MagnificationDock extends StatefulWidget {
  final List<DockItemData> items;
  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;
  final double distance;
  final double panelHeight;
  final double baseItemSize;
  final double magnification;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final bool showLabels;
  final bool enableHaptics;

  const MagnificationDock({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onItemSelected,
    this.distance = 120.0,
    this.panelHeight = 68.0,
    this.baseItemSize = 38.0,
    this.magnification = 56.0,
    this.margin = const EdgeInsets.fromLTRB(16, 0, 16, 16),
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.showLabels = true,
    this.enableHaptics = true,
  });

  @override
  State<MagnificationDock> createState() => _MagnificationDockState();
}

class _MagnificationDockState extends State<MagnificationDock> {
  double? _pointerX;
  int? _hoveredIndex;
  final GlobalKey _dockKey = GlobalKey();

  void _handlePointerUpdate(Offset localPosition) {
    setState(() {
      _pointerX = localPosition.dx;
      _updateHoveredIndex();
    });
  }

  void _handlePointerEnd() {
    setState(() {
      _pointerX = null;
      _hoveredIndex = null;
    });
  }

  void _updateHoveredIndex() {
    if (_pointerX == null || widget.items.isEmpty) {
      _hoveredIndex = null;
      return;
    }
    final RenderBox? box = _dockKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final totalWidth = box.size.width;
    final itemSlotWidth = totalWidth / widget.items.length;
    final index = (_pointerX! / itemSlotWidth).floor().clamp(0, widget.items.length - 1);
    if (_hoveredIndex != index) {
      _hoveredIndex = index;
      if (widget.enableHaptics) {
        HapticFeedback.selectionClick();
      }
    }
  }

  double _calculateItemSize(int index, double totalWidth) {
    final base = widget.baseItemSize;
    final max = widget.magnification;

    if (_pointerX == null) {
      return index == widget.selectedIndex ? base + 2 : base;
    }

    final itemSlotWidth = totalWidth / widget.items.length;
    final itemCenterX = (index + 0.5) * itemSlotWidth;

    final delta = (_pointerX! - itemCenterX).abs();
    if (delta > widget.distance) {
      return base;
    }

    final factor = math.cos((delta / widget.distance) * (math.pi / 2));
    return base + (max - base) * factor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          return MouseRegion(
            onHover: (event) => _handlePointerUpdate(event.localPosition),
            onExit: (_) => _handlePointerEnd(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (details) => _handlePointerUpdate(details.localPosition),
              onHorizontalDragUpdate: (details) => _handlePointerUpdate(details.localPosition),
              onHorizontalDragEnd: (_) {
                if (_hoveredIndex != null) {
                  widget.onItemSelected?.call(_hoveredIndex!);
                  widget.items[_hoveredIndex!].onClick?.call();
                }
                _handlePointerEnd();
              },
              onHorizontalDragCancel: _handlePointerEnd,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  // Frosted Glass Dock Panel
                  ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        key: _dockKey,
                        height: widget.panelHeight,
                        padding: widget.padding,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xE60D1814),
                              Color(0xF207100D),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: AppTheme.neonEmerald.withValues(alpha: 0.22),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.55),
                              blurRadius: 26,
                              offset: const Offset(0, 10),
                            ),
                            BoxShadow(
                              color: AppTheme.neonEmerald.withValues(alpha: 0.12),
                              blurRadius: 16,
                              spreadRadius: 1,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: List.generate(widget.items.length, (index) {
                            final item = widget.items[index];
                            final isSelected = index == widget.selectedIndex;
                            final size = _calculateItemSize(index, totalWidth);
                            final lift = (size - widget.baseItemSize) * 0.75;

                            return Expanded(
                              child: _DockItemWidget(
                                item: item,
                                index: index,
                                isSelected: isSelected,
                                isHovered: _hoveredIndex == index,
                                size: size,
                                lift: lift,
                                baseSize: widget.baseItemSize,
                                showLabels: widget.showLabels,
                                onTap: () {
                                  if (widget.enableHaptics) {
                                    HapticFeedback.lightImpact();
                                  }
                                  widget.onItemSelected?.call(index);
                                  item.onClick?.call();
                                },
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),

                  // Floating Tooltip Badge above active/hovered item
                  if (_hoveredIndex != null && _hoveredIndex! < widget.items.length)
                    Positioned(
                      bottom: widget.panelHeight + 8,
                      child: _DockTooltip(
                        label: widget.items[_hoveredIndex!].label,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Single Animated Dock Item Widget with spring physics and elevation
class _DockItemWidget extends StatelessWidget {
  final DockItemData item;
  final int index;
  final bool isSelected;
  final bool isHovered;
  final double size;
  final double lift;
  final double baseSize;
  final bool showLabels;
  final VoidCallback onTap;

  const _DockItemWidget({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.isHovered,
    required this.size,
    required this.lift,
    required this.baseSize,
    required this.showLabels,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = item.activeColor ?? AppTheme.neonEmerald;
    final isSpecial = item.isSpecial;

    return Semantics(
      label: item.label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, -lift, 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOutCubic,
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSpecial
                          ? (item.specialGradient ??
                              const LinearGradient(
                                colors: [Color(0xFF00FF88), Color(0xFF00B0FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ))
                          : (isSelected
                              ? LinearGradient(
                                  colors: [
                                    activeColor.withValues(alpha: 0.35),
                                    activeColor.withValues(alpha: 0.12),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null),
                      color: (!isSpecial && !isSelected)
                          ? (isHovered
                              ? Colors.white.withValues(alpha: 0.12)
                              : Colors.white.withValues(alpha: 0.05))
                          : null,
                      border: Border.all(
                        color: isSpecial
                            ? Colors.white.withValues(alpha: 0.6)
                            : (isSelected
                                ? activeColor.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.1)),
                        width: isSelected || isSpecial ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        if (isSpecial)
                          BoxShadow(
                            color: const Color(0xFF00F59B).withValues(alpha: 0.5),
                            blurRadius: 14,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        if (isSelected && !isSpecial)
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                      ],
                    ),
                    child: Center(
                      child: item.iconWidget ??
                          Icon(
                            item.icon,
                            size: (size * 0.48).clamp(16.0, 30.0),
                            color: isSpecial
                                ? const Color(0xFF04130D)
                                : (isSelected
                                    ? activeColor
                                    : (isHovered ? Colors.white : AppTheme.textSecondary)),
                          ),
                    ),
                  ),
                  const SizedBox(height: 2),

                  // Label Text & Active Dot
                  if (showLabels)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? activeColor
                                : (isHovered ? Colors.white : AppTheme.textSecondary),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: isSelected ? 3.5 : 0.0,
                          height: isSelected ? 3.5 : 0.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: activeColor,
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: activeColor.withValues(alpha: 0.8),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating Frosted Glass Tooltip Badge that pops up on hover/magnification
class _DockTooltip extends StatelessWidget {
  final String label;

  const _DockTooltip({required this.label});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutBack,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xE60A1410),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.neonEmerald.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppTheme.neonEmerald.withValues(alpha: 0.2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.0,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

