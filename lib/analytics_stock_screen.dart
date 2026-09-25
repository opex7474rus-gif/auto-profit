import 'package:flutter/material.dart';

import 'analytics.dart';
import 'car.dart';
import 'car_details_screen.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class AnalyticsStockScreen extends StatelessWidget {
  final Analytics analytics;
  final void Function(Car) onOpenCar;
  final VoidCallback onChanged;

  const AnalyticsStockScreen({
    super.key,
    required this.analytics,
    required this.onOpenCar,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    final theme = Theme.of(context);

    final stockList = a.stockCars.toList()
      ..sort((x, y) => y.daysInStock.compareTo(x.daysInStock));

    return Scaffold(
      appBar: AppBar(
        title: const Text('В наличии'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _mainCard(a),
          const SizedBox(height: 20),

          // РАСПРЕДЕЛЕНИЕ ПО ДНЯМ
          const SectionTitle(
            text: 'Распределение по дням на складе',
            icon: Icons.schedule_outlined,
          ),
          PaddedCard(
            child: Column(
              children: a.stockByDays.map((b) {
                final maxCount = a.stockByDays
                    .map((x) => x.count)
                    .fold<int>(1, (m, x) => x > m ? x : m);
                final pct =
                    maxCount == 0 ? 0.0 : b.count / maxCount;
                final color = _bucketColor(b.label);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          Text(
                            '${b.count} ${carsLabel(b.count)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor:
                              color.withValues(alpha: 0.12),
                          valueColor:
                              AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          // ФИНАНСЫ ПО СКЛАДУ
          const SectionTitle(
            text: 'Финансы по складу',
            icon: Icons.account_balance_wallet_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Закуп в наличии',
                  value: money(a.totalPurchaseStock),
                  valueColor: const Color(0xFFFF7A45),
                ),
                DetailRow(
                  label: 'Расходы в наличии',
                  value: money(a.totalExpensesStock),
                  valueColor: const Color(0xFFEF4444),
                ),
                const Divider(),
                DetailRow(
                  label: 'Всего вложено в наличие',
                  value: money(a.totalInvestedStock),
                  bold: true,
                  valueColor: const Color(0xFF4A4FC7),
                ),
                const Divider(),
                DetailRow(
                  label: 'Прогноз прибыли со склада',
                  value: money(a.potentialProfit),
                  bold: true,
                  valueColor: const Color(0xFF10B981),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Прогноз основан на средней марже прошлых продаж.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // СРЕДНИЕ ПО СКЛАДУ
          const SectionTitle(
            text: 'Средние показатели',
            icon: Icons.analytics_outlined,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'Средняя цена закупки',
                  value: a.stockCars.isEmpty
                      ? '—'
                      : money(a.totalPurchaseStock /
                          a.stockCars.length),
                ),
                DetailRow(
                  label: 'Средние вложения в машину',
                  value: a.stockCars.isEmpty
                      ? '—'
                      : money(a.totalInvestedStock /
                          a.stockCars.length),
                ),
                DetailRow(
                  label: 'Среднее время в наличии',
                  value: a.stockCars.isEmpty
                      ? '—'
                      : '${(a.stockCars.map((c) => c.daysInStock).reduce((x, y) => x + y) / a.stockCars.length).toStringAsFixed(0)} дн.',
                ),
              ],
            ),
          ),

          // СПИСОК МАШИН
          const SectionTitle(
            text: 'Машины на складе',
            icon: Icons.directions_car_outlined,
          ),
          if (stockList.isEmpty)
            PaddedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Склад пуст',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...stockList.map((c) => _stockTile(context, c)),
        ],
      ),
    );
  }
    Widget _mainCard(Analytics a) {
    final staleCount = a.staleCountStock;
    final isGood = staleCount == 0;

    final gradient = isGood
        ? const [Color(0xFFFF7A45), Color(0xFFFFA76C)]
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
                  Icons.directions_car_filled_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'МАШИН В НАЛИЧИИ',
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
            '${a.stockCars.length}',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1.5,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _miniChip(
                icon: Icons.attach_money,
                text: 'вложено ${moneyShort(a.totalInvestedStock)}',
              ),
              if (isGood)
                _miniChip(
                  icon: Icons.check_circle_outline,
                  text: 'все в работе',
                )
              else
                _miniChip(
                  icon: Icons.warning_amber_rounded,
                  text: '$staleCount залежались',
                ),
              _miniChip(
                icon: Icons.schedule_rounded,
                text: a.stockCars.isEmpty
                    ? '—'
                    : 'ср. ${(a.stockCars.map((c) => c.daysInStock).reduce((x, y) => x + y) / a.stockCars.length).toStringAsFixed(0)} дн.',
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

  Color _bucketColor(String label) {
    if (label.startsWith('0')) return const Color(0xFF10B981);
    if (label.startsWith('15')) return const Color(0xFF06B6D4);
    if (label.startsWith('30')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _stockTile(BuildContext context, Car c) {
    final days = c.daysInStock;
    Color daysColor = const Color(0xFF10B981);
    if (days >= 60) {
      daysColor = const Color(0xFFEF4444);
    } else if (days >= 30) {
      daysColor = const Color(0xFFF59E0B);
    } else if (days >= 15) {
      daysColor = const Color(0xFF06B6D4);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => onOpenCar(c),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: daysColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$days дн.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: daysColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'вложено ${money(c.invested)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                    ),
                    if (c.partnerAmount > 0) ...[
                      const SizedBox(width: 10),
                      Icon(
                        Icons.handshake_outlined,
                        size: 14,
                        color: const Color(0xFF9B5DE5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'партнёр ${money(c.partnerAmount)}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF9B5DE5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
