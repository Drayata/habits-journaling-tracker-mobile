import 'package:flutter/material.dart';

import '../theme.dart';

class HeatmapGrid extends StatelessWidget {
  final Map<DateTime, int> data;

  const HeatmapGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final date = today.subtract(Duration(days: 29 - index));
        final count = data[date] ?? 0;
        final isToday = date == today;

        return Container(
          decoration: BoxDecoration(
            color: count > 0 ? AppTheme.successColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
            border: isToday
                ? Border.all(color: AppTheme.primaryColor, width: 2)
                : null,
          ),
        );
      },
    );
  }
}
