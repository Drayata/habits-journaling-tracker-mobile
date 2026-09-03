import 'package:flutter/material.dart';

import '../theme.dart';

class HeatmapGrid extends StatelessWidget {
  final Map<DateTime, int> data;

  const HeatmapGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return LayoutBuilder(
      builder: (context, constraints) {
        const crossAxisCount = 7;
        const spacing = 4.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final cellSize =
            ((constraints.maxWidth - totalSpacing) / crossAxisCount)
                .clamp(28.0, 48.0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day-of-week labels
            Row(
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
                return SizedBox(
                  width: cellSize,
                  child: Padding(
                    padding: const EdgeInsets.only(right: spacing),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            // Heatmap cells
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(30, (index) {
                final date = today.subtract(Duration(days: 29 - index));
                final count = data[date] ?? 0;
                final isToday = date == today;

                final opacity = count == 0
                    ? 0.0
                    : count <= 1
                        ? 0.4
                        : count <= 3
                            ? 0.7
                            : 1.0;

                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: count > 0
                          ? AppTheme.successColor.withValues(alpha: opacity)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF282F4A)
                              : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(6),
                      border: isToday
                          ? Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            )
                          : null,
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}
