import 'package:flutter/material.dart';

import 'analytics.dart';
import 'car.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class AnalyticsTotalScreen extends StatelessWidget {
  final Analytics analytics;
  final void Function(Car) onOpenCar;

  const AnalyticsTotalScreen({
    super.key,
    required this.analytics,
    required this.onOpenCar,
  });

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Прибыль всего')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _mainCard(a),
          const SizedBox(height: 20),

          // ОБЩИЕ ФИНАНСЫ
          const SectionTitle(
            text: 'Общие финансы',
            icon: Icons.receipt_long_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Вложено всего',
                  value: money(a.totalInvested),
                  valueColor: const Color(0xFF4A4FC7),
                ),
                DetailRow(
                  label: 'Заработано',
                  value: money(a.totalRevenue),
                  valueColor: const Color(0xFF06B6D4),
                ),
                const Divider(),
                DetailRow(
                  label: 'Прибыль всего',
                  value: money(a.totalProfit),
                  bold: true,
                  valueColor: a.totalProfit >= 0
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
                DetailRow(
                  label: 'Средняя маржа',
                  value:
                      '${a.avgMarginAllPercent.toStringAsFixed(1)}%',
                  valueColor: const Color(0xFF10B981),
                ),
              ],
            ),
          ),

          // СРЕДНИЕ ПОКАЗАТЕЛИ
          const SectionTitle(
            text: 'Средние показатели',
            icon: Icons.analytics_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Средняя цена закупки',
                  value: money(a.averagePurchase),
                ),
                DetailRow(
                  label: 'Средняя цена продажи',
                  value: money(a.averageSalePrice),
                ),
                DetailRow(
                  label: 'Средняя прибыль',
                  value: money(a.averageProfit),
                ),
                DetailRow(
                  label: 'Средние вложения в машину',
                  value: money(a.averageInvestment),
                ),
                DetailRow(
                  label: 'Средний срок продажи',
                  value: a.soldCars.isEmpty
                      ? '—'
                      : '${a.averageDaysToSell.toStringAsFixed(1)} дн.',
                ),
                DetailRow(
                  label: 'Средний срок (послед. 3 мес.)',
                  value: a.averageDaysToSellLast3Months == 0
                      ? '—'
                      : '${a.averageDaysToSellLast3Months.toStringAsFixed(1)} дн.',
                ),
              ],
            ),
          ),

          // ТОП-10 ПО ПРИБЫЛИ
          const SectionTitle(
            text: 'Топ-10 по прибыли',
            icon: Icons.emoji_events_outlined,
          ),
          if (a.top10ByProfit.isEmpty)
            PaddedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Нет проданных машин',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...a.top10ByProfit.asMap().entries.map(
                  (e) => _topTile(
                    context,
                    position: e.key + 1,
                    car: e.value,
                    positive: true,
                  ),
                ),

          // ТОП УБЫТКОВ
          if (a.top10ByLoss.isNotEmpty) ...[
            const SectionTitle(
              text: 'Топ по убытку',
              icon: Icons.trending_down_rounded,
            ),
            ...a.top10ByLoss.asMap().entries.map(
                  (e) => _topTile(
                    context,
                    position: e.key + 1,
                    car: e.value,
                    positive: false,
                  ),
                ),
          ],

          // ПРИБЫЛЬ ПО МЕСЯЦАМ
          const SectionTitle(
            text: 'Прибыль по всем месяцам',
            icon: Icons.calendar_month_outlined,
          ),
          _allMonths(a),

          // ПРИБЫЛЬ ПО МАРКАМ
          const SectionTitle(
            text: 'Прибыль по маркам',
            icon: Icons.bar_chart_rounded,
          ),
          _brandStats(a),
        ],
      ),
    );
  }

  Widget _mainCard(Analytics a) {
    final positive = a.totalProfit >= 0;
    final gradient = positive
        ? const [Color(0xFF10B981), Color(0xFF34D399)]
        : const [Color(0xFFEF4444), Color(0xFFF87171)];

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
                  Icons.trending_up,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ПРИБЫЛЬ ВСЕГО',
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
            money(a.totalProfit),
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
              _miniChip(
                icon: Icons.sell_outlined,
                text: '${a.soldAllTimeCount} '
                    '${carsLabel(a.soldAllTimeCount)} продано',
              ),
              _miniChip(
                icon: Icons.percent,
                text:
                    'ср. маржа ${a.avgMarginAllPercent.toStringAsFixed(0)}%',
              ),
              if (a.partnerCarsCount > 0)
                _miniChip(
                  icon: Icons.handshake_outlined,
                  text:
                      'вам ${moneyShort(a.myProfitShare)}',
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

  Widget _topTile(
    BuildContext context, {
    required int position,
    required Car car,
    required bool positive,
  }) {
    final color = positive
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpenCar(car),
          child: PaddedCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${car.make} ${car.model}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${car.daysInStock} дн. · вложено ${moneyShort(car.invested)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  money(car.profit),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _allMonths(Analytics a) {
    final list = a.allMonthlyStats;
    if (list.isEmpty) {
      return PaddedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Нет проданных машин',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return PaddedCard(
      child: Column(
        children: list.map((m) {
          final positive = m.profit >= 0;
          final color = positive
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 60,
                  child: Text(
                    m.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${m.count} ${carsLabel(m.count)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  money(m.profit),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _brandStats(Analytics a) {
    final list = a.brandStats;
    if (list.isEmpty) {
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
    return PaddedCard(
      child: Column(
        children: list.map((b) {
          final isPositive = b.totalProfit >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    Text(
                      '${b.count} ${carsLabel(b.count)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Прибыль: ${money(b.totalProfit)}',
                      style: TextStyle(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    Text(
                      'Ср. маржа: ${b.avgProfit.toStringAsFixed(0)} ₽ · ${b.avgDays.toStringAsFixed(0)} дн.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 14),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
