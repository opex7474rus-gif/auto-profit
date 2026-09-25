import 'package:flutter/material.dart';

import 'analytics.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class AnalyticsInvestedScreen extends StatelessWidget {
  final Analytics analytics;
  const AnalyticsInvestedScreen({super.key, required this.analytics});

  @override
  Widget build(BuildContext context) {
    final a = analytics;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Вложено')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _mainCard(a),
          const SizedBox(height: 20),

          // СТРУКТУРА ВЛОЖЕНИЙ
          const SectionTitle(
            text: 'Структура вложений',
            icon: Icons.pie_chart_outline,
          ),
          PaddedCard(
            child: Column(
              children: [
                _progressRow(
                  context,
                  label: 'Закуп',
                  value: a.totalInvested,
                  part: a.totalPurchase,
                  color: const Color(0xFF4A4FC7),
                ),
                const SizedBox(height: 12),
                _progressRow(
                  context,
                  label: 'Расходы',
                  value: a.totalInvested,
                  part: a.totalExpenses,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),

          // ВЛОЖЕНИЯ В НАЛИЧИИ VS ПРОДАННЫЕ
          const SectionTitle(
            text: 'Где сейчас деньги',
            icon: Icons.call_split_rounded,
          ),
          PaddedCard(
            child: Column(
              children: [
                DetailRow(
                  label: 'В машинах в наличии',
                  value: money(a.totalInvestedStock),
                  valueColor: const Color(0xFFFF7A45),
                ),
                DetailRow(
                  label: 'В проданных машинах',
                  value: money(a.totalInvestedSold),
                  valueColor: const Color(0xFF10B981),
                ),
                const Divider(),
                DetailRow(
                  label: 'Всего вложено',
                  value: money(a.totalInvested),
                  bold: true,
                  valueColor: const Color(0xFF4A4FC7),
                ),
              ],
            ),
          ),

          // ДЕТАЛИЗАЦИЯ ПО КАЖДОЙ МАШИНЕ
          const SectionTitle(
            text: 'Вложено по машинам',
            icon: Icons.list_alt_rounded,
          ),
          if (a.cars.isEmpty)
            PaddedCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Машин пока нет',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            ...a.cars.map((c) => _carTile(context, c)),

          // ВСЕ КАТЕГОРИИ РАСХОДОВ
          const SectionTitle(
            text: 'Все категории расходов',
            icon: Icons.local_gas_station_outlined,
          ),
          _allCategories(context, a),
        ],
      ),
    );
  }

  Widget _mainCard(Analytics a) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
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
                  Icons.account_balance_wallet_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'ВСЕГО ВЛОЖЕНО',
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
            money(a.totalInvested),
            style: const TextStyle(
              fontSize: 34,
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
                icon: Icons.shopping_cart_outlined,
                text: 'закуп ${moneyShort(a.totalPurchase)}',
              ),
              _miniChip(
                icon: Icons.build_outlined,
                text: 'расходы ${moneyShort(a.totalExpenses)}',
              ),
              _miniChip(
                icon: Icons.directions_car_outlined,
                text: '${a.cars.length} ${carsLabel(a.cars.length)}',
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

  Widget _progressRow(
    BuildContext context, {
    required String label,
    required double value,
    required double part,
    required Color color,
  }) {
    final pct = value == 0 ? 0.0 : (part / value) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
            Text(
              '${money(part)} · ${pct.toStringAsFixed(0)}%',
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
            value: (pct / 100).clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _carTile(BuildContext context, dynamic c) {
    final theme = Theme.of(context);
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
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  money(c.invested),
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0EA5E9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'закуп ${money(c.purchase)} · расходы ${money(c.expensesTotal)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _allCategories(BuildContext context, Analytics a) {
    final list = a.allExpenseCategories;
    if (list.isEmpty) {
      return PaddedCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Расходов пока нет',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    const palette = [
      Color(0xFF4A4FC7),
      Color(0xFFFF7A45),
      Color(0xFF9B5DE5),
      Color(0xFF06B6D4),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFFEC4899),
      Color(0xFFEF4444),
    ];
    return PaddedCard(
      child: Column(
        children: list.asMap().entries.map((e) {
          final idx = e.key;
          final s = e.value;
          final pct = a.totalExpenses == 0
              ? 0.0
              : (s.amount / a.totalExpenses) * 100;
          final color = palette[idx % palette.length];
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
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(color),
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
