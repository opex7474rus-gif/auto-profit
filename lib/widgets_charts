import 'package:flutter/material.dart';

import 'analytics.dart';
import 'car.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class ExpensesTopCard extends StatelessWidget {
  final List<CategoryStat> stats;
  final double totalExpenses;

  const ExpensesTopCard({
    super.key,
    required this.stats,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return PaddedCard(
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            const Text('Расходов ещё нет'),
          ],
        ),
      );
    }
    const palette = [
      Color(0xFF4A4FC7),
      Color(0xFFFF7A45),
      Color(0xFF9B5DE5),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
    ];
    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < stats.length; i++)
            Builder(builder: (context) {
              final s = stats[i];
              final pct = totalExpenses == 0
                  ? 0.0
                  : (s.amount / totalExpenses) * 100;
              final color = palette[i % palette.length];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          money(s.amount),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${pct.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (pct / 100).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor:
                            color.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class MonthlyChart extends StatelessWidget {
  final List<MonthStat> stats;
  const MonthlyChart({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();
    final maxProfit = stats
        .map((m) => m.profit.abs())
        .fold<double>(0, (a, b) => a > b ? a : b);
    final theme = Theme.of(context);
    final positiveColor = const Color(0xFF10B981);
    final negativeColor = const Color(0xFFEF4444);

    return PaddedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: stats.map((m) {
                final positive = m.profit >= 0;
                final value = maxProfit == 0
                    ? 0.0
                    : (m.profit.abs() / maxProfit);
                final barHeight = 12 + 88 * value;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            m.profit == 0 ? '—' : moneyShort(m.profit),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: positive
                                  ? positiveColor
                                  : negativeColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: positive
                                  ? [
                                      positiveColor,
                                      positiveColor
                                          .withValues(alpha: 0.6),
                                    ]
                                  : [
                                      negativeColor,
                                      negativeColor
                                          .withValues(alpha: 0.6),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          m.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Прибыль по месяцам (последние 6)',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class BestWorstCard extends StatelessWidget {
  final Car? best;
  final Car? worst;

  const BestWorstCard({super.key, required this.best, required this.worst});

  @override
  Widget build(BuildContext context) {
    if (best == null && worst == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _miniCard(
            context,
            title: 'Лучшая',
            car: best,
            icon: Icons.emoji_events_outlined,
            color: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniCard(
            context,
            title: 'Худшая',
            car: worst,
            icon: Icons.trending_down,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _miniCard(
    BuildContext context, {
    required String title,
    required Car? car,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (car != null) ...[
            Text(
              '${car.make} ${car.model}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              money(car.profit),
              style: TextStyle(
                color: car.profit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ] else
            const Text('—'),
        ],
      ),
    );
  }
}
