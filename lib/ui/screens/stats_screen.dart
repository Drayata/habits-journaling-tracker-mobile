import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/dashboard_providers.dart';
import '../../providers/stats_provider.dart';
import '../theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statsDataProvider);
    final monthRange = ref.watch(statsMonthRangeProvider);

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthLabel =
        '${months[monthRange.start.month - 1]} ${monthRange.start.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: CustomScrollView(
        slivers: [
          // Month Navigator
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(statsMonthOffsetProvider.notifier).state--;
                    },
                    icon: const Icon(Icons.chevron_left),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                  Text(
                    monthLabel,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () {
                      final current =
                          ref.read(statsMonthOffsetProvider);
                      if (current < 0) {
                        ref.read(statsMonthOffsetProvider.notifier).state++;
                      }
                    },
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      minimumSize: const Size(44, 44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          statsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
            data: (stats) => SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Summary Cards - 2x2 grid
                  _buildSummaryGrid(context, stats),
                  const SizedBox(height: 24),
                  // Daily Completion Trend
                  _buildSectionTitle(context, Icons.trending_up,
                      'Daily Completion Rate', AppTheme.primaryColor),
                  const SizedBox(height: 12),
                  _buildCompletionChart(context, stats),
                  const SizedBox(height: 24),
                  // Sleep Trend
                  _buildSectionTitle(context, Icons.bedtime,
                      'Sleep Duration', Colors.deepPurple),
                  const SizedBox(height: 12),
                  _buildSleepChart(context, stats),
                  const SizedBox(height: 24),
                  // Mood vs Completion
                  _buildSectionTitle(context, Icons.favorite,
                      'Mood vs. Habit Completion', Colors.pink),
                  const SizedBox(height: 4),
                  Text(
                    'Average completion rate grouped by daily mood',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade500,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildMoodChart(context, stats),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildSummaryGrid(BuildContext context, StatsData stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Avg Completion',
                value: '${stats.avgCompletion}%',
                icon: Icons.trending_up,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Best Day (${stats.bestDayRate}%)',
                value: stats.bestDayLabel,
                icon: Icons.star,
                color: AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Active Days',
                value: '${stats.activeDays}/${stats.daysInMonth}',
                icon: Icons.calendar_today,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Avg Sleep',
                value: stats.avgSleep,
                icon: Icons.bedtime,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionChart(BuildContext context, StatsData stats) {
    final trend = stats.completionTrend;
    if (trend.isEmpty) {
      return _emptyChartPlaceholder(context, 'No completion data');
    }

    // Show up to 14 bars to avoid overcrowding, sampled evenly
    final displayData = _sampleData(trend, 14);
    final maxRate = trend.fold<double>(0, (m, d) => d.rate > m ? d.rate : m);
    final chartMax = maxRate > 0 ? maxRate : 100.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayData.map((data) {
              final heightRatio = chartMax == 0 ? 0.0 : data.rate / chartMax;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (data.rate > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${data.rate.round()}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                      Container(
                        height: max(2, 140 * heightRatio),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryColor,
                              AppTheme.primaryColor.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.label.split(' ').last,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSleepChart(BuildContext context, StatsData stats) {
    final trend = stats.sleepTrend;
    if (trend.isEmpty) {
      return _emptyChartPlaceholder(context, 'No sleep data');
    }

    final displayData = _sampleSleepData(trend, 14);
    final maxHours =
        trend.fold<double>(0, (m, d) => d.hours > m ? d.hours : m);
    final chartMax = maxHours > 8.0 ? maxHours : 8.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: displayData.map((data) {
              final heightRatio = chartMax == 0 ? 0.0 : data.hours / chartMax;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (data.hours > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            data.hours.toStringAsFixed(1),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.deepPurple,
                                  fontSize: 9,
                                ),
                          ),
                        ),
                      Container(
                        height: max(2, 140 * heightRatio),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.deepPurple,
                              Colors.deepPurple.withValues(alpha: 0.5),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.label.split(' ').last,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChart(BuildContext context, StatsData stats) {
    final data = stats.moodCorrelation;
    final hasData = data.any((d) => d.entries > 0);

    if (!hasData) {
      return _emptyChartPlaceholder(
          context, 'No mood data. Write journal entries with moods.');
    }

    final maxVal =
        data.fold<double>(0, (m, d) => d.avgCompletion > m ? d.avgCompletion : m);
    final chartMax = maxVal > 0 ? maxVal : 100.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 200,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final heightRatio =
                  chartMax == 0 ? 0.0 : d.avgCompletion / chartMax;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (d.entries > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${d.avgCompletion.round()}%',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppTheme.successColor,
                                  fontSize: 10,
                                ),
                          ),
                        ),
                      Container(
                        height: max(2, 120 * heightRatio),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.successColor,
                              AppTheme.successColor.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        d.mood,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                      ),
                      if (d.entries > 0)
                        Text(
                          '${d.entries}',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                              ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _emptyChartPlaceholder(BuildContext context, String message) {
    return Card(
      child: SizedBox(
        height: 160,
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade400,
                ),
          ),
        ),
      ),
    );
  }

  List<DayTrend> _sampleData(List<DayTrend> data, int maxBars) {
    if (data.length <= maxBars) return data;
    final step = data.length / maxBars;
    return List.generate(
        maxBars, (i) => data[(i * step).floor().clamp(0, data.length - 1)]);
  }

  List<SleepTrendPoint> _sampleSleepData(
      List<SleepTrendPoint> data, int maxBars) {
    if (data.length <= maxBars) return data;
    final step = data.length / maxBars;
    return List.generate(
        maxBars, (i) => data[(i * step).floor().clamp(0, data.length - 1)]);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
