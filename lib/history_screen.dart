import 'package:flutter/material.dart';

import 'car.dart';
import 'utils.dart';
import 'widgets_ui.dart';

class HistoryEvent {
  final DateTime date;
  final String type;
  final Car car;
  final double amount;
  HistoryEvent({
    required this.date,
    required this.type,
    required this.car,
    required this.amount,
  });
}

class HistoryScreen extends StatelessWidget {
  final List<Car> cars;
  const HistoryScreen({super.key, required this.cars});

  List<HistoryEvent> _events() {
    final list = <HistoryEvent>[];
    for (final c in cars) {
      final pd = c.purchaseDateTime;
      if (pd != null) {
        list.add(HistoryEvent(
          date: pd,
          type: 'Покупка',
          car: c,
          amount: c.purchase,
        ));
      }
      final sd = c.saleDateTime;
      if (sd != null) {
        list.add(HistoryEvent(
          date: sd,
          type: 'Продажа',
          car: c,
          amount: c.sale,
        ));
      }
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final events = _events();
    return Scaffold(
      appBar: AppBar(title: const Text('История покупок и продаж')),
      body: events.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              title: 'Пока нет ни покупок, ни продаж',
              subtitle: 'История появится по мере работы',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final isBuy = e.type == 'Покупка';
                final color = isBuy
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF10B981);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: PaddedCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isBuy
                                ? Icons.shopping_cart_outlined
                                : Icons.sell_outlined,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e.car.make} ${e.car.model}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${formatDate(e.date)} · ${e.type}',
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
                          money(e.amount),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
