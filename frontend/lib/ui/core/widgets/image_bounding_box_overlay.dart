import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/analysis_model.dart';

class ImageBoundingBoxOverlay extends StatelessWidget {
  final Uint8List? imageBytes;
  final List<MealItemAnalysisModel> items;
  final int? selectedIndex;
  final ValueChanged<int>? onItemSelected;

  static const List<Color> _boxColors = [
    Color(0xFF10B981), // Emerald
    Color(0xFF3B82F6), // Blue
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF14B8A6), // Teal
  ];

  const ImageBoundingBoxOverlay({
    super.key,
    required this.imageBytes,
    required this.items,
    this.selectedIndex,
    this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (imageBytes == null) {
      return Container(
        height: 220,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 48, color: AppTheme.textSecondary),
        ),
      );
    }

    final itemsWithBoxes = items
        .asMap()
        .entries
        .where((entry) => entry.value.boundingBox != null)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image with interactive bounding box painter
          AspectRatio(
            aspectRatio: 4 / 3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = constraints.maxHeight;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      imageBytes!,
                      fit: BoxFit.cover,
                      width: width,
                      height: height,
                    ),
                    // Semi-dark scrim for contrast
                    Container(
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                    // Draw boxes and tags
                    ...itemsWithBoxes.map((entry) {
                      final originalIndex = entry.key;
                      final item = entry.value;
                      final box = item.boundingBox!;
                      final color = _boxColors[originalIndex % _boxColors.length];
                      final isSelected = selectedIndex == originalIndex;

                      final rectLeft = box.xmin * width;
                      final rectTop = box.ymin * height;
                      final rectWidth = (box.xmax - box.xmin) * width;
                      final rectHeight = (box.ymax - box.ymin) * height;

                      return Positioned(
                        left: rectLeft,
                        top: rectTop,
                        width: rectWidth.clamp(30.0, width),
                        height: rectHeight.clamp(30.0, height),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onItemSelected?.call(originalIndex),
                          child: Stack(
                            children: [
                              // Bounding box border
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? Colors.white : color,
                                    width: isSelected ? 3.0 : 2.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: color.withValues(alpha: isSelected ? 0.30 : 0.15),
                                ),
                              ),
                              // Tag badge inside the top-left of the box
                              Positioned(
                                left: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (item.confidence != null) ...[
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(item.confidence! * 100).toInt()}%',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
          // Food Item Pill Chips at the bottom of the photo
          if (items.isNotEmpty)
            Container(
              color: const Color(0xFF1F2937),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final color = _boxColors[index % _boxColors.length];
                    final isSelected = selectedIndex == index;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => onItemSelected?.call(index),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isSelected ? color : const Color(0xFF374151),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? Colors.white : color.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
