import 'package:flutter/material.dart';

import 'analytics.dart';
import 'car.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class AnalyticsMonthScreen extends StatelessWidget {
  final Analytics analytics;
  const AnalyticsMonthScreen({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    final theme = Theme.of(context);

    final soldList = a.soldThisMonth.toList()
      ..sort((x, y) => y.profit.compareTo(x.profit));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Прибыль за месяц'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _mainCard(a),
          const SizedBox(height: 20),

          // СРАВНЕНИЕ С ПРОШЛЫМ МЕСЯЦЕМ
          const SectionTitle(
            text: 'Сравнение с прошлым месяцем',
            icon: Icons.compare_arrows,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Прибыль в этом месяце',
                  value: money(a.profitThisMonth),
                  valueColor: a.profitThisMonth >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                DetailRow(
                  label: 'Прибыль в прошлом месяце',
                  value: money(a.profitPrevMonth),
                  valueColor: const Color(0xFF94A3B8),
                ),
                const Divider(),
                DetailRow(
                  label: 'Разница',
                  value: (a.trendDiff >= 0 ? '+ ' : '− ') +
                      money(a.trendDiff.abs()),
                  bold: true,
                  valueColor: a.trendDiff >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                if (a.trendPercent != null)
                  DetailRow(
                    label: 'Изменение, %',
                    value:
                        '${a.trendPercent! >= 0 ? '+' : '−'}${a.trendPercent!.abs().toStringAsFixed(1)}%',
                    bold: true,
                    valueColor: (a.trendPercent ?? 0) >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
              ],
            ),
          ),

          // СДЕЛКИ МЕСЯЦА
          const SectionTitle(
            text: 'Сделки месяца',
            icon: Icons.receipt_long_outlined,
          ),
          if (soldList.isEmpty)
            PaddedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'В этом месяце ещё не было продаж',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...soldList.map((c) => _soldTile(c)),

          // РАЗБИВКА ПО МАРКАМ
          const SectionTitle(
            text: 'Прибыль по маркам за месяц',
            icon: Icons.bar_chart_rounded,
          ),
          _brandBreakdown(soldList),
        ],
      ),
    );
  }

  Widget _mainCard(Analytics a) {
    final trendDiff = a.trendDiff;
    final trendPositive = trendDiff >= 0;
    final gradient = trendPositive
        ? const [Color(0xFF10B981), Color(0xFF34D399)]
        : const [Color(0xFFEF4444), Color(0xFFF87171)];

    String trendText = '';
    if (a.soldPrevMonth.isNotEmpty) {
      final sign = trendDiff >= 0 ? '+' : '−';
      final diffAbs = trendDiff.abs();
      final pctAbs = a.trendPercent == null
          ? 0
          : a.trendPercent!.abs();
      trendText = '$sign${pctAbs.toStringAsFixed(0)}% ($sign${moneyShort(diffAbs)})';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ПРИБЫЛЬ ЗА МЕСЯЦ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            money(a.profitThisMonth),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.2,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (trendText.isNotEmpty)
                _miniChip(
                  icon: trendPositive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  text: '$trendText к прошлому',
                ),
              _miniChip(
                icon: Icons.sell_outlined,
                text: '${a.soldThisMonthCount} '
                    '${carsLabel(a.soldThisMonthCount)}',
              ),
              if (a.soldThisMonthCount > 0)
                _miniChip(
                  icon: Icons.percent,
                  text: 'ср. маржа ${a.avgMarginThisMonthPercent.toStringAsFixed(0)}%',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
    Widget _soldTile(Car c) {
    final days = c.daysInStock;
    final positive = c.profit >= 0;
    final color = positive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: PaddedCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${c.make} ${c.model}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  money(c.profit),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  '$days дн. на складе',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.attach_money,
                  size: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'вложено ${money(c.invested)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (c.saleDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Продано ${formatDate(c.saleDateTime!)}',
                style: TextStyle(
                  fontSize: 11.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _brandBreakdown(List<Car> soldList) {
    if (soldList.isEmpty) {
      return PaddedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Нет данных',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final map = <String, List<Car>>{};
    for (final c in soldList) {
      final brand = c.make.trim().isEmpty ? 'Без марки' : c.make.trim();
      map.putIfAbsent(brand, () => []).add(c);
    }

    final list = map.entries.map((e) {
      final total = e.value.fold(0.0, (s, c) => s + c.profit);
      return MapEntry(e.key, {'count': e.value.length, 'profit': total});
    }).toList()
      ..sort((a, b) => (b.value['profit'] as double)
          .compareTo(a.value['profit'] as double));

    return PaddedCard(
      child: Column(
        children: list.map((e) {
          final count = e.value['count'] as int;
          final profit = e.value['profit'] as double;
          final isPositive = profit >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                Text(
                  '$count ${carsLabel(count)}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  money(profit),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isPositive
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
