import 'package:flutter/material.dart';

import 'analytics.dart';
import 'analytics_invested_screen.dart';
import 'analytics_month_screen.dart';
import 'analytics_stock_screen.dart';
import 'analytics_total_screen.dart';
import 'car.dart';
import 'partner_screen.dart';
import 'utils.dart';
import 'widgets_charts.dart';
import 'widgets_ui.dart';

class AnalyticsSection extends StatefulWidget {
  final Analytics analytics;
  final List<Car> allCars;
  final void Function(Car) onOpenCar;

  const AnalyticsSection({
    super.key,
    required this.analytics,
    required this.allCars,
    required this.onOpenCar,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.analytics;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainProfitCard(context, a),
        const SizedBox(height: 10),
        _buildGrid(context, a),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => expanded = !expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      expanded
                          ? 'Свернуть подробную аналитику'
                          : 'Развернуть подробную аналитику',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.analytics_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded) ...[
                  const SizedBox(height: 4),
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
                label: 'Закупка всего',
                value: money(a.totalPurchase),
              ),
              DetailRow(
                label: 'Расходы всего',
                value: money(a.totalExpenses),
              ),
              const Divider(),
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
              DetailRow(
                label: 'Всего вложено в наличие',
                value: money(a.totalInvestedStock),
                valueColor: const Color(0xFFF59E0B),
              ),
              const SizedBox(height: 4),
              DetailRow(
                label: 'Закуп в проданных',
                value: money(a.totalPurchaseSold),
              ),
              DetailRow(
                label: 'Расходы в проданных',
                value: money(a.totalExpensesSold),
              ),
              DetailRow(
                label: 'Всего вложено в проданные',
                value: money(a.totalInvestedSold),
              ),
              const Divider(),
              DetailRow(
                label: 'Прибыль за месяц',
                value: money(a.profitThisMonth),
                valueColor: a.profitThisMonth >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              DetailRow(
                label: 'Прибыль за прошлый месяц',
                value: money(a.profitPrevMonth),
              ),
              DetailRow(
                label: 'Прибыль за всё время',
                value: money(a.totalProfit),
                valueColor: a.totalProfit >= 0
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
        const SectionTitle(
          text: 'Разделение прибыли с партнёром',
          icon: Icons.handshake_outlined,
        ),
        PaddedCard(
          child: Column(
            children: [
              if (a.partnerCarsCount == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Доля партнёра нигде не указана',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else ...[
                DetailRow(
                  label: 'Всего вложено партнёром',
                  value: money(a.totalPartnerInvestment),
                  valueColor: const Color(0xFF9B5DE5),
                ),
                DetailRow(
                  label: 'Указано в машинах',
                  value: '${a.partnerCarsCount} '
                      '${carsLabel(a.partnerCarsCount)}',
                ),
                const Divider(),
                DetailRow(
                  label: 'Доля партнёра в наличии',
                  value: money(a.totalPartnerStock),
                  valueColor: const Color(0xFF9B5DE5),
                ),
                DetailRow(
                  label: 'Машин в наличии с долей',
                  value: '${a.partnerCarsCountStock}',
                ),
                DetailRow(
                  label: 'Доля партнёра в проданных',
                  value: money(a.totalPartnerSold),
                  valueColor: const Color(0xFF9B5DE5),
                ),
                DetailRow(
                  label: 'Машин проданных с долей',
                  value: '${a.partnerCarsCountSold}',
                ),
                const Divider(),
                DetailRow(
                  label: 'Прибыль партнёра',
                  value: money(a.partnerProfitShare),
                  valueColor: const Color(0xFF9B5DE5),
                ),
                DetailRow(
                  label: 'Ваша прибыль',
                  value: money(a.myProfitShare),
                  valueColor: const Color(0xFF10B981),
                ),
              ],
            ],
          ),
        ),
        const SectionTitle(
          text: 'Статистика по маркам',
          icon: Icons.bar_chart_rounded,
        ),
        PaddedCard(
          child: Column(
            children: [
              if (a.brandStats.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Пока нет проданных машин',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...a.brandStats.take(8).map((b) {
                  final isPositive = b.totalProfit >= 0;
                  final daysStr = '${b.avgDays.toStringAsFixed(0)} дн.';
                  final cntStr = '${b.count} шт.';
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                cntStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
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
                              'Ср. срок: $daysStr',
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
                }),
            ],
          ),
        ),
        const SectionTitle(
          text: 'Потенциал склада',
          icon: Icons.lightbulb_outline,
        ),
        PaddedCard(
          child: Column(
            children: [
              DetailRow(
                label: 'Вложено в наличие',
                value: money(a.totalInvestedStock),
                valueColor: const Color(0xFFFF7A45),
              ),
              DetailRow(
                label: 'Средняя маржа по проданным',
                value: '${a.avgMarginAllPercent.toStringAsFixed(1)}%',
                valueColor: const Color(0xFF06B6D4),
              ),
              const Divider(),
              DetailRow(
                label: 'Прогноз прибыли со склада',
                value: money(a.potentialProfit),
                valueColor: const Color(0xFF10B981),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Прогноз основан на средней рентабельности прошлых продаж.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
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
                label: 'Средняя прибыль за месяц',
                value: money(a.averageProfitThisMonth),
              ),
              DetailRow(
                label: 'Средняя прибыль за всё время',
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
            ],
          ),
        ),
        const SectionTitle(
          text: 'Топ-5 расходов',
          icon: Icons.local_gas_station_outlined,
        ),
        ExpensesTopCard(
          stats: a.topExpenseCategories,
          totalExpenses: a.totalExpenses,
        ),
        const SectionTitle(
          text: 'Прибыль по месяцам',
          icon: Icons.calendar_month_outlined,
        ),
        MonthlyChart(stats: a.monthlyStats),
        const SectionTitle(
          text: 'Лучшая и худшая машина',
          icon: Icons.emoji_events_outlined,
        ),
        BestWorstCard(best: a.bestCar, worst: a.worstCar),
        const SizedBox(height: 12),
      ],
    ],
  );
  }
    Widget _buildMainProfitCard(BuildContext context, Analytics a) {
    final trendPercent = a.trendPercent;
    final trendDiff = a.trendDiff;

    String? trendText;
    bool? trendPositive;

    if (a.soldPrevMonth.isEmpty && a.soldThisMonthCount > 0) {
      trendText = '${a.soldThisMonthCount} '
          '${carsLabel(a.soldThisMonthCount)}';
      trendPositive = true;
    } else if (a.soldPrevMonth.isNotEmpty) {
      final sign = trendDiff >= 0 ? '+' : '−';
      final diffAbs = trendDiff.abs();
      final pctAbs = trendPercent == null ? 0 : trendPercent.abs();
      trendText =
          '$sign${pctAbs.toStringAsFixed(0)}% ($sign${moneyShort(diffAbs)})';
      trendPositive = trendDiff >= 0;
    }

    final marginPct = a.avgMarginThisMonthPercent;
    final marginText = a.soldThisMonthCount == 0
        ? null
        : 'Средняя маржа: ${moneyShort(a.averageProfitThisMonth)} '
            '(${marginPct.toStringAsFixed(0)}%)';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyticsMonthScreen(analytics: a),
          ),
        );
      },
      child: WideKpiCard(
        title: 'ПРИБЫЛЬ ЗА МЕСЯЦ',
        value: money(a.profitThisMonth),
        subtitle: a.soldThisMonthCount == 0
            ? 'В этом месяце ещё нет продаж'
            : '${a.soldThisMonthCount} '
                '${carsLabel(a.soldThisMonthCount)} продано',
        trendText: trendText,
        trendPositive: trendPositive,
        marginText: marginText,
        icon: Icons.savings_outlined,
        gradient: const [
          Color(0xFF4A4FC7),
          Color(0xFF6D72E0),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, Analytics a) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.38,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsStockScreen(
                  analytics: a,
                  onOpenCar: widget.onOpenCar,
                  onChanged: () {},
                ),
              ),
            );
          },
          child: KpiCard(
            title: 'В наличии',
            value: '${a.stockCars.length}',
            subtitle: a.staleCountStock == 0
                ? 'все в работе'
                : '${a.staleCountStock} залежались',
            icon: Icons.directions_car_filled_outlined,
            color: const Color(0xFFFF7A45),
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsInvestedScreen(analytics: a),
              ),
            );
          },
          child: KpiCard(
            title: 'Вложено',
            value: moneyShort(a.totalInvested),
            subtitle: 'закуп + расходы',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF0EA5E9),
          ),
        ),
        if (a.partnerCarsCount > 0)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerScreen(cars: widget.allCars),
                ),
              );
            },
            child: KpiCard(
              title: 'Партнёр',
              value: 'Вам: ${moneyShort(a.myProfitShare)}',
              subtitle: 'Ему: ${moneyShort(a.partnerProfitShare)}',
              icon: Icons.handshake_outlined,
              color: const Color(0xFF9B5DE5),
            ),
          )
        else
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerScreen(cars: widget.allCars),
                ),
              );
            },
            child: KpiCard(
              title: 'Средний срок',
              value: a.soldCars.isEmpty
                  ? '—'
                  : '${a.averageDaysToSell.toStringAsFixed(0)} дн.',
              subtitle: 'от покупки до продажи',
              icon: Icons.schedule_outlined,
              color: const Color(0xFF9B5DE5),
            ),
          ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsTotalScreen(
                  analytics: a,
                  onOpenCar: widget.onOpenCar,
                ),
              ),
            );
          },
          child: KpiCard(
            title: 'Прибыль всего',
            value: moneyShort(a.totalProfit),
            subtitle:
                '${a.soldAllTimeCount} ${carsLabel(a.soldAllTimeCount)} · '
                'ср. ${a.avgMarginAllPercent.toStringAsFixed(0)}%',
            icon: Icons.trending_up,
            color: a.totalProfit >= 0
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}
