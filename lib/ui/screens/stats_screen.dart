import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/habits_provider.dart';
import '../../providers/journal_provider.dart';
import '../../providers/sleep_provider.dart';
import '../theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final journalAsync = ref.watch(journalProvider);
    final sleepAsync = ref.watch(sleepProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Insights',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildMetricsGrid(
                  context,
                  habitsAsync: habitsAsync,
                  journalAsync: journalAsync,
                  sleepAsync: sleepAsync,
                ),
                const SizedBox(height: 32),
                Text(
                  'Sleep Trend (Last 7 Days)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                _buildSleepChart(context, sleepAsync: sleepAsync),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(
    BuildContext context, {
    required AsyncValue habitsAsync,
    required AsyncValue journalAsync,
    required AsyncValue sleepAsync,
  }) {
    if (habitsAsync.isLoading || journalAsync.isLoading || sleepAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final journals = journalAsync.valueOrNull ?? [];
    final sleeps = sleepAsync.valueOrNull ?? [];

    // Calculate Average Sleep (7 days)
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentSleeps = sleeps.where((s) => s.date.isAfter(sevenDaysAgo)).toList();
    final avgSleep = recentSleeps.isEmpty
        ? 0.0
        : recentSleeps.map((s) => s.hours).reduce((a, b) => a + b) /
            recentSleeps.length;

    // Total Journals
    final totalJournals = journals.length;

    // Habit Completion Rate
    // Basic calculation: (total completions / total possible completions today)
    // If we just want a simple aggregated metric:
    // Assuming we have a provider for today's completed habit IDs
    // For this simple stat, we'll just show "Active Habits" or a placeholder if we don't have historical completions loaded here.
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Avg Sleep',
            value: '${avgSleep.toStringAsFixed(1)}h',
            subtitle: 'Last 7 days',
            icon: Icons.bedtime,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Journals',
            value: '$totalJournals',
            subtitle: 'Total written',
            icon: Icons.book,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildSleepChart(BuildContext context, {required AsyncValue sleepAsync}) {
    if (sleepAsync.isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    
    final sleeps = sleepAsync.valueOrNull ?? [];
    final now = DateTime.now();
    
    // Generate last 7 days data
    final chartData = List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      final dateOnly = DateTime(date.year, date.month, date.day);
      final log = sleeps.cast().firstWhere(
            (s) => s.date == dateOnly,
            orElse: () => null,
          );
      return {'date': date, 'hours': log?.hours ?? 0.0};
    });

    final maxHours = chartData.fold<double>(0.0, (max, item) => item['hours'] as double > max ? item['hours'] as double : max);
    final chartMax = maxHours > 8.0 ? maxHours : 8.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          height: 200,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: chartData.map((data) {
              final hours = data['hours'] as double;
              final heightRatio = chartMax == 0 ? 0.0 : hours / chartMax;
              final date = data['date'] as DateTime;
              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    hours > 0 ? hours.toStringAsFixed(1) : '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 120 * heightRatio,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    days[date.weekday - 1],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
